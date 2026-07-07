import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/season_period_ranges.dart';

/// Per-player counters accumulated across one or more matches.
class TeamPlayerMatchStatsAccumulator {
  TeamPlayerMatchStatsAccumulator({required this.playerId});

  final String playerId;
  int convocations = 0;
  int starts = 0;
  int minutesPlayed = 0;
  int goals = 0;
  int yellowCards = 0;
  int redCards = 0;

  void merge(TeamPlayerMatchStatsAccumulator other) {
    convocations += other.convocations;
    starts += other.starts;
    minutesPlayed += other.minutesPlayed;
    goals += other.goals;
    yellowCards += other.yellowCards;
    redCards += other.redCards;
  }
}

/// Player stat totals for one season half plus team match count in that half.
class TeamPlayerHalfCounts {
  const TeamPlayerHalfCounts({
    this.convocations = 0,
    this.starts = 0,
    this.minutesPlayed = 0,
    this.goals = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.teamMatchCount = 0,
  });

  final int convocations;
  final int starts;
  final int minutesPlayed;
  final int goals;
  final int yellowCards;
  final int redCards;
  final int teamMatchCount;

  factory TeamPlayerHalfCounts.fromAccumulator({
    required TeamPlayerMatchStatsAccumulator? accumulator,
    required int teamMatchCount,
  }) {
    return TeamPlayerHalfCounts(
      convocations: accumulator?.convocations ?? 0,
      starts: accumulator?.starts ?? 0,
      minutesPlayed: accumulator?.minutesPlayed ?? 0,
      goals: accumulator?.goals ?? 0,
      yellowCards: accumulator?.yellowCards ?? 0,
      redCards: accumulator?.redCards ?? 0,
      teamMatchCount: teamMatchCount,
    );
  }

  double? get convocationsRate =>
      teamMatchCount == 0 ? null : convocations / teamMatchCount;

  double? get startsRate => teamMatchCount == 0 ? null : starts / teamMatchCount;

  double? get minutesRate =>
      teamMatchCount == 0 ? null : minutesPlayed / teamMatchCount;

  double? get goalsRate => teamMatchCount == 0 ? null : goals / teamMatchCount;

  double? get yellowCardsRate =>
      teamMatchCount == 0 ? null : yellowCards / teamMatchCount;

  double? get redCardsRate =>
      teamMatchCount == 0 ? null : redCards / teamMatchCount;
}

/// H1 vs H2 trend directions for each sortable player stat column.
class TeamPlayerStatTrends {
  const TeamPlayerStatTrends({
    this.convocations = TeamWdlTrendDirection.insufficientData,
    this.starts = TeamWdlTrendDirection.insufficientData,
    this.playTime = TeamWdlTrendDirection.insufficientData,
    this.goals = TeamWdlTrendDirection.insufficientData,
    this.yellowCards = TeamWdlTrendDirection.insufficientData,
    this.redCards = TeamWdlTrendDirection.insufficientData,
  });

  final TeamWdlTrendDirection convocations;
  final TeamWdlTrendDirection starts;
  final TeamWdlTrendDirection playTime;
  final TeamWdlTrendDirection goals;
  final TeamWdlTrendDirection yellowCards;
  final TeamWdlTrendDirection redCards;

  /// Compares per-match rates between [firstHalf] and [secondHalf].
  static TeamPlayerStatTrends compare({
    required TeamPlayerHalfCounts firstHalf,
    required TeamPlayerHalfCounts secondHalf,
  }) {
    return TeamPlayerStatTrends(
      convocations: _compareRates(
        firstRate: firstHalf.convocationsRate,
        secondRate: secondHalf.convocationsRate,
        flatThreshold: 0.02,
      ),
      starts: _compareRates(
        firstRate: firstHalf.startsRate,
        secondRate: secondHalf.startsRate,
        flatThreshold: 0.02,
      ),
      playTime: _compareRates(
        firstRate: firstHalf.minutesRate,
        secondRate: secondHalf.minutesRate,
        flatThreshold: 0.02,
      ),
      goals: _compareRates(
        firstRate: firstHalf.goalsRate,
        secondRate: secondHalf.goalsRate,
        flatThreshold: 0.05,
      ),
      yellowCards: _compareRates(
        firstRate: firstHalf.yellowCardsRate,
        secondRate: secondHalf.yellowCardsRate,
        flatThreshold: 0.05,
      ),
      redCards: _compareRates(
        firstRate: firstHalf.redCardsRate,
        secondRate: secondHalf.redCardsRate,
        flatThreshold: 0.05,
      ),
    );
  }

  static TeamWdlTrendDirection _compareRates({
    required double? firstRate,
    required double? secondRate,
    required double flatThreshold,
  }) {
    if (firstRate == null || secondRate == null) {
      return TeamWdlTrendDirection.insufficientData;
    }

    final diff = secondRate - firstRate;
    if (diff.abs() <= flatThreshold) {
      return TeamWdlTrendDirection.flat;
    }

    return diff > 0 ? TeamWdlTrendDirection.up : TeamWdlTrendDirection.down;
  }
}

int _matchEndMinute(models.Match match, List<Highlights> highlights) {
  final endHighlight = findTimeEventHighlight(highlights, TimeType.end);
  final endMinute = endHighlight?.minute;
  if (endMinute != null && endMinute > 0) {
    return endMinute;
  }
  return regulationMatchDuration(match);
}

int _compareHighlightMinute(Highlights a, Highlights b) {
  final minuteCompare = (a.minute ?? 0).compareTo(b.minute ?? 0);
  if (minuteCompare != 0) {
    return minuteCompare;
  }
  return (a.extraTime ?? 0).compareTo(b.extraTime ?? 0);
}

Set<String> _starterPlayerIds(MatchCompo compo) {
  return startersFromMatchCompo(compo)
      .values
      .map((player) => player.playerID?.trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();
}

/// Minutes played in one match from compo roles and team substitution highlights.
int minutesPlayedInMatch({
  required models.Match match,
  required MatchCompo compo,
  required List<Highlights> highlights,
  required String playerId,
}) {
  final normalizedPlayerId = playerId.trim();
  if (normalizedPlayerId.isEmpty) {
    return 0;
  }

  final endMinute = _matchEndMinute(match, highlights);
  final starterIds = _starterPlayerIds(compo);

  final enterMinute = <String, int>{};
  final exitMinute = <String, int>{};

  for (final id in starterIds) {
    enterMinute[id] = kHighlightMinuteMin;
    exitMinute[id] = endMinute;
  }

  final substitutions = highlights
      .where((highlight) => highlight.actionType == ActionType.substitution)
      .toList()
    ..sort(_compareHighlightMinute);

  for (final highlight in substitutions) {
    final substitution = highlight.value as Substitution?;
    if (substitution == null) {
      continue;
    }

    final minute = highlight.minute ?? kHighlightMinuteMin;
    final outgoingId = substitution.outgoingPlayerId?.trim() ?? '';
    final enteringId = substitution.enteringPlayerId?.trim() ?? '';

    if (outgoingId.isNotEmpty && enterMinute.containsKey(outgoingId)) {
      exitMinute[outgoingId] = minute;
    }

    if (enteringId.isNotEmpty) {
      enterMinute[enteringId] = minute;
      exitMinute[enteringId] = endMinute;
    }
  }

  final enter = enterMinute[normalizedPlayerId];
  if (enter == null) {
    return 0;
  }

  final exit = exitMinute[normalizedPlayerId] ?? endMinute;
  if (exit < enter) {
    return 0;
  }

  return exit - enter + 1;
}

/// Builds per-player stats for a single played match.
Map<String, TeamPlayerMatchStatsAccumulator> statsForMatch({
  required models.Match match,
  required MatchCompo? compo,
  required List<Highlights> highlights,
}) {
  final statsByPlayerId = <String, TeamPlayerMatchStatsAccumulator>{};

  TeamPlayerMatchStatsAccumulator statsFor(String playerId) {
    return statsByPlayerId.putIfAbsent(
      playerId,
      () => TeamPlayerMatchStatsAccumulator(playerId: playerId),
    );
  }

  if (compo != null) {
    final convokedIds = convokedPlayerIds(compo);
    final starterIds = _starterPlayerIds(compo);

    for (final playerId in convokedIds) {
      statsFor(playerId).convocations = 1;
    }

    for (final playerId in starterIds) {
      statsFor(playerId).starts = 1;
    }

    final playersOnPitch = <String>{
      ...starterIds,
      ...substitutesFromMatchCompo(compo)
          .map((player) => player.playerID?.trim() ?? '')
          .where((id) => id.isNotEmpty),
    };

    for (final playerId in playersOnPitch) {
      final minutes = minutesPlayedInMatch(
        match: match,
        compo: compo,
        highlights: highlights,
        playerId: playerId,
      );
      if (minutes > 0) {
        statsFor(playerId).minutesPlayed = minutes;
      }
    }
  }

  for (final highlight in highlights) {
    switch (highlight.actionType) {
      case ActionType.goal:
        final goal = highlight.value as Goal?;
        final scorerId = goal?.playerId?.trim() ?? '';
        if (scorerId.isEmpty) {
          continue;
        }
        statsFor(scorerId).goals += 1;
      case ActionType.yellowCard:
        final card = highlight.value as YellowRedCard?;
        final playerId = card?.playerId?.trim() ?? '';
        if (playerId.isEmpty) {
          continue;
        }
        statsFor(playerId).yellowCards += 1;
      case ActionType.redCard:
        final card = highlight.value as YellowRedCard?;
        final playerId = card?.playerId?.trim() ?? '';
        if (playerId.isEmpty) {
          continue;
        }
        statsFor(playerId).redCards += 1;
      default:
        break;
    }
  }

  return statsByPlayerId;
}

String _cleanMatchStatText(String? value) {
  return value?.trim() ?? '';
}

String _normalizeMatchStatToken(String? value) {
  return _cleanMatchStatText(value).toLowerCase();
}

String _normalizeMatchStatPlayerName(String? value) {
  return _cleanMatchStatText(value)
      .toLowerCase()
      .replaceAll('.', ' ')
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'[^a-z0-9àâäéèêëîïôöùûüçñ\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _matchStatPlayerSignature(String value) {
  final parts = value.split(' ');
  if (parts.isEmpty) {
    return '';
  }

  final first = parts.first;
  final last = parts.length > 1 ? parts.last : '';
  if (last.isEmpty) {
    return first;
  }
  return '$first ${last[0]}';
}

/// Stable key for aggregating [matchStats] players across matches (name-based).
String normalizeMatchStatPlayerKey(String? playerName) {
  final normalized = _normalizeMatchStatPlayerName(playerName);
  if (normalized.isEmpty) {
    return '';
  }
  return normalized;
}

/// Whether two [matchStats] team labels refer to the same side.
bool sameMatchStatTeam(String? left, String? right) {
  return _normalizeMatchStatToken(left) == _normalizeMatchStatToken(right);
}

/// Whether two [matchStats] player labels refer to the same person.
bool sameMatchStatPlayer(String? left, String? right) {
  final leftName = _normalizeMatchStatPlayerName(left);
  final rightName = _normalizeMatchStatPlayerName(right);

  if (leftName.isEmpty || rightName.isEmpty) {
    return false;
  }
  if (leftName == rightName) {
    return true;
  }

  final leftParts = leftName.split(' ');
  final rightParts = rightName.split(' ');

  if (leftParts.isEmpty || rightParts.isEmpty) {
    return false;
  }
  if (leftParts.first != rightParts.first) {
    return false;
  }

  if (leftParts.length < 2 || rightParts.length < 2) {
    return false;
  }

  final leftLast = leftParts.last;
  final rightLast = rightParts.last;

  if (leftLast == rightLast) {
    return true;
  }

  if (leftLast.length == 1 && rightLast.startsWith(leftLast)) {
    return true;
  }

  if (rightLast.length == 1 && leftLast.startsWith(rightLast)) {
    return true;
  }

  return _matchStatPlayerSignature(leftName) == _matchStatPlayerSignature(rightName);
}

String _normalizeMatchStatHighlightType(String? value) {
  return _normalizeMatchStatToken(value)
      .replaceAll(' ', '')
      .replaceAll('_', '');
}

bool _isMatchStatSubstitutionHighlight(MatchStatHighLight highlight) {
  final outgoingPlayer = _cleanMatchStatText(highlight.player);
  final incomingPlayer = _cleanMatchStatText(highlight.incomingPlayer);
  if (outgoingPlayer.isEmpty || incomingPlayer.isEmpty) {
    return false;
  }

  switch (_normalizeMatchStatHighlightType(highlight.type)) {
    case 'replacement':
    case 'substitution':
    case 'change':
    case 'changement':
      return true;
    default:
      return false;
  }
}

bool _isMatchStatGoalHighlight(MatchStatHighLight highlight) {
  switch (_normalizeMatchStatHighlightType(highlight.type)) {
    case 'goal':
    case 'but':
    case 'penalty':
      return true;
    default:
      return false;
  }
}

bool _isMatchStatYellowCardHighlight(MatchStatHighLight highlight) {
  switch (_normalizeMatchStatHighlightType(highlight.type)) {
    case 'yellowcard':
    case 'yellow_card':
    case 'cartonjaune':
    case 'carton_jaune':
      return true;
    default:
      return false;
  }
}

bool _isMatchStatRedCardHighlight(MatchStatHighLight highlight) {
  switch (_normalizeMatchStatHighlightType(highlight.type)) {
    case 'redcard':
    case 'red_card':
    case 'cartonrouge':
    case 'carton_rouge':
      return true;
    default:
      return false;
  }
}

Set<String> _teamNamesFromMatchStats(MatchStats matchStats) {
  final teams = <String>{};

  void addTeam(String? value) {
    final team = _cleanMatchStatText(value);
    if (team.isNotEmpty) {
      teams.add(team);
    }
  }

  for (final player in matchStats.titulars ?? const <MatchStatPlayer>[]) {
    addTeam(player.team);
  }
  for (final player in matchStats.substitutes ?? const <MatchStatPlayer>[]) {
    addTeam(player.team);
  }
  for (final highlight in matchStats.highlights ?? const <MatchStatHighLight>[]) {
    addTeam(highlight.team);
  }

  return teams;
}

/// Picks the team label used in [matchStats] for [preferredTeamName].
String? resolveMatchStatTeamName({
  required String preferredTeamName,
  required MatchStats matchStats,
}) {
  final preferred = _cleanMatchStatText(preferredTeamName);
  if (preferred.isEmpty) {
    return null;
  }

  for (final team in _teamNamesFromMatchStats(matchStats)) {
    if (sameMatchStatTeam(team, preferred)) {
      return team;
    }
  }

  return preferred;
}

int _matchEndMinuteFromMatchStats(
  models.Match match,
  List<MatchStatHighLight> highlights,
) {
  for (final highlight in highlights) {
    switch (_normalizeMatchStatHighlightType(highlight.type)) {
      case 'end':
      case 'fulltime':
      case 'fin':
      case 'finmatch':
        final minute = highlight.time ?? 0;
        if (minute > 0) {
          return minute;
        }
        break;
      default:
        break;
    }
  }

  var maxMinute = 0;
  for (final highlight in highlights) {
    final minute = highlight.time ?? 0;
    if (minute > maxMinute) {
      maxMinute = minute;
    }
  }

  if (maxMinute > 0) {
    return maxMinute;
  }

  return regulationMatchDuration(match);
}

List<MatchStatPlayer> _matchStatPlayersForTeam(
  List<MatchStatPlayer> players,
  String teamName,
) {
  return players
      .where((player) => sameMatchStatTeam(player.team, teamName))
      .toList();
}

List<MatchStatHighLight> _matchStatHighlightsForTeam(
  List<MatchStatHighLight> highlights,
  String teamName,
) {
  return highlights
      .where((highlight) => sameMatchStatTeam(highlight.team, teamName))
      .toList();
}

Set<String> _starterPlayerKeys(List<MatchStatPlayer> titulars) {
  return titulars
      .map((player) => normalizeMatchStatPlayerKey(player.player))
      .where((key) => key.isNotEmpty)
      .toSet();
}

Set<String> _convokedPlayerKeys({
  required List<MatchStatPlayer> titulars,
  required List<MatchStatPlayer> substitutes,
}) {
  final keys = <String>{};
  for (final player in [...titulars, ...substitutes]) {
    final key = normalizeMatchStatPlayerKey(player.player);
    if (key.isNotEmpty) {
      keys.add(key);
    }
  }
  return keys;
}

/// Minutes played in one match from [matchStats] composition and substitutions.
int minutesPlayedInMatchFromMatchStats({
  required models.Match match,
  required MatchStats matchStats,
  required String teamName,
  required String playerKey,
}) {
  final normalizedPlayerKey = playerKey.trim();
  if (normalizedPlayerKey.isEmpty) {
    return 0;
  }

  final resolvedTeamName = resolveMatchStatTeamName(
    preferredTeamName: teamName,
    matchStats: matchStats,
  );
  if (resolvedTeamName == null || resolvedTeamName.isEmpty) {
    return 0;
  }

  final titulars = _matchStatPlayersForTeam(
    matchStats.titulars ?? const <MatchStatPlayer>[],
    resolvedTeamName,
  );
  final highlights = _matchStatHighlightsForTeam(
    matchStats.highlights ?? const <MatchStatHighLight>[],
    resolvedTeamName,
  );

  final endMinute = _matchEndMinuteFromMatchStats(match, highlights);
  final starterKeys = _starterPlayerKeys(titulars);

  final enterMinute = <String, int>{};
  final exitMinute = <String, int>{};

  for (final key in starterKeys) {
    enterMinute[key] = kHighlightMinuteMin;
    exitMinute[key] = endMinute;
  }

  final substitutions = highlights.where(_isMatchStatSubstitutionHighlight).toList()
    ..sort((a, b) => (a.time ?? 0).compareTo(b.time ?? 0));

  for (final highlight in substitutions) {
    final minute = highlight.time ?? kHighlightMinuteMin;
    final outgoingKey = normalizeMatchStatPlayerKey(highlight.player);
    final enteringKey = normalizeMatchStatPlayerKey(highlight.incomingPlayer);

    if (outgoingKey.isNotEmpty && enterMinute.containsKey(outgoingKey)) {
      exitMinute[outgoingKey] = minute;
    }

    if (enteringKey.isNotEmpty) {
      enterMinute[enteringKey] = minute;
      exitMinute[enteringKey] = endMinute;
    }
  }

  String? matchedKey;
  for (final key in enterMinute.keys) {
    if (sameMatchStatPlayer(key, normalizedPlayerKey)) {
      matchedKey = key;
      break;
    }
  }

  final enter = matchedKey == null ? null : enterMinute[matchedKey];
  if (enter == null) {
    return 0;
  }

  final exit = exitMinute[matchedKey] ?? endMinute;
  if (exit < enter) {
    return 0;
  }

  return exit - enter + 1;
}

/// Builds per-player stats for one match from Firestore [matchStats].
///
/// Player keys are normalized names ([normalizeMatchStatPlayerKey]).
Map<String, TeamPlayerMatchStatsAccumulator> statsForMatchFromMatchStats({
  required models.Match match,
  required MatchStats? matchStats,
  required String opponentTeamName,
}) {
  final statsByPlayerKey = <String, TeamPlayerMatchStatsAccumulator>{};

  TeamPlayerMatchStatsAccumulator statsFor(String playerKey) {
    return statsByPlayerKey.putIfAbsent(
      playerKey,
      () => TeamPlayerMatchStatsAccumulator(playerId: playerKey),
    );
  }

  if (matchStats == null) {
    return statsByPlayerKey;
  }

  final resolvedTeamName = resolveMatchStatTeamName(
    preferredTeamName: opponentTeamName,
    matchStats: matchStats,
  );
  if (resolvedTeamName == null || resolvedTeamName.isEmpty) {
    return statsByPlayerKey;
  }

  final titulars = _matchStatPlayersForTeam(
    matchStats.titulars ?? const <MatchStatPlayer>[],
    resolvedTeamName,
  );
  final substitutes = _matchStatPlayersForTeam(
    matchStats.substitutes ?? const <MatchStatPlayer>[],
    resolvedTeamName,
  );
  final highlights = _matchStatHighlightsForTeam(
    matchStats.highlights ?? const <MatchStatHighLight>[],
    resolvedTeamName,
  );

  if (titulars.isEmpty && substitutes.isEmpty) {
    return statsByPlayerKey;
  }

  final convokedKeys = _convokedPlayerKeys(
    titulars: titulars,
    substitutes: substitutes,
  );
  final starterKeys = _starterPlayerKeys(titulars);

  for (final key in convokedKeys) {
    statsFor(key).convocations = 1;
  }

  for (final key in starterKeys) {
    statsFor(key).starts = 1;
  }

  for (final key in convokedKeys) {
    final minutes = minutesPlayedInMatchFromMatchStats(
      match: match,
      matchStats: matchStats,
      teamName: resolvedTeamName,
      playerKey: key,
    );
    if (minutes > 0) {
      statsFor(key).minutesPlayed = minutes;
    }
  }

  for (final highlight in highlights) {
    final isGoal = _isMatchStatGoalHighlight(highlight);
    final isYellowCard = _isMatchStatYellowCardHighlight(highlight);
    final isRedCard = _isMatchStatRedCardHighlight(highlight);
    if (!isGoal && !isYellowCard && !isRedCard) {
      continue;
    }

    final playerKey = normalizeMatchStatPlayerKey(highlight.player);
    if (playerKey.isEmpty) {
      continue;
    }

    var targetKey = playerKey;
    for (final key in convokedKeys) {
      if (sameMatchStatPlayer(key, playerKey)) {
        targetKey = key;
        break;
      }
    }

    if (isGoal) {
      statsFor(targetKey).goals += 1;
    } else if (isYellowCard) {
      statsFor(targetKey).yellowCards += 1;
    } else if (isRedCard) {
      statsFor(targetKey).redCards += 1;
    }
  }

  return statsByPlayerKey;
}

/// Stable key for typical-team aggregation (normalized name + shirt number).
String normalizeTypicalTeamPlayerKey(String? playerName, String? shirt) {
  final nameKey = normalizeMatchStatPlayerKey(playerName);
  final shirtToken = _cleanMatchStatText(shirt).toLowerCase();
  if (nameKey.isEmpty && shirtToken.isEmpty) {
    return '';
  }
  if (shirtToken.isEmpty) {
    return nameKey;
  }
  return '$nameKey#$shirtToken';
}

int? parseMatchStatShirtNumber(String? shirt) {
  final trimmed = _cleanMatchStatText(shirt);
  if (trimmed.isEmpty) {
    return null;
  }

  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return null;
  }

  return int.tryParse(digits);
}

/// One player row in a computed typical team.
class TypicalTeamPlayerEntry {
  const TypicalTeamPlayerEntry({
    required this.playerKey,
    required this.displayName,
    this.shirtNumber,
    required this.titularCount,
    required this.substituteCount,
    required this.totalMatchesInSquad,
    required this.matchesWithSquadData,
    required this.titularTrend,
  });

  final String playerKey;
  final String displayName;
  final int? shirtNumber;
  final int titularCount;
  final int substituteCount;
  final int totalMatchesInSquad;
  final int matchesWithSquadData;
  final TeamWdlTrendDirection titularTrend;
}

/// Probable starting XI and bench derived from [matchStats] lineups.
class TypicalTeamResult {
  const TypicalTeamResult({
    required this.probableStarters,
    required this.probableSubstitutes,
    required this.matchesWithSquadData,
    required this.totalPlayedMatches,
  });

  final List<TypicalTeamPlayerEntry> probableStarters;
  final List<TypicalTeamPlayerEntry> probableSubstitutes;
  final int matchesWithSquadData;
  final int totalPlayedMatches;

  bool get hasSquadData => matchesWithSquadData > 0;
}

/// One played match plus its external [matchStats] payload.
class TypicalTeamMatchInput {
  const TypicalTeamMatchInput({
    required this.match,
    required this.matchStats,
    required this.opponentTeamName,
    this.matchDate,
  });

  final models.Match match;
  final MatchStats? matchStats;
  final String opponentTeamName;
  final DateTime? matchDate;
}

class _TypicalTeamPlayerAccumulator {
  _TypicalTeamPlayerAccumulator({required this.playerKey});

  final String playerKey;
  String displayName = '';
  int? shirtNumber;
  int titularCount = 0;
  int substituteCount = 0;
  int firstHalfTitularCount = 0;
  int firstHalfSquadCount = 0;
  int secondHalfTitularCount = 0;
  int secondHalfSquadCount = 0;

  int get totalMatchesInSquad => titularCount + substituteCount;

  void registerAppearance({
    required String rawName,
    required String? shirt,
    required bool isTitular,
    required bool isFirstHalf,
    required bool isSecondHalf,
  }) {
    final trimmedName = rawName.trim();
    if (trimmedName.isNotEmpty) {
      displayName = trimmedName;
    }

    final parsedShirt = parseMatchStatShirtNumber(shirt);
    if (parsedShirt != null) {
      shirtNumber = parsedShirt;
    }

    if (isTitular) {
      titularCount++;
      if (isFirstHalf) {
        firstHalfTitularCount++;
      }
      if (isSecondHalf) {
        secondHalfTitularCount++;
      }
    } else {
      substituteCount++;
    }

    if (isFirstHalf) {
      firstHalfSquadCount++;
    }
    if (isSecondHalf) {
      secondHalfSquadCount++;
    }
  }

  TypicalTeamPlayerEntry toEntry({
    required int matchesWithSquadData,
  }) {
    return TypicalTeamPlayerEntry(
      playerKey: playerKey,
      displayName: displayName.isNotEmpty ? displayName : playerKey,
      shirtNumber: shirtNumber,
      titularCount: titularCount,
      substituteCount: substituteCount,
      totalMatchesInSquad: totalMatchesInSquad,
      matchesWithSquadData: matchesWithSquadData,
      titularTrend: _titularTrend(),
    );
  }

  TeamWdlTrendDirection _titularTrend() {
    final firstRate = firstHalfSquadCount == 0
        ? null
        : firstHalfTitularCount / firstHalfSquadCount;
    final secondRate = secondHalfSquadCount == 0
        ? null
        : secondHalfTitularCount / secondHalfSquadCount;

    if (firstRate == null || secondRate == null) {
      return TeamWdlTrendDirection.insufficientData;
    }

    const flatThreshold = 0.02;
    final diff = secondRate - firstRate;
    if (diff.abs() <= flatThreshold) {
      return TeamWdlTrendDirection.flat;
    }

    return diff > 0 ? TeamWdlTrendDirection.up : TeamWdlTrendDirection.down;
  }
}

int _compareTypicalTeamShirt(int? left, int? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }
  return left.compareTo(right);
}

int _compareTypicalTeamStarters(
  _TypicalTeamPlayerAccumulator left,
  _TypicalTeamPlayerAccumulator right,
) {
  final byTitular = right.titularCount.compareTo(left.titularCount);
  if (byTitular != 0) {
    return byTitular;
  }

  final bySquad = right.totalMatchesInSquad.compareTo(left.totalMatchesInSquad);
  if (bySquad != 0) {
    return bySquad;
  }

  return _compareTypicalTeamShirt(left.shirtNumber, right.shirtNumber);
}

int _compareTypicalTeamSubstitutes(
  _TypicalTeamPlayerAccumulator left,
  _TypicalTeamPlayerAccumulator right,
) {
  final bySubstitute =
      right.substituteCount.compareTo(left.substituteCount);
  if (bySubstitute != 0) {
    return bySubstitute;
  }

  final byTitular = right.titularCount.compareTo(left.titularCount);
  if (byTitular != 0) {
    return byTitular;
  }

  return _compareTypicalTeamShirt(left.shirtNumber, right.shirtNumber);
}

int _compareTypicalTeamDisplayOrder(
  TypicalTeamPlayerEntry left,
  TypicalTeamPlayerEntry right,
) {
  final byShirt =
      _compareTypicalTeamShirt(left.shirtNumber, right.shirtNumber);
  if (byShirt != 0) {
    return byShirt;
  }

  return left.displayName.toLowerCase().compareTo(right.displayName.toLowerCase());
}

void _registerTypicalTeamPlayer({
  required Map<String, _TypicalTeamPlayerAccumulator> accumulators,
  required MatchStatPlayer player,
  required bool isTitular,
  required bool isFirstHalf,
  required bool isSecondHalf,
}) {
  final playerKey = normalizeTypicalTeamPlayerKey(player.player, player.shirt);
  if (playerKey.isEmpty) {
    return;
  }

  accumulators
      .putIfAbsent(
        playerKey,
        () => _TypicalTeamPlayerAccumulator(playerKey: playerKey),
      )
      .registerAppearance(
        rawName: player.player ?? '',
        shirt: player.shirt,
        isTitular: isTitular,
        isFirstHalf: isFirstHalf,
        isSecondHalf: isSecondHalf,
      );
}

/// Builds a probable starting XI and bench from aggregated [matchStats] lineups.
TypicalTeamResult computeTypicalTeamFromMatchStats({
  required List<TypicalTeamMatchInput> matches,
  SeasonPeriodRanges? seasonPeriods,
  int maxStarters = 11,
  int maxSubstitutes = 7,
}) {
  final accumulators = <String, _TypicalTeamPlayerAccumulator>{};
  var matchesWithSquadData = 0;

  for (final input in matches) {
    final matchStats = input.matchStats;
    if (matchStats == null) {
      continue;
    }

    final resolvedTeamName = resolveMatchStatTeamName(
      preferredTeamName: input.opponentTeamName,
      matchStats: matchStats,
    );
    if (resolvedTeamName == null || resolvedTeamName.isEmpty) {
      continue;
    }

    final titulars = _matchStatPlayersForTeam(
      matchStats.titulars ?? const <MatchStatPlayer>[],
      resolvedTeamName,
    );
    final substitutes = _matchStatPlayersForTeam(
      matchStats.substitutes ?? const <MatchStatPlayer>[],
      resolvedTeamName,
    );

    if (titulars.isEmpty && substitutes.isEmpty) {
      continue;
    }

    matchesWithSquadData++;

    final matchDate = input.matchDate;
    final isFirstHalf = seasonPeriods != null &&
        matchDate != null &&
        seasonPeriods.firstHalf.contains(matchDate);
    final isSecondHalf = seasonPeriods != null &&
        matchDate != null &&
        seasonPeriods.secondHalf.contains(matchDate);

    for (final player in titulars) {
      _registerTypicalTeamPlayer(
        accumulators: accumulators,
        player: player,
        isTitular: true,
        isFirstHalf: isFirstHalf,
        isSecondHalf: isSecondHalf,
      );
    }

    for (final player in substitutes) {
      _registerTypicalTeamPlayer(
        accumulators: accumulators,
        player: player,
        isTitular: false,
        isFirstHalf: isFirstHalf,
        isSecondHalf: isSecondHalf,
      );
    }
  }

  if (accumulators.isEmpty) {
    return TypicalTeamResult(
      probableStarters: const [],
      probableSubstitutes: const [],
      matchesWithSquadData: 0,
      totalPlayedMatches: matches.length,
    );
  }

  final starterCandidates = accumulators.values
      .where((player) => player.titularCount >= 1)
      .toList()
    ..sort(_compareTypicalTeamStarters);

  final selectedStarterKeys = starterCandidates
      .take(maxStarters)
      .map((player) => player.playerKey)
      .toSet();

  final probableStarters = starterCandidates
      .take(maxStarters)
      .map(
        (player) => player.toEntry(matchesWithSquadData: matchesWithSquadData),
      )
      .toList()
    ..sort(_compareTypicalTeamDisplayOrder);

  final substituteCandidates = accumulators.values
      .where(
        (player) =>
            !selectedStarterKeys.contains(player.playerKey) &&
            player.totalMatchesInSquad >= 1,
      )
      .toList()
    ..sort(_compareTypicalTeamSubstitutes);

  final probableSubstitutes = substituteCandidates
      .take(maxSubstitutes)
      .map(
        (player) => player.toEntry(matchesWithSquadData: matchesWithSquadData),
      )
      .toList()
    ..sort(_compareTypicalTeamDisplayOrder);

  return TypicalTeamResult(
    probableStarters: probableStarters,
    probableSubstitutes: probableSubstitutes,
    matchesWithSquadData: matchesWithSquadData,
    totalPlayedMatches: matches.length,
  );
}
