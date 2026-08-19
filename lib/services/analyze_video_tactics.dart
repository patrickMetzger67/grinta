import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_analysis.dart';

const int kTacticsTrailLookbackMs = 8000;
const String kTacticsJsonSuffix = '.tactics.json';

/// Storage object next to the MP4: `clip.mp4` → `clip.tactics.json`.
String tacticsStoragePathForVideo(String videoStoragePath) {
  final path = videoStoragePath.trim();
  if (path.isEmpty) return '';
  if (path.toLowerCase().endsWith('.mp4')) {
    return '${path.substring(0, path.length - 4)}$kTacticsJsonSuffix';
  }
  return '$path$kTacticsJsonSuffix';
}

class TacticsPlayerTrail {
  const TacticsPlayerTrail({
    required this.playerId,
    required this.points,
    this.teamId,
  });

  final String playerId;
  final List<({double x, double y})> points;
  final String? teamId;
}

/// Frozen 2D recording of an analysis run: associated players + ball,
/// mapped onto the 105×68 pitch. Enough to replay the match without video.
class AnalyzeTacticsRecording {
  const AnalyzeTacticsRecording({
    required this.players,
    this.balls = const <BallSample>[],
    this.pitch,
    this.quad,
    this.videoStoragePath,
    this.matchId,
  });

  final List<PlayerDistanceSample> players;
  final List<BallSample> balls;
  final PitchRegion? pitch;
  final PitchQuad? quad;
  final String? videoStoragePath;
  final String? matchId;

  bool get isEmpty => players.isEmpty && balls.isEmpty;

  int get startMs {
    var start = 1 << 30;
    for (final sample in players) {
      if (sample.atMs < start) start = sample.atMs;
    }
    for (final ball in balls) {
      if (ball.atMs < start) start = ball.atMs;
    }
    return start == 1 << 30 ? 0 : start;
  }

  int get endMs {
    var end = 0;
    for (final sample in players) {
      if (sample.atMs > end) end = sample.atMs;
    }
    for (final ball in balls) {
      if (ball.atMs > end) end = ball.atMs;
    }
    return end;
  }

  int get durationMs {
    final span = endMs - startMs;
    return span < 0 ? 0 : span;
  }

  AnalyzeTacticsRecording copyWith({
    List<PlayerDistanceSample>? players,
    List<BallSample>? balls,
    PitchRegion? pitch,
    PitchQuad? quad,
    String? videoStoragePath,
    String? matchId,
  }) {
    return AnalyzeTacticsRecording(
      players: players ?? this.players,
      balls: balls ?? this.balls,
      pitch: pitch ?? this.pitch,
      quad: quad ?? this.quad,
      videoStoragePath: videoStoragePath ?? this.videoStoragePath,
      matchId: matchId ?? this.matchId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'v': 1,
      if (videoStoragePath != null) 'videoStoragePath': videoStoragePath,
      if (matchId != null) 'matchId': matchId,
      if (pitch != null) 'pitch': pitchRegionToJson(pitch!),
      if (quad != null) 'quad': pitchQuadToJson(quad!),
      'players': [
        for (final sample in players) playerDistanceSampleToJson(sample),
      ],
      'balls': [
        for (final ball in balls) ballSampleToJson(ball),
      ],
    };
  }

  factory AnalyzeTacticsRecording.fromJson(Map<String, dynamic> json) {
    final rawPlayers = json['players'];
    final rawBalls = json['balls'];
    return AnalyzeTacticsRecording(
      videoStoragePath: json['videoStoragePath']?.toString(),
      matchId: json['matchId']?.toString(),
      pitch: json['pitch'] is Map
          ? pitchRegionFromJson(Map<String, dynamic>.from(json['pitch'] as Map))
          : null,
      quad: json['quad'] is Map
          ? pitchQuadFromJson(Map<String, dynamic>.from(json['quad'] as Map))
          : null,
      players: rawPlayers is List
          ? rawPlayers
              .whereType<Map>()
              .map(
                (item) => playerDistanceSampleFromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <PlayerDistanceSample>[],
      balls: rawBalls is List
          ? rawBalls
              .whereType<Map>()
              .map((item) => ballSampleFromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <BallSample>[],
    );
  }
}

AnalyzeTacticsRecording buildTacticsRecording({
  required List<PlayerDistanceSample> samples,
  List<BallSample> balls = const <BallSample>[],
  PitchRegion? pitch,
  PitchQuad? quad,
  String? videoStoragePath,
  String? matchId,
}) {
  return AnalyzeTacticsRecording(
    players: List<PlayerDistanceSample>.from(samples),
    balls: List<BallSample>.from(balls),
    pitch: pitch,
    quad: quad,
    videoStoragePath: videoStoragePath,
    matchId: matchId,
  );
}

Map<String, dynamic> playerDistanceSampleToJson(PlayerDistanceSample sample) {
  return <String, dynamic>{
    'id': sample.playerId,
    'x': sample.x,
    'y': sample.y,
    't': sample.atMs,
    if (sample.nx != null) 'nx': sample.nx,
    if (sample.ny != null) 'ny': sample.ny,
  };
}

PlayerDistanceSample playerDistanceSampleFromJson(Map<String, dynamic> json) {
  return PlayerDistanceSample(
    playerId: '${json['id'] ?? json['playerId'] ?? ''}',
    x: (json['x'] as num?)?.toDouble() ?? 0,
    y: (json['y'] as num?)?.toDouble() ?? 0,
    atMs: (json['t'] as num?)?.toInt() ?? (json['atMs'] as num?)?.toInt() ?? 0,
    nx: (json['nx'] as num?)?.toDouble(),
    ny: (json['ny'] as num?)?.toDouble(),
  );
}

Map<String, dynamic> ballSampleToJson(BallSample sample) {
  return <String, dynamic>{
    'x': sample.x,
    'y': sample.y,
    't': sample.atMs,
  };
}

BallSample ballSampleFromJson(Map<String, dynamic> json) {
  return BallSample(
    x: (json['x'] as num?)?.toDouble() ?? 0,
    y: (json['y'] as num?)?.toDouble() ?? 0,
    atMs: (json['t'] as num?)?.toInt() ?? (json['atMs'] as num?)?.toInt() ?? 0,
  );
}

Map<String, dynamic> pitchRegionToJson(PitchRegion pitch) {
  return <String, dynamic>{
    'top': pitch.top,
    'bottom': pitch.bottom,
    'left': pitch.left,
    'right': pitch.right,
  };
}

PitchRegion pitchRegionFromJson(Map<String, dynamic> json) {
  return PitchRegion(
    top: (json['top'] as num?)?.toDouble() ?? 0,
    bottom: (json['bottom'] as num?)?.toDouble() ?? 1,
    left: (json['left'] as num?)?.toDouble() ?? 0,
    right: (json['right'] as num?)?.toDouble() ?? 1,
  );
}

Map<String, dynamic> pitchQuadToJson(PitchQuad quad) {
  return <String, dynamic>{
    'farLeft': <double>[quad.farLeft.x, quad.farLeft.y],
    'farRight': <double>[quad.farRight.x, quad.farRight.y],
    'nearLeft': <double>[quad.nearLeft.x, quad.nearLeft.y],
    'nearRight': <double>[quad.nearRight.x, quad.nearRight.y],
  };
}

({double x, double y}) _pointFromJson(dynamic raw, {double x = 0, double y = 0}) {
  if (raw is List && raw.length >= 2) {
    return (
      x: (raw[0] as num?)?.toDouble() ?? x,
      y: (raw[1] as num?)?.toDouble() ?? y,
    );
  }
  if (raw is Map) {
    return (
      x: (raw['x'] as num?)?.toDouble() ?? x,
      y: (raw['y'] as num?)?.toDouble() ?? y,
    );
  }
  return (x: x, y: y);
}

PitchQuad pitchQuadFromJson(Map<String, dynamic> json) {
  return PitchQuad(
    farLeft: _pointFromJson(json['farLeft']),
    farRight: _pointFromJson(json['farRight'], x: 1),
    nearLeft: _pointFromJson(json['nearLeft'], y: 1),
    nearRight: _pointFromJson(json['nearRight'], x: 1, y: 1),
  );
}

({double x, double y}) interpolateMinimapAlongSamples({
  required List<PlayerDistanceSample> samples,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
}) {
  final points = [...samples]..sort((a, b) => a.atMs.compareTo(b.atMs));
  if (points.isEmpty) return (x: 0.5, y: 0.5);
  if (atMs <= points.first.atMs) {
    return minimapPointFromSample(points.first, pitch: pitch, quad: quad);
  }
  if (atMs >= points.last.atMs) {
    return minimapPointFromSample(points.last, pitch: pitch, quad: quad);
  }
  var index = 0;
  while (index < points.length - 2 && points[index + 1].atMs < atMs) {
    index++;
  }
  final a = points[index];
  final b = points[index + 1];
  final span = b.atMs - a.atMs;
  final w = span <= 0 ? 0.0 : ((atMs - a.atMs) / span).clamp(0.0, 1.0);
  final from = minimapPointFromSample(a, pitch: pitch, quad: quad);
  final to = minimapPointFromSample(b, pitch: pitch, quad: quad);
  return (
    x: from.x + (to.x - from.x) * w,
    y: from.y + (to.y - from.y) * w,
  );
}

({double x, double y})? interpolateBallAlongSamples({
  required List<BallSample> balls,
  required int atMs,
}) {
  if (balls.isEmpty) return null;
  final points = [...balls]..sort((a, b) => a.atMs.compareTo(b.atMs));
  BallSample at(int index) => points[index];
  ({double x, double y}) norm(BallSample sample) => (
        x: (sample.x / kAnalysisPitchLengthMeters).clamp(0.0, 1.0),
        y: (sample.y / kAnalysisPitchWidthMeters).clamp(0.0, 1.0),
      );
  if (atMs <= points.first.atMs) return norm(points.first);
  if (atMs >= points.last.atMs) return norm(points.last);
  var index = 0;
  while (index < points.length - 2 && at(index + 1).atMs < atMs) {
    index++;
  }
  final a = at(index);
  final b = at(index + 1);
  final span = b.atMs - a.atMs;
  final w = span <= 0 ? 0.0 : ((atMs - a.atMs) / span).clamp(0.0, 1.0);
  final from = norm(a);
  final to = norm(b);
  return (
    x: from.x + (to.x - from.x) * w,
    y: from.y + (to.y - from.y) * w,
  );
}

Map<String, List<PlayerDistanceSample>> tacticsSamplesByPlayer(
  Iterable<PlayerDistanceSample> samples,
) {
  final byPlayer = <String, List<PlayerDistanceSample>>{};
  for (final sample in samples) {
    final id = sample.playerId.trim();
    if (id.isEmpty) continue;
    byPlayer.putIfAbsent(id, () => <PlayerDistanceSample>[]).add(sample);
  }
  return byPlayer;
}

/// Smooth 2D positions at [atMs] from the saved path (not live YOLO boxes).
List<MinimapPlayerMarker> tacticsReplayMarkersAt({
  required AnalyzeTacticsRecording recording,
  required int atMs,
  Map<String, int> rosterJerseyByPlayerId = const <String, int>{},
  Map<String, String> rosterTeamByPlayerId = const <String, String>{},
}) {
  final markers = <MinimapPlayerMarker>[];
  for (final entry in tacticsSamplesByPlayer(recording.players).entries) {
    final jersey = rosterJerseyByPlayerId[entry.key];
    if (jersey == null) continue;
    if (entry.value.isEmpty) continue;
    final earliest = entry.value.map((sample) => sample.atMs).reduce(
          (a, b) => a < b ? a : b,
        );
    final latest = entry.value.map((sample) => sample.atMs).reduce(
          (a, b) => a > b ? a : b,
        );
    if (atMs < earliest - 200 || atMs > latest + 400) continue;
    final point = interpolateMinimapAlongSamples(
      samples: entry.value,
      atMs: atMs,
      pitch: recording.pitch,
      quad: recording.quad,
    );
    markers.add(
      MinimapPlayerMarker(
        playerId: entry.key,
        x: point.x,
        y: point.y,
        teamId: rosterTeamByPlayerId[entry.key],
        jerseyNumber: jersey,
      ),
    );
  }
  return markers;
}

List<TacticsPlayerTrail> tacticsTrailsAt({
  required List<PlayerDistanceSample> samples,
  required int atMs,
  PitchRegion? pitch,
  PitchQuad? quad,
  Map<String, String> rosterTeamByPlayerId = const <String, String>{},
  int lookbackMs = kTacticsTrailLookbackMs,
}) {
  final trails = <TacticsPlayerTrail>[];
  final fromMs = atMs - lookbackMs;
  for (final entry in tacticsSamplesByPlayer(samples).entries) {
    final window = [
      for (final sample in entry.value)
        if (sample.atMs >= fromMs && sample.atMs <= atMs) sample,
    ]..sort((a, b) => a.atMs.compareTo(b.atMs));
    if (window.length < 2) continue;
    trails.add(
      TacticsPlayerTrail(
        playerId: entry.key,
        teamId: rosterTeamByPlayerId[entry.key],
        points: [
          for (final sample in window)
            minimapPointFromSample(sample, pitch: pitch, quad: quad),
        ],
      ),
    );
  }
  return trails;
}
