import 'dart:math' as math;

import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';

const double kAnalysisPitchLengthMeters = 105;
const double kAnalysisPitchWidthMeters = 68;
const PitchRegion kFullFramePitchRegion = PitchRegion(
  top: 0,
  bottom: 1,
  left: 0,
  right: 1,
);
const double kAnalysisMaxSpeedMetersPerSecond = 12;
const double kAnalysisMinStepMeters = 0.25;
const int kAnalysisSampleDedupMs = 250;
const int kAnalysisSampleMinIntervalMs = 250;
const int kAnalysisPathGridMs = 250;
const int kAnalysisPathSmoothWindow = 3;
const double kBallPossessionRadiusMeters = 3.2;
const double kBallHolderKeepRadiusMeters = 3.8;
const int kBallEventTimeoutMs = 2200;
const double kShotMinSpeedMetersPerSecond = 7;
const double kShotMinTravelMeters = 10;
const Duration kDebugVideoAnalysisNearEndWindow = Duration(milliseconds: 280);

/// While paused / seeking, ignore samples farther than this from the playhead
/// so a far-off analyzed frame cannot place the dot. Live boxes are used
/// while playing.
const int kAnalysisMinimapSampleMaxDeltaMs = 400;

/// Timestamp marker placed while analysis is paused. [type] and [text] are
/// reserved for a later qualification step.
class DebugVideoTag {
  const DebugVideoTag({
    required this.id,
    required this.atMs,
    this.type,
    this.text,
  });

  final String id;
  final int atMs;
  final String? type;
  final String? text;
}

bool shouldFinishDebugVideoAnalysisOnPause({
  required bool analyzing,
  required bool isPlaying,
  required bool isInitialized,
  required Duration duration,
  required Duration position,
  bool framingPlayer = false,
  Duration nearEndWindow = kDebugVideoAnalysisNearEndWindow,
}) {
  if (!analyzing || !isInitialized || isPlaying || framingPlayer) {
    return false;
  }
  if (duration <= Duration.zero) return false;
  return position >= duration - nearEndWindow;
}

bool canDebugVideoFramePlayer({
  required bool videoReady,
  required bool uploading,
  required bool capturingStill,
  required bool isPlaying,
}) {
  return videoReady && !uploading && !capturingStill && !isPlaying;
}

bool canPlaceDebugVideoTag({
  required bool videoReady,
  required bool isPlaying,
  required bool capturingStill,
}) {
  return videoReady && !isPlaying && !capturingStill;
}

bool shouldClearDebugVideoAnalysisSamples({required bool alreadyAnalyzing}) {
  return !alreadyAnalyzing;
}

/// Record while playing. The first point of a run may be taken while still
/// paused so the path has a start sample.
bool shouldRecordAnalysisSamples({
  required bool analyzing,
  required bool isPlaying,
  required bool hasExistingSamples,
}) {
  if (!analyzing) return false;
  return isPlaying || !hasExistingSamples;
}

/// A grass estimate we can freeze for the video. The full-frame
/// fallback is not a real pitch and must not lock the meter scale.
bool isUsablePitchRegion(PitchRegion? pitch) {
  if (pitch == null || pitch == kFullFramePitchRegion) return false;
  final width = pitch.right - pitch.left;
  final height = pitch.bottom - pitch.top;
  return width >= 0.20 && height >= 0.18;
}

bool isUsablePitchQuad(PitchQuad? quad) => quad != null && quad.isUsable;

class PlayerDistanceSample {
  const PlayerDistanceSample({
    required this.playerId,
    required this.x,
    required this.y,
    required this.atMs,
    this.nx,
    this.ny,
  });

  final String playerId;
  final double x;
  final double y;
  final int atMs;
  final double? nx;
  final double? ny;
}

class PlayerDistanceResult {
  const PlayerDistanceResult({
    required this.playerId,
    required this.displayName,
    required this.meters,
    required this.sampleCount,
    this.number,
    this.ballsPlayed = 0,
    this.ballsReceived = 0,
    this.ballsGiven = 0,
    this.passes = 0,
    this.shots = 0,
  });

  final String playerId;
  final String displayName;
  final int? number;
  final double meters;
  final int sampleCount;
  final int ballsPlayed;
  final int ballsReceived;
  final int ballsGiven;
  final int passes;
  final int shots;
}

({double x, double y}) playerGroundPoint(PlayerDetectionBox box) {
  return (
    x: (box.left + box.width / 2).clamp(0.0, 1.0),
    y: detectionAnchorY(box).clamp(0.0, 1.0),
  );
}

/// Pitch used to map pixels to meters / the minimap.
/// The first usable [PitchRegion] for a video is reused for every analysis
/// run so the meter scale does not change. A missing estimate falls back
/// to the full frame for display only and is not frozen.
PitchRegion analysisMappingPitch({
  required bool analyzing,
  PitchRegion? frozenPitch,
  PitchRegion? latestPitch,
}) {
  final locked = isUsablePitchRegion(frozenPitch) ? frozenPitch : null;
  final latest = isUsablePitchRegion(latestPitch) ? latestPitch : null;
  if (analyzing) {
    return locked ?? latest ?? frozenPitch ?? latestPitch ?? kFullFramePitchRegion;
  }
  return locked ?? latest ?? frozenPitch ?? latestPitch ?? kFullFramePitchRegion;
}

PitchRegion? freezeAnalysisPitch({
  PitchRegion? frozenPitch,
  PitchRegion? latestPitch,
}) {
  if (isUsablePitchRegion(frozenPitch)) return frozenPitch;
  if (isUsablePitchRegion(latestPitch)) return latestPitch;
  return frozenPitch ?? latestPitch;
}

PitchQuad? freezeAnalysisQuad({
  PitchQuad? frozenQuad,
  PitchQuad? latestQuad,
}) {
  if (isUsablePitchQuad(frozenQuad)) return frozenQuad;
  if (isUsablePitchQuad(latestQuad)) return latestQuad;
  return frozenQuad ?? latestQuad;
}

/// Same freeze rule as [analysisMappingPitch], for the perspective quad.
PitchQuad? analysisMappingQuad({
  required bool analyzing,
  PitchQuad? frozenQuad,
  PitchQuad? latestQuad,
}) {
  final locked = isUsablePitchQuad(frozenQuad) ? frozenQuad : null;
  final latest = isUsablePitchQuad(latestQuad) ? latestQuad : null;
  return locked ?? latest ?? frozenQuad ?? latestQuad;
}

/// Image (nx, ny) are 0–1 of the **video frame** (same space as detection
/// boxes). Sideline camera convention, matching [GpsFieldWidget] /
/// heatmap meters:
/// - image X (left → right) → pitch **length** (0 = left goal, 105 m)
/// - image Y (top → bottom) → pitch **width** (0 = far sideline, 68 m)
/// No Y flip. Prefer [PitchQuad] (inverse bilinear). [PitchRegion] is
/// only the AABB fallback when no grass quad was estimated.
({double x, double y}) pitchPointToMeters({
  required double nx,
  required double ny,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final mapping = quad ??
      (pitch == null ? null : pitchQuadFromRegion(pitch));
  if (mapping != null) {
    final uv = imagePointToPitchUv(x: nx, y: ny, quad: mapping);
    if (uv != null) {
      return (
        x: uv.u * kAnalysisPitchLengthMeters,
        y: uv.v * kAnalysisPitchWidthMeters,
      );
    }
  }
  final left = pitch?.left ?? 0;
  final right = pitch?.right ?? 1;
  final top = pitch?.top ?? 0;
  final bottom = pitch?.bottom ?? 1;
  final width = (right - left).clamp(0.08, 1.0);
  final height = (bottom - top).clamp(0.08, 1.0);
  return (
    x: ((nx - left) / width).clamp(0.0, 1.0) * kAnalysisPitchLengthMeters,
    y: ((ny - top) / height).clamp(0.0, 1.0) * kAnalysisPitchWidthMeters,
  );
}

/// Normalized 2D pitch coordinates (0–1 along length, 0–1 along width)
/// from a detection's feet / ground point. Same axes as heatmap
/// `xMeters / 105` and `yMeters / 68`. Missing [pitch] uses the full
/// frame so the minimap still moves.
({double x, double y}) minimapPointFromBox(
  PlayerDetectionBox box, {
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final ground = playerGroundPoint(box);
  final meters = pitchPointToMeters(
    nx: ground.x,
    ny: ground.y,
    pitch: pitch ?? kFullFramePitchRegion,
    quad: quad,
  );
  return (
    x: (meters.x / kAnalysisPitchLengthMeters).clamp(0.0, 1.0),
    y: (meters.y / kAnalysisPitchWidthMeters).clamp(0.0, 1.0),
  );
}

/// Normalized 2D pitch coordinates (0–1) from a stored meter sample.
({double x, double y}) minimapPointFromSample(
  PlayerDistanceSample sample, {
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  if (sample.nx != null && sample.ny != null) {
    final meters = pitchPointToMeters(
      nx: sample.nx!,
      ny: sample.ny!,
      pitch: pitch,
      quad: quad,
    );
    return (
      x: (meters.x / kAnalysisPitchLengthMeters).clamp(0.0, 1.0),
      y: (meters.y / kAnalysisPitchWidthMeters).clamp(0.0, 1.0),
    );
  }
  return (
    x: (sample.x / kAnalysisPitchLengthMeters).clamp(0.0, 1.0),
    y: (sample.y / kAnalysisPitchWidthMeters).clamp(0.0, 1.0),
  );
}

class MinimapPlayerMarker {
  const MinimapPlayerMarker({
    required this.playerId,
    required this.x,
    required this.y,
    this.teamId,
    this.jerseyNumber,
  });

  final String playerId;
  final double x;
  final double y;
  final String? teamId;
  final int? jerseyNumber;
}

/// For each player, the sample whose [atMs] is closest to [atMs].
/// On a tie, prefers the last sample at or before the playhead.
Map<String, PlayerDistanceSample> nearestPlayerSamplesAt({
  required Iterable<PlayerDistanceSample> samples,
  required int atMs,
}) {
  final nearest = <String, PlayerDistanceSample>{};
  for (final sample in samples) {
    final id = sample.playerId.trim();
    if (id.isEmpty) continue;
    final current = nearest[id];
    if (current == null) {
      nearest[id] = sample;
      continue;
    }
    final currentDelta = (current.atMs - atMs).abs();
    final nextDelta = (sample.atMs - atMs).abs();
    if (nextDelta < currentDelta) {
      nearest[id] = sample;
      continue;
    }
    if (nextDelta > currentDelta) continue;
    final currentOnOrBefore = current.atMs <= atMs;
    final nextOnOrBefore = sample.atMs <= atMs;
    if (nextOnOrBefore && !currentOnOrBefore) {
      nearest[id] = sample;
    } else if (nextOnOrBefore == currentOnOrBefore &&
        nextOnOrBefore &&
        sample.atMs >= current.atMs) {
      nearest[id] = sample;
    } else if (nextOnOrBefore == currentOnOrBefore &&
        !nextOnOrBefore &&
        sample.atMs < current.atMs) {
      nearest[id] = sample;
    }
  }
  return nearest;
}

/// Numbered associated players at [atMs].
///
/// While [preferLiveDetections] (playback), the current associated box is
/// mapped through the stable [pitch]. Recorded samples are only used when
/// paused / seeking and the closest sample is within [maxSampleDeltaMs].
List<MinimapPlayerMarker> minimapMarkersAt({
  required List<PlayerDistanceSample> samples,
  required int atMs,
  required List<PlayerDetectionBox> detections,
  PitchRegion? pitch,
  PitchQuad? quad,
  Map<String, int> rosterJerseyByPlayerId = const <String, int>{},
  Map<String, String> rosterTeamByPlayerId = const <String, String>{},
  int maxSampleDeltaMs = kAnalysisMinimapSampleMaxDeltaMs,
  bool preferLiveDetections = false,
}) {
  final nearest = nearestPlayerSamplesAt(samples: samples, atMs: atMs);
  final boxById = <String, PlayerDetectionBox>{
    for (final box in associatedDetectionBoxes(detections))
      box.playerId!.trim(): box,
  };
  final ids = <String>{...nearest.keys, ...boxById.keys};
  final markers = <MinimapPlayerMarker>[];
  for (final id in ids) {
    final box = boxById[id];
    final jersey = box?.jerseyNumber ?? rosterJerseyByPlayerId[id];
    if (jersey == null) continue;
    final sample = nearest[id];
    final sampleIsClose =
        sample != null && (sample.atMs - atMs).abs() <= maxSampleDeltaMs;
    final useLiveBox = box != null && (preferLiveDetections || !sampleIsClose);
    final ({double x, double y})? point = useLiveBox
        ? minimapPointFromBox(box, pitch: pitch, quad: quad)
        : sampleIsClose
            ? minimapPointFromSample(sample, pitch: pitch, quad: quad)
            : null;
    if (point == null) continue;
    markers.add(
      MinimapPlayerMarker(
        playerId: id,
        x: point.x,
        y: point.y,
        teamId: box?.teamId ?? rosterTeamByPlayerId[id],
        jerseyNumber: jersey,
      ),
    );
  }
  return markers;
}

void mergeAnalysisSamples(
  List<PlayerDistanceSample> into,
  Iterable<PlayerDistanceSample> incoming, {
  int dedupMs = kAnalysisSampleDedupMs,
}) {
  for (final sample in incoming) {
    final lastIndex = _lastIndexForPlayer(into, sample.playerId);
    if (lastIndex >= 0 &&
        (sample.atMs - into[lastIndex].atMs).abs() < dedupMs) {
      into[lastIndex] = sample;
    } else {
      into.add(sample);
    }
  }
}

void mergeBallSamples(
  List<BallSample> into,
  Iterable<BallSample> incoming, {
  int dedupMs = kAnalysisSampleDedupMs,
}) {
  for (final sample in incoming) {
    if (into.isNotEmpty && (sample.atMs - into.last.atMs).abs() < dedupMs) {
      into[into.length - 1] = sample;
    } else {
      into.add(sample);
    }
  }
}

int _lastIndexForPlayer(List<PlayerDistanceSample> samples, String playerId) {
  for (var i = samples.length - 1; i >= 0; i--) {
    if (samples[i].playerId == playerId) return i;
  }
  return -1;
}

List<PlayerDistanceSample> resamplePlayerSamples(
  List<PlayerDistanceSample> samples, {
  int minIntervalMs = kAnalysisSampleMinIntervalMs,
}) {
  if (samples.length < 2) return samples;
  final points = [...samples]..sort((a, b) => a.atMs.compareTo(b.atMs));
  final kept = <PlayerDistanceSample>[points.first];
  for (var i = 1; i < points.length; i++) {
    if (points[i].atMs - kept.last.atMs >= minIntervalMs) {
      kept.add(points[i]);
    }
  }
  return kept;
}

List<PlayerDistanceSample> smoothPlayerPath(
  List<PlayerDistanceSample> samples, {
  int window = kAnalysisPathSmoothWindow,
}) {
  if (samples.length < 3 || window < 3) return samples;
  final points = [...samples]..sort((a, b) => a.atMs.compareTo(b.atMs));
  final half = window ~/ 2;
  return [
    for (var i = 0; i < points.length; i++)
      if (i == 0 || i == points.length - 1)
        points[i]
      else
        PlayerDistanceSample(
          playerId: points[i].playerId,
          atMs: points[i].atMs,
          x: _windowMean(points, i, half, (sample) => sample.x),
          y: _windowMean(points, i, half, (sample) => sample.y),
        ),
  ];
}

double _windowMean(
  List<PlayerDistanceSample> samples,
  int index,
  int half,
  double Function(PlayerDistanceSample sample) read,
) {
  final start = math.max(0, index - half);
  final end = math.min(samples.length - 1, index + half);
  var sum = 0.0;
  var count = 0;
  for (var i = start; i <= end; i++) {
    sum += read(samples[i]);
    count++;
  }
  return count == 0 ? read(samples[index]) : sum / count;
}

PlayerDistanceSample? sampleAssociatedPlayer({
  required PlayerDetectionBox box,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final playerId = box.playerId?.trim() ?? '';
  if (playerId.isEmpty || box.kind != PlayerDetectionKind.person) {
    return null;
  }
  final ground = playerGroundPoint(box);
  final meters = pitchPointToMeters(
    nx: ground.x,
    ny: ground.y,
    pitch: pitch,
    quad: quad,
  );
  return PlayerDistanceSample(
    playerId: playerId,
    x: meters.x,
    y: meters.y,
    atMs: atMs,
    nx: ground.x,
    ny: ground.y,
  );
}

List<PlayerDistanceSample> samplesFromBoxes({
  required List<PlayerDetectionBox> boxes,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final samples = <PlayerDistanceSample>[];
  for (final box in boxes) {
    final sample = sampleAssociatedPlayer(
      box: box,
      atMs: atMs,
      pitch: pitch,
      quad: quad,
    );
    if (sample != null) samples.add(sample);
  }
  return samples;
}

PlayerDistanceSample remapSampleToMeters(
  PlayerDistanceSample sample, {
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  if (sample.nx == null || sample.ny == null) return sample;
  if (!isUsablePitchQuad(quad) && !isUsablePitchRegion(pitch)) {
    return sample;
  }
  final meters = pitchPointToMeters(
    nx: sample.nx!,
    ny: sample.ny!,
    pitch: pitch,
    quad: quad,
  );
  return PlayerDistanceSample(
    playerId: sample.playerId,
    x: meters.x,
    y: meters.y,
    atMs: sample.atMs,
    nx: sample.nx,
    ny: sample.ny,
  );
}

/// Linear interpolation onto a fixed time grid so two YOLO cadences
/// of the same motion produce the same path length.
List<PlayerDistanceSample> interpolateOnTimeGrid(
  List<PlayerDistanceSample> samples, {
  int intervalMs = kAnalysisPathGridMs,
}) {
  if (samples.length < 2 || intervalMs <= 0) return samples;
  final points = [...samples]..sort((a, b) => a.atMs.compareTo(b.atMs));
  final start = points.first.atMs;
  final end = points.last.atMs;
  if (end <= start) return points;
  final grid = <PlayerDistanceSample>[];
  var index = 0;
  for (var t = start; t <= end; t += intervalMs) {
    while (index < points.length - 2 && points[index + 1].atMs < t) {
      index++;
    }
    final a = points[index];
    final b = points[math.min(index + 1, points.length - 1)];
    final span = b.atMs - a.atMs;
    final w = span <= 0 ? 0.0 : ((t - a.atMs) / span).clamp(0.0, 1.0);
    grid.add(
      PlayerDistanceSample(
        playerId: a.playerId,
        x: a.x + (b.x - a.x) * w,
        y: a.y + (b.y - a.y) * w,
        atMs: t,
        nx: a.nx == null || b.nx == null ? a.nx : a.nx! + (b.nx! - a.nx!) * w,
        ny: a.ny == null || b.ny == null ? a.ny : a.ny! + (b.ny! - a.ny!) * w,
      ),
    );
  }
  if (grid.isEmpty || grid.last.atMs != end) {
    grid.add(points.last);
  }
  return grid;
}

double pathDistanceMeters(
  List<PlayerDistanceSample> samples, {
  double maxSpeedMetersPerSecond = kAnalysisMaxSpeedMetersPerSecond,
  double minStepMeters = kAnalysisMinStepMeters,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  if (samples.length < 2) return 0;
  final remapped = [
    for (final sample in samples)
      remapSampleToMeters(sample, pitch: pitch, quad: quad),
  ];
  final cleaned = dropTeleportSamples(
    remapped,
    maxSpeedMetersPerSecond: maxSpeedMetersPerSecond,
  );
  final points = smoothPlayerPath(interpolateOnTimeGrid(cleaned));
  var distance = 0.0;
  var last = points.first;
  for (var i = 1; i < points.length; i++) {
    final next = points[i];
    final dt = (next.atMs - last.atMs) / 1000;
    if (dt <= 0) {
      last = next;
      continue;
    }
    final step = math.sqrt(
      math.pow(next.x - last.x, 2) + math.pow(next.y - last.y, 2),
    );
    last = next;
    if (step < minStepMeters) continue;
    if (step / dt > maxSpeedMetersPerSecond) continue;
    distance += step;
  }
  return distance;
}

List<PlayerDistanceSample> dropTeleportSamples(
  List<PlayerDistanceSample> samples, {
  double maxSpeedMetersPerSecond = kAnalysisMaxSpeedMetersPerSecond,
}) {
  if (samples.length < 2) return samples;
  final points = [...samples]..sort((a, b) => a.atMs.compareTo(b.atMs));
  final kept = <PlayerDistanceSample>[points.first];
  for (var i = 1; i < points.length; i++) {
    final previous = kept.last;
    final next = points[i];
    final dt = (next.atMs - previous.atMs) / 1000;
    if (dt <= 0) continue;
    final step = math.sqrt(
      math.pow(next.x - previous.x, 2) + math.pow(next.y - previous.y, 2),
    );
    if (step / dt > maxSpeedMetersPerSecond) continue;
    kept.add(next);
  }
  return kept;
}

List<PlayerDistanceResult> summarizePlayerDistances({
  required List<PlayerDistanceSample> samples,
  required List<DebugVideoRosterPlayer> roster,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final byPlayer = <String, List<PlayerDistanceSample>>{};
  for (final sample in samples) {
    byPlayer.putIfAbsent(sample.playerId, () => <PlayerDistanceSample>[]).add(
      sample,
    );
  }
  final results = <PlayerDistanceResult>[];
  for (final entry in byPlayer.entries) {
    DebugVideoRosterPlayer? player;
    for (final candidate in roster) {
      if ((candidate.playerId ?? '').trim() == entry.key) {
        player = candidate;
        break;
      }
    }
    results.add(
      PlayerDistanceResult(
        playerId: entry.key,
        displayName: player?.displayName ?? entry.key,
        number: player?.number,
        meters: pathDistanceMeters(entry.value, pitch: pitch, quad: quad),
        sampleCount: entry.value.length,
      ),
    );
  }
  results.sort((a, b) => b.meters.compareTo(a.meters));
  return results;
}

String formatDebugVideoDistanceMeters(double meters) {
  if (meters <= 0) return '0';
  if (meters < 20) return meters.toStringAsFixed(1);
  return meters.round().toString();
}

class BallSample {
  const BallSample({
    required this.x,
    required this.y,
    required this.atMs,
  });

  final double x;
  final double y;
  final int atMs;
}

class PlayerBallStats {
  const PlayerBallStats({
    this.played = 0,
    this.received = 0,
    this.given = 0,
    this.passes = 0,
    this.shots = 0,
  });

  final int played;
  final int received;
  final int given;
  final int passes;
  final int shots;
}

class _MutableBallStats {
  int played = 0;
  int received = 0;
  int given = 0;
  int passes = 0;
  int shots = 0;

  PlayerBallStats freeze() {
    return PlayerBallStats(
      played: played,
      received: received,
      given: given,
      passes: passes,
      shots: shots,
    );
  }
}

class _BallRelease {
  const _BallRelease({
    required this.playerId,
    required this.x,
    required this.y,
    required this.atMs,
  });

  final String playerId;
  final double x;
  final double y;
  final int atMs;
}

BallSample? sampleBall({
  required PlayerDetectionBox box,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  if (box.kind != PlayerDetectionKind.ball) return null;
  final meters = pitchPointToMeters(
    nx: (box.left + box.width / 2).clamp(0.0, 1.0),
    ny: detectionAnchorY(box).clamp(0.0, 1.0),
    pitch: pitch,
    quad: quad,
  );
  return BallSample(x: meters.x, y: meters.y, atMs: atMs);
}

List<BallSample> ballSamplesFromBoxes({
  required List<PlayerDetectionBox> boxes,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final samples = <BallSample>[];
  for (final box in boxes) {
    final sample = sampleBall(box: box, atMs: atMs, pitch: pitch, quad: quad);
    if (sample != null) samples.add(sample);
  }
  return samples;
}

double _pointDistance(double x1, double y1, double x2, double y2) {
  return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
}

bool ballMovingTowardGoal({
  required double fromX,
  required double toX,
}) {
  final goal = fromX < kAnalysisPitchLengthMeters / 2
      ? 0.0
      : kAnalysisPitchLengthMeters;
  return (toX - goal).abs() < (fromX - goal).abs() - 1;
}

bool _isShotRelease({
  required _BallRelease release,
  required BallSample ball,
}) {
  final dt = (ball.atMs - release.atMs) / 1000;
  if (dt <= 0) return false;
  final travel = _pointDistance(release.x, release.y, ball.x, ball.y);
  final speed = travel / dt;
  return travel >= kShotMinTravelMeters &&
      speed >= kShotMinSpeedMetersPerSecond &&
      ballMovingTowardGoal(fromX: release.x, toX: ball.x);
}

String? closestPlayerToBall({
  required BallSample ball,
  required Map<String, PlayerDistanceSample> players,
  String? holderId,
}) {
  String? closestId;
  var closestDist = kBallPossessionRadiusMeters;
  for (final sample in players.values) {
    final distance = _pointDistance(sample.x, sample.y, ball.x, ball.y);
    final limit = sample.playerId == holderId
        ? kBallHolderKeepRadiusMeters
        : kBallPossessionRadiusMeters;
    if (distance <= limit && distance <= closestDist) {
      closestDist = distance;
      closestId = sample.playerId;
    }
  }
  if (holderId != null && players.containsKey(holderId)) {
    final holder = players[holderId]!;
    final holderDist = _pointDistance(holder.x, holder.y, ball.x, ball.y);
    if (holderDist <= kBallHolderKeepRadiusMeters &&
        (closestId == null ||
            closestId == holderId ||
            holderDist <= closestDist + 0.8)) {
      return holderId;
    }
  }
  return closestId;
}

Map<String, PlayerBallStats> detectPlayerBallStats({
  required List<PlayerDistanceSample> players,
  required List<BallSample> balls,
  required List<DebugVideoRosterPlayer> roster,
}) {
  final teamByPlayer = <String, String>{
    for (final player in roster)
      if ((player.playerId ?? '').trim().isNotEmpty)
        player.playerId!.trim(): player.teamId,
  };
  final playerTimeline = [...players]..sort((a, b) => a.atMs.compareTo(b.atMs));
  final ballTimeline = [...balls]..sort((a, b) => a.atMs.compareTo(b.atMs));
  if (ballTimeline.isEmpty) return const <String, PlayerBallStats>{};

  final lastPos = <String, PlayerDistanceSample>{};
  var playerIndex = 0;
  String? holderId;
  _BallRelease? pending;
  final stats = <String, _MutableBallStats>{};

  _MutableBallStats of(String playerId) {
    return stats.putIfAbsent(playerId, _MutableBallStats.new);
  }

  void creditPlayed(String playerId) {
    of(playerId).played++;
  }

  void creditPass(String fromId, String toId) {
    if (fromId == toId) return;
    final fromTeam = teamByPlayer[fromId] ?? '';
    final toTeam = teamByPlayer[toId] ?? '';
    if (fromTeam.isEmpty || fromTeam != toTeam) return;
    of(fromId).passes++;
    of(fromId).given++;
    of(toId).received++;
  }

  void maybeShot(_BallRelease release, BallSample ball) {
    if (_isShotRelease(release: release, ball: ball)) {
      of(release.playerId).shots++;
    }
  }

  for (final ball in ballTimeline) {
    while (playerIndex < playerTimeline.length &&
        playerTimeline[playerIndex].atMs <= ball.atMs) {
      lastPos[playerTimeline[playerIndex].playerId] =
          playerTimeline[playerIndex];
      playerIndex++;
    }

    final closestId = closestPlayerToBall(
      ball: ball,
      players: lastPos,
      holderId: holderId ?? pending?.playerId,
    );

    if (closestId != null) {
      final release = pending;
      final previousHolder = holderId;
      if (release != null && closestId != release.playerId) {
        creditPass(release.playerId, closestId);
        pending = null;
      } else if (previousHolder != null &&
          release == null &&
          closestId != previousHolder) {
        creditPass(previousHolder, closestId);
      }
      if (closestId != previousHolder) {
        if (release?.playerId != closestId) {
          creditPlayed(closestId);
        }
        holderId = closestId;
      }
      pending = null;
    } else if (holderId != null) {
      final previousHolder = holderId;
      final holder = lastPos[previousHolder];
      pending = _BallRelease(
        playerId: previousHolder,
        x: holder?.x ?? ball.x,
        y: holder?.y ?? ball.y,
        atMs: ball.atMs,
      );
      holderId = null;
    } else if (pending != null) {
      final release = pending;
      if (ball.atMs - release.atMs >= kBallEventTimeoutMs) {
        maybeShot(release, ball);
        pending = null;
      }
    }
  }

  final leftover = pending;
  if (leftover != null) {
    maybeShot(leftover, ballTimeline.last);
  }

  return {
    for (final entry in stats.entries) entry.key: entry.value.freeze(),
  };
}

List<PlayerDistanceResult> summarizePlayerAnalysis({
  required List<PlayerDistanceSample> samples,
  required List<BallSample> balls,
  required List<DebugVideoRosterPlayer> roster,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final distances = summarizePlayerDistances(
    samples: samples,
    roster: roster,
    pitch: pitch,
    quad: quad,
  );
  final ballStats = detectPlayerBallStats(
    players: samples,
    balls: balls,
    roster: roster,
  );
  final byId = <String, PlayerDistanceResult>{
    for (final result in distances) result.playerId: result,
  };

  DebugVideoRosterPlayer? rosterPlayer(String playerId) {
    for (final player in roster) {
      if ((player.playerId ?? '').trim() == playerId) return player;
    }
    return null;
  }

  for (final entry in ballStats.entries) {
    final existing = byId[entry.key];
    final stats = entry.value;
    final player = rosterPlayer(entry.key);
    byId[entry.key] = PlayerDistanceResult(
      playerId: entry.key,
      displayName: existing?.displayName ?? player?.displayName ?? entry.key,
      number: existing?.number ?? player?.number,
      meters: existing?.meters ?? 0,
      sampleCount: existing?.sampleCount ?? 0,
      ballsPlayed: stats.played,
      ballsReceived: stats.received,
      ballsGiven: stats.given,
      passes: stats.passes,
      shots: stats.shots,
    );
  }

  final results = byId.values.toList()
    ..sort((a, b) {
      final ballCmp = (b.ballsPlayed + b.passes + b.shots).compareTo(
        a.ballsPlayed + a.passes + a.shots,
      );
      if (ballCmp != 0) return ballCmp;
      return b.meters.compareTo(a.meters);
    });
  return results;
}
