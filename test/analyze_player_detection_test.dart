import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/analyze_player_detection.dart';

void main() {
  group('playerBoxFromPixelRect', () {
    test('normalizes a coco-style bbox', () {
      final box = playerBoxFromPixelRect(
        x: 50,
        y: 20,
        width: 100,
        height: 80,
        imageWidth: 200,
        imageHeight: 100,
        score: 0.9,
      );
      expect(box, isNotNull);
      expect(box!.left, 0.25);
      expect(box.top, 0.2);
      expect(box.width, 0.5);
      expect(box.height, 0.8);
      expect(box.score, 0.9);
    });

    test('rejects low-confidence detections', () {
      expect(
        playerBoxFromPixelRect(
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          imageWidth: 100,
          imageHeight: 100,
          score: 0.1,
        ),
        isNull,
      );
    });
  });

  group('playerBoxesFromCocoPredictions', () {
    test('keeps person and sports ball detections', () {
      final boxes = playerBoxesFromCocoPredictions(
        predictions: <dynamic>[
          <String, dynamic>{
            'class': 'person',
            'score': 0.8,
            'bbox': <num>[10, 10, 16, 40],
          },
          <String, dynamic>{
            'class': 'sports ball',
            'score': 0.99,
            'bbox': <num>[0, 0, 10, 10],
          },
          <String, dynamic>{
            'class': 'chair',
            'score': 0.99,
            'bbox': <num>[1, 1, 10, 10],
          },
        ],
        imageWidth: 100,
        imageHeight: 100,
      );
      expect(boxes, hasLength(2));
      expect(boxes.first.kind, PlayerDetectionKind.person);
      expect(boxes.first.width, 0.16);
      expect(boxes.first.height, 0.4);
      expect(boxes.last.kind, PlayerDetectionKind.ball);
    });

    test('keeps a jersey number from the prediction', () {
      final boxes = playerBoxesFromCocoPredictions(
        predictions: <dynamic>[
          <String, dynamic>{
            'class': 'person',
            'score': 0.8,
            'bbox': <num>[10, 10, 16, 40],
            'jerseyNumber': 10,
          },
        ],
        imageWidth: 100,
        imageHeight: 100,
      );
      expect(boxes, hasLength(1));
      expect(boxes.first.jerseyNumber, 10);
    });

    test('drops a pitch-sized person box', () {
      final boxes = playerBoxesFromCocoPredictions(
        predictions: <dynamic>[
          <String, dynamic>{
            'class': 'person',
            'score': 0.9,
            'bbox': <num>[10, 10, 180, 80],
          },
        ],
        imageWidth: 200,
        imageHeight: 100,
      );
      expect(boxes, isEmpty);
    });
  });

  group('detectPlayersFromKitColors', () {
    List<int> greenPitch(int width, int height) {
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var i = 0; i < width * height; i++) {
        final o = i * 4;
        rgba[o] = 40;
        rgba[o + 1] = 140;
        rgba[o + 2] = 50;
        rgba[o + 3] = 255;
      }
      return rgba;
    }

    void paintRect(
      List<int> rgba,
      int width, {
      required int left,
      required int top,
      required int right,
      required int bottom,
      required int r,
      required int g,
      required int b,
    }) {
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = r;
          rgba[o + 1] = g;
          rgba[o + 2] = b;
          rgba[o + 3] = 255;
        }
      }
    }

    test('finds a midfield blue kit and a foreground white kit', () {
      const width = 200;
      const height = 150;
      final rgba = greenPitch(width, height);
      // Blue player on the center line.
      paintRect(
        rgba,
        width,
        left: 96,
        top: 58,
        right: 104,
        bottom: 78,
        r: 30,
        g: 55,
        b: 150,
      );
      // White player in the lower-right foreground.
      paintRect(
        rgba,
        width,
        left: 150,
        top: 95,
        right: 168,
        bottom: 138,
        r: 230,
        g: 230,
        b: 228,
      );
      final boxes = detectPlayersFromKitColors(
        rgba: rgba,
        width: width,
        height: height,
      );
      expect(boxes.length, greaterThanOrEqualTo(2));
      expect(boxes.every((box) => box.kind == PlayerDetectionKind.person), isTrue);
      expect(
        boxes.any((box) {
          final cx = box.left + box.width / 2;
          final cy = box.top + box.height / 2;
          return cx > 0.42 && cx < 0.58 && cy > 0.35 && cy < 0.62;
        }),
        isTrue,
      );
      expect(
        boxes.any((box) {
          final cx = box.left + box.width / 2;
          final cy = box.top + box.height / 2;
          return cx > 0.70 && cy > 0.60;
        }),
        isTrue,
      );
    });

    test('ignores a thin white center line', () {
      const width = 200;
      const height = 150;
      final rgba = greenPitch(width, height);
      paintRect(
        rgba,
        width,
        left: 99,
        top: 20,
        right: 100,
        bottom: 140,
        r: 235,
        g: 235,
        b: 235,
      );
      expect(
        detectPlayersFromKitColors(rgba: rgba, width: width, height: height),
        isEmpty,
      );
    });
  });

  group('detectSoccerBallsFromRgba', () {
    test('finds a small white blob on a green pitch', () {
      const width = 200;
      const height = 150;
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var i = 0; i < width * height; i++) {
        final o = i * 4;
        rgba[o] = 40;
        rgba[o + 1] = 140;
        rgba[o + 2] = 50;
        rgba[o + 3] = 255;
      }
      for (var y = 70; y <= 77; y++) {
        for (var x = 96; x <= 103; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 230;
          rgba[o + 1] = 230;
          rgba[o + 2] = 230;
          rgba[o + 3] = 255;
        }
      }
      final boxes = detectSoccerBallsFromRgba(
        rgba: rgba,
        width: width,
        height: height,
      );
      expect(boxes, isNotEmpty);
      expect(boxes.first.kind, PlayerDetectionKind.ball);
    });
  });

  group('jersey numbers', () {
    test('parseJerseyNumber accepts 1-99 and digit strings', () {
      expect(parseJerseyNumber(10), 10);
      expect(parseJerseyNumber(10.4), 10);
      expect(parseJerseyNumber('#7'), 7);
      expect(parseJerseyNumber('10 Louis'), 10);
      expect(parseJerseyNumber(0), isNull);
      expect(parseJerseyNumber(100), isNull);
      expect(parseJerseyNumber(null), isNull);
      expect(parseJerseyNumber('abc'), isNull);
    });

    test('detectedJerseyNumbers keeps unique person numbers', () {
      const boxes = <PlayerDetectionBox>[
        PlayerDetectionBox(
          left: 0.1,
          top: 0.1,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
        ),
        PlayerDetectionBox(
          left: 0.3,
          top: 0.1,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
        ),
        PlayerDetectionBox(
          left: 0.5,
          top: 0.1,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 7,
        ),
        PlayerDetectionBox(
          left: 0.7,
          top: 0.1,
          width: 0.05,
          height: 0.05,
          kind: PlayerDetectionKind.ball,
          jerseyNumber: 1,
        ),
      ];
      expect(detectedJerseyNumbers(boxes), {10, 7});
    });

    test('isRosterJerseyDetected matches a sheet number', () {
      expect(isRosterJerseyDetected(10, {10, 7}), isTrue);
      expect(isRosterJerseyDetected(11, {10, 7}), isFalse);
      expect(isRosterJerseyDetected(null, {10}), isFalse);
    });

    test('isRosterPlayerAssociated matches a labeled sheet player', () {
      expect(isRosterPlayerAssociated('p1', {'p1', 'p2'}), isTrue);
      expect(isRosterPlayerAssociated('p3', {'p1'}), isFalse);
      expect(isRosterPlayerAssociated(null, {'p1'}), isFalse);
      expect(
        associatedPlayerIds(const [
          PlayerDetectionBox(
            left: 0.1,
            top: 0.1,
            width: 0.1,
            height: 0.2,
            playerId: 'p1',
          ),
          PlayerDetectionBox(left: 0.4, top: 0.4, width: 0.1, height: 0.2),
        ]),
        {'p1'},
      );
      expect(
        associatedDetectionBoxes(const [
          PlayerDetectionBox(
            left: 0.1,
            top: 0.1,
            width: 0.1,
            height: 0.2,
            playerId: 'p1',
          ),
          PlayerDetectionBox(left: 0.4, top: 0.4, width: 0.1, height: 0.2),
        ]),
        hasLength(1),
      );
      const overlayBoxes = <PlayerDetectionBox>[
        PlayerDetectionBox(
          left: 0.1,
          top: 0.1,
          width: 0.1,
          height: 0.2,
          playerId: 'p1',
          jerseyNumber: 2,
        ),
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          playerId: 'p2',
        ),
        PlayerDetectionBox(
          left: 0.5,
          top: 0.5,
          width: 0.04,
          height: 0.04,
          kind: PlayerDetectionKind.ball,
        ),
        PlayerDetectionBox(left: 0.4, top: 0.4, width: 0.1, height: 0.2),
      ];
      expect(
        overlayDetectionBoxes(overlayBoxes, showAssociatedPlayers: false),
        isEmpty,
      );
      final paused = overlayDetectionBoxes(
        overlayBoxes,
        showAssociatedPlayers: true,
      );
      expect(paused, hasLength(2));
      expect(paused.every((box) => box.playerId != null), isTrue);
      expect(paused.any((box) => box.kind == PlayerDetectionKind.ball), isFalse);
      final minimap = minimapDetectionBoxes(overlayBoxes);
      expect(minimap, hasLength(1));
      expect(minimap.single.jerseyNumber, 2);
      expect(minimap.single.playerId, 'p1');
    });

    test('carryJerseyNumbers copies a number onto an overlapping box', () {
      const previous = <PlayerDetectionBox>[
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 14,
        ),
      ];
      const current = <PlayerDetectionBox>[
        PlayerDetectionBox(
          left: 0.21,
          top: 0.21,
          width: 0.1,
          height: 0.2,
        ),
      ];
      final carried = carryJerseyNumbers(previous, current);
      expect(carried.single.jerseyNumber, 14);
    });
  });

  group('pitch filtering', () {
    List<int> standsOverPitch(int width, int height, {required int pitchTop}) {
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final o = (y * width + x) * 4;
          if (y < pitchTop) {
            rgba[o] = 90;
            rgba[o + 1] = 75;
            rgba[o + 2] = 70;
          } else {
            rgba[o] = 40;
            rgba[o + 1] = 140;
            rgba[o + 2] = 50;
          }
          rgba[o + 3] = 255;
        }
      }
      return rgba;
    }

    test('estimatePitchRegion finds the green band under the stands', () {
      const width = 80;
      const height = 100;
      final rgba = standsOverPitch(width, height, pitchTop: 30);
      final pitch = estimatePitchRegion(
        rgba: rgba,
        width: width,
        height: height,
      );
      expect(pitch, isNotNull);
      expect(pitch!.top, closeTo(0.30, 0.04));
      expect(pitch.bottom, greaterThan(0.9));
    });

    test('estimatePitchQuad fits a tapering grass trap, not the AABB', () {
      const width = 160;
      const height = 120;
      const farLeft = 0.28;
      const farRight = 0.72;
      const nearLeft = 0.08;
      const nearRight = 0.92;
      const top = 0.22;
      const bottom = 0.90;
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var y = 0; y < height; y++) {
        final ny = (y + 0.5) / height;
        final v = (ny - top) / (bottom - top);
        final left = v < 0 || v > 1
            ? -1.0
            : farLeft + (nearLeft - farLeft) * v;
        final right = v < 0 || v > 1
            ? -1.0
            : farRight + (nearRight - farRight) * v;
        for (var x = 0; x < width; x++) {
          final o = (y * width + x) * 4;
          final nx = (x + 0.5) / width;
          final onPitch = left >= 0 && nx >= left && nx <= right;
          rgba[o] = onPitch ? 40 : 90;
          rgba[o + 1] = onPitch ? 140 : 75;
          rgba[o + 2] = onPitch ? 50 : 70;
          rgba[o + 3] = 255;
        }
      }
      final quad = estimatePitchQuad(
        rgba: rgba,
        width: width,
        height: height,
      );
      expect(quad, isNotNull);
      expect(quad!.isUsable, isTrue);
      final farW = quad.farRight.x - quad.farLeft.x;
      final nearW = quad.nearRight.x - quad.nearLeft.x;
      expect(farW, lessThan(nearW - 0.08));
      expect(quad.farLeft.x, greaterThan(quad.nearLeft.x + 0.06));
      expect(quad.farRight.x, lessThan(quad.nearRight.x - 0.06));
      expect(quad.farLeft.x, isNot(closeTo(quad.bounds.left, 0.04)));
    });

    test('keepMatchSheetDetections drops stand people and keeps pitch players', () {
      const width = 80;
      const height = 100;
      final rgba = standsOverPitch(width, height, pitchTop: 30);
      final pitch = estimatePitchRegion(
        rgba: rgba,
        width: width,
        height: height,
      );
      const stand = PlayerDetectionBox(
        left: 0.40,
        top: 0.04,
        width: 0.05,
        height: 0.08,
        score: 0.9,
      );
      const player = PlayerDetectionBox(
        left: 0.46,
        top: 0.52,
        width: 0.05,
        height: 0.16,
        score: 0.9,
      );
      final kept = keepMatchSheetDetections(
        boxes: const [stand, player],
        pitch: pitch,
        rgba: rgba,
        sampleWidth: width,
        sampleHeight: height,
      );
      expect(kept, hasLength(1));
      expect(kept.single.top, player.top);
    });

    test('rejectCrowdBoxes removes a dense upper cluster', () {
      final crowd = List<PlayerDetectionBox>.generate(8, (index) {
        return PlayerDetectionBox(
          left: 0.20 + index * 0.04,
          top: 0.06,
          width: 0.03,
          height: 0.08,
          score: 0.8,
        );
      });
      const player = PlayerDetectionBox(
        left: 0.48,
        top: 0.55,
        width: 0.05,
        height: 0.16,
        score: 0.9,
      );
      final kept = rejectCrowdBoxes([...crowd, player]);
      expect(kept, hasLength(1));
      expect(kept.single.top, player.top);
    });

    test('fluorescent lime is not treated as pitch grass', () {
      expect(isFieldGreenPixel(40, 140, 50), isTrue);
      expect(isFieldGreenPixel(212, 255, 0), isFalse);
      expect(isFieldGreenPixel(160, 190, 50), isFalse);
      expect(isOfficialFluorescentPixel(160, 190, 50), isTrue);
    });

    test('keepMatchSheetDetections drops a referee in the defined kit', () {
      const width = 80;
      const height = 100;
      final rgba = standsOverPitch(width, height, pitchTop: 30);
      for (var y = 52; y <= 68; y++) {
        for (var x = 36; x <= 44; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 160;
          rgba[o + 1] = 190;
          rgba[o + 2] = 50;
          rgba[o + 3] = 255;
        }
      }
      final pitch = estimatePitchRegion(
        rgba: rgba,
        width: width,
        height: height,
      );
      const official = PlayerDetectionBox(
        left: 0.42,
        top: 0.48,
        width: 0.12,
        height: 0.24,
        score: 0.9,
      );
      const player = PlayerDetectionBox(
        left: 0.62,
        top: 0.52,
        width: 0.05,
        height: 0.16,
        score: 0.9,
      );
      final kept = keepMatchSheetDetections(
        boxes: const [official, player],
        pitch: pitch,
        rgba: rgba,
        sampleWidth: width,
        sampleHeight: height,
        refereeKitColor: 0xFFD4FF00,
      );
      expect(kept, hasLength(1));
      expect(kept.single.left, player.left);
    });

    test('looksLikeMatchOfficial uses the chosen referee kit color', () {
      const width = 40;
      const height = 40;
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 40;
          rgba[o + 1] = 140;
          rgba[o + 2] = 50;
          rgba[o + 3] = 255;
        }
      }
      for (var y = 8; y <= 22; y++) {
        for (var x = 14; x <= 24; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 220;
          rgba[o + 1] = 255;
          rgba[o + 2] = 20;
          rgba[o + 3] = 255;
        }
      }
      const official = PlayerDetectionBox(
        left: 0.30,
        top: 0.15,
        width: 0.30,
        height: 0.45,
        score: 0.9,
      );
      expect(
        looksLikeMatchOfficial(
          box: official,
          rgba: rgba,
          width: width,
          height: height,
          refereeKitColor: 0xFFD4FF00,
        ),
        isTrue,
      );
      expect(
        looksLikeMatchOfficial(
          box: official,
          rgba: rgba,
          width: width,
          height: height,
          refereeKitColor: 0xFF1E4DB7,
        ),
        isFalse,
      );
      for (var y = 8; y <= 22; y++) {
        for (var x = 14; x <= 24; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 160;
          rgba[o + 1] = 190;
          rgba[o + 2] = 50;
        }
      }
      expect(
        looksLikeMatchOfficial(
          box: official,
          rgba: rgba,
          width: width,
          height: height,
          refereeKitColor: 0xFFD4FF00,
        ),
        isTrue,
      );
    });

    test('playerBoxFromNormalizedDrag rejects a tiny drag', () {
      expect(
        playerBoxFromNormalizedDrag(x1: 0.50, y1: 0.50, x2: 0.502, y2: 0.505),
        isNull,
      );
    });

    test('moveManualPlayerFrame keeps the frame on screen', () {
      final moved = moveManualPlayerFrame(
        defaultManualPlayerFrame(),
        dx: -1,
        dy: -1,
      );
      expect(moved.left, 0);
      expect(moved.top, 0);
    });

    test('resizeManualPlayerFrame grows from the center', () {
      const box = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
      );
      final taller = resizeManualPlayerFrame(box, dHeight: 0.10);
      expect(taller.height, closeTo(0.30, 1e-9));
      expect(taller.top, closeTo(0.35, 1e-9));
      expect(taller.width, closeTo(0.10, 1e-9));
    });

    test('playerBoxFromNormalizedCircle stores a visual circle', () {
      final box = playerBoxFromNormalizedCircle(
        cx: 0.40,
        cy: 0.50,
        edgeX: 0.46,
        edgeY: 0.50,
        aspectRatio: 16 / 9,
      );
      expect(box, isNotNull);
      expect(box!.circular, isTrue);
      expect(box.left, closeTo(0.34, 1e-9));
      expect(box.width, closeTo(0.12, 1e-9));
      expect(box.height, closeTo(0.12 * (16 / 9), 1e-9));
    });

    test('suggestedTeamIdFromKitSample picks the matching kit', () {
      const width = 40;
      const height = 40;
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 30;
          rgba[o + 1] = 40;
          rgba[o + 2] = 180;
          rgba[o + 3] = 255;
        }
      }
      const box = PlayerDetectionBox(
        left: 0.2,
        top: 0.2,
        width: 0.4,
        height: 0.5,
      );
      expect(
        suggestedTeamIdFromKitSample(
          box: box,
          rgba: rgba,
          width: width,
          height: height,
          team1KitColor: 0xFF1E4DB7,
          team2KitColor: 0xFFFFFFFF,
          team1Id: 'home',
          team2Id: 'away',
        ),
        'home',
      );
    });

    test('suggestedTeamIdFromKitSample returns null when neither kit matches', () {
      const width = 20;
      const height = 20;
      final rgba = List<int>.filled(width * height * 4, 0);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final o = (y * width + x) * 4;
          rgba[o] = 40;
          rgba[o + 1] = 140;
          rgba[o + 2] = 50;
          rgba[o + 3] = 255;
        }
      }
      const box = PlayerDetectionBox(
        left: 0.1,
        top: 0.1,
        width: 0.5,
        height: 0.5,
      );
      expect(
        suggestedTeamIdFromKitSample(
          box: box,
          rgba: rgba,
          width: width,
          height: height,
          team1KitColor: 0xFF1E4DB7,
          team2KitColor: 0xFFC62828,
          team1Id: 'home',
          team2Id: 'away',
        ),
        isNull,
      );
    });

    test('persistAssociatedPlayers keeps the locked player on the next box', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 10,
      );
      const moved = PlayerDetectionBox(
        left: 0.42,
        top: 0.41,
        width: 0.10,
        height: 0.20,
        jerseyNumber: 99,
      );
      const other = PlayerDetectionBox(
        left: 0.10,
        top: 0.10,
        width: 0.08,
        height: 0.16,
      );
      final persisted = persistAssociatedPlayers(
        current: const [moved, other],
        tracks: const [AssociatedPlayerTrack(box: lock)],
      );
      expect(persisted.boxes, hasLength(2));
      final followed = persisted.boxes.firstWhere((box) => box.left == 0.42);
      expect(followed.playerId, 'p1');
      expect(followed.teamId, 'home');
      expect(followed.jerseyNumber, 10);
      expect(persisted.tracks.single.box.playerId, 'p1');
      expect(persisted.tracks.single.missed, 0);
    });

    test('persistAssociatedPlayers does not carry a lock onto the other kit', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 10,
      );
      const otherKit = PlayerDetectionBox(
        left: 0.41,
        top: 0.41,
        width: 0.10,
        height: 0.20,
        teamId: 'away',
        jerseyNumber: 10,
      );
      final persisted = persistAssociatedPlayers(
        current: const [otherKit],
        tracks: const [AssociatedPlayerTrack(box: lock)],
      );
      final moved = persisted.boxes.firstWhere((box) => box.left == 0.41);
      expect(moved.playerId, isNull);
      expect(moved.teamId, 'away');
    });

    test('persistAssociatedPlayers coasts a lock for a few missed frames', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
      );
      final persisted = persistAssociatedPlayers(
        current: const [
          PlayerDetectionBox(left: 0.8, top: 0.8, width: 0.05, height: 0.1),
        ],
        tracks: const [AssociatedPlayerTrack(box: lock, missed: 2)],
        maxMissed: 4,
      );
      expect(persisted.boxes.any((box) => box.playerId == 'p1'), isTrue);
      expect(persisted.tracks.single.missed, 3);
    });

    test('persistAssociatedPlayers follows a nearby walking teammate', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 2,
      );
      const neighbor = PlayerDetectionBox(
        left: 0.475,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        teamId: 'home',
      );
      expect(detectionBoxIou(lock, neighbor), lessThan(kAssociatedTrackMinIou));
      final persisted = persistAssociatedPlayers(
        current: const [neighbor],
        tracks: const [AssociatedPlayerTrack(box: lock)],
      );
      final followed = persisted.boxes.firstWhere((box) => box.left == 0.475);
      expect(followed.playerId, 'p1');
      expect(followed.jerseyNumber, 2);
      expect(persisted.tracks.single.box.left, 0.475);
      expect(persisted.tracks.single.missed, 0);
    });

    test('persistAssociatedPlayers follows a running stride without IoU', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 2,
      );
      const stride = PlayerDetectionBox(
        left: 0.56,
        top: 0.42,
        width: 0.10,
        height: 0.20,
      );
      expect(detectionBoxIou(lock, stride), lessThan(0.05));
      expect(
        detectionCenterDistance(lock, stride),
        lessThan(kAssociatedTrackMaxCenterDistance),
      );
      final persisted = persistAssociatedPlayers(
        current: const [stride],
        tracks: const [AssociatedPlayerTrack(box: lock)],
      );
      expect(
        persisted.boxes.firstWhere((box) => box.left == 0.56).playerId,
        'p1',
      );
      expect(persisted.tracks.single.missed, 0);
    });

    test('persistAssociatedPlayers ignores a far jump even with overlap room', () {
      const lock = PlayerDetectionBox(
        left: 0.20,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        jerseyNumber: 2,
      );
      const far = PlayerDetectionBox(
        left: 0.70,
        top: 0.40,
        width: 0.10,
        height: 0.20,
      );
      expect(
        detectionCenterDistance(lock, far),
        greaterThan(kAssociatedTrackMaxCenterDistance),
      );
      final persisted = persistAssociatedPlayers(
        current: const [far],
        tracks: const [AssociatedPlayerTrack(box: lock)],
      );
      expect(persisted.tracks.single.box.left, 0.20);
      expect(persisted.tracks.single.missed, 1);
    });

    test('persistAssociatedPlayers follows an unlabeled box during analysis', () {
      const lock = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 2,
      );
      const unlabeled = PlayerDetectionBox(
        left: 0.41,
        top: 0.41,
        width: 0.10,
        height: 0.20,
      );
      final persisted = persistAssociatedPlayers(
        current: const [unlabeled],
        tracks: const [AssociatedPlayerTrack(box: lock)],
        requireSameTeam: true,
      );
      expect(
        persisted.boxes.firstWhere((box) => box.left == 0.41).playerId,
        'p1',
      );
      expect(persisted.tracks.single.box.left, 0.41);
      expect(persisted.tracks.single.missed, 0);
    });

    test('mergeManualPlayerBoxes drops overlapping automatic boxes', () {
      const automatic = PlayerDetectionBox(
        left: 0.40,
        top: 0.40,
        width: 0.10,
        height: 0.20,
      );
      const other = PlayerDetectionBox(
        left: 0.10,
        top: 0.10,
        width: 0.08,
        height: 0.16,
      );
      const manual = PlayerDetectionBox(
        left: 0.41,
        top: 0.41,
        width: 0.10,
        height: 0.20,
        playerId: 'p1',
        teamId: 'home',
        jerseyNumber: 10,
      );
      final merged = mergeManualPlayerBoxes([automatic, other], [manual]);
      expect(merged, hasLength(2));
      expect(merged.any((box) => box.playerId == 'p1'), isTrue);
      expect(merged.any((box) => identical(box, other)), isTrue);
      expect(merged.any((box) => identical(box, automatic)), isFalse);
    });

    test('hasPlausiblePlayerScale rejects a huge midfield box', () {
      const huge = PlayerDetectionBox(
        left: 0.2,
        top: 0.30,
        width: 0.16,
        height: 0.50,
        score: 0.9,
      );
      expect(hasPlausiblePlayerScale(huge), isFalse);
      const player = PlayerDetectionBox(
        left: 0.46,
        top: 0.52,
        width: 0.05,
        height: 0.16,
        score: 0.9,
      );
      expect(hasPlausiblePlayerScale(player), isTrue);
    });
  });
}
