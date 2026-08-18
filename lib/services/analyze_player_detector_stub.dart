import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';

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

/// Native detector: iOS Vision human rectangles via method channel.
class DebugPlayerDetector {
  DebugPlayerDetector._();

  static final DebugPlayerDetector instance = DebugPlayerDetector._();

  static const MethodChannel _channel =
      MethodChannel('io.grinta.app/player_detection');

  bool _running = false;
  ValueChanged<List<PlayerDetectionBox>>? _onBoxes;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get isReady => isSupported;

  bool get isRunning => _running;

  PitchRegion? get lastPitchRegion => null;

  PitchQuad? get lastPitchQuad => null;

  void setAnalyzePlayback(bool enabled) {}

  void notifySeek() {}

  Future<void> ensureReady() async {}

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
    _running = true;
    _onBoxes = onBoxes;
  }

  void stop() {
    _running = false;
    _onBoxes = null;
  }

  void updateKitColors({
    int? team1KitColor,
    int? team2KitColor,
    int? refereeKitColor,
    String? team1Id,
    String? team2Id,
  }) {}

  void setVideoSrcHint(String srcHint) {}

  void setManualLabeling({
    required bool enabled,
    ValueChanged<PlayerDetectionBox>? onBox,
    VoidCallback? onDrawStart,
    String? videoSrcHint,
  }) {}

  void setDraftFrame(
    PlayerDetectionBox? box, {
    ValueChanged<PlayerDetectionBox>? onMoved,
  }) {}

  Future<Uint8List?> captureStillPng({
    double? timeSeconds,
    String? downloadUrl,
    String? storagePath,
    Future<Uint8List> Function(String storagePath)? downloadBytes,
  }) async =>
      null;

  void setManualBoxes(List<PlayerDetectionBox> boxes) {}

  void addAssociatedBox(PlayerDetectionBox box) {}

  void clearAssociations() {}

  void setRoster(List<DebugVideoRosterPlayer> roster) {}

  String? suggestTeamIdForBox(
    PlayerDetectionBox box, {
    String? team1Id,
    String? team2Id,
  }) {
    return null;
  }

  Future<List<PlayerDetectionBox>> detectFromCapturedFrame(
    CapturedDetectionFrame frame,
  ) async {
    if (!isSupported || !_running) return const <PlayerDetectionBox>[];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'detectPeople',
        <String, dynamic>{'bytes': Uint8List.fromList(frame.bytes)},
      );
      final boxes = <PlayerDetectionBox>[];
      for (final item in raw ?? const <dynamic>[]) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final score = (map['score'] as num?)?.toDouble() ?? 1;
        if (score < kPlayerDetectionMinScore) continue;
        boxes.add(
          PlayerDetectionBox(
            left: (map['left'] as num).toDouble().clamp(0.0, 1.0),
            top: (map['top'] as num).toDouble().clamp(0.0, 1.0),
            width: (map['width'] as num).toDouble().clamp(0.0, 1.0),
            height: (map['height'] as num).toDouble().clamp(0.0, 1.0),
            score: score,
          ),
        );
      }
      _onBoxes?.call(boxes);
      return boxes;
    } on MissingPluginException {
      return const <PlayerDetectionBox>[];
    }
  }
}
