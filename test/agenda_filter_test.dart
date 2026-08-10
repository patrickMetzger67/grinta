import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/agenda_filter.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/training.dart';

void main() {
  group('AgendaFilter', () {
    test('normalize collapses full selection to inactive', () {
      final filter = AgendaFilter.normalize(
        selectedTeamIds: {'t1', 't2'},
        selectedTypes: AgendaItemType.values.toSet(),
        availableTeamIds: {'t1', 't2'},
        availableTypes: AgendaItemType.values.toSet(),
      );
      expect(filter.isActive, isFalse);
      expect(filter.teamIds, isEmpty);
      expect(filter.types, isEmpty);
    });

    test('fromJson round-trips', () {
      const original = AgendaFilter(
        teamIds: {'alpha', 'beta'},
        types: {AgendaItemType.match, AgendaItemType.entrainement},
      );
      final restored = AgendaFilter.fromJson(original.toJson());
      expect(restored.teamIds, original.teamIds);
      expect(restored.types, original.types);
      expect(restored.isActive, isTrue);
    });
  });

  group('applyAgendaFilter', () {
    Training training({required String teamId}) {
      return Training()..teamId = teamId;
    }

    AgendaItem matchItem(
      String teamId, {
      bool putInTeams = true,
      bool putInTeamId = false,
      List<String>? agendaTeamIds,
    }) {
      final match = grinta_match.Match();
      if (putInTeams) {
        match.teams = <dynamic>[teamId];
      } else {
        match.teams = <dynamic>[];
      }
      if (putInTeamId) {
        match.teamID = teamId;
      }
      return AgendaItem(
        id: 'm-$teamId-${putInTeams ? 'teams' : 'noteams'}',
        startAt: DateTime(2026, 1, 1),
        endAt: DateTime(2026, 1, 1, 1),
        title: 'Match',
        type: AgendaItemType.match,
        match: match,
        teamIds: agendaTeamIds ?? const <String>[],
      );
    }

    AgendaItem trainingItem(String teamId) {
      return AgendaItem(
        id: 't-$teamId',
        startAt: DateTime(2026, 1, 1),
        endAt: DateTime(2026, 1, 1, 1),
        title: 'Training',
        type: AgendaItemType.entrainement,
        training: training(teamId: teamId),
      );
    }

    AgendaItem personalItem({List<String> teamIds = const []}) {
      return AgendaItem(
        id: 'p1',
        startAt: DateTime(2026, 1, 1),
        endAt: DateTime(2026, 1, 1, 1),
        title: 'Run',
        type: AgendaItemType.preparationPhysique,
        personalSportActivity: PersonalSportActivity(
          memberId: 'm',
          createdByUserId: 'u',
          startAt: DateTime(2026, 1, 1),
          endAt: DateTime(2026, 1, 1, 1),
          typeId: 'run',
          visibility: PersonalSportVisibility.private,
          entryMode: PersonalSportEntryMode.manual,
          teamIds: teamIds,
        ),
      );
    }

    test('filters by type', () {
      final items = [
        matchItem('t1'),
        trainingItem('t1'),
        personalItem(),
      ];
      final filtered = applyAgendaFilter(
        items,
        const AgendaFilter(types: {AgendaItemType.match}),
      );
      expect(filtered.map((e) => e.id), ['m-t1-teams']);
    });

    test('filters by team and keeps unscoped personal items', () {
      final items = [
        matchItem('t1'),
        matchItem('t2'),
        trainingItem('t2'),
        personalItem(),
      ];
      final filtered = applyAgendaFilter(
        items,
        const AgendaFilter(teamIds: {'t1'}),
      );
      expect(filtered.map((e) => e.id).toSet(), {'m-t1-teams', 'p1'});
    });

    test('match with empty teams but teamID still filters by team', () {
      final items = [
        matchItem('t1', putInTeams: false, putInTeamId: true),
        matchItem('t2', putInTeams: false, putInTeamId: true),
      ];
      final filtered = applyAgendaFilter(
        items,
        const AgendaFilter(teamIds: {'t1'}),
      );
      expect(filtered.map((e) => e.id), ['m-t1-noteams']);
    });

    test('match agendaTeamIds from load context filters scraped calendars', () {
      final items = [
        matchItem('t1', putInTeams: false, agendaTeamIds: const ['t1']),
        matchItem('t2', putInTeams: false, agendaTeamIds: const ['t2']),
      ];
      final filtered = applyAgendaFilter(
        items,
        const AgendaFilter(teamIds: {'t1'}),
      );
      expect(filtered.map((e) => e.id), ['m-t1-noteams']);
    });

    test('combines team and type filters', () {
      final items = [
        matchItem('t1'),
        trainingItem('t1'),
        matchItem('t2'),
      ];
      final filtered = applyAgendaFilter(
        items,
        const AgendaFilter(
          teamIds: {'t1'},
          types: {AgendaItemType.entrainement},
        ),
      );
      expect(filtered.map((e) => e.id), ['t-t1']);
    });
  });

  group('agendaItemTeamIds', () {
    test('prefers AgendaItem.teamIds over empty match.teams', () {
      final item = AgendaItem(
        id: 'm1',
        startAt: DateTime(2026, 10, 17, 18, 30),
        endAt: DateTime(2026, 10, 17, 20),
        title: 'Séniors 1',
        type: AgendaItemType.match,
        match: grinta_match.Match()..teams = <dynamic>[],
        teamIds: const ['team-seniors-1'],
      );
      expect(agendaItemTeamIds(item), {'team-seniors-1'});
    });
  });
}
