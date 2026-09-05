import 'package:cloud_firestore/cloud_firestore.dart';

const String keyPredGameDayTeamId = 'teamId';
const String keyPredGameDayEngagementId = 'engagementId';
const String keyPredGameDayCompetitionId = 'competitionId';
const String keyPredGameDayGroup = 'group';
const String keyPredGameDayStage = 'stage';
const String keyPredGameDayDay = 'day';
const String keyPredGameDaySeasonId = 'seasonId';
const String keyPredGameDayClubId = 'clubId';
const String keyPredGameDayMatchIds = 'matchIds';
const String keyPredGameDayFixtures = 'fixtures';
const String keyPredGameDayFirstKickoffAt = 'firstKickoffAt';
const String keyPredGameDayClosesAt = 'closesAt';
const String keyPredGameDayCreatedAt = 'createdAt';
const String keyPredGameDayEntries = 'entries';

const String keyPredGameDayFixtureMatchId = 'matchId';
const String keyPredGameDayFixtureTeam1 = 'team1';
const String keyPredGameDayFixtureTeam2 = 'team2';
const String keyPredGameDayFixtureTeam1UrlLogo = 'team1UrlLogo';
const String keyPredGameDayFixtureTeam2UrlLogo = 'team2UrlLogo';
const String keyPredGameDayFixtureKickoffAt = 'kickoffAt';
const String keyPredGameDayFixtureDay = 'day';

const String keyPredGameDayEntryUserId = 'userId';
const String keyPredGameDayEntryPlayerId = 'playerId';
const String keyPredGameDayEntryPicks = 'picks';
const String keyPredGameDayEntrySubmittedAt = 'submittedAt';

/// Allowed pick values: 1 = home win, 2 = away win, 3 = draw.
const int predGameDayPickHome = 1;
const int predGameDayPickAway = 2;
const int predGameDayPickDraw = 3;

/// Snapshot of one fixture inside a [PredGameDay] contest.
class PredGameDayFixture {
  String matchId;
  String team1;
  String team2;
  String? team1UrlLogo;
  String? team2UrlLogo;
  DateTime? kickoffAt;
  int? day;

  PredGameDayFixture({
    this.matchId = '',
    this.team1 = '',
    this.team2 = '',
    this.team1UrlLogo,
    this.team2UrlLogo,
    this.kickoffAt,
    this.day,
  });

  factory PredGameDayFixture.fromMap(Map<String, dynamic>? map) {
    return PredGameDayFixture(
      matchId: _asString(map?[keyPredGameDayFixtureMatchId]),
      team1: _asString(map?[keyPredGameDayFixtureTeam1]),
      team2: _asString(map?[keyPredGameDayFixtureTeam2]),
      team1UrlLogo: _asOptionalString(map?[keyPredGameDayFixtureTeam1UrlLogo]),
      team2UrlLogo: _asOptionalString(map?[keyPredGameDayFixtureTeam2UrlLogo]),
      kickoffAt: _asDateTime(map?[keyPredGameDayFixtureKickoffAt]),
      day: _asOptionalInt(map?[keyPredGameDayFixtureDay]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyPredGameDayFixtureMatchId: matchId,
      keyPredGameDayFixtureTeam1: team1,
      keyPredGameDayFixtureTeam2: team2,
      if (team1UrlLogo != null && team1UrlLogo!.trim().isNotEmpty)
        keyPredGameDayFixtureTeam1UrlLogo: team1UrlLogo!.trim(),
      if (team2UrlLogo != null && team2UrlLogo!.trim().isNotEmpty)
        keyPredGameDayFixtureTeam2UrlLogo: team2UrlLogo!.trim(),
      if (kickoffAt != null)
        keyPredGameDayFixtureKickoffAt: Timestamp.fromDate(kickoffAt!),
      if (day != null) keyPredGameDayFixtureDay: day,
    };
  }
}

/// One player's submitted picks for a [PredGameDay].
class PredGameDayEntry {
  String userId;
  String playerId;
  Map<String, int> picks;
  DateTime? submittedAt;

  PredGameDayEntry({
    this.userId = '',
    this.playerId = '',
    Map<String, int>? picks,
    this.submittedAt,
  }) : picks = picks ?? <String, int>{};

  factory PredGameDayEntry.fromMap(Map<String, dynamic>? map) {
    return PredGameDayEntry(
      userId: _asString(map?[keyPredGameDayEntryUserId]),
      playerId: _asString(map?[keyPredGameDayEntryPlayerId]),
      picks: _asPicks(map?[keyPredGameDayEntryPicks]),
      submittedAt: _asDateTime(map?[keyPredGameDayEntrySubmittedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyPredGameDayEntryUserId: userId,
      keyPredGameDayEntryPlayerId: playerId,
      keyPredGameDayEntryPicks: picks,
      if (submittedAt != null)
        keyPredGameDayEntrySubmittedAt: Timestamp.fromDate(submittedAt!),
    };
  }
}

/// Firestore `predGameDay` — one contest per team + engagement + matchday.
class PredGameDay {
  String? id;
  String teamId;
  String engagementId;
  String competitionId;
  String group;
  String stage;
  int day;
  String seasonId;
  String clubId;
  List<String> matchIds;
  List<PredGameDayFixture> fixtures;
  DateTime? firstKickoffAt;
  DateTime? closesAt;
  DateTime? createdAt;
  Map<String, PredGameDayEntry> entries;
  DocumentReference? ref;

  PredGameDay({
    this.id,
    this.teamId = '',
    this.engagementId = '',
    this.competitionId = '',
    this.group = '',
    this.stage = '',
    this.day = 0,
    this.seasonId = '',
    this.clubId = '',
    List<String>? matchIds,
    List<PredGameDayFixture>? fixtures,
    this.firstKickoffAt,
    this.closesAt,
    this.createdAt,
    Map<String, PredGameDayEntry>? entries,
    this.ref,
  })  : matchIds = matchIds ?? <String>[],
        fixtures = fixtures ?? <PredGameDayFixture>[],
        entries = entries ?? <String, PredGameDayEntry>{};

  factory PredGameDay.fromMap(
    Map<String, dynamic>? map, {
    String? id,
    DocumentReference? ref,
  }) {
    return PredGameDay(
      id: id,
      teamId: _asString(map?[keyPredGameDayTeamId]),
      engagementId: _asString(map?[keyPredGameDayEngagementId]),
      competitionId: _asString(map?[keyPredGameDayCompetitionId]),
      group: _asString(map?[keyPredGameDayGroup]),
      stage: _asString(map?[keyPredGameDayStage]),
      day: _asOptionalInt(map?[keyPredGameDayDay]) ?? 0,
      seasonId: _asString(map?[keyPredGameDaySeasonId]),
      clubId: _asString(map?[keyPredGameDayClubId]),
      matchIds: _asStringList(map?[keyPredGameDayMatchIds]),
      fixtures: _asFixtures(map?[keyPredGameDayFixtures]),
      firstKickoffAt: _asDateTime(map?[keyPredGameDayFirstKickoffAt]),
      closesAt: _asDateTime(map?[keyPredGameDayClosesAt]),
      createdAt: _asDateTime(map?[keyPredGameDayCreatedAt]),
      entries: _asEntries(map?[keyPredGameDayEntries]),
      ref: ref,
    );
  }

  factory PredGameDay.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    return PredGameDay.fromMap(
      snapshot.data() as Map<String, dynamic>?,
      id: snapshot.id,
      ref: snapshot.reference,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyPredGameDayTeamId: teamId,
      keyPredGameDayEngagementId: engagementId,
      keyPredGameDayCompetitionId: competitionId,
      keyPredGameDayGroup: group,
      keyPredGameDayStage: stage,
      keyPredGameDayDay: day,
      keyPredGameDaySeasonId: seasonId,
      keyPredGameDayClubId: clubId,
      keyPredGameDayMatchIds: matchIds,
      keyPredGameDayFixtures: fixtures.map((f) => f.toMap()).toList(),
      if (firstKickoffAt != null)
        keyPredGameDayFirstKickoffAt: Timestamp.fromDate(firstKickoffAt!),
      if (closesAt != null) keyPredGameDayClosesAt: Timestamp.fromDate(closesAt!),
      if (createdAt != null)
        keyPredGameDayCreatedAt: Timestamp.fromDate(createdAt!),
      keyPredGameDayEntries: entries.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  bool isOpenAt(DateTime now) {
    final deadline = closesAt;
    if (deadline == null) return false;
    return now.isBefore(deadline);
  }

  PredGameDayEntry? entryForPlayer(String playerId) {
    final trimmed = playerId.trim();
    if (trimmed.isEmpty) return null;
    return entries[trimmed];
  }

  @override
  String toString() {
    return 'PredGameDay: id=$id teamId=$teamId engagementId=$engagementId '
        'day=$day matchIds=$matchIds closesAt=$closesAt '
        'entries=${entries.length}';
  }
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _asOptionalString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asOptionalInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

List<PredGameDayFixture> _asFixtures(dynamic value) {
  if (value is! List) return <PredGameDayFixture>[];
  return value
      .whereType<Map>()
      .map(
        (entry) => PredGameDayFixture.fromMap(Map<String, dynamic>.from(entry)),
      )
      .toList();
}

Map<String, PredGameDayEntry> _asEntries(dynamic value) {
  if (value is! Map) return <String, PredGameDayEntry>{};
  final result = <String, PredGameDayEntry>{};
  value.forEach((key, entry) {
    final id = key?.toString().trim() ?? '';
    if (id.isEmpty || entry is! Map) return;
    result[id] = PredGameDayEntry.fromMap(Map<String, dynamic>.from(entry));
  });
  return result;
}

Map<String, int> _asPicks(dynamic value) {
  if (value is! Map) return <String, int>{};
  final result = <String, int>{};
  value.forEach((key, pick) {
    final matchId = key?.toString().trim() ?? '';
    final parsed = _asOptionalInt(pick);
    if (matchId.isEmpty || parsed == null) return;
    result[matchId] = parsed;
  });
  return result;
}
