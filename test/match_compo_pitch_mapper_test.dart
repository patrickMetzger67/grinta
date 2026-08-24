import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/compoType.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/widget/half_pitch_compo_widget.dart';

void main() {
  group('4-3-3 pitch slots', () {
    late CompoType fourThreeThree;

    setUp(() {
      fourThreeThree = CompoType(
        name: '4-3-3',
        defender: 4,
        midfielder: 3,
        midfielderDefensive: 0,
        midfielderAttacking: 0,
        stricker: 3,
        isDiamond: false,
        soccerType: 11,
      );
    });

    test('builds four defender slots with right-back as defender_4', () {
      final slots = buildCompoSlots(fourThreeThree);
      final defenders =
          slots.where((CompoSlot s) => s.role == 'defender').toList();

      expect(defenders.map((s) => s.id), [
        'defender_1',
        'defender_2',
        'defender_3',
        'defender_4',
      ]);
      expect(defenders.first.x, lessThan(defenders.last.x));
      expect(defenders.last.id, 'defender_4');
    });

    test('round-trips right-back (defender_4) through MatchCompo', () {
      final starters = <String, PlayerCompo>{
        'goalkeeper_1': PlayerCompo(playerID: 'gk', number: 1),
        'defender_1': PlayerCompo(playerID: 'lb', number: 3),
        'defender_2': PlayerCompo(playerID: 'lcb', number: 4),
        'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
        'defender_4': PlayerCompo(playerID: 'rb', number: 2),
        'midfielder_1': PlayerCompo(playerID: 'lm', number: 8),
        'midfielder_2': PlayerCompo(playerID: 'cm', number: 6),
        'midfielder_3': PlayerCompo(playerID: 'rm', number: 7),
        'striker_1': PlayerCompo(playerID: 'lw', number: 11),
        'striker_2': PlayerCompo(playerID: 'st', number: 9),
        'striker_3': PlayerCompo(playerID: 'rw', number: 10),
      };

      final compo = MatchCompo(matchID: 'm1', teamID: 't1');
      applyAssignmentsToMatchCompo(
        compo: compo,
        startersBySlotId: starters,
        substitutes: const <PlayerCompo>[],
      );

      expect(compo.defender, isNotNull);
      expect(compo.defender!.length, 4);
      expect(compo.defender![3].playerID, 'rb');
      expect(compo.defender![3].number, 2);

      final restored = startersFromMatchCompo(compo);
      expect(restored['defender_4']?.playerID, 'rb');
      expect(restored['defender_4']?.number, 2);
      expect(restored.length, 11);
    });

    test('preserves right-back when a centre-back slot is empty', () {
      final starters = <String, PlayerCompo>{
        'defender_1': PlayerCompo(playerID: 'lb', number: 3),
        'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
        'defender_4': PlayerCompo(playerID: 'rb', number: 2),
      };

      final compo = MatchCompo(matchID: 'm1', teamID: 't1');
      applyAssignmentsToMatchCompo(
        compo: compo,
        startersBySlotId: starters,
        substitutes: const <PlayerCompo>[],
      );

      expect(compo.defender!.length, 4);
      expect(compo.defender![0].playerID, 'lb');
      expect(compo.defender![1].playerID, isNull);
      expect(compo.defender![2].playerID, 'rcb');
      expect(compo.defender![3].playerID, 'rb');

      final restored = startersFromMatchCompo(compo);
      expect(restored.containsKey('defender_2'), isFalse);
      expect(restored['defender_4']?.playerID, 'rb');
    });

    test('toMap keeps four defenders including right-back', () {
      final starters = <String, PlayerCompo>{
        'defender_1': PlayerCompo(playerID: 'lb', number: 3),
        'defender_2': PlayerCompo(playerID: 'lcb', number: 4),
        'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
        'defender_4': PlayerCompo(playerID: 'rb', number: 2),
      };

      final compo = MatchCompo(matchID: 'm1', teamID: 't1');
      applyAssignmentsToMatchCompo(
        compo: compo,
        startersBySlotId: starters,
        substitutes: const <PlayerCompo>[],
      );

      final map = compo.toMap();
      final defenders = map[keyMatchCompoDefender] as List<dynamic>;
      expect(defenders.length, 4);
      expect(
        (defenders[3] as Map)[keyPlayerCompoPlayerId],
        'rb',
      );
    });

    test('lineupToMap omits convocations so tabs cannot cross-wipe', () {
      final savedLineup = MatchCompo(matchID: 'm1', teamID: 't1');
      applyAssignmentsToMatchCompo(
        compo: savedLineup,
        startersBySlotId: <String, PlayerCompo>{
          'defender_1': PlayerCompo(playerID: 'lb', number: 3),
          'defender_2': PlayerCompo(playerID: 'lcb', number: 4),
          'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
          'defender_4': PlayerCompo(playerID: 'rb', number: 2),
        },
        substitutes: const <PlayerCompo>[],
      );
      savedLineup.convocation = [
        PlayerConvo(playerID: 'rb', isPresent: true, asAnswer: true),
      ];

      final lineupPayload = savedLineup.lineupToMap();
      expect(lineupPayload.containsKey(keyMatchCompoConvocation), isFalse);
      expect(
        ((lineupPayload[keyMatchCompoDefender] as List)[3]
            as Map)[keyPlayerCompoPlayerId],
        'rb',
      );

      final fullPayload = savedLineup.toMap();
      expect(fullPayload.containsKey(keyMatchCompoConvocation), isTrue);
    });

    test(
      'stale convocations draft full toMap would wipe right-back; '
      'convocations-only payload does not',
      () {
        final remoteWithRightBack = MatchCompo(matchID: 'm1', teamID: 't1');
        applyAssignmentsToMatchCompo(
          compo: remoteWithRightBack,
          startersBySlotId: <String, PlayerCompo>{
            'defender_1': PlayerCompo(playerID: 'lb', number: 3),
            'defender_2': PlayerCompo(playerID: 'lcb', number: 4),
            'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
            'defender_4': PlayerCompo(playerID: 'rb', number: 2),
          },
          substitutes: const <PlayerCompo>[],
        );

        // Keep-alive convocations tab still holding a draft without RB.
        final staleConvocationsDraft = MatchCompo(matchID: 'm1', teamID: 't1');
        applyAssignmentsToMatchCompo(
          compo: staleConvocationsDraft,
          startersBySlotId: <String, PlayerCompo>{
            'defender_1': PlayerCompo(playerID: 'lb', number: 3),
            'defender_2': PlayerCompo(playerID: 'lcb', number: 4),
            'defender_3': PlayerCompo(playerID: 'rcb', number: 5),
          },
          substitutes: const <PlayerCompo>[],
        );
        staleConvocationsDraft.convocation = [
          PlayerConvo(playerID: 'lb', isPresent: true, asAnswer: false),
          PlayerConvo(playerID: 'rb', isPresent: true, asAnswer: false),
        ];

        final dangerousFullMerge = staleConvocationsDraft.toMap();
        expect(
          (dangerousFullMerge[keyMatchCompoDefender] as List).length,
          3,
          reason: 'documents why full toMap() from a stale draft drops RB',
        );

        final convocationsOnly = <String, dynamic>{
          keyMatchCompoMatchId: 'm1',
          keyMatchCompoTeamID: 't1',
          keyMatchCompoConvocation: staleConvocationsDraft.convocation!
              .map((PlayerConvo c) => c.toMap())
              .toList(),
        };
        expect(convocationsOnly.containsKey(keyMatchCompoDefender), isFalse);

        // After a convocations-only write, remote lineup must still round-trip.
        final stillPresent = startersFromMatchCompo(remoteWithRightBack);
        expect(stillPresent['defender_4']?.playerID, 'rb');
      },
    );

    test(
      'stale tactical draft full toMap would wipe convocations; '
      'lineupToMap does not',
      () {
        final remoteWithAnswers = MatchCompo(matchID: 'm1', teamID: 't1');
        applyAssignmentsToMatchCompo(
          compo: remoteWithAnswers,
          startersBySlotId: <String, PlayerCompo>{
            'defender_4': PlayerCompo(playerID: 'rb', number: 2),
          },
          substitutes: const <PlayerCompo>[],
        );
        remoteWithAnswers.convocation = [
          PlayerConvo(playerID: 'rb', isPresent: true, asAnswer: true),
        ];

        final staleTacticalDraft = MatchCompo(matchID: 'm1', teamID: 't1');
        applyAssignmentsToMatchCompo(
          compo: staleTacticalDraft,
          startersBySlotId: <String, PlayerCompo>{
            'defender_4': PlayerCompo(playerID: 'rb', number: 2),
          },
          substitutes: const <PlayerCompo>[],
        );
        // Draft never received the player's answer.
        staleTacticalDraft.convocation = [
          PlayerConvo(playerID: 'rb', isPresent: true, asAnswer: false),
        ];

        final dangerousFullMerge = staleTacticalDraft.toMap();
        expect(
          ((dangerousFullMerge[keyMatchCompoConvocation] as List).first
              as Map)[keyPlayerConvoAsAnswer],
          false,
        );

        final lineupOnly = staleTacticalDraft.lineupToMap();
        expect(lineupOnly.containsKey(keyMatchCompoConvocation), isFalse);
        expect(
          ((lineupOnly[keyMatchCompoDefender] as List).last
              as Map)[keyPlayerCompoPlayerId],
          'rb',
        );
      },
    );
  });
}
