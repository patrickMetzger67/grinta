import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/team.dart' show Team, removeDiacritics;
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_typical_team_service.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

/// Agenda opponent entry used to resolve a name from the user message.
class AgendaOpponentCandidate {
  const AgendaOpponentCandidate({
    required this.team,
    required this.match,
    required this.opponentName,
    required this.opponent,
  });

  final Team team;
  final grinta_match.Match match;
  final String opponentName;
  final TeamStatsOpponent opponent;
}

/// Intent detection and typical-team context for Ask Diego.
class OpponentTypicalTeamChatContext {
  OpponentTypicalTeamChatContext({
    TeamTypicalTeamService? teamTypicalTeamService,
    TeamCompetitionStatsService? teamCompetitionStatsService,
    TeamsPerClubService? teamsPerClubService,
  })  : _teamTypicalTeamService =
            teamTypicalTeamService ?? TeamTypicalTeamService(),
        _teamCompetitionStatsService =
            teamCompetitionStatsService ?? TeamCompetitionStatsService(),
        _teamsPerClubService = teamsPerClubService ?? TeamsPerClubService();

  final TeamTypicalTeamService _teamTypicalTeamService;
  final TeamCompetitionStatsService _teamCompetitionStatsService;
  final TeamsPerClubService _teamsPerClubService;

  static const Duration _computeTimeout = Duration(seconds: 20);

  static final RegExp _intentPattern = RegExp(
    r"équipe\s+type|composition\s+(?:de\s+l['\u2019]?)?(?:adversaire|équipe)|"
    r'line\s?-?up|titulaires?\s+(?:habituels?|probables?)|'
    r'onze\s+type|composition\s+probable|équipe\s+probable|'
    r'typical\s+(?:line\s?-?up|team)|starting\s+(?:eleven|xi)',
    caseSensitive: false,
  );

  static final RegExp _namedOpponentPattern = RegExp(
    r"(?:équipe\s+type|composition|line\s?-?up|titulaires?\s+(?:habituels?|probables?)|onze\s+type)\s+(?:de\s+|d['\u2019]|du\s+|des\s+)?(.+?)\s*$",
    caseSensitive: false,
  );

  /// Whether [message] asks for an opponent typical lineup.
  static bool detectsTypicalTeamIntent(String? message) {
    final normalized = message?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }
    return _intentPattern.hasMatch(normalized);
  }

  static String normalizeOpponentSearchText(String value) {
    final lowered = removeDiacritics(value.trim().toLowerCase());
    return lowered.replaceAll(RegExp(r"[^a-z0-9\s'-]"), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Collects opponents seen in [items] for the user's [teams].
  static List<AgendaOpponentCandidate> collectAgendaOpponents({
    required List<Team> teams,
    required List<AgendaItem> items,
    required Map<String, String> teamNames,
  }) {
    final teamById = <String, Team>{
      for (final Team team in teams)
        if (team.keyTeam != null) team.keyTeam!: team,
    };
    final seenKeys = <String>{};
    final candidates = <AgendaOpponentCandidate>[];

    for (final AgendaItem item in items) {
      if (item.type != AgendaItemType.match) continue;
      final match = item.match;
      if (match == null) continue;

      final teamId = match.teamID?.trim() ?? '';
      final team = teamById[teamId];
      if (team == null) continue;

      final teamName = teamNames[teamId];
      final opponentName = _opponentNameForMatch(match, teamId, teamName);
      if (opponentName == null || opponentName.isEmpty) continue;

      final opponent = opponentForMatch(
        match: match,
        teamId: teamId,
        clubId: team.clubId,
      );
      if (opponent == null) continue;

      final dedupeKey = '$teamId|${opponent.key}';
      if (seenKeys.contains(dedupeKey)) continue;
      seenKeys.add(dedupeKey);

      candidates.add(
        AgendaOpponentCandidate(
          team: team,
          match: match,
          opponentName: opponentName,
          opponent: opponent,
        ),
      );
    }

    candidates.sort(
      (AgendaOpponentCandidate a, AgendaOpponentCandidate b) =>
          a.opponentName.toLowerCase().compareTo(b.opponentName.toLowerCase()),
    );
    return candidates;
  }

  /// Best agenda opponent whose name appears in [message], if any.
  static AgendaOpponentCandidate? findOpponentMentionInMessage({
    required String message,
    required List<AgendaOpponentCandidate> candidates,
  }) {
    final normalizedMessage = normalizeOpponentSearchText(message);
    if (normalizedMessage.isEmpty || candidates.isEmpty) {
      return null;
    }

    AgendaOpponentCandidate? best;
    var bestScore = 0;

    for (final AgendaOpponentCandidate candidate in candidates) {
      final normalizedName = normalizeOpponentSearchText(candidate.opponentName);
      if (normalizedName.isEmpty) continue;

      var score = 0;
      if (normalizedMessage == normalizedName) {
        score = 100 + normalizedName.length;
      } else if (normalizedMessage.contains(normalizedName)) {
        score = 80 + normalizedName.length;
      } else {
        final tokens = normalizedName.split(' ').where((token) => token.length >= 4);
        for (final token in tokens) {
          if (normalizedMessage.contains(token)) {
            score = 50 + token.length;
            break;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return bestScore >= 50 ? best : null;
  }

  static String? extractNamedOpponentQuery(String message) {
    final match = _namedOpponentPattern.firstMatch(message.trim());
    if (match == null) {
      return null;
    }
    final query = match.group(1)?.trim() ?? '';
    if (query.isEmpty) {
      return null;
    }
    return query.replaceAll(RegExp(r'[?.!]+$'), '').trim();
  }

  /// Resolves opponent from [message], agenda candidates, or [nextMatchContext].
  static AgendaOpponentCandidate? resolveTargetOpponent({
    required String? userMessage,
    required List<AgendaOpponentCandidate> agendaOpponents,
    required Map<String, dynamic>? nextMatchContext,
    required List<Team> teams,
    required Map<String, String> teamNames,
  }) {
    final message = userMessage?.trim() ?? '';
    final hasIntent = detectsTypicalTeamIntent(message);

    if (message.isNotEmpty) {
      final mentioned = findOpponentMentionInMessage(
        message: message,
        candidates: agendaOpponents,
      );
      if (mentioned != null) {
        return mentioned;
      }

      final namedQuery = extractNamedOpponentQuery(message);
      if (namedQuery != null && namedQuery.isNotEmpty) {
        final fromQuery = findOpponentMentionInMessage(
          message: namedQuery,
          candidates: agendaOpponents,
        );
        if (fromQuery != null) {
          return fromQuery;
        }
      }
    }

    if (hasIntent || message.isEmpty) {
      return _candidateFromNextMatch(
        nextMatchContext: nextMatchContext,
        teams: teams,
        teamNames: teamNames,
      );
    }

    return null;
  }

  static AgendaOpponentCandidate? _candidateFromNextMatch({
    required Map<String, dynamic>? nextMatchContext,
    required List<Team> teams,
    required Map<String, String> teamNames,
  }) {
    if (nextMatchContext == null) {
      return null;
    }

    final matchId = (nextMatchContext['matchId'] ?? '').toString().trim();
    final teamId = (nextMatchContext['teamId'] ?? '').toString().trim();
    if (teamId.isEmpty) {
      return null;
    }

    Team? team;
    for (final Team candidate in teams) {
      if (candidate.keyTeam == teamId) {
        team = candidate;
        break;
      }
    }
    team ??= teams.isNotEmpty ? teams.first : null;
    if (team == null) {
      return null;
    }

    final opponentName = (nextMatchContext['opponentName'] ??
            nextMatchContext['opponent'] ??
            '')
        .toString()
        .trim();
    if (opponentName.isEmpty) {
      return null;
    }

    final opponentKey = (nextMatchContext['opponentKey'] ?? '').toString().trim();
    final opponent = TeamStatsOpponent(
      key: opponentKey.isNotEmpty
          ? opponentKey
          : opponentStableKey(displayName: opponentName),
      displayName: opponentName,
      affiliation: (nextMatchContext['opponentAffiliation'] ?? '').toString().trim().isEmpty
          ? null
          : (nextMatchContext['opponentAffiliation'] ?? '').toString().trim(),
      clubId: (nextMatchContext['opponentClubId'] ?? '').toString().trim().isEmpty
          ? null
          : (nextMatchContext['opponentClubId'] ?? '').toString().trim(),
    );

    return AgendaOpponentCandidate(
      team: team,
      match: grinta_match.Match(id: matchId.isEmpty ? null : matchId, teamID: teamId),
      opponentName: opponentName,
      opponent: opponent,
    );
  }

  Future<Map<String, dynamic>?> buildContext({
    required AppSession session,
    required List<Team> teams,
    required String? seasonId,
    required List<AgendaItem> seasonItems,
    required Map<String, String> teamNames,
    Map<String, dynamic>? nextMatchContext,
    String? userMessage,
    bool preloadNextMatchOpponent = false,
  }) async {
    if (teams.isEmpty || seasonId == null || seasonId.trim().isEmpty) {
      return null;
    }

    await UserTrialService.instance.ensureInitialized();
    final managedTeamIds = session.managedTeamsIdsForSelectedSeason;
    final isManager = teams.any(
      (Team team) =>
          team.keyTeam != null && managedTeamIds.contains(team.keyTeam),
    );
    final hasPremium = UserTrialService.instance.hasPremiumAccess;
    if (!isManager && !hasPremium) {
      return _unavailableContext(
        reason: 'premium_required',
        opponentName: null,
        team: teams.first,
      );
    }

    final agendaOpponents = collectAgendaOpponents(
      teams: teams,
      items: seasonItems,
      teamNames: teamNames,
    );

    final message = userMessage?.trim() ?? '';
    final hasIntent = detectsTypicalTeamIntent(message);
    final mentionedOpponent = message.isNotEmpty
        ? findOpponentMentionInMessage(
            message: message,
            candidates: agendaOpponents,
          )
        : null;

    final shouldInclude = preloadNextMatchOpponent ||
        hasIntent ||
        mentionedOpponent != null ||
        (message.isEmpty && nextMatchContext != null);

    if (!shouldInclude) {
      return null;
    }

    final target = resolveTargetOpponent(
      userMessage: userMessage,
      agendaOpponents: agendaOpponents,
      nextMatchContext: nextMatchContext,
      teams: teams,
      teamNames: teamNames,
    );

    if (target == null) {
      if (!hasIntent && mentionedOpponent == null) {
        return null;
      }
      return _unavailableContext(
        reason: 'opponent_not_found',
        opponentName: extractNamedOpponentQuery(message) ?? message,
        team: teams.first,
      );
    }

    try {
      return await _buildForCandidate(
        candidate: target,
        seasonId: seasonId,
        nextMatchContext: nextMatchContext,
      ).timeout(_computeTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('OpponentTypicalTeamChatContext timed out');
      }
      return _unavailableContext(
        reason: 'compute_timeout',
        opponentName: target.opponentName,
        team: target.team,
        opponent: target.opponent,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'OpponentTypicalTeamChatContext failed: $error\n$stackTrace',
        );
      }
      return _unavailableContext(
        reason: 'compute_failed',
        opponentName: target.opponentName,
        team: target.team,
        opponent: target.opponent,
      );
    }
  }

  Future<Map<String, dynamic>> _buildForCandidate({
    required AgendaOpponentCandidate candidate,
    required String seasonId,
    required Map<String, dynamic>? nextMatchContext,
  }) async {
    final team = candidate.team;
    final teamId = team.keyTeam?.trim() ?? '';
    final normalizedSeasonId = seasonId.trim();

    var competitionUrl = (nextMatchContext?['competitionUrl'] ?? '').toString().trim();
    final nextMatchTeamId = (nextMatchContext?['teamId'] ?? '').toString().trim();
    final nextOpponentKey = (nextMatchContext?['opponentKey'] ?? '').toString().trim();
    final usesNextMatchCompetition = nextMatchTeamId == teamId &&
        nextOpponentKey.isNotEmpty &&
        nextOpponentKey == candidate.opponent.key;

    if (!usesNextMatchCompetition || competitionUrl.isEmpty) {
      competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
            team: team,
            match: candidate.match,
            fallbackSeasonId: normalizedSeasonId,
            teamsPerClubService: _teamsPerClubService,
          ) ??
          '';
    }

    if (competitionUrl.isEmpty) {
      final urls = await loadTeamStatsCompetitionUrls(
        team: team,
        fallbackSeasonId: normalizedSeasonId,
        teamsPerClubService: _teamsPerClubService,
      );
      competitionUrl = urls.isNotEmpty ? urls.first : '';
    }

    if (competitionUrl.isEmpty) {
      return _unavailableContext(
        reason: 'competition_not_found',
        opponentName: candidate.opponentName,
        team: team,
        opponent: candidate.opponent,
      );
    }

    var opponentFilter = candidate.opponent;
    if (opponentFilter.key.startsWith('name:')) {
      final opponents = await _teamCompetitionStatsService.loadOpponentsForTeam(
        team: team,
        seasonId: normalizedSeasonId,
        competitionUrl: competitionUrl,
      );
      final resolved = _resolveOpponentInList(
        opponents: opponents,
        candidate: candidate,
      );
      if (resolved != null) {
        opponentFilter = resolved;
      }
    }

    final result = await _teamTypicalTeamService.computeTypicalTeamForOpponent(
      team: team,
      seasonId: normalizedSeasonId,
      competitionUrl: competitionUrl,
      opponentFilter: opponentFilter,
    );

    return _serializeResult(
      result: result,
      opponentName: candidate.opponentName,
      team: team,
      opponent: opponentFilter,
      competitionUrl: competitionUrl,
    );
  }

  TeamStatsOpponent? _resolveOpponentInList({
    required List<TeamStatsOpponent> opponents,
    required AgendaOpponentCandidate candidate,
  }) {
    final targetKey = candidate.opponent.key.trim();
    if (targetKey.isNotEmpty) {
      for (final TeamStatsOpponent opponent in opponents) {
        if (opponent.key == targetKey) {
          return opponent;
        }
      }
    }

    final normalizedTarget = normalizeOpponentSearchText(candidate.opponentName);
    for (final TeamStatsOpponent opponent in opponents) {
      if (normalizeOpponentSearchText(opponent.displayName) == normalizedTarget) {
        return opponent;
      }
    }

    for (final TeamStatsOpponent opponent in opponents) {
      final normalizedName = normalizeOpponentSearchText(opponent.displayName);
      if (normalizedName.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedName)) {
        return opponent;
      }
    }

    return null;
  }

  Map<String, dynamic> _serializeResult({
    required TypicalTeamResult result,
    required String opponentName,
    required Team team,
    required TeamStatsOpponent opponent,
    required String competitionUrl,
  }) {
    final dataUnavailable = !result.hasSquadData;

    return <String, dynamic>{
      'opponentName': opponentName,
      'opponentKey': opponent.key,
      'teamId': team.keyTeam,
      'teamName': team.name,
      'competitionUrl': competitionUrl,
      'matchesWithSquadData': result.matchesWithSquadData,
      'totalPlayedMatches': result.totalPlayedMatches,
      'dataUnavailable': dataUnavailable,
      if (dataUnavailable) 'unavailableReason': 'no_squad_data',
      'probableStarters': result.probableStarters
          .map(
            (TypicalTeamPlayerEntry player) => <String, dynamic>{
              'name': player.displayName,
              if (player.shirtNumber != null) 'shirt': player.shirtNumber,
              'starts': player.titularCount,
              'total': player.matchesWithSquadData,
            },
          )
          .toList(),
      'probableSubstitutes': result.probableSubstitutes
          .map(
            (TypicalTeamPlayerEntry player) => <String, dynamic>{
              'name': player.displayName,
              if (player.shirtNumber != null) 'shirt': player.shirtNumber,
              'starts': player.titularCount,
              'subs': player.substituteCount,
              'total': player.matchesWithSquadData,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _unavailableContext({
    required String reason,
    required String? opponentName,
    required Team team,
    TeamStatsOpponent? opponent,
  }) {
    return <String, dynamic>{
      if (opponentName != null && opponentName.isNotEmpty)
        'opponentName': opponentName,
      if (opponent != null) 'opponentKey': opponent.key,
      'teamId': team.keyTeam,
      'teamName': team.name,
      'dataUnavailable': true,
      'unavailableReason': reason,
      'matchesWithSquadData': 0,
      'totalPlayedMatches': 0,
      'probableStarters': const <Map<String, dynamic>>[],
      'probableSubstitutes': const <Map<String, dynamic>>[],
    };
  }

  static String? _opponentNameForMatch(
    grinta_match.Match match,
    String? teamId,
    String? teamName,
  ) {
    final t1 = (match.team1 ?? '').trim();
    final t2 = (match.team2 ?? '').trim();

    if (teamName != null && teamName.isNotEmpty) {
      if (t1.toLowerCase() == teamName.toLowerCase()) return t2;
      if (t2.toLowerCase() == teamName.toLowerCase()) return t1;
    }

    if (teamId != null && teamId.isNotEmpty && match.teamID == teamId) {
      return t2.isNotEmpty ? t2 : t1;
    }

    return t2.isNotEmpty ? t2 : t1;
  }
}
