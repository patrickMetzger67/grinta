import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:web/web.dart' as web;

class CapturedDetectionFrame {
  const CapturedDetectionFrame({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final List<int> bytes;
  final int width;
  final int height;
}

class _SampledFrame {
  const _SampledFrame({
    required this.pixels,
    required this.width,
    required this.height,
  });

  final List<int> pixels;
  final int width;
  final int height;
}

/// Web player detector: YOLOv8n (ONNX Runtime) + HTML canvas overlay.
///
/// The overlay is drawn in the DOM so boxes stay visible above the
/// `video_player` platform view.
class DebugPlayerDetector {
  DebugPlayerDetector._();

  static final DebugPlayerDetector instance = DebugPlayerDetector._();

  static const String _ortScript =
      'https://cdn.jsdelivr.net/npm/onnxruntime-web@1.21.0/dist/ort.min.js';
  static const String _yoloScript = 'yolo_player_detect.js';
  static const String _tesseractScript =
      'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';

  JSObject? _yolo;
  bool _ready = false;
  Future<void>? _readyFuture;
  bool _starting = false;
  bool _running = false;
  bool _busy = false;
  web.HTMLCanvasElement? _overlay;
  web.HTMLVideoElement? _probe;
  String _probeSrc = '';
  String _srcHint = '';
  String? _objectUrl;
  Color _associatedColor = const Color(0xFF1FA971);
  int? _team1KitColor;
  int? _team2KitColor;
  int? _refereeKitColor;
  String? _team1Id;
  String? _team2Id;
  ValueChanged<List<PlayerDetectionBox>>? _onBoxes;
  bool _labeling = false;
  ValueChanged<PlayerDetectionBox>? _onManualBox;
  VoidCallback? _onDrawStart;
  List<AssociatedPlayerTrack> _tracks = const <AssociatedPlayerTrack>[];
  List<PlayerDetectionBox> _lastAutoBoxes = const <PlayerDetectionBox>[];
  List<PlayerDetectionBox> _lastBallBoxes = const <PlayerDetectionBox>[];
  _SampledFrame? _lastSample;
  PitchRegion? _lastPitch;
  bool _analyzePlayback = false;
  double? _lastStillTime;
  PlayerDetectionBox? _draftFrame;
  web.HTMLElement? _pointerLockedParent;
  String _pointerLockedParentEvents = '';
  Timer? _labelSyncTimer;
  web.HTMLDivElement? _drawHost;
  web.HTMLDivElement? _drawSurface;
  web.HTMLCanvasElement? _drawCanvas;
  web.HTMLVideoElement? _pointerLockedVideo;
  JSFunction? _drawDown;
  JSFunction? _drawMove;
  JSFunction? _drawUp;
  double? _dragX1;
  double? _dragY1;
  double? _dragX2;
  double? _dragY2;

  bool get isSupported => true;

  bool get isReady => _ready;

  bool get isRunning => _running;

  PitchRegion? get lastPitchRegion => _lastPitch;

  void setAnalyzePlayback(bool enabled) {
    _analyzePlayback = enabled;
    if (enabled) {
      _lastStillTime = null;
      _clearOverlay();
    } else {
      _drawOverlay(_mergedBoxes());
    }
  }

  void notifySeek() {
    _lastStillTime = null;
  }

  Future<void> ensureReady() {
    return _readyFuture ??= _loadModel().catchError((Object error) {
      _readyFuture = null;
      throw error;
    });
  }

  Future<void> _loadModel() async {
    if (_ready) return;
    await _loadScript(_ortScript);
    await _loadScript(_yoloScript);
    try {
      await _loadScript(_tesseractScript);
    } catch (_) {}
    final api = globalContext.getProperty('grintaYolo'.toJS);
    if (api == null) {
      throw StateError('yolo-unavailable');
    }
    _yolo = api as JSObject;
    await _promiseToFuture<JSAny?>(_yolo!.callMethod('load'.toJS));
    _ready = true;
  }

  Future<void> start({
    required String videoSrcHint,
    String? storagePath,
    Future<Uint8List> Function(String storagePath)? downloadBytes,
    int? team1KitColor,
    int? team2KitColor,
    int? refereeKitColor,
    String? team1Id,
    String? team2Id,
    required Color boxColor,
    Color? associatedColor,
    required ValueChanged<List<PlayerDetectionBox>> onBoxes,
  }) async {
    if (_starting || _running) return;
    _starting = true;
    setVideoSrcHint(videoSrcHint);
    _associatedColor = associatedColor ?? boxColor;
    _team1KitColor = team1KitColor;
    _team2KitColor = team2KitColor;
    _refereeKitColor = refereeKitColor;
    _team1Id = team1Id;
    _team2Id = team2Id;
    _onBoxes = onBoxes;
    _lastStillTime = null;
    try {
      await ensureReady();
      final detectionSrc = await _resolveDetectionSrc(
        downloadUrl: videoSrcHint,
        storagePath: storagePath,
        downloadBytes: downloadBytes,
      );
      _ensureProbe(detectionSrc);
      _running = true;
      _ensureOverlay();
      unawaited(_loop());
    } finally {
      _starting = false;
    }
  }

  void stop() {
    _running = false;
    _analyzePlayback = false;
    _onBoxes = null;
    _lastAutoBoxes = const <PlayerDetectionBox>[];
    _lastStillTime = null;
    if (_labeling ||
        _draftFrame != null ||
        _tracks.isNotEmpty ||
        _lastBallBoxes.isNotEmpty) {
      _drawOverlay(_mergedBoxes());
      _startLabelSync();
    } else {
      _stopLabelSync();
      _removeOverlay();
    }
    _removeProbe();
    _revokeObjectUrl();
  }

  void setVideoSrcHint(String srcHint) {
    if (srcHint.trim().isEmpty) return;
    if (_srcHint.isNotEmpty && _srcHint != srcHint) {
      _lastPitch = null;
    }
    _srcHint = srcHint;
  }

  void setDraftFrame(
    PlayerDetectionBox? box, {
    ValueChanged<PlayerDetectionBox>? onMoved,
  }) {
    if (box == null) {
      _draftFrame = null;
      _restoreVideoPointers();
      if (!_running && !_labeling) {
        _stopLabelSync();
        _removeOverlay();
      } else {
        _drawOverlay(_mergedBoxes());
      }
      return;
    }
    _draftFrame = box;
    _ensureOverlay();
    _startLabelSync();
    final visible = _findVideoElement(_srcHint);
    if (visible != null) {
      _lockVideoPointers(visible);
      _syncOverlayToVideo(visible);
    }
    _drawOverlay(_mergedBoxes());
  }

  Future<Uint8List?> captureStillPng({
    double? timeSeconds,
    String? downloadUrl,
    String? storagePath,
    Future<Uint8List> Function(String storagePath)? downloadBytes,
  }) async {
    final url = (downloadUrl ?? _srcHint).trim();
    if (url.isNotEmpty) {
      _srcHint = url;
      try {
        await ensureReady();
        final src = await _resolveDetectionSrc(
          downloadUrl: url,
          storagePath: storagePath,
          downloadBytes: downloadBytes,
        );
        final probe = _ensureProbe(src);
        await _waitUntilReadable(probe, const Duration(seconds: 4));
        if (timeSeconds != null) {
          await _seekProbe(probe, timeSeconds);
        }
        final fromProbe = _pngFromVideo(probe);
        if (fromProbe != null && fromProbe.isNotEmpty) return fromProbe;
      } catch (error) {
        debugPrint('DebugPlayerDetector: still probe failed: $error');
      }
    }
    for (final video in <web.HTMLVideoElement?>[_probe, _findVideoElement(_srcHint)]) {
      if (video == null || video.videoWidth <= 0 || video.readyState < 2) {
        continue;
      }
      final png = _pngFromVideo(video);
      if (png != null && png.isNotEmpty) return png;
    }
    return null;
  }

  Uint8List? _pngFromVideo(web.HTMLVideoElement video) {
    if (video.videoWidth <= 0 || video.videoHeight <= 0) return null;
    try {
      final canvas = web.HTMLCanvasElement()
        ..width = video.videoWidth
        ..height = video.videoHeight;
      canvas.context2D.drawImage(
        video,
        0,
        0,
        video.videoWidth,
        video.videoHeight,
      );
      final dataUrl = canvas.toDataUrl('image/png');
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(dataUrl.substring(comma + 1));
    } catch (error) {
      debugPrint('DebugPlayerDetector: still PNG failed: $error');
      return null;
    }
  }

  void setManualLabeling({
    required bool enabled,
    ValueChanged<PlayerDetectionBox>? onBox,
    VoidCallback? onDrawStart,
    String? videoSrcHint,
  }) {
    if (videoSrcHint != null && videoSrcHint.trim().isNotEmpty) {
      _srcHint = videoSrcHint;
    }
    _onManualBox = enabled ? onBox : null;
    _onDrawStart = enabled ? onDrawStart : null;
    if (_labeling == enabled) {
      if (enabled) _syncDrawLayer();
      return;
    }
    _labeling = enabled;
    if (enabled) {
      _ensureOverlay();
      _ensureDrawLayer();
      _startLabelSync();
      _syncDrawLayer();
      scheduleMicrotask(_syncDrawLayer);
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (_labeling) _syncDrawLayer();
      });
      _drawOverlay(_mergedBoxes());
    } else {
      _removeDrawLayer();
      _stopLabelSync();
      if (!_running) {
        _removeOverlay();
      } else {
        final visible = _findVideoElement(_srcHint);
        if (visible != null) _syncOverlayToVideo(visible);
        _drawOverlay(_mergedBoxes());
      }
    }
  }

  void setManualBoxes(List<PlayerDetectionBox> boxes) {
    final existing = <String, AssociatedPlayerTrack>{
      for (final track in _tracks)
        if ((track.box.playerId ?? '').isNotEmpty) track.box.playerId!: track,
    };
    _tracks = [
      for (final box in boxes)
        if ((box.playerId ?? '').trim().isNotEmpty)
          AssociatedPlayerTrack(
            box: box,
            missed: existing[box.playerId]?.missed ?? 0,
          ),
    ];
    _drawOverlay(_mergedBoxes());
  }

  void addAssociatedBox(PlayerDetectionBox box) {
    final playerId = box.playerId?.trim() ?? '';
    if (playerId.isEmpty) return;
    _tracks = [
      ..._tracks.where((track) {
        final id = track.box.playerId?.trim() ?? '';
        if (id == playerId) return false;
        return detectionBoxIou(track.box, box) <= 0.22;
      }),
      AssociatedPlayerTrack(box: box),
    ];
    _drawOverlay(_mergedBoxes());
  }

  void clearAssociations() {
    _tracks = const <AssociatedPlayerTrack>[];
    _lastBallBoxes = const <PlayerDetectionBox>[];
    _drawOverlay(_mergedBoxes());
  }

  void setRoster(List<DebugVideoRosterPlayer> roster) {}

  String? suggestTeamIdForBox(
    PlayerDetectionBox box, {
    String? team1Id,
    String? team2Id,
  }) {
    var sample = _lastSample;
    if (sample == null) {
      final visible = _findVideoElement(_srcHint);
      if (visible != null && _canReadVideo(visible)) {
        sample = _sampleVideoPixels(visible);
        _lastSample = sample;
      }
    }
    if (sample == null) return null;
    return suggestedTeamIdFromKitSample(
      box: box,
      rgba: sample.pixels,
      width: sample.width,
      height: sample.height,
      team1KitColor: _team1KitColor,
      team2KitColor: _team2KitColor,
      team1Id: team1Id,
      team2Id: team2Id,
    );
  }

  List<PlayerDetectionBox> _mergedBoxes([List<PlayerDetectionBox>? automatic]) {
    final persisted = persistAssociatedPlayers(
      current: automatic ?? _lastAutoBoxes,
      tracks: _tracks,
    );
    return [
      ...associatedDetectionBoxes(persisted.boxes),
      ..._lastBallBoxes,
    ];
  }

  List<PlayerDetectionBox> _commitAssociations(
    List<PlayerDetectionBox> people,
  ) {
    final persisted = persistAssociatedPlayers(
      current: people,
      tracks: _tracks,
    );
    _tracks = persisted.tracks;
    return associatedDetectionBoxes(persisted.boxes);
  }

  void _startLabelSync() {
    _labelSyncTimer?.cancel();
    _labelSyncTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_labeling) _syncDrawLayer();
      if (_draftFrame == null &&
          !_labeling &&
          !_running &&
          _tracks.isEmpty &&
          _lastBallBoxes.isEmpty) {
        return;
      }
      final visible = _findVideoElement(_srcHint);
      if (visible == null) return;
      if (_draftFrame != null ||
          _running ||
          _labeling ||
          _tracks.isNotEmpty ||
          _lastBallBoxes.isNotEmpty) {
        _ensureOverlay();
        _syncOverlayToVideo(visible);
        _drawOverlay(_mergedBoxes());
      }
      if (_lastSample == null && _canReadVideo(visible)) {
        _lastSample = _sampleVideoPixels(visible);
      }
    });
  }

  void _stopLabelSync() {
    _labelSyncTimer?.cancel();
    _labelSyncTimer = null;
  }

  static const double _drawControlsReserve = 88;

  void _ensureDrawLayer() {
    if (_drawHost != null) return;
    final host = web.HTMLDivElement()
      ..style.position = 'fixed'
      ..style.zIndex = '2147483646'
      ..style.pointerEvents = 'none'
      ..style.boxSizing = 'border-box'
      ..style.border = 'none'
      ..style.backgroundColor = 'transparent';
    final surface = web.HTMLDivElement()
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.right = '0'
      ..style.cursor = 'crosshair'
      ..style.pointerEvents = 'auto'
      ..style.touchAction = 'none'
      ..style.userSelect = 'none'
      ..style.boxSizing = 'border-box'
      ..style.border = 'none'
      ..style.backgroundColor = 'transparent';
    final canvas = web.HTMLCanvasElement()
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.pointerEvents = 'none';
    host.append(canvas);
    host.append(surface);
    _drawDown = ((web.Event event) {
      _onDrawPointerDown(event as web.PointerEvent);
    }).toJS;
    _drawMove = ((web.Event event) {
      _onDrawPointerMove(event as web.PointerEvent);
    }).toJS;
    _drawUp = ((web.Event event) {
      _onDrawPointerUp(event as web.PointerEvent);
    }).toJS;
    surface.addEventListener('pointerdown', _drawDown);
    web.document.addEventListener('pointerdown', _drawDown, true.toJS);
    web.document.addEventListener('pointermove', _drawMove, true.toJS);
    web.document.addEventListener('pointerup', _drawUp, true.toJS);
    web.document.addEventListener('pointercancel', _drawUp, true.toJS);
    web.document.body?.append(host);
    _drawHost = host;
    _drawSurface = surface;
    _drawCanvas = canvas;
  }

  void _syncDrawLayer() {
    final host = _drawHost;
    final surface = _drawSurface;
    final canvas = _drawCanvas;
    if (host == null || surface == null || canvas == null) return;
    final video = _findVideoElement(_srcHint);
    if (video == null || video.clientWidth <= 0) {
      host.style.display = 'none';
      return;
    }
    host.style.display = 'block';
    final content = _videoContentBoxViewport(video);
    final drawHeight =
        (content.height - _drawControlsReserve).clamp(0.0, content.height);
    host.style
      ..left = '${content.left}px'
      ..top = '${content.top}px'
      ..width = '${content.width}px'
      ..height = '${content.height}px';
    surface.style.height = '${drawHeight}px';
    final pixelWidth = content.width.round().clamp(1, 4096);
    final pixelHeight = content.height.round().clamp(1, 4096);
    if (canvas.width != pixelWidth) canvas.width = pixelWidth;
    if (canvas.height != pixelHeight) canvas.height = pixelHeight;
    _paintDrawDraft();
  }

  ({double left, double top, double width, double height})
      _videoContentBoxViewport(web.HTMLVideoElement video) {
    final rect = video.getBoundingClientRect();
    final elW = rect.width;
    final elH = rect.height;
    final vw = video.videoWidth.toDouble();
    final vh = video.videoHeight.toDouble();
    if (vw <= 0 || vh <= 0 || elW <= 0 || elH <= 0) {
      return (left: rect.left, top: rect.top, width: elW, height: elH);
    }
    final scale = elW / vw < elH / vh ? elW / vw : elH / vh;
    final width = vw * scale;
    final height = vh * scale;
    return (
      left: rect.left + (elW - width) / 2,
      top: rect.top + (elH - height) / 2,
      width: width,
      height: height,
    );
  }

  void _lockVideoPointers(web.HTMLVideoElement video) {
    if (!identical(_pointerLockedVideo, video)) {
      _restoreVideoPointers();
      _pointerLockedVideo = video;
    }
    video.style.pointerEvents = 'none';
    final parent = video.parentElement;
    if (parent is web.HTMLElement &&
        !identical(_pointerLockedParent, parent)) {
      _pointerLockedParent = parent;
      _pointerLockedParentEvents = parent.style.pointerEvents;
      parent.style.pointerEvents = 'none';
    }
  }

  void _restoreVideoPointers() {
    _pointerLockedVideo?.style.pointerEvents = 'auto';
    _pointerLockedVideo = null;
    if (_pointerLockedParent != null) {
      _pointerLockedParent!.style.pointerEvents = _pointerLockedParentEvents;
      _pointerLockedParent = null;
      _pointerLockedParentEvents = '';
    }
  }

  void _removeDrawLayer() {
    final host = _drawHost;
    final surface = _drawSurface;
    if (_drawDown != null) {
      surface?.removeEventListener('pointerdown', _drawDown);
      web.document.removeEventListener('pointerdown', _drawDown, true.toJS);
    }
    if (_drawMove != null) {
      web.document.removeEventListener('pointermove', _drawMove, true.toJS);
      web.document.removeEventListener('pointerup', _drawUp, true.toJS);
      web.document.removeEventListener('pointercancel', _drawUp, true.toJS);
    }
    host?.remove();
    _drawHost = null;
    _drawSurface = null;
    _drawCanvas = null;
    _drawDown = null;
    _drawMove = null;
    _drawUp = null;
    _dragX1 = null;
    _dragY1 = null;
    _dragX2 = null;
    _dragY2 = null;
    _restoreVideoPointers();
  }

  void _onDrawPointerDown(web.PointerEvent event) {
    if (!_labeling) return;
    if (!_isInDrawArea(event)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    _onDrawStart?.call();
    try {
      _drawSurface?.setPointerCapture(event.pointerId);
    } catch (_) {}
    final point = _normalizedDrawPoint(event);
    if (point == null) return;
    _dragX1 = point.$1;
    _dragY1 = point.$2;
    _dragX2 = point.$1;
    _dragY2 = point.$2;
    _paintDrawDraft();
  }

  void _onDrawPointerMove(web.PointerEvent event) {
    if (_dragX1 == null) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    final point = _normalizedDrawPoint(event);
    if (point == null) return;
    _dragX2 = point.$1;
    _dragY2 = point.$2;
    _paintDrawDraft();
  }

  void _onDrawPointerUp(web.PointerEvent event) {
    if (_dragX1 == null) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    final x1 = _dragX1;
    final y1 = _dragY1;
    final x2 = _dragX2;
    final y2 = _dragY2;
    _dragX1 = null;
    _dragY1 = null;
    _dragX2 = null;
    _dragY2 = null;
    _paintDrawDraft();
    if (x1 == null || y1 == null || x2 == null || y2 == null) return;
    final canvas = _drawCanvas;
    final aspect = canvas != null && canvas.height > 0
        ? canvas.width / canvas.height
        : 16 / 9;
    final box = playerBoxFromNormalizedCircle(
      cx: x1,
      cy: y1,
      edgeX: x2,
      edgeY: y2,
      aspectRatio: aspect,
    );
    if (box != null) _onManualBox?.call(box);
  }

  bool _isInDrawArea(web.PointerEvent event) {
    final surface = _drawSurface;
    if (surface == null || _drawHost?.style.display == 'none') return false;
    final rect = surface.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) return false;
    final x = event.clientX;
    final y = event.clientY;
    return x >= rect.left &&
        x <= rect.right &&
        y >= rect.top &&
        y <= rect.bottom;
  }

  (double, double)? _normalizedDrawPoint(web.PointerEvent event) {
    final video = _findVideoElement(_srcHint);
    if (video == null) return null;
    final content = _videoContentBoxViewport(video);
    if (content.width <= 0 || content.height <= 0) return null;
    return (
      ((event.clientX - content.left) / content.width).clamp(0.0, 1.0),
      ((event.clientY - content.top) / content.height).clamp(0.0, 1.0),
    );
  }

  void _paintDrawDraft() {
    final canvas = _drawCanvas;
    if (canvas == null) return;
    final ctx = canvas.context2D;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    final x1 = _dragX1;
    final y1 = _dragY1;
    final x2 = _dragX2;
    final y2 = _dragY2;
    if (x1 == null || y1 == null || x2 == null || y2 == null) return;
    final cx = x1 * canvas.width;
    final cy = y1 * canvas.height;
    final radius = math.sqrt(
      math.pow((x2 - x1) * canvas.width, 2) +
          math.pow((y2 - y1) * canvas.height, 2),
    );
    if (radius < 3) return;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, math.pi * 2);
    ctx.fillStyle = '#1FA971'.toJS;
    ctx.globalAlpha = 0.22;
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.strokeStyle = '#1FA971'.toJS;
    ctx.lineWidth = 3;
    ctx.stroke();
  }

  void updateKitColors({
    int? team1KitColor,
    int? team2KitColor,
    int? refereeKitColor,
    String? team1Id,
    String? team2Id,
  }) {
    _team1KitColor = team1KitColor;
    _team2KitColor = team2KitColor;
    _refereeKitColor = refereeKitColor;
    if (team1Id != null) _team1Id = team1Id;
    if (team2Id != null) _team2Id = team2Id;
    _lastStillTime = null;
  }

  Future<List<PlayerDetectionBox>> detectFromCapturedFrame(
    CapturedDetectionFrame frame,
  ) async {
    return const <PlayerDetectionBox>[];
  }

  Future<void> _loop() async {
    while (_running) {
      if (_busy) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      _busy = true;
      final started = DateTime.now();
      try {
        final visible = _findVideoElement(_srcHint);
        if (visible != null && visible.videoWidth > 0 && visible.videoHeight > 0) {
          _syncOverlayToVideo(visible);
          final stillTime = visible.currentTime;
          final minDelta = _analyzePlayback && !visible.paused ? 0.18 : 0.04;
          final sameStill = _lastStillTime != null &&
              (stillTime - _lastStillTime!).abs() <= minDelta;
          final wantDetect =
              (visible.paused || _analyzePlayback) && !sameStill;
          if (wantDetect) {
            final source = await _lockedProbeFrame(visible);
            if (source != null) {
              final detected = await _detectOnVideo(source);
              final yoloPeople = [
                for (final box in detected)
                  if (box.kind == PlayerDetectionKind.person) box,
              ];
              final yoloBalls = styledBallBoxes(detected);
              final sampled = _sampleVideoPixels(source);
              final pitch = sampled == null
                  ? null
                  : estimatePitchRegion(
                      rgba: sampled.pixels,
                      width: sampled.width,
                      height: sampled.height,
                    );
              if (_lastPitch == null && pitch != null) _lastPitch = pitch;
              var people = keepMatchSheetDetections(
                boxes: yoloPeople,
                pitch: pitch,
                rgba: sampled?.pixels,
                sampleWidth: sampled?.width,
                sampleHeight: sampled?.height,
                team1KitColor: _team1KitColor,
                team2KitColor: _team2KitColor,
                refereeKitColor: _refereeKitColor,
              );
              var balls = [
                for (final box in yoloBalls)
                  if (boxStandsOnPitch(box, pitch)) box,
              ];
              if (sampled != null) {
                if (!_analyzePlayback) {
                  people = mergeDetectionBoxes(
                    people,
                    keepMatchSheetDetections(
                      boxes: detectPlayersFromKitColors(
                        rgba: sampled.pixels,
                        width: sampled.width,
                        height: sampled.height,
                        team1KitColor: _team1KitColor,
                        team2KitColor: _team2KitColor,
                      ),
                      pitch: pitch,
                      rgba: sampled.pixels,
                      sampleWidth: sampled.width,
                      sampleHeight: sampled.height,
                      team1KitColor: _team1KitColor,
                      team2KitColor: _team2KitColor,
                      refereeKitColor: _refereeKitColor,
                    ),
                  );
                }
                balls = mergeDetectionBoxes(
                  balls,
                  detectSoccerBallsFromRgba(
                    rgba: sampled.pixels,
                    width: sampled.width,
                    height: sampled.height,
                  ).where((box) => boxStandsOnPitch(box, pitch)).toList(),
                );
                _lastSample = sampled;
                people = assignTeamIdsFromKit(
                  boxes: people,
                  rgba: sampled.pixels,
                  width: sampled.width,
                  height: sampled.height,
                  team1KitColor: _team1KitColor,
                  team2KitColor: _team2KitColor,
                  team1Id: _team1Id,
                  team2Id: _team2Id,
                );
              }
              _lastAutoBoxes = people;
              _lastBallBoxes = styledBallBoxes(balls);
              _lastStillTime = stillTime;
              final published = [
                ..._commitAssociations(people),
                ..._lastBallBoxes,
              ];
              _drawOverlay(published);
              _onBoxes?.call(published);
            }
          }
        }
      } catch (error) {
        debugPrint('DebugPlayerDetector: detect tick failed: $error');
      } finally {
        _busy = false;
      }
      final elapsed = DateTime.now().difference(started);
      final wait = const Duration(milliseconds: 80) - elapsed;
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
    }
  }

  Future<List<PlayerDetectionBox>> _detectOnVideo(
    web.HTMLVideoElement video,
  ) async {
    final yolo = _yolo;
    if (yolo == null || !_ready) return const <PlayerDetectionBox>[];
    final raw = await _promiseToFuture<JSAny>(
      yolo.callMethod('detect'.toJS, video, 40.toJS, 0.20.toJS),
    );
    return _boxesFromJsPredictions(
      raw,
      imageWidth: video.videoWidth.toDouble(),
      imageHeight: video.videoHeight.toDouble(),
    );
  }

  List<PlayerDetectionBox> _boxesFromJsPredictions(
    JSAny? raw, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (raw == null) return const <PlayerDetectionBox>[];
    final decoded = raw.dartify();
    if (decoded is List) {
      final fromDart = playerBoxesFromCocoPredictions(
        predictions: decoded,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
      if (fromDart.isNotEmpty) return fromDart;
    }

    final root = raw as JSObject;
    final length = _jsLength(root);
    if (length <= 0) return const <PlayerDetectionBox>[];
    final boxes = <PlayerDetectionBox>[];
    for (var i = 0; i < length; i++) {
      final item = root.getProperty(i.toJS);
      if (item == null) continue;
      final pred = item as JSObject;
      final label = pred.getProperty('class'.toJS)?.dartify()?.toString() ??
          pred.getProperty('label'.toJS)?.dartify()?.toString() ??
          '';
      final kind = detectionKindForCocoClass(label);
      if (kind == null) continue;
      final score = _jsDouble(pred.getProperty('score'.toJS)) ?? 0;
      final bbox = pred.getProperty('bbox'.toJS);
      if (bbox == null) continue;
      final bboxObj = bbox as JSObject;
      final x = _jsDouble(bboxObj.getProperty(0.toJS));
      final y = _jsDouble(bboxObj.getProperty(1.toJS));
      final w = _jsDouble(bboxObj.getProperty(2.toJS));
      final h = _jsDouble(bboxObj.getProperty(3.toJS));
      if (x == null || y == null || w == null || h == null) continue;
      final box = playerBoxFromPixelRect(
        x: x,
        y: y,
        width: w,
        height: h,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        score: score,
        minScore: kind == PlayerDetectionKind.ball
            ? kBallDetectionMinScore
            : kPlayerDetectionMinScore,
      );
      if (box == null) continue;
      boxes.add(
        PlayerDetectionBox(
          left: box.left,
          top: box.top,
          width: box.width,
          height: box.height,
          score: box.score,
          kind: kind,
          jerseyNumber: parseJerseyNumber(
            pred.getProperty('jerseyNumber'.toJS)?.dartify(),
          ),
          circular: kind == PlayerDetectionKind.ball,
        ),
      );
    }
    return filterPlausibleDetections(boxes);
  }

  web.HTMLCanvasElement? _sampleCanvas;

  _SampledFrame? _sampleVideoPixels(web.HTMLVideoElement video) {
    if (video.videoWidth <= 0 || video.videoHeight <= 0) return null;
    try {
      final canvas = _sampleCanvas ??= web.HTMLCanvasElement();
      const targetW = 640;
      final targetH =
          (targetW * video.videoHeight / video.videoWidth).round().clamp(8, 720);
      canvas.width = targetW;
      canvas.height = targetH;
      final ctx = canvas.context2D;
      ctx.drawImage(video, 0, 0, targetW, targetH);
      final imageData = ctx.getImageData(0, 0, targetW, targetH);
      return _SampledFrame(
        pixels: imageData.data.toDart,
        width: targetW,
        height: targetH,
      );
    } catch (error) {
      _sampleCanvas = null;
      debugPrint('DebugPlayerDetector: frame sample failed: $error');
      return null;
    }
  }

  int _jsLength(JSObject object) {
    final value = object.getProperty('length'.toJS)?.dartify();
    if (value is num) return value.toInt();
    return 0;
  }

  double? _jsDouble(JSAny? value) {
    final decoded = value?.dartify();
    if (decoded is num) return decoded.toDouble();
    return null;
  }

  Future<String> _resolveDetectionSrc({
    required String downloadUrl,
    String? storagePath,
    Future<Uint8List> Function(String storagePath)? downloadBytes,
  }) async {
    final corsProbe = _ensureProbe(downloadUrl);
    if (await _waitUntilReadable(corsProbe, const Duration(seconds: 2))) {
      return downloadUrl;
    }

    _removeProbe();
    final fetched = await _fetchObjectUrl(downloadUrl);
    if (fetched != null) return fetched;

    final path = storagePath?.trim();
    if (path != null && path.isNotEmpty && downloadBytes != null) {
      try {
        final bytes = await downloadBytes(path);
        final fromBytes = _objectUrlFromBytes(bytes);
        if (fromBytes != null) return fromBytes;
      } catch (error) {
        debugPrint('DebugPlayerDetector: storage download failed: $error');
      }
    }
    return downloadUrl;
  }

  Future<String?> _fetchObjectUrl(String downloadUrl) async {
    final yolo = _yolo;
    if (yolo == null || downloadUrl.isEmpty) return null;
    try {
      final raw = await _promiseToFuture<JSAny?>(
        yolo.callMethod('fetchAsObjectUrl'.toJS, downloadUrl.toJS),
      );
      final url = raw?.dartify()?.toString();
      if (url == null || url.isEmpty) return null;
      _objectUrl = url;
      return url;
    } catch (error) {
      debugPrint('DebugPlayerDetector: fetch object URL failed: $error');
      return null;
    }
  }

  String? _objectUrlFromBytes(Uint8List bytes) {
    final yolo = _yolo;
    if (yolo == null || bytes.isEmpty) return null;
    try {
      final raw = yolo.callMethod('objectUrlFromBytes'.toJS, bytes.toJS);
      final url = raw?.dartify()?.toString();
      if (url == null || url.isEmpty) return null;
      _objectUrl = url;
      return url;
    } catch (error) {
      debugPrint('DebugPlayerDetector: object URL from bytes failed: $error');
      return null;
    }
  }

  void _revokeObjectUrl() {
    final yolo = _yolo;
    try {
      yolo?.callMethod('revokeObjectUrl'.toJS);
    } catch (_) {}
    _objectUrl = null;
  }

  bool _canReadVideo(web.HTMLVideoElement video) {
    final yolo = _yolo;
    if (yolo == null) return false;
    try {
      final result = yolo.callMethod('canReadVideo'.toJS, video);
      return result?.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _waitUntilReadable(
    web.HTMLVideoElement video,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (video.readyState >= 2 &&
          video.videoWidth > 0 &&
          _canReadVideo(video)) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return video.readyState >= 2 &&
        video.videoWidth > 0 &&
        _canReadVideo(video);
  }

  Future<web.HTMLVideoElement?> _lockedProbeFrame(
    web.HTMLVideoElement visible,
  ) async {
    final probe = _probe;
    if (probe == null) return null;
    try {
      probe.pause();
      await _seekProbe(probe, visible.currentTime);
    } catch (error) {
      debugPrint('DebugPlayerDetector: probe seek failed: $error');
    }
    if (probe.readyState < 2 ||
        probe.videoWidth <= 0 ||
        !_canReadVideo(probe)) {
      return null;
    }
    return probe;
  }

  Future<void> _seekProbe(web.HTMLVideoElement probe, double seconds) async {
    if ((probe.currentTime - seconds).abs() <= 0.04) return;
    final completer = Completer<void>();
    late final JSFunction handler;
    handler = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    probe.addEventListener('seeked', handler);
    try {
      probe.currentTime = seconds;
      await completer.future.timeout(const Duration(milliseconds: 280));
    } catch (_) {
    } finally {
      probe.removeEventListener('seeked', handler);
    }
  }

  web.HTMLVideoElement _ensureProbe(String src) {
    final existing = _probe;
    if (existing != null && _probeSrc == src) return existing;
    existing?.remove();
    final probe = web.HTMLVideoElement()
      ..muted = true
      ..preload = 'auto'
      ..playsInline = true
      ..autoplay = false;
    if (!src.startsWith('blob:')) {
      probe.crossOrigin = 'anonymous';
    }
    probe.src = src;
    probe.style
      ..position = 'fixed'
      ..left = '-12000px'
      ..top = '0'
      ..width = '4px'
      ..height = '4px'
      ..opacity = '0'
      ..pointerEvents = 'none';
    web.document.body?.append(probe);
    _probe = probe;
    _probeSrc = src;
    return probe;
  }

  void _removeProbe() {
    _probe?.remove();
    _probe = null;
    _probeSrc = '';
  }

  web.HTMLVideoElement? _findVideoElement(String srcHint) {
    final nodes = web.document.querySelectorAll('video');
    web.HTMLVideoElement? best;
    var bestArea = 0.0;
    final token = _srcToken(srcHint);
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes.item(i);
      if (node == null) continue;
      final video = node as web.HTMLVideoElement;
      if (identical(video, _probe)) continue;
      if (video.videoWidth <= 0 || video.videoHeight <= 0) continue;
      final rect = video.getBoundingClientRect();
      if (rect.width <= 8 || rect.height <= 8) continue;
      if (token.isNotEmpty) {
        final src = video.currentSrc;
        if (src.isNotEmpty && !src.contains(token) && !srcHint.contains(src)) {
          continue;
        }
      }
      final area = rect.width * rect.height;
      if (area > bestArea) {
        bestArea = area;
        best = video;
      }
    }
    if (best != null) return best;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes.item(i);
      if (node == null) continue;
      final video = node as web.HTMLVideoElement;
      if (identical(video, _probe)) continue;
      if (video.videoWidth > 0) return video;
    }
    return null;
  }

  String _srcToken(String srcHint) {
    final uri = Uri.tryParse(srcHint);
    if (uri == null) return srcHint;
    final last = uri.pathSegments.isEmpty ? srcHint : uri.pathSegments.last;
    return last.length > 12 ? last.substring(0, 12) : last;
  }

  void _ensureOverlay() {
    if (_overlay != null) return;
    _overlay = web.HTMLCanvasElement()
      ..style.position = 'absolute'
      ..style.pointerEvents = 'none'
      ..style.cursor = 'default'
      ..style.zIndex = '20'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.touchAction = 'none'
      ..style.userSelect = 'none';
  }

  void _syncOverlayToVideo(web.HTMLVideoElement video) {
    final canvas = _overlay;
    if (canvas == null) return;
    final parent = video.parentElement;
    if (parent is! web.HTMLElement) return;
    if (parent.style.position == 'static' || parent.style.position == '') {
      parent.style.position = 'relative';
    }
    if (canvas.parentElement != parent) {
      parent.append(canvas);
    }
    if (_draftFrame != null) {
      _lockVideoPointers(video);
    }
    final content = _videoContentBox(video);
    canvas.style
      ..position = 'absolute'
      ..left = '${content.left}px'
      ..top = '${content.top}px'
      ..width = '${content.width}px'
      ..height = '${content.height}px'
      ..pointerEvents = 'none'
      ..cursor = 'default'
      ..touchAction = 'none'
      ..userSelect = 'none'
      ..zIndex = '20';
    final pixelWidth = content.width.round().clamp(1, 4096);
    final pixelHeight = content.height.round().clamp(1, 4096);
    if (canvas.width != pixelWidth) canvas.width = pixelWidth;
    if (canvas.height != pixelHeight) canvas.height = pixelHeight;
  }

  ({double left, double top, double width, double height}) _videoContentBox(
    web.HTMLVideoElement video,
  ) {
    final elW = video.clientWidth.toDouble();
    final elH = video.clientHeight.toDouble();
    final vw = video.videoWidth.toDouble();
    final vh = video.videoHeight.toDouble();
    final offsetLeft = video.offsetLeft.toDouble();
    final offsetTop = video.offsetTop.toDouble();
    if (vw <= 0 || vh <= 0 || elW <= 0 || elH <= 0) {
      return (left: offsetLeft, top: offsetTop, width: elW, height: elH);
    }
    final scale = elW / vw < elH / vh ? elW / vw : elH / vh;
    final width = vw * scale;
    final height = vh * scale;
    return (
      left: offsetLeft + (elW - width) / 2,
      top: offsetTop + (elH - height) / 2,
      width: width,
      height: height,
    );
  }

  void _clearOverlay() {
    final canvas = _overlay;
    if (canvas == null) return;
    canvas.context2D.clearRect(0, 0, canvas.width, canvas.height);
  }

  bool _hideFramesWhilePlaying() {
    final visible = _findVideoElement(_srcHint);
    if (visible == null) return _analyzePlayback;
    return !visible.paused;
  }

  void _drawOverlay(List<PlayerDetectionBox> boxes) {
    final canvas = _overlay;
    if (canvas == null) return;
    final ctx = canvas.context2D;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    final showPlayers = !_hideFramesWhilePlaying();
    for (final box in overlayDetectionBoxes(
      boxes,
      showAssociatedPlayers: showPlayers,
    )) {
      var left = box.left * canvas.width;
      var top = box.top * canvas.height;
      var width = box.width * canvas.width;
      var height = box.height * canvas.height;
      const minSize = 4.0;
      if (width < minSize) {
        left -= (minSize - width) / 2;
        width = minSize;
      }
      if (height < minSize) {
        top -= (minSize - height) / 2;
        height = minSize;
      }
      ctx.strokeStyle = colorToCssHex(_associatedColor).toJS;
      ctx.lineWidth = 3;
      if (box.circular) {
        ctx.beginPath();
        ctx.ellipse(
          left + width / 2,
          top + height / 2,
          width / 2,
          height / 2,
          0,
          0,
          math.pi * 2,
        );
        ctx.stroke();
      } else {
        ctx.strokeRect(left, top, width, height);
      }
    }
    final draft = _draftFrame;
    if (draft != null) {
      ctx.fillStyle = 'rgba(255, 255, 255, 0.16)'.toJS;
      ctx.fillRect(
        draft.left * canvas.width,
        draft.top * canvas.height,
        draft.width * canvas.width,
        draft.height * canvas.height,
      );
      ctx.strokeStyle = '#FFFFFF'.toJS;
      ctx.lineWidth = 3;
      ctx.strokeRect(
        draft.left * canvas.width,
        draft.top * canvas.height,
        draft.width * canvas.width,
        draft.height * canvas.height,
      );
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _loadScript(String src) async {
    final existing = web.document.querySelector('script[src="$src"]');
    if (existing != null) return;
    final script = web.HTMLScriptElement()
      ..src = src
      ..async = true;
    final completer = Completer<void>();
    script.addEventListener(
      'load',
      (web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }.toJS,
    );
    script.addEventListener(
      'error',
      (web.Event _) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('script-load-failed $src'));
        }
      }.toJS,
    );
    web.document.head?.append(script);
    await completer.future;
  }
}

Future<T> _promiseToFuture<T>(JSAny? promise) {
  if (promise == null) {
    return Future.error(StateError('Promise JS nulle'));
  }

  final completer = Completer<T>();
  final jsPromise = promise as JSObject;
  final then = jsPromise.getProperty('then'.toJS);
  if (then == null) {
    return Future.error(StateError('Objet JS non Promise'));
  }

  (then as JSFunction).callAsFunction(
    jsPromise,
    ((JSAny? value) {
      completer.complete(value as T);
    }).toJS,
    ((JSAny? error) {
      completer.completeError(error ?? 'Unknown JS error');
    }).toJS,
  );

  return completer.future;
}
