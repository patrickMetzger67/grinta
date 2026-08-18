import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/match_creation_helper.dart';

class DebugVideoMatchService {
  DebugVideoMatchService({
    MatchService? matchService,
    MatchCompoService? matchCompoService,
  })  : _matchService = matchService ?? MatchService(),
        _matchCompoService = matchCompoService ?? MatchCompoService();

  final MatchService _matchService;
  final MatchCompoService _matchCompoService;

  Future<List<Match>> matchesForManagedTeamsOnDay({
    required AppSession session,
    required DateTime day,
  }) async {
    final teams = session.managerTeamsForSelectedSeason;
    if (teams.isEmpty) return const <Match>[];

    final seasonId = session.selectedSeason?.ref?.id;
    final start = Timestamp.fromDate(debugVideoDayStart(day));
    final end = Timestamp.fromDate(debugVideoDayEnd(day));
    final byId = <String, Match>{};

    await Future.wait(
      teams.map((team) async {
        final teamId = team.keyTeam?.trim() ?? '';
        if (teamId.isEmpty) return;
        final matches =
            await _matchService.getMatchesForTeamEngagementsBetweenDates(
          teamId: teamId,
          clubId: team.clubId ?? '',
          seasonId: seasonId,
          start: start,
          end: end,
        );
        for (final match in matches) {
          if (!canManageMatch(match, session)) continue;
          if (!matchOccursOnDebugVideoDay(match, day)) continue;
          final id = match.id?.trim();
          if (id == null || id.isEmpty) continue;
          byId[id] = match;
        }
      }),
    );

    final list = byId.values.toList();
    list.sort((a, b) {
      final time = (a.timeCh ?? '').compareTo(b.timeCh ?? '');
      if (time != 0) return time;
      return debugVideoMatchLabel(a).compareTo(debugVideoMatchLabel(b));
    });
    return list;
  }

  Future<List<MatchCompo>> composForMatch(String matchId) {
    final id = matchId.trim();
    if (id.isEmpty) return Future.value(const <MatchCompo>[]);
    return _matchCompoService.getMatchComposByMatchId(id);
  }
}
