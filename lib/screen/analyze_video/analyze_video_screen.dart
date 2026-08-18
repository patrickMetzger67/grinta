import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/match_video.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_player_detector.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/services/analyze_video_match_service.dart';
import 'package:grinta/services/analyze_video_storage_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/widget/analyze_video/analyze_dropped_file.dart';
import 'package:grinta/widget/analyze_video/analyze_mp4_player.dart';
import 'package:grinta/widget/analyze_video/analyze_video_analysis_results.dart';
import 'package:grinta/widget/analyze_video/analyze_video_drop_zone.dart';
import 'package:grinta/widget/analyze_video/analyze_video_frame_controls.dart';
import 'package:grinta/widget/analyze_video/analyze_video_match_picker.dart';
import 'package:grinta/widget/analyze_video/analyze_video_player_association.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DebugVideoScreen extends StatefulWidget {
  const DebugVideoScreen({
    super.key,
    this.storageService,
  });

  final DebugVideoStorageService? storageService;

  @override
  State<DebugVideoScreen> createState() => _DebugVideoScreenState();
}

class _DebugVideoScreenState extends State<DebugVideoScreen> {
  late final DebugVideoStorageService _storage;
  late final DebugVideoMatchService _matchService;
  late final TextEditingController _dateController;
  DateTime? _matchDate;
  bool _dateInvalid = false;
  String _managedTeamsSignature = '';
  List<Match> _dayMatches = const [];
  bool _loadingMatches = false;
  bool _matchesFailed = false;
  Match? _selectedMatch;
  final MatchVideo _matchVideo = MatchVideo();
  List<MatchCompo> _compos = const [];
  bool _loadingCompos = false;
  VideoPlayerController? _controller;
  DebugVideoItem? _selected;
  List<DebugVideoItem> _library = const [];
  bool _loadingLibrary = true;
  bool _libraryLoadFailed = false;
  bool _uploading = false;
  double _uploadProgress = 0;
  bool _fullscreenOpen = false;
  bool _detecting = false;
  bool _detectionLoading = false;
  final ValueNotifier<List<PlayerDetectionBox>> _detections =
      ValueNotifier<List<PlayerDetectionBox>>(const <PlayerDetectionBox>[]);
  final GlobalKey _videoBoundaryKey = GlobalKey();
  Timer? _nativeDetectionTimer;
  Duration? _lastNativeStillPosition;
  List<PlayerDetectionBox> _manualBoxes = const <PlayerDetectionBox>[];
  bool _associating = false;
  bool _drawMode = false;
  bool _capturingStill = false;
  bool _analyzing = false;
  bool _finishingAnalysis = false;
  PlayerDetectionBox? _frameBox;
  Uint8List? _stillFrameBytes;
  PitchRegion? _analysisPitch;
  PitchQuad? _analysisQuad;
  final List<PlayerDistanceSample> _analysisSamples = <PlayerDistanceSample>[];
  final List<BallSample> _analysisBallSamples = <BallSample>[];
  final List<DebugVideoTag> _analysisTags = <DebugVideoTag>[];
  int _nextTagSeq = 0;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? DebugVideoStorageService.instance;
    _matchService = DebugVideoMatchService();
    _matchDate = DateUtils.dateOnly(DateTime.now());
    _dateController = TextEditingController(
      text: formatDebugVideoDate(_matchDate!),
    );
    unawaited(_reloadLibrary());
    unawaited(DebugPlayerDetector.instance.ensureReady());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.watch<AppSession>();
    final signature = session.managedTeamsIdsForSelectedSeason.join('|');
    if (signature == _managedTeamsSignature) return;
    _managedTeamsSignature = signature;
    unawaited(_reloadMatches());
  }

  @override
  void dispose() {
    _analyzing = false;
    DebugPlayerDetector.instance.setManualLabeling(enabled: false);
    DebugPlayerDetector.instance.setDraftFrame(null);
    _stopDetection();
    _detections.dispose();
    _dateController.dispose();
    _controller?.removeListener(_onControllerTick);
    _controller?.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    if (!mounted) return;
    final controller = _controller;
    if (controller != null &&
        shouldFinishDebugVideoAnalysisOnPause(
          analyzing: _analyzing,
          isPlaying: controller.value.isPlaying,
          isInitialized: controller.value.isInitialized,
          duration: controller.value.duration,
          position: controller.value.position,
          framingPlayer: _drawMode || _capturingStill,
        )) {
      unawaited(_finishAnalysis());
    }
    setState(() {});
  }

  List<DebugVideoRosterPlayer> get _rosterPlayers {
    return _compos.expand(debugVideoRosterFromCompo).toList();
  }

  bool get _canManuallyLabel {
    final controller = _controller;
    return controller != null &&
        controller.value.isInitialized &&
        _rosterPlayers.isNotEmpty;
  }

  void _pauseForStillFrame() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      unawaited(controller.pause());
    }
  }

  void _setDrawMode(bool enabled) {
    unawaited(_applyDrawMode(enabled));
  }

  Future<void> _applyDrawMode(bool enabled) async {
    if (!_canManuallyLabel) enabled = false;
    if (enabled) {
      _pauseForStillFrame();
      _frameBox ??= defaultManualPlayerFrame();
      Uint8List? still;
      if (kIsWeb) {
        setState(() => _capturingStill = true);
        try {
          final seconds =
              (_controller?.value.position.inMilliseconds ?? 0) / 1000;
          still = await DebugPlayerDetector.instance.captureStillPng(
            timeSeconds: seconds,
            downloadUrl: _selected?.downloadUrl,
            storagePath: _selected?.storagePath,
            downloadBytes: _storage.downloadVideoBytes,
          );
        } catch (_) {
        } finally {
          if (mounted) setState(() => _capturingStill = false);
        }
      }
      if (!mounted) return;
      setState(() {
        _drawMode = true;
        _stillFrameBytes = still;
      });
    } else {
      setState(() {
        _drawMode = false;
        _frameBox = null;
        _stillFrameBytes = null;
      });
      _continueAnalysisPlayback();
    }
    _syncManualLabeling();
  }

  void _continueAnalysisPlayback() {
    if (!_analyzing) return;
    if (_selected != null) {
      DebugPlayerDetector.instance.setVideoSrcHint(_selected!.downloadUrl);
    }
    DebugPlayerDetector.instance.setAnalyzePlayback(true);
  }

  Future<void> _onBeforeVideoPlay() async {
    if (_drawMode) await _applyDrawMode(false);
    _continueAnalysisPlayback();
  }

  void _addTagAtCurrentPosition() {
    final controller = _controller;
    if (controller == null ||
        !canPlaceDebugVideoTag(
          videoReady: controller.value.isInitialized,
          isPlaying: controller.value.isPlaying,
          capturingStill: _capturingStill,
        )) {
      return;
    }
    final atMs = controller.value.position.inMilliseconds;
    if (_analysisTags.any((tag) => tag.atMs == atMs)) return;
    setState(() {
      _analysisTags.add(
        DebugVideoTag(
          id: 'tag_${_nextTagSeq++}_$atMs',
          atMs: atMs,
        ),
      );
      _analysisTags.sort((a, b) => a.atMs.compareTo(b.atMs));
    });
  }

  void _removeTag(String id) {
    setState(() {
      _analysisTags.removeWhere((tag) => tag.id == id);
    });
  }

  void _toggleDrawMode() {
    _setDrawMode(!_drawMode);
  }

  void _updateFrame(PlayerDetectionBox Function(PlayerDetectionBox) transform) {
    final current = _frameBox;
    if (current == null) return;
    setState(() => _frameBox = transform(current));
    _syncManualLabeling();
  }

  void _syncManualLabeling() {
    if (!_canManuallyLabel) {
      _drawMode = false;
      _frameBox = null;
      _stillFrameBytes = null;
    }
    DebugPlayerDetector.instance.setRoster(_rosterPlayers);
    DebugPlayerDetector.instance.setManualLabeling(enabled: false);
    if (_selected != null) {
      DebugPlayerDetector.instance.setVideoSrcHint(_selected!.downloadUrl);
    }
    DebugPlayerDetector.instance.setDraftFrame(
      _drawMode ? _frameBox : null,
      onMoved: _drawMode ? _onFrameDragged : null,
    );
  }

  void _onFrameDragged(PlayerDetectionBox box) {
    if (!_drawMode) return;
    setState(() => _frameBox = box);
    DebugPlayerDetector.instance.setDraftFrame(
      box,
      onMoved: _onFrameDragged,
    );
  }

  List<DebugVideoAssociationTeam> _associationTeams(AppLocalizations l10n) {
    final match = _selectedMatch;
    final ids = <String>[];
    void addId(String? id) {
      final trimmed = id?.trim() ?? '';
      if (trimmed.isNotEmpty && !ids.contains(trimmed)) ids.add(trimmed);
    }

    addId(_matchVideo.team1.teamId);
    addId(_matchVideo.team2.teamId);
    for (final player in _rosterPlayers) {
      addId(player.teamId);
    }

    return ids.map((id) {
      final isTeam1 = id == _matchVideo.team1.teamId;
      final isTeam2 = id == _matchVideo.team2.teamId;
      final storedName = isTeam1
          ? _matchVideo.team1.name?.trim()
          : isTeam2
              ? _matchVideo.team2.name?.trim()
              : null;
      final fromMatch =
          match == null ? null : teamDisplayNameForTeamId(match, id);
      final name = (storedName != null && storedName.isNotEmpty)
          ? storedName
          : (fromMatch != null && fromMatch.isNotEmpty)
              ? fromMatch
              : isTeam1
                  ? l10n.debugVideoTeam1Fallback
                  : isTeam2
                      ? l10n.debugVideoTeam2Fallback
                      : id;
      return DebugVideoAssociationTeam(
        id: id,
        name: name,
        kitColor: isTeam1
            ? _matchVideo.team1KitColor
            : isTeam2
                ? _matchVideo.team2KitColor
                : null,
      );
    }).toList();
  }

  void _publishDetections(List<PlayerDetectionBox> boxes) {
    _detections.value = boxes;
    _manualBoxes = boxes
        .where((box) => (box.playerId ?? '').trim().isNotEmpty)
        .toList();
    _syncMatchVideoDetections(boxes);
    if (_analyzing) _recordAnalysisSamples(boxes);
  }

  void _recordAnalysisSamples(List<PlayerDetectionBox> boxes) {
    final playing = _controller?.value.isPlaying ?? false;
    if (!shouldRecordAnalysisSamples(
      analyzing: true,
      isPlaying: playing,
      hasExistingSamples: _analysisSamples.isNotEmpty,
    )) {
      return;
    }
    _analysisQuad = freezeAnalysisQuad(
      frozenQuad: _analysisQuad,
      latestQuad: DebugPlayerDetector.instance.lastPitchQuad,
    );
    _analysisPitch = freezeAnalysisPitch(
      frozenPitch: _analysisPitch ?? _analysisQuad?.bounds,
      latestPitch: DebugPlayerDetector.instance.lastPitchRegion,
    );
    if (isUsablePitchQuad(_analysisQuad)) {
      _analysisPitch = _analysisQuad!.bounds;
    }
    if (!isUsablePitchRegion(_analysisPitch) &&
        !isUsablePitchQuad(_analysisQuad)) {
      return;
    }
    final pitch = _analysisPitch;
    final atMs = _controller?.value.position.inMilliseconds ?? 0;
    mergeAnalysisSamples(
      _analysisSamples,
      samplesFromBoxes(
        boxes: boxes,
        atMs: atMs,
        pitch: pitch,
        quad: _analysisQuad,
      ),
    );
    mergeBallSamples(
      _analysisBallSamples,
      ballSamplesFromBoxes(
        boxes: boxes,
        atMs: atMs,
        pitch: pitch,
        quad: _analysisQuad,
      ),
    );
  }

  PitchRegion get _pitchForDisplay {
    final quad = _quadForDisplay;
    if (isUsablePitchQuad(quad)) return quad!.bounds;
    return analysisMappingPitch(
      analyzing: _analyzing,
      frozenPitch: _analysisPitch,
      latestPitch: DebugPlayerDetector.instance.lastPitchRegion,
    );
  }

  PitchQuad? get _quadForDisplay {
    return analysisMappingQuad(
      analyzing: _analyzing,
      frozenQuad: _analysisQuad,
      latestQuad: DebugPlayerDetector.instance.lastPitchQuad,
    );
  }

  Map<String, int> get _rosterJerseyByPlayerId {
    return {
      for (final player in _rosterPlayers)
        if ((player.playerId ?? '').trim().isNotEmpty && player.number != null)
          player.playerId!.trim(): player.number!,
    };
  }

  Map<String, String> get _rosterTeamByPlayerId {
    return {
      for (final player in _rosterPlayers)
        if ((player.playerId ?? '').trim().isNotEmpty)
          player.playerId!.trim(): player.teamId,
    };
  }

  void _onVideoSeek() {
    DebugPlayerDetector.instance.notifySeek();
    _lastNativeStillPosition = null;
  }

  void _publishManualBoxes() {
    DebugPlayerDetector.instance.setManualBoxes(_manualBoxes);
    final automatic = _detections.value
        .where((box) => box.playerId == null)
        .toList();
    _publishDetections(persistAssociatedPlayers(
      current: automatic,
      tracks: [
        for (final box in _manualBoxes) AssociatedPlayerTrack(box: box),
      ],
    ).boxes);
  }

  Future<void> _assignFramePlayer() async {
    final box = _frameBox;
    if (box == null) return;
    await _onManualBoxDrawn(box);
  }

  Future<void> _onManualBoxDrawn(PlayerDetectionBox box) async {
    if (_associating || !mounted) return;
    final already = _manualBoxes.where(
      (existing) =>
          (existing.playerId ?? '').isNotEmpty &&
          detectionBoxIou(existing, box) > 0.22,
    );
    if (already.isNotEmpty) return;
    final taken = associatedPlayerIds(_manualBoxes);
    final roster = _rosterPlayers
        .where(
          (player) =>
              (player.playerId ?? '').isEmpty ||
              !taken.contains(player.playerId),
        )
        .toList();
    if (roster.isEmpty) {
      _showMessage(context.l10n.debugVideoNoRosterToAssociate);
      return;
    }
    _associating = true;
    try {
      final player = await showDebugVideoPlayerAssociationSheet(
        context: context,
        useRootNavigator: _fullscreenOpen,
        teams: _associationTeams(context.l10n),
        roster: roster,
        suggestedTeamId: DebugPlayerDetector.instance.suggestTeamIdForBox(
          box,
          team1Id: _matchVideo.team1.teamId,
          team2Id: _matchVideo.team2.teamId,
        ),
      );
      if (!mounted || player == null) return;
      final labeled = PlayerDetectionBox(
        left: box.left,
        top: box.top,
        width: box.width,
        height: box.height,
        jerseyNumber: player.number,
        teamId: player.teamId,
        playerId: player.playerId,
        circular: box.circular,
      );
      _manualBoxes = [
        ..._manualBoxes.where((existing) {
          if (existing.playerId != null &&
              existing.playerId == labeled.playerId) {
            return false;
          }
          return detectionBoxIou(existing, labeled) <= 0.22;
        }),
        labeled,
      ];
      DebugPlayerDetector.instance.addAssociatedBox(labeled);
      _publishManualBoxes();
      _setDrawMode(false);
    } finally {
      _associating = false;
    }
  }

  Future<void> _reloadLibrary() async {
    setState(() {
      _loadingLibrary = true;
      _libraryLoadFailed = false;
    });
    try {
      final items = await _storage.listUserVideos();
      if (!mounted) return;
      setState(() {
        _library = items;
        _loadingLibrary = false;
      });
    } on DebugVideoStorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLibrary = false;
        _libraryLoadFailed =
            error.code != DebugVideoStorageError.notSignedIn;
      });
      if (error.code == DebugVideoStorageError.notSignedIn) {
        _showMessage(context.l10n.debugVideoAuthRequired);
      } else {
        _showMessage(context.l10n.debugVideoLoadError);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLibrary = false;
        _libraryLoadFailed = true;
      });
      _showMessage(context.l10n.debugVideoLoadError);
    }
  }

  Future<void> _reloadMatches() async {
    final date = _matchDate;
    if (date == null) return;
    setState(() {
      _loadingMatches = true;
      _matchesFailed = false;
    });
    try {
      final session = context.read<AppSession>();
      final matches = await _matchService.matchesForManagedTeamsOnDay(
        session: session,
        day: date,
      );
      if (!mounted) return;
      final selectedId = _selectedMatch?.id;
      final stillThere = matches.where((match) => match.id == selectedId);
      setState(() {
        _dayMatches = matches;
        _loadingMatches = false;
        _selectedMatch = stillThere.isEmpty ? null : stillThere.first;
        if (_selectedMatch == null) {
          _compos = const [];
        }
      });
      if (_selectedMatch != null) {
        unawaited(_reloadCompos());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMatches = false;
        _matchesFailed = true;
        _dayMatches = const [];
      });
    }
  }

  Future<void> _reloadCompos() async {
    final matchId = _selectedMatch?.id?.trim();
    if (matchId == null || matchId.isEmpty) {
      setState(() => _compos = const []);
      _syncManualLabeling();
      return;
    }
    setState(() => _loadingCompos = true);
    try {
      final compos = await _matchService.composForMatch(matchId);
      if (!mounted) return;
      setState(() {
        _compos = compos;
        _loadingCompos = false;
      });
      _syncManualLabeling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _compos = const [];
        _loadingCompos = false;
      });
      _syncManualLabeling();
    }
  }

  void _applyDate(DateTime day) {
    final normalized = DateUtils.dateOnly(day);
    _dateController.text = formatDebugVideoDate(normalized);
    setState(() {
      _matchDate = normalized;
      _dateInvalid = false;
      _selectedMatch = null;
      _compos = const [];
      _matchVideo.matchId = null;
      _matchVideo.detections = <MatchVideoDetection>[];
    });
    _syncManualLabeling();
    unawaited(_reloadMatches());
  }

  void _onDateSubmitted(String raw) {
    final parsed = parseDebugVideoDate(raw);
    if (parsed == null) {
      setState(() => _dateInvalid = true);
      return;
    }
    _applyDate(parsed);
  }

  Future<void> _pickMatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate ?? DateUtils.dateOnly(DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.debugVideoMatchDateLabel,
    );
    if (picked == null || !mounted) return;
    _applyDate(picked);
  }

  void _selectMatch(Match match) {
    setState(() {
      _selectedMatch = match;
      _matchVideo.applyMatch(match);
      match.videoUrl = _matchVideo.videoUrl ?? match.videoUrl;
      if (match.videoUrl != null) {
        _matchVideo.videoUrl = match.videoUrl;
      }
    });
    _syncKitColorsToDetector();
    unawaited(_reloadCompos());
  }

  void _syncKitColorsToDetector() {
    DebugPlayerDetector.instance.updateKitColors(
      team1KitColor: _matchVideo.team1KitColor,
      team2KitColor: _matchVideo.team2KitColor,
      refereeKitColor: _matchVideo.refereeKitColor,
      team1Id: _matchVideo.team1.teamId,
      team2Id: _matchVideo.team2.teamId,
    );
  }

  void _setTeam1KitColor(int color) {
    setState(() => _matchVideo.team1KitColor = color);
    _syncKitColorsToDetector();
  }

  void _setTeam2KitColor(int color) {
    setState(() => _matchVideo.team2KitColor = color);
    _syncKitColorsToDetector();
  }

  void _setRefereeKitColor(int color) {
    setState(() => _matchVideo.refereeKitColor = color);
    _syncKitColorsToDetector();
  }

  void _syncMatchVideoDetections(List<PlayerDetectionBox> boxes) {
    final atMs = _controller?.value.position.inMilliseconds;
    _matchVideo.detections = boxes
        .map(
          (box) => MatchVideoDetection(
            kind: box.kind == PlayerDetectionKind.ball
                ? MatchVideoObjectKind.ball
                : MatchVideoObjectKind.person,
            left: box.left,
            top: box.top,
            width: box.width,
            height: box.height,
            score: box.score,
            atMs: atMs,
            jerseyNumber: box.jerseyNumber,
            teamId: box.teamId,
            playerId: box.playerId,
          ),
        )
        .toList(growable: false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _messageForStorageError(
    AppLocalizations l10n,
    DebugVideoStorageException error,
  ) {
    switch (error.code) {
      case DebugVideoStorageError.notSignedIn:
        return l10n.debugVideoAuthRequired;
      case DebugVideoStorageError.invalidFormat:
        return l10n.debugVideoInvalidFormat;
      case DebugVideoStorageError.tooLarge:
        return l10n.debugVideoFileTooLarge;
      case DebugVideoStorageError.emptyFile:
        return l10n.debugVideoInvalidFormat;
      case DebugVideoStorageError.uploadFailed:
        return l10n.debugVideoUploadError('${error.details ?? ''}');
    }
  }

  Future<void> _pickFile() async {
    final l10n = context.l10n;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['mp4'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage(l10n.debugVideoInvalidFormat);
        return;
      }
      await _importBytes(name: file.name, bytes: bytes);
    } catch (error) {
      if (!mounted) return;
      _showMessage(context.l10n.debugVideoPickError(error.toString()));
    }
  }

  Future<void> _onFilesDropped(List<DebugDroppedFile> files) async {
    if (files.isEmpty) return;
    final file = files.first;
    await _importBytes(name: file.name, bytes: file.bytes);
  }

  Future<void> _importBytes({
    required String name,
    required Uint8List bytes,
  }) async {
    final l10n = context.l10n;
    try {
      _storage.validateMp4(filename: name, byteLength: bytes.lengthInBytes);
    } on DebugVideoStorageException catch (error) {
      _showMessage(_messageForStorageError(l10n, error));
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final session = context.read<AppSession>();
      final item = await _storage.uploadMp4(
        bytes: bytes,
        filename: name,
        matchId: _selectedMatch?.id,
        teamId: _selectedMatch == null
            ? null
            : preferredManagedMatchTeamId(_selectedMatch!, session),
        seasonId: session.selectedSeason?.ref?.id,
        matchLabel:
            _selectedMatch == null ? null : debugVideoMatchLabel(_selectedMatch!),
        team1KitColor: matchVideoColorToHex(_matchVideo.team1KitColor),
        team2KitColor: matchVideoColorToHex(_matchVideo.team2KitColor),
        refereeKitColor: matchVideoColorToHex(_matchVideo.refereeKitColor),
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _library = <DebugVideoItem>[
          item,
          ..._library.where((existing) => existing.storagePath != item.storagePath),
        ];
        _uploading = false;
        _matchVideo.videoUrl = item.downloadUrl;
        _matchVideo.storagePath = item.storagePath;
        _selectedMatch?.videoUrl = item.downloadUrl;
      });
      await _play(item);
    } on DebugVideoStorageException catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showMessage(_messageForStorageError(l10n, error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showMessage(l10n.debugVideoUploadError(error.toString()));
    }
  }

  List<({String name, int detected, int total})> _teamPlayerProgress() {
    final associated = associatedPlayerIds(_manualBoxes);
    return [
      for (final team in _associationTeams(context.l10n))
        (
          name: team.name,
          detected: _rosterPlayers
              .where(
                (player) =>
                    player.teamId == team.id &&
                    isRosterPlayerAssociated(player.playerId, associated),
              )
              .length,
          total: _rosterPlayers
              .where((player) => player.teamId == team.id)
              .length,
        ),
    ].where((team) => team.total > 0).toList();
  }

  Future<void> _ensureDetectionRunning() async {
    if (_detecting) return;
    final controller = _controller;
    final selected = _selected;
    if (controller == null ||
        !controller.value.isInitialized ||
        selected == null) {
      _showMessage(context.l10n.debugVideoNoVideo);
      return;
    }

    final detector = DebugPlayerDetector.instance;
    if (!detector.isSupported) {
      _showMessage(context.l10n.debugVideoDetectionUnsupported);
      return;
    }

    setState(() {
      _detectionLoading = true;
    });
    try {
      await detector.ensureReady();
      if (!mounted) return;
      await detector.start(
        videoSrcHint: selected.downloadUrl,
        storagePath: selected.storagePath,
        downloadBytes: _storage.downloadVideoBytes,
        team1KitColor: _matchVideo.team1KitColor,
        team2KitColor: _matchVideo.team2KitColor,
        refereeKitColor: _matchVideo.refereeKitColor,
        team1Id: _matchVideo.team1.teamId,
        team2Id: _matchVideo.team2.teamId,
        boxColor: context.appColors.primary,
        associatedColor: context.appColors.success,
        onBoxes: _publishDetections,
      );
      DebugPlayerDetector.instance.setManualBoxes(_manualBoxes);
      if (!mounted) return;
      setState(() {
        _detecting = true;
        _detectionLoading = false;
      });
      _syncManualLabeling();
      if (!kIsWeb) {
        _lastNativeStillPosition = null;
        _nativeDetectionTimer?.cancel();
        _nativeDetectionTimer = Timer.periodic(
          const Duration(milliseconds: 280),
          (_) => unawaited(_runNativeDetectionTick()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _detectionLoading = false;
      });
      _showMessage(context.l10n.debugVideoDetectionError(error.toString()));
    }
  }

  void _stopDetection() {
    _nativeDetectionTimer?.cancel();
    _nativeDetectionTimer = null;
    _lastNativeStillPosition = null;
    DebugPlayerDetector.instance.setAnalyzePlayback(false);
    DebugPlayerDetector.instance.stop();
    final balls = _detections.value
        .where((box) => box.kind == PlayerDetectionKind.ball)
        .toList();
    _publishDetections([
      ..._manualBoxes,
      ...balls,
    ]);
    if (mounted && (_detecting || _detectionLoading)) {
      setState(() {
        _detecting = false;
        _detectionLoading = false;
      });
    } else {
      _detecting = false;
      _detectionLoading = false;
    }
  }

  Future<void> _toggleAnalysis() async {
    if (_analyzing) {
      await _finishAnalysis();
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _showMessage(context.l10n.debugVideoNoVideo);
      return;
    }
    if (_manualBoxes.every((box) => (box.playerId ?? '').trim().isEmpty)) {
      _showMessage(context.l10n.debugVideoAnalyzeNeedPlayers);
      return;
    }
    if (_drawMode) await _applyDrawMode(false);
    if (!mounted) return;
    await _ensureDetectionRunning();
    if (!mounted || !_detecting) return;
    if (shouldClearDebugVideoAnalysisSamples(alreadyAnalyzing: _analyzing)) {
      _analysisSamples.clear();
      _analysisBallSamples.clear();
    }
    _analysisQuad = freezeAnalysisQuad(
      frozenQuad: _analysisQuad,
      latestQuad: DebugPlayerDetector.instance.lastPitchQuad,
    );
    _analysisPitch = freezeAnalysisPitch(
      frozenPitch: _analysisPitch ?? _analysisQuad?.bounds,
      latestPitch: DebugPlayerDetector.instance.lastPitchRegion,
    );
    _recordAnalysisSamples(_manualBoxes);
    DebugPlayerDetector.instance.setAnalyzePlayback(true);
    setState(() => _analyzing = true);
    await controller.play();
  }

  Future<void> _finishAnalysis() async {
    if (!_analyzing || _finishingAnalysis) return;
    _finishingAnalysis = true;
    DebugPlayerDetector.instance.setAnalyzePlayback(false);
    final controller = _controller;
    if (controller != null && controller.value.isPlaying) {
      await controller.pause();
    }
    _analyzing = false;
    _stopDetection();
    if (mounted) {
      setState(() {});
      await _showAnalysisResults();
    }
    _finishingAnalysis = false;
  }

  bool get _hasAnalysisData =>
      _analysisSamples.isNotEmpty || _analysisBallSamples.isNotEmpty;

  void _resetAnalysisStats() {
    if (!_hasAnalysisData) return;
    setState(() {
      _analysisSamples.clear();
      _analysisBallSamples.clear();
    });
  }

  Future<void> _showAnalysisResults() async {
    if (!mounted) return;
    final results = summarizePlayerAnalysis(
      samples: List<PlayerDistanceSample>.from(_analysisSamples),
      balls: List<BallSample>.from(_analysisBallSamples),
      roster: _rosterPlayers,
      pitch: _analysisPitch,
      quad: _analysisQuad,
    );
    await showDebugVideoAnalysisResults(
      context: context,
      results: results,
    );
  }

  Future<void> _runNativeDetectionTick() async {
    if (!_detecting || kIsWeb) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying && !_analyzing) return;
    final position = controller.value.position;
    if (_lastNativeStillPosition != null &&
        (position - _lastNativeStillPosition!).inMilliseconds.abs() < 40) {
      return;
    }
    final frame = await _captureVideoFrame();
    if (frame == null) return;
    _lastNativeStillPosition = position;
    await DebugPlayerDetector.instance.detectFromCapturedFrame(frame);
  }

  Future<CapturedDetectionFrame?> _captureVideoFrame() async {
    final context = _videoBoundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    try {
      final image = await boundary.toImage(pixelRatio: 0.45);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return CapturedDetectionFrame(
        bytes: data.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _play(DebugVideoItem item) async {
    _manualBoxes = const <PlayerDetectionBox>[];
    _drawMode = false;
    _analyzing = false;
    _analysisSamples.clear();
    _analysisBallSamples.clear();
    _analysisTags.clear();
    _analysisPitch = null;
    _analysisQuad = null;
    _frameBox = null;
    _stillFrameBytes = null;
    DebugPlayerDetector.instance.clearAssociations();
    _stopDetection();
    final previous = _controller;
    previous?.removeListener(_onControllerTick);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(item.downloadUrl),
    );
    setState(() {
      _controller = controller;
      _selected = item;
      _matchVideo.videoUrl = item.downloadUrl;
      _matchVideo.storagePath = item.storagePath;
      _matchVideo.matchId = item.matchId ?? _selectedMatch?.id;
      _matchVideo.team1KitColor =
          matchVideoColorFromHex(item.team1KitColor) ??
          _matchVideo.team1KitColor;
      _matchVideo.team2KitColor =
          matchVideoColorFromHex(item.team2KitColor) ??
          _matchVideo.team2KitColor;
      _matchVideo.refereeKitColor =
          matchVideoColorFromHex(item.refereeKitColor) ??
          _matchVideo.refereeKitColor;
      _selectedMatch?.videoUrl = item.downloadUrl;
    });
    controller.addListener(_onControllerTick);
    DebugPlayerDetector.instance.setVideoSrcHint(item.downloadUrl);
    try {
      await controller.initialize();
      await controller.pause();
    } catch (_) {
      if (!mounted) return;
      _showMessage(context.l10n.debugVideoLoadError);
    }
    await previous?.dispose();
    if (mounted) {
      _syncManualLabeling();
      setState(() {});
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _fullscreenOpen = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DebugMp4FullscreenPage(
            controller: controller,
            detectionsListenable: _detections,
            detectionColor: context.appColors.primary,
            associatedColor: context.appColors.success,
            videoBoundaryKey: kIsWeb ? null : _videoBoundaryKey,
            draftBox: _frameBox,
            onSeek: _onVideoSeek,
            analysisSamples: _analysisSamples,
            pitch: _pitchForDisplay,
            quad: _quadForDisplay,
            team1Id: _matchVideo.team1.teamId,
            team2Id: _matchVideo.team2.teamId,
            team1KitColor: _matchVideo.team1KitColor,
            team2KitColor: _matchVideo.team2KitColor,
            rosterJerseyByPlayerId: _rosterJerseyByPlayerId,
            rosterTeamByPlayerId: _rosterTeamByPlayerId,
          );
        },
      ),
    );
    if (mounted) setState(() => _fullscreenOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final controller = _controller;
    final videoReady =
        controller != null && controller.value.isInitialized;
    final isPlaying = controller?.value.isPlaying ?? false;
    final canFrame = canDebugVideoFramePlayer(
      videoReady: videoReady,
      uploading: _uploading,
      capturingStill: _capturingStill,
      isPlaying: isPlaying,
    );
    final canTag = canPlaceDebugVideoTag(
      videoReady: videoReady,
      isPlaying: isPlaying,
      capturingStill: _capturingStill,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.debugVideoTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: _drawMode ? const NeverScrollableScrollPhysics() : null,
        children: [
          if (controller != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ValueListenableBuilder<List<PlayerDetectionBox>>(
                      valueListenable: _detections,
                      builder: (context, boxes, _) {
                        return DebugMp4Player(
                          controller: controller,
                          showSurface: !_fullscreenOpen,
                          onEnterFullscreen: _openFullscreen,
                          detections: boxes,
                          detectionColor: colors.primary,
                          associatedColor: colors.success,
                          videoBoundaryKey: kIsWeb || _fullscreenOpen
                              ? null
                              : _videoBoundaryKey,
                          draftBox: _frameBox,
                          onDraftMoved: _onFrameDragged,
                          stillFrameBytes: _stillFrameBytes,
                          onBeforePlay: _onBeforeVideoPlay,
                          onSeek: _onVideoSeek,
                          analysisSamples: _analysisSamples,
                          pitch: _pitchForDisplay,
                          quad: _quadForDisplay,
                          team1Id: _matchVideo.team1.teamId,
                          team2Id: _matchVideo.team2.teamId,
                          team1KitColor: _matchVideo.team1KitColor,
                          team2KitColor: _matchVideo.team2KitColor,
                          rosterJerseyByPlayerId: _rosterJerseyByPlayerId,
                          rosterTeamByPlayerId: _rosterTeamByPlayerId,
                        );
                      },
                    ),
                  ),
                ),
                if (_drawMode) ...[
                  const SizedBox(width: 8),
                  DebugVideoFrameControls(
                    onMoveUp: () => _updateFrame(
                      (box) => moveManualPlayerFrame(box, dy: -0.03),
                    ),
                    onMoveDown: () => _updateFrame(
                      (box) => moveManualPlayerFrame(box, dy: 0.03),
                    ),
                    onMoveLeft: () => _updateFrame(
                      (box) => moveManualPlayerFrame(box, dx: -0.03),
                    ),
                    onMoveRight: () => _updateFrame(
                      (box) => moveManualPlayerFrame(box, dx: 0.03),
                    ),
                    onTaller: () => _updateFrame(
                      (box) => resizeManualPlayerFrame(box, dHeight: 0.04),
                    ),
                    onShorter: () => _updateFrame(
                      (box) => resizeManualPlayerFrame(box, dHeight: -0.04),
                    ),
                    onWider: () => _updateFrame(
                      (box) => resizeManualPlayerFrame(box, dWidth: 0.03),
                    ),
                    onNarrower: () => _updateFrame(
                      (box) => resizeManualPlayerFrame(box, dWidth: -0.03),
                    ),
                    onAssign: () => unawaited(_assignFramePlayer()),
                    onReset: () => _updateFrame((_) => defaultManualPlayerFrame()),
                  ),
                ],
              ],
            )
          else
            _EmptyPlayerCard(message: l10n.debugVideoNoVideo),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: !videoReady || _uploading || _detectionLoading
                        ? null
                        : () => unawaited(_toggleAnalysis()),
                    icon: _detectionLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _analyzing
                                ? Icons.stop_circle_outlined
                                : Icons.analytics_outlined,
                          ),
                    label: Text(
                      _analyzing
                          ? l10n.debugVideoStopAnalyze
                          : l10n.debugVideoAnalyze,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: !videoReady || !_hasAnalysisData
                        ? null
                        : () => unawaited(_showAnalysisResults()),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.debugVideoView),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: !videoReady || !_hasAnalysisData
                        ? null
                        : _resetAnalysisStats,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.debugVideoResetStats),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: canTag ? _addTagAtCurrentPosition : null,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l10n.debugVideoAddTag),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_drawMode)
                    FilledButton.icon(
                      onPressed: _toggleDrawMode,
                      icon: const Icon(Icons.close),
                      label: Text(l10n.debugVideoCancelDraw),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: !canFrame
                          ? null
                          : () {
                              if (!_canManuallyLabel) {
                                _showMessage(l10n.debugVideoDrawNeedRoster);
                                return;
                              }
                              _setDrawMode(true);
                            },
                      icon: _capturingStill
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.crop_free),
                      label: Text(l10n.debugVideoDrawPlayer),
                    ),
                  if (_canManuallyLabel) ...[
                    const SizedBox(height: 8),
                    for (final team in _teamPlayerProgress())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          l10n.debugVideoTeamPlayerProgress(
                            team.name,
                            team.detected,
                            team.total,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
          if (controller != null && controller.value.isInitialized) ...[
            const SizedBox(height: 8),
            Text(
              _drawMode
                  ? l10n.debugVideoDrawModeHelp
                  : _analyzing
                      ? l10n.debugVideoAnalyzeHelp
                      : _canManuallyLabel
                          ? l10n.debugVideoManualLabelHint
                          : l10n.debugVideoDrawNeedRoster,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (_analysisTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _analysisTags)
                    InputChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        formatDebugVideoTime(
                          Duration(milliseconds: tag.atMs),
                        ),
                      ),
                      onDeleted: () => _removeTag(tag.id),
                      deleteButtonTooltipMessage: l10n.debugVideoRemoveTag,
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          ValueListenableBuilder<List<PlayerDetectionBox>>(
            valueListenable: _detections,
            builder: (context, boxes, _) {
              return DebugVideoMatchPicker(
                dateController: _dateController,
                dateInvalid: _dateInvalid,
                loadingMatches: _loadingMatches,
                matchesFailed: _matchesFailed,
                hasManagedTeams: context
                    .watch<AppSession>()
                    .managerTeamsForSelectedSeason
                    .isNotEmpty,
                matches: _dayMatches,
                selectedMatch: _selectedMatch,
                loadingCompos: _loadingCompos,
                compos: _compos,
                onDateSubmitted: _onDateSubmitted,
                onPickDate: () => unawaited(_pickMatchDate()),
                onSelectMatch: _selectMatch,
                team1KitColor: _matchVideo.team1KitColor,
                team2KitColor: _matchVideo.team2KitColor,
                onTeam1KitColor: _setTeam1KitColor,
                onTeam2KitColor: _setTeam2KitColor,
                refereeKitColor: _matchVideo.refereeKitColor,
                onRefereeKitColor: _setRefereeKitColor,
                detectedJerseyNumbers: detectedJerseyNumbers(boxes),
                detectedTeamJerseyKeys: detectedTeamJerseyKeys(boxes),
                associatedPlayerIds: associatedPlayerIds(boxes),
              );
            },
          ),
          const SizedBox(height: 16),
          _UploadCard(
            uploading: _uploading,
            progress: _uploadProgress,
            onPick: _uploading ? null : _pickFile,
            onFilesDropped: _uploading ? (_) {} : _onFilesDropped,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.debugVideoLibraryTitle,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingLibrary)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_libraryLoadFailed)
            Text(
              l10n.debugVideoLoadError,
              style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            )
          else if (_library.isEmpty)
            Text(
              l10n.debugVideoEmptyList,
              style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            )
          else
            ..._library.map((item) {
              final selected = item.storagePath == _selected?.storagePath;
              return Card(
                color: colors.card,
                child: ListTile(
                  leading: Icon(
                    Icons.videocam_outlined,
                    color: selected ? colors.primary : colors.textSecondary,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: item.matchLabel == null || item.matchLabel!.isEmpty
                      ? null
                      : Text(
                          item.matchLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                  selected: selected,
                  onTap: _uploading ? null : () => unawaited(_play(item)),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EmptyPlayerCard extends StatelessWidget {
  const _EmptyPlayerCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.uploading,
    required this.progress,
    required this.onPick,
    required this.onFilesDropped,
  });

  final bool uploading;
  final double progress;
  final VoidCallback? onPick;
  final ValueChanged<List<DebugDroppedFile>> onFilesDropped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebugVideoDropZone(
              onFilesDropped: onFilesDropped,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 140),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.debugVideoDropHint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (uploading) ...[
              LinearProgressIndicator(
                value: progress <= 0 || progress >= 1 ? null : progress,
                color: colors.primary,
                backgroundColor: colors.border,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.debugVideoUploading,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.debugVideoChooseFile),
            ),
          ],
        ),
      ),
    );
  }
}
