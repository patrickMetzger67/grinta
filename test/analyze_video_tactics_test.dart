import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/services/analyze_video_tactics.dart';

void main() {
  group('tacticsStoragePathForVideo', () {
    test('replaces the mp4 extension', () {
      expect(
        tacticsStoragePathForVideo('video/u1/1700_clip.mp4'),
        'video/u1/1700_clip.tactics.json',
      );
      expect(
        tacticsStoragePathForVideo('video/u1/1700_clip.MP4'),
        'video/u1/1700_clip.tactics.json',
      );
    });

    test('appends the suffix when there is no mp4 extension', () {
      expect(
        tacticsStoragePathForVideo('video/u1/clip'),
        'video/u1/clip.tactics.json',
      );
    });
  });

  group('AnalyzeTacticsRecording', () {
    const trap = PitchQuad(
      farLeft: (x: 0.30, y: 0.20),
      farRight: (x: 0.70, y: 0.20),
      nearLeft: (x: 0.10, y: 0.80),
      nearRight: (x: 0.90, y: 0.80),
    );

    test('round-trips players, ball, and the frozen grass quad', () {
      final recording = buildTacticsRecording(
        samples: const [
          PlayerDistanceSample(
            playerId: 'p1',
            x: 10,
            y: 12,
            atMs: 1000,
            nx: 0.32,
            ny: 0.40,
          ),
          PlayerDistanceSample(playerId: 'p1', x: 18, y: 14, atMs: 2000),
        ],
        balls: const [BallSample(x: 12, y: 13, atMs: 1500)],
        pitch: trap.bounds,
        quad: trap,
        videoStoragePath: 'video/u1/clip.mp4',
        matchId: 'm1',
      );
      final restored = AnalyzeTacticsRecording.fromJson(recording.toJson());
      expect(restored.matchId, 'm1');
      expect(restored.videoStoragePath, 'video/u1/clip.mp4');
      expect(restored.players, hasLength(2));
      expect(restored.players.first.playerId, 'p1');
      expect(restored.players.first.nx, closeTo(0.32, 0.0001));
      expect(restored.balls.single.x, 12);
      expect(restored.quad, trap);
      expect(restored.startMs, 1000);
      expect(restored.endMs, 2000);
      expect(restored.durationMs, 1000);
    });

    test('interpolates a player halfway along a saved path', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'p1', x: 0, y: 0, atMs: 0),
        PlayerDistanceSample(playerId: 'p1', x: 105, y: 68, atMs: 1000),
      ];
      final mid = interpolateMinimapAlongSamples(samples: samples, atMs: 500);
      expect(mid.x, closeTo(0.5, 0.02));
      expect(mid.y, closeTo(0.5, 0.02));
    });

    test('keeps a trail of the last seconds only', () {
      final samples = [
        for (var t = 0; t <= 12000; t += 1000)
          PlayerDistanceSample(playerId: 'p1', x: t / 200, y: 10, atMs: t),
      ];
      final trails = tacticsTrailsAt(samples: samples, atMs: 10000);
      expect(trails, hasLength(1));
      expect(trails.single.points.length, greaterThanOrEqualTo(8));
      expect(trails.single.points.first.x, lessThan(trails.single.points.last.x));
    });

    test('replay markers follow the interpolated path, not the last raw sample', () {
      final recording = buildTacticsRecording(
        samples: const [
          PlayerDistanceSample(playerId: 'p1', x: 0, y: 34, atMs: 0),
          PlayerDistanceSample(playerId: 'p1', x: 105, y: 34, atMs: 2000),
        ],
      );
      final markers = tacticsReplayMarkersAt(
        recording: recording,
        atMs: 1000,
        rosterJerseyByPlayerId: const {'p1': 9},
        rosterTeamByPlayerId: const {'p1': 't1'},
      );
      expect(markers, hasLength(1));
      expect(markers.single.x, closeTo(0.5, 0.02));
      expect(markers.single.jerseyNumber, 9);
      expect(markers.single.teamId, 't1');
    });
  });
}
