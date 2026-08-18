import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/widget/analyze_video/analyze_video_pitch_minimap.dart';

void main() {
  group('analysisMappingPitch', () {
    const frozen = PitchRegion(top: 0.25, bottom: 0.85, left: 0.08, right: 0.92);
    const latest = PitchRegion(top: 0.10, bottom: 0.95, left: 0.0, right: 1.0);

    test('keeps the frozen pitch while analyzing', () {
      expect(
        analysisMappingPitch(
          analyzing: true,
          frozenPitch: frozen,
          latestPitch: latest,
        ),
        frozen,
      );
      expect(
        freezeAnalysisPitch(frozenPitch: frozen, latestPitch: latest),
        frozen,
      );
    });

    test('keeps the frozen video pitch after analysis too', () {
      expect(
        analysisMappingPitch(
          analyzing: false,
          frozenPitch: frozen,
          latestPitch: latest,
        ),
        frozen,
      );
      expect(
        freezeAnalysisPitch(frozenPitch: null, latestPitch: latest),
        latest,
      );
    });

    test('does not freeze the full-frame fallback', () {
      expect(isUsablePitchRegion(kFullFramePitchRegion), isFalse);
      expect(isUsablePitchRegion(frozen), isTrue);
      expect(
        freezeAnalysisPitch(frozenPitch: null, latestPitch: null),
        isNull,
      );
      expect(
        freezeAnalysisPitch(
          frozenPitch: kFullFramePitchRegion,
          latestPitch: latest,
        ),
        latest,
      );
      expect(
        analysisMappingPitch(
          analyzing: true,
          frozenPitch: null,
          latestPitch: null,
        ),
        kFullFramePitchRegion,
      );
      expect(
        analysisMappingPitch(
          analyzing: true,
          frozenPitch: null,
          latestPitch: latest,
        ),
        latest,
      );
    });
  });

  group('pitchPointToMeters', () {
    test('maps image corners onto heatmap length/width (no Y flip)', () {
      const pitch = PitchRegion(top: 0.2, bottom: 0.8, left: 0.1, right: 0.9);
      final farLeft = pitchPointToMeters(nx: 0.1, ny: 0.2, pitch: pitch);
      final farRight = pitchPointToMeters(nx: 0.9, ny: 0.2, pitch: pitch);
      final nearLeft = pitchPointToMeters(nx: 0.1, ny: 0.8, pitch: pitch);
      final nearRight = pitchPointToMeters(nx: 0.9, ny: 0.8, pitch: pitch);
      expect(farLeft.x, closeTo(0, 0.01));
      expect(farLeft.y, closeTo(0, 0.01));
      expect(farRight.x, closeTo(105, 0.01));
      expect(farRight.y, closeTo(0, 0.01));
      expect(nearLeft.x, closeTo(0, 0.01));
      expect(nearLeft.y, closeTo(68, 0.01));
      expect(nearRight.x, closeTo(105, 0.01));
      expect(nearRight.y, closeTo(68, 0.01));
    });
  });

  group('minimapPointFromBox', () {
    test('maps feet point to normalized pitch coordinates', () {
      const pitch = PitchRegion(top: 0.2, bottom: 0.8, left: 0.1, right: 0.9);
      const box = PlayerDetectionBox(
        left: 0.45,
        top: 0.4,
        width: 0.1,
        height: 0.2,
        playerId: 'p1',
      );
      final point = minimapPointFromBox(box, pitch: pitch);
      expect(point.x, closeTo(0.5, 0.02));
      expect(point.y, closeTo(0.64, 0.02));
    });

    test('falls back to the full frame without a pitch estimate', () {
      const box = PlayerDetectionBox(
        left: 0.4,
        top: 0.4,
        width: 0.1,
        height: 0.2,
        playerId: 'p1',
      );
      final point = minimapPointFromBox(box);
      expect(point.x, closeTo(0.45, 0.02));
      expect(point.y, greaterThan(0.4));
    });

    test('frozen pitch keeps the same box at the same minimap point', () {
      const frozen = PitchRegion(top: 0.25, bottom: 0.85, left: 0.08, right: 0.92);
      const flickered = PitchRegion(top: 0.05, bottom: 0.98, left: 0.0, right: 1.0);
      const box = PlayerDetectionBox(
        left: 0.20,
        top: 0.40,
        width: 0.08,
        height: 0.20,
        playerId: 'p1',
        jerseyNumber: 2,
      );
      final a = minimapPointFromBox(box, pitch: frozen);
      final b = minimapPointFromBox(box, pitch: frozen);
      expect(a.x, closeTo(b.x, 0.0001));
      expect(a.y, closeTo(b.y, 0.0001));
      final drifted = minimapPointFromBox(box, pitch: flickered);
      expect(drifted.x, isNot(closeTo(a.x, 0.02)));
    });

    test('known corners sit on the same relative 2D place as the frame', () {
      const pitch = PitchRegion(top: 0.2, bottom: 0.8, left: 0.1, right: 0.9);
      PlayerDetectionBox boxAt(double nx, double ny) {
        const height = 0.10;
        const width = 0.08;
        return PlayerDetectionBox(
          left: nx - width / 2,
          top: ny - height * 0.92,
          width: width,
          height: height,
          playerId: 'p1',
          jerseyNumber: 2,
        );
      }

      final farLeft = minimapPointFromBox(boxAt(0.1, 0.2), pitch: pitch);
      final farRight = minimapPointFromBox(boxAt(0.9, 0.2), pitch: pitch);
      final nearLeft = minimapPointFromBox(boxAt(0.1, 0.8), pitch: pitch);
      final nearRight = minimapPointFromBox(boxAt(0.9, 0.8), pitch: pitch);
      expect(farLeft.x, closeTo(0, 0.02));
      expect(farLeft.y, closeTo(0, 0.02));
      expect(farRight.x, closeTo(1, 0.02));
      expect(farRight.y, closeTo(0, 0.02));
      expect(nearLeft.x, closeTo(0, 0.02));
      expect(nearLeft.y, closeTo(1, 0.02));
      expect(nearRight.x, closeTo(1, 0.02));
      expect(nearRight.y, closeTo(1, 0.02));
    });
  });

  group('nearestPlayerSamplesAt', () {
    const samples = <PlayerDistanceSample>[
      PlayerDistanceSample(playerId: 'a', x: 10, y: 8, atMs: 0),
      PlayerDistanceSample(playerId: 'a', x: 22, y: 9, atMs: 1000),
      PlayerDistanceSample(playerId: 'a', x: 40, y: 12, atMs: 4000),
      PlayerDistanceSample(playerId: 'b', x: 5, y: 4, atMs: 0),
      PlayerDistanceSample(playerId: 'b', x: 18, y: 6, atMs: 4000),
    ];

    test('picks the closest sample per player at a timestamp', () {
      final start = nearestPlayerSamplesAt(samples: samples, atMs: 0);
      expect(start['a']?.x, 10);
      expect(start['a']?.atMs, 0);
      expect(start['b']?.x, 5);

      final mid = nearestPlayerSamplesAt(samples: samples, atMs: 1200);
      expect(mid['a']?.atMs, 1000);
      expect(mid['a']?.x, 22);

      final end = nearestPlayerSamplesAt(samples: samples, atMs: 4000);
      expect(end['a']?.x, 40);
      expect(end['b']?.x, 18);

      final afterEnd = nearestPlayerSamplesAt(samples: samples, atMs: 9000);
      expect(afterEnd['a']?.atMs, 4000);
      expect(afterEnd['a']?.x, 40);
    });

    test('on a tie prefers the last sample at or before the timestamp', () {
      const tied = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'a', x: 10, y: 0, atMs: 0),
        PlayerDistanceSample(playerId: 'a', x: 30, y: 0, atMs: 2000),
      ];
      final at = nearestPlayerSamplesAt(samples: tied, atMs: 1000);
      expect(at['a']?.atMs, 0);
      expect(at['a']?.x, 10);
    });
  });

  group('minimapMarkersAt', () {
    test('maps the nearest meter sample onto the 105x68 pitch', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'p1', x: 52.5, y: 34, atMs: 0),
        PlayerDistanceSample(playerId: 'p1', x: 84, y: 17, atMs: 4000),
      ];
      const box = PlayerDetectionBox(
        left: 0.1,
        top: 0.2,
        width: 0.08,
        height: 0.2,
        playerId: 'p1',
        jerseyNumber: 7,
        teamId: 't1',
      );
      final start = minimapMarkersAt(
        samples: samples,
        atMs: 0,
        detections: const [box],
      );
      expect(start, hasLength(1));
      expect(start.single.x, closeTo(0.5, 0.01));
      expect(start.single.y, closeTo(0.5, 0.01));
      expect(start.single.jerseyNumber, 7);

      final end = minimapMarkersAt(
        samples: samples,
        atMs: 4000,
        detections: const [box],
      );
      expect(end.single.x, closeTo(0.8, 0.01));
      expect(end.single.y, closeTo(0.25, 0.01));
    });

    test('falls back to the current box when no sample is near the playhead', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'p1', x: 84, y: 17, atMs: 20000),
      ];
      const box = PlayerDetectionBox(
        left: 0.2,
        top: 0.3,
        width: 0.1,
        height: 0.2,
        playerId: 'p1',
        jerseyNumber: 9,
      );
      final markers = minimapMarkersAt(
        samples: samples,
        atMs: 0,
        detections: const [box],
        pitch: kFullFramePitchRegion,
      );
      expect(markers, hasLength(1));
      final fromBox = minimapPointFromBox(box, pitch: kFullFramePitchRegion);
      expect(markers.single.x, closeTo(fromBox.x, 0.0001));
      expect(markers.single.y, closeTo(fromBox.y, 0.0001));
    });

    test('while playing uses the live box, not a delayed sample', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'p1', x: 84, y: 17, atMs: 200),
      ];
      const box = PlayerDetectionBox(
        left: 0.20,
        top: 0.30,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        jerseyNumber: 2,
      );
      final live = minimapMarkersAt(
        samples: samples,
        atMs: 240,
        detections: const [box],
        pitch: kFullFramePitchRegion,
        preferLiveDetections: true,
      );
      final fromBox = minimapPointFromBox(box, pitch: kFullFramePitchRegion);
      expect(live.single.x, closeTo(fromBox.x, 0.0001));
      expect(live.single.y, closeTo(fromBox.y, 0.0001));
      expect(live.single.x, isNot(closeTo(84 / 105, 0.02)));
    });

    test('while paused ignores a sample farther than 400ms', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'p1', x: 84, y: 17, atMs: 1800),
      ];
      const box = PlayerDetectionBox(
        left: 0.20,
        top: 0.30,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        jerseyNumber: 2,
      );
      final markers = minimapMarkersAt(
        samples: samples,
        atMs: 0,
        detections: const [box],
        pitch: kFullFramePitchRegion,
      );
      final fromBox = minimapPointFromBox(box, pitch: kFullFramePitchRegion);
      expect(markers.single.x, closeTo(fromBox.x, 0.0001));
    });
  });

  group('pathDistanceMeters', () {
    test('sums consecutive steps and ignores teleport jumps', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'a', x: 0, y: 0, atMs: 0),
        PlayerDistanceSample(playerId: 'a', x: 10, y: 0, atMs: 1000),
        PlayerDistanceSample(playerId: 'a', x: 90, y: 0, atMs: 1100),
        PlayerDistanceSample(playerId: 'a', x: 14, y: 0, atMs: 2000),
      ];
      expect(pathDistanceMeters(samples), closeTo(14, 0.01));
    });

    test('ignores sub-40cm jitter around the same point', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 0),
        PlayerDistanceSample(playerId: 'a', x: 10.12, y: 10.08, atMs: 200),
        PlayerDistanceSample(playerId: 'a', x: 9.85, y: 10.1, atMs: 400),
        PlayerDistanceSample(playerId: 'a', x: 10.2, y: 9.9, atMs: 600),
        PlayerDistanceSample(playerId: 'a', x: 10.05, y: 10.15, atMs: 800),
      ];
      expect(pathDistanceMeters(samples), closeTo(0, 0.01));
    });

    test('the same sample sequence always yields the same distance', () {
      const samples = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'a', x: 0, y: 0, atMs: 0),
        PlayerDistanceSample(playerId: 'a', x: 4, y: 0, atMs: 400),
        PlayerDistanceSample(playerId: 'a', x: 8, y: 1, atMs: 800),
        PlayerDistanceSample(playerId: 'a', x: 12, y: 1, atMs: 1200),
        PlayerDistanceSample(playerId: 'a', x: 16, y: 2, atMs: 1600),
      ];
      expect(pathDistanceMeters(samples), pathDistanceMeters(samples));
      expect(pathDistanceMeters(samples), greaterThan(10));
    });

    test('resamples to at most one point per 200ms before summing', () {
      const dense = <PlayerDistanceSample>[
        PlayerDistanceSample(playerId: 'a', x: 0, y: 0, atMs: 0),
        PlayerDistanceSample(playerId: 'a', x: 0.2, y: 0, atMs: 80),
        PlayerDistanceSample(playerId: 'a', x: 2, y: 0, atMs: 200),
        PlayerDistanceSample(playerId: 'a', x: 2.1, y: 0, atMs: 260),
        PlayerDistanceSample(playerId: 'a', x: 4, y: 0, atMs: 400),
      ];
      final kept = resamplePlayerSamples(dense);
      expect(kept.map((sample) => sample.atMs), [0, 200, 400]);
      expect(pathDistanceMeters(dense), closeTo(4, 0.01));
    });
  });

  group('mergeAnalysisSamples', () {
    test('replaces a sample within 150ms instead of appending', () {
      final samples = <PlayerDistanceSample>[
        const PlayerDistanceSample(playerId: 'a', x: 10, y: 4, atMs: 0),
      ];
      mergeAnalysisSamples(samples, const [
        PlayerDistanceSample(playerId: 'a', x: 11, y: 4, atMs: 80),
      ]);
      expect(samples, hasLength(1));
      expect(samples.single.x, 11);
      expect(samples.single.atMs, 80);
      mergeAnalysisSamples(samples, const [
        PlayerDistanceSample(playerId: 'a', x: 16, y: 4, atMs: 280),
      ]);
      expect(samples, hasLength(2));
      expect(samples.last.x, 16);
    });
  });

  group('shouldRecordAnalysisSamples', () {
    test('records the first paused point then only while playing', () {
      expect(
        shouldRecordAnalysisSamples(
          analyzing: true,
          isPlaying: false,
          hasExistingSamples: false,
        ),
        isTrue,
      );
      expect(
        shouldRecordAnalysisSamples(
          analyzing: true,
          isPlaying: false,
          hasExistingSamples: true,
        ),
        isFalse,
      );
      expect(
        shouldRecordAnalysisSamples(
          analyzing: true,
          isPlaying: true,
          hasExistingSamples: true,
        ),
        isTrue,
      );
      expect(
        shouldRecordAnalysisSamples(
          analyzing: false,
          isPlaying: true,
          hasExistingSamples: false,
        ),
        isFalse,
      );
    });
  });

  group('summarizePlayerDistances', () {
    test('keeps roster names and sorts by distance', () {
      const roster = <DebugVideoRosterPlayer>[
        DebugVideoRosterPlayer(
          teamId: 't1',
          playerId: 'p1',
          displayName: 'Ada',
          isSubstitute: false,
          number: 10,
        ),
        DebugVideoRosterPlayer(
          teamId: 't1',
          playerId: 'p2',
          displayName: 'Bea',
          isSubstitute: false,
          number: 7,
        ),
      ];
      final results = summarizePlayerDistances(
        samples: const <PlayerDistanceSample>[
          PlayerDistanceSample(playerId: 'p1', x: 0, y: 0, atMs: 0),
          PlayerDistanceSample(playerId: 'p1', x: 8, y: 0, atMs: 1000),
          PlayerDistanceSample(playerId: 'p2', x: 0, y: 0, atMs: 0),
          PlayerDistanceSample(playerId: 'p2', x: 3, y: 0, atMs: 1000),
        ],
        roster: roster,
      );
      expect(results, hasLength(2));
      expect(results.first.playerId, 'p1');
      expect(results.first.displayName, 'Ada');
      expect(results.first.meters, closeTo(8, 0.01));
      expect(results.last.meters, closeTo(3, 0.01));
    });
  });

  test('moving associated boxes yield a non-zero distance on the full frame', () {
    const start = PlayerDetectionBox(
      left: 0.20,
      top: 0.40,
      width: 0.08,
      height: 0.20,
      playerId: 'p1',
      jerseyNumber: 2,
    );
    const moved = PlayerDetectionBox(
      left: 0.40,
      top: 0.42,
      width: 0.08,
      height: 0.20,
      playerId: 'p1',
      jerseyNumber: 2,
    );
    final samples = [
      ...samplesFromBoxes(boxes: const [start], atMs: 0, pitch: kFullFramePitchRegion),
      ...samplesFromBoxes(boxes: const [moved], atMs: 2000, pitch: kFullFramePitchRegion),
    ];
    expect(samples, hasLength(2));
    expect(pathDistanceMeters(samples), greaterThan(5));
    expect(
      minimapPointFromBox(moved, pitch: kFullFramePitchRegion).x,
      isNot(closeTo(minimapPointFromBox(start, pitch: kFullFramePitchRegion).x, 0.05)),
    );
  });

  test('sampleAssociatedPlayer ignores unlabeled boxes', () {
    const box = PlayerDetectionBox(
      left: 0.4,
      top: 0.4,
      width: 0.1,
      height: 0.2,
    );
    expect(sampleAssociatedPlayer(box: box, atMs: 0), isNull);
  });

  test('frozen pitch keeps associated samples from drifting', () {
    const frozen = PitchRegion(top: 0.25, bottom: 0.85, left: 0.08, right: 0.92);
    const flickered = PitchRegion(top: 0.05, bottom: 0.98, left: 0.0, right: 1.0);
    const box = PlayerDetectionBox(
      left: 0.20,
      top: 0.40,
      width: 0.08,
      height: 0.20,
      playerId: 'p1',
      jerseyNumber: 2,
    );
    final first = sampleAssociatedPlayer(box: box, atMs: 0, pitch: frozen)!;
    final same = sampleAssociatedPlayer(box: box, atMs: 1000, pitch: frozen)!;
    expect(pathDistanceMeters([first, same]), closeTo(0, 0.01));
    final drifted = sampleAssociatedPlayer(box: box, atMs: 1000, pitch: flickered)!;
    expect(pathDistanceMeters([first, drifted]), greaterThan(1));
  });

  test('sampleBall ignores person boxes', () {
    const box = PlayerDetectionBox(
      left: 0.4,
      top: 0.4,
      width: 0.1,
      height: 0.2,
    );
    expect(sampleBall(box: box, atMs: 0), isNull);
  });

  group('detectPlayerBallStats', () {
    const roster = <DebugVideoRosterPlayer>[
      DebugVideoRosterPlayer(
        teamId: 't1',
        playerId: 'a',
        displayName: 'Ada',
        isSubstitute: false,
        number: 10,
      ),
      DebugVideoRosterPlayer(
        teamId: 't1',
        playerId: 'b',
        displayName: 'Bea',
        isSubstitute: false,
        number: 7,
      ),
      DebugVideoRosterPlayer(
        teamId: 't2',
        playerId: 'c',
        displayName: 'Cam',
        isSubstitute: false,
        number: 9,
      ),
    ];

    test('counts a completed pass between teammates', () {
      final stats = detectPlayerBallStats(
        players: const [
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 0),
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 200),
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 500),
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 800),
          PlayerDistanceSample(playerId: 'b', x: 20, y: 10, atMs: 0),
          PlayerDistanceSample(playerId: 'b', x: 20, y: 10, atMs: 200),
          PlayerDistanceSample(playerId: 'b', x: 20, y: 10, atMs: 500),
          PlayerDistanceSample(playerId: 'b', x: 20, y: 10, atMs: 800),
        ],
        balls: const [
          BallSample(x: 10, y: 10, atMs: 0),
          BallSample(x: 10, y: 10, atMs: 200),
          BallSample(x: 15, y: 10, atMs: 500),
          BallSample(x: 20, y: 10, atMs: 800),
        ],
        roster: roster,
      );
      expect(stats['a']?.played, 1);
      expect(stats['a']?.passes, 1);
      expect(stats['a']?.given, 1);
      expect(stats['b']?.played, 1);
      expect(stats['b']?.received, 1);
      expect(stats['a']?.shots, 0);
    });

    test('counts a shot toward the goal when nobody receives', () {
      final stats = detectPlayerBallStats(
        players: const [
          PlayerDistanceSample(playerId: 'a', x: 90, y: 34, atMs: 0),
          PlayerDistanceSample(playerId: 'a', x: 90, y: 34, atMs: 200),
          PlayerDistanceSample(playerId: 'a', x: 90, y: 34, atMs: 500),
          PlayerDistanceSample(playerId: 'a', x: 90, y: 34, atMs: 900),
        ],
        balls: const [
          BallSample(x: 90, y: 34, atMs: 0),
          BallSample(x: 90, y: 34, atMs: 200),
          BallSample(x: 96, y: 34, atMs: 500),
          BallSample(x: 104, y: 34, atMs: 900),
        ],
        roster: roster,
      );
      expect(stats['a']?.played, 1);
      expect(stats['a']?.shots, 1);
      expect(stats['a']?.passes, 0);
    });

    test('does not count a pass when the opponent takes the ball', () {
      final stats = detectPlayerBallStats(
        players: const [
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 0),
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 200),
          PlayerDistanceSample(playerId: 'a', x: 10, y: 10, atMs: 600),
          PlayerDistanceSample(playerId: 'c', x: 18, y: 10, atMs: 0),
          PlayerDistanceSample(playerId: 'c', x: 18, y: 10, atMs: 200),
          PlayerDistanceSample(playerId: 'c', x: 18, y: 10, atMs: 600),
        ],
        balls: const [
          BallSample(x: 10, y: 10, atMs: 0),
          BallSample(x: 10, y: 10, atMs: 200),
          BallSample(x: 18, y: 10, atMs: 600),
        ],
        roster: roster,
      );
      expect(stats['a']?.played, 1);
      expect(stats['a']?.passes, 0);
      expect(stats['a']?.given, 0);
      expect(stats['c']?.played, 1);
      expect(stats['c']?.received, 0);
    });
  });

  group('DebugVideoTag', () {
    test('keeps the timestamp and optional type/text for later', () {
      const tag = DebugVideoTag(
        id: 'tag_1',
        atMs: 90500,
        type: null,
        text: null,
      );
      expect(tag.atMs, 90500);
      expect(tag.type, isNull);
      expect(tag.text, isNull);
    });
  });

  group('shouldFinishDebugVideoAnalysisOnPause', () {
    test('does not finish a mid-video pause', () {
      expect(
        shouldFinishDebugVideoAnalysisOnPause(
          analyzing: true,
          isPlaying: false,
          isInitialized: true,
          duration: const Duration(minutes: 2),
          position: const Duration(seconds: 40),
        ),
        isFalse,
      );
    });

    test('finishes only when paused near the end', () {
      expect(
        shouldFinishDebugVideoAnalysisOnPause(
          analyzing: true,
          isPlaying: false,
          isInitialized: true,
          duration: const Duration(minutes: 2),
          position: const Duration(minutes: 2) - const Duration(milliseconds: 100),
        ),
        isTrue,
      );
    });

    test('does not finish while framing a player near the end', () {
      expect(
        shouldFinishDebugVideoAnalysisOnPause(
          analyzing: true,
          isPlaying: false,
          isInitialized: true,
          duration: const Duration(minutes: 2),
          position: const Duration(minutes: 2),
          framingPlayer: true,
        ),
        isFalse,
      );
    });
  });

  test('heatmap pitch inset keeps a 105x68 field rect for player dots', () {
    final field = debugVideoMinimapFieldRect(const Size(208, 208 / (105 / 68)));
    expect(field.width, greaterThan(150));
    expect(field.height, greaterThan(90));
    expect(field.width / field.height, closeTo(105 / 68, 0.2));
  });

  group('debug video pause actions', () {
    test('allows framing and tagging while paused, including during analysis', () {
      expect(
        canDebugVideoFramePlayer(
          videoReady: true,
          uploading: false,
          capturingStill: false,
          isPlaying: false,
        ),
        isTrue,
      );
      expect(
        canPlaceDebugVideoTag(
          videoReady: true,
          isPlaying: false,
          capturingStill: false,
        ),
        isTrue,
      );
      expect(
        canDebugVideoFramePlayer(
          videoReady: true,
          uploading: false,
          capturingStill: false,
          isPlaying: true,
        ),
        isFalse,
      );
      expect(
        canPlaceDebugVideoTag(
          videoReady: true,
          isPlaying: true,
          capturingStill: false,
        ),
        isFalse,
      );
    });

    test('clears samples only when starting a new analysis', () {
      expect(
        shouldClearDebugVideoAnalysisSamples(alreadyAnalyzing: false),
        isTrue,
      );
      expect(
        shouldClearDebugVideoAnalysisSamples(alreadyAnalyzing: true),
        isFalse,
      );
    });
  });
}
