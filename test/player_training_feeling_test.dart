import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player_feeling.dart';
import 'package:grinta/model/training.dart';

void main() {
  group('PlayerFeeling', () {
    test('maps 1–5 scale values', () {
      expect(PlayerFeeling.veryBad.value, 1);
      expect(PlayerFeeling.bad.value, 2);
      expect(PlayerFeeling.neutral.value, 3);
      expect(PlayerFeeling.good.value, 4);
      expect(PlayerFeeling.veryGood.value, 5);
    });

    test('fromValue returns matching enum or null', () {
      expect(PlayerFeeling.fromValue(3), PlayerFeeling.neutral);
      expect(PlayerFeeling.fromValue(0), isNull);
      expect(PlayerFeeling.fromValue(null), isNull);
      expect(PlayerFeeling.fromValue(6), isNull);
    });
  });

  group('PlayerTraining feeling fields', () {
    test('serializes feelingBefore and feelingAfter', () {
      final player = PlayerTraining(
        playerId: 'p1',
        presenceType: PresenceType.present,
      )
        ..feelingBefore = PlayerFeeling.neutral.value
        ..feelingAfter = PlayerFeeling.veryGood.value;

      final map = player.toMap();
      expect(map[keyPtFeelingBefore], 3);
      expect(map[keyPtFeelingAfter], 5);

      final restored = PlayerTraining.fromMap(map);
      expect(restored.feelingBefore, 3);
      expect(restored.feelingAfter, 5);
      expect(restored.feelingBeforeEnum, PlayerFeeling.neutral);
      expect(restored.feelingAfterEnum, PlayerFeeling.veryGood);
    });

    test('defaults missing feeling fields to 0', () {
      final restored = PlayerTraining.fromMap({
        keyPtPlayerId: 'p1',
        keyPtPresenceType: 'PresenceType.present',
      });
      expect(restored.feelingBefore, 0);
      expect(restored.feelingAfter, 0);
      expect(restored.feelingBeforeEnum, isNull);
      expect(restored.feelingAfterEnum, isNull);
    });
  });

  group('PlayerCompo feeling fields', () {
    test('serializes feelingBefore and feelingAfter', () {
      final player = PlayerCompo(
        playerID: 'p1',
        number: 10,
        playerNameDisplayed: 'Joueur',
      )
        ..feelingBefore = PlayerFeeling.bad.value
        ..feelingAfter = PlayerFeeling.good.value;

      final map = player.toMap();
      expect(map[keyPlayerCompoFeelingBefore], 2);
      expect(map[keyPlayerCompoFeelingAfter], 4);

      final restored = PlayerCompo.fromMap(map);
      expect(restored.feelingBefore, 2);
      expect(restored.feelingAfter, 4);
      expect(restored.feelingBeforeEnum, PlayerFeeling.bad);
      expect(restored.feelingAfterEnum, PlayerFeeling.good);
    });

    test('defaults missing feeling fields to 0', () {
      final restored = PlayerCompo.fromMap({
        keyPlayerCompoPlayerId: 'p1',
        keyPlayerCompoPlayerNumber: 7,
      });
      expect(restored.feelingBefore, 0);
      expect(restored.feelingAfter, 0);
      expect(restored.feelingBeforeEnum, isNull);
      expect(restored.feelingAfterEnum, isNull);
    });
  });
}
