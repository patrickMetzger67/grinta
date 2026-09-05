import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/util/match_outcome_helper.dart';

const String keyLastResultsClubId = 'clubId';
const String keyLastResultsCompetitionId = 'competitionId';
const String keyLastResultsResults = 'results';
const String keyLastResultsUpdatedAt = 'updatedAt';
const String keyLastResultOutcome = 'outcome';
const String keyLastResultMatchId = 'matchId';
const String keyLastResultTimestamp = 'timestamp';

const String lastResultsOutcomeWin = 'win';
const String lastResultsOutcomeDraw = 'draw';
const String lastResultsOutcomeLoss = 'loss';

/// One played match in a club's recent form (same competition).
class LastResultEntry {
  const LastResultEntry({
    required this.outcome,
    this.matchId,
    this.timestamp,
  });

  final MatchOutcome outcome;
  final String? matchId;
  final Timestamp? timestamp;

  factory LastResultEntry.fromMap(Map<String, dynamic> map) {
    return LastResultEntry(
      outcome: parseLastResultOutcome(map[keyLastResultOutcome]),
      matchId: _readNonEmptyString(map[keyLastResultMatchId]),
      timestamp: _readTimestamp(map[keyLastResultTimestamp]),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyLastResultOutcome: lastResultOutcomeToString(outcome),
      if (matchId != null && matchId!.isNotEmpty) keyLastResultMatchId: matchId,
      if (timestamp != null) keyLastResultTimestamp: timestamp,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LastResultEntry &&
        other.outcome == outcome &&
        other.matchId == matchId;
  }

  @override
  int get hashCode => Object.hash(outcome, matchId);
}

/// Precomputed last results for a club in one competition.
///
/// Firestore `lastResults/{clubId}_{competitionId}`.
///
/// ```
/// {
///   clubId: '500554',
///   competitionId: '450652',
///   updatedAt: Timestamp, // date/heure de dernière mise à jour
///   results: [            // max 5, plus ancien → plus récent
///     { outcome: 'win'|'draw'|'loss', matchId: '56174440', timestamp: Timestamp }
///   ],
/// }
/// ```
class LastResults {
  const LastResults({
    required this.clubId,
    required this.competitionId,
    this.results = const <LastResultEntry>[],
    this.updatedAt,
    this.ref,
  });

  final String clubId;
  final String competitionId;
  final List<LastResultEntry> results;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  String get documentId => lastResultsDocumentId(clubId, competitionId);

  factory LastResults.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final map = snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final fromId = parseLastResultsDocumentId(snapshot.id);
    return LastResults.fromMap(
      map,
      fallbackClubId: fromId?.clubId,
      fallbackCompetitionId: fromId?.competitionId,
      ref: snapshot.reference,
    );
  }

  factory LastResults.fromMap(
    Map<String, dynamic> map, {
    String? fallbackClubId,
    String? fallbackCompetitionId,
    DocumentReference? ref,
  }) {
    final rawResults = map[keyLastResultsResults];
    final results = <LastResultEntry>[];
    if (rawResults is List) {
      for (final entry in rawResults) {
        if (entry is Map) {
          results.add(
            LastResultEntry.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return LastResults(
      clubId: _readNonEmptyString(map[keyLastResultsClubId]) ??
          fallbackClubId?.trim() ??
          '',
      competitionId: _readNonEmptyString(map[keyLastResultsCompetitionId]) ??
          fallbackCompetitionId?.trim() ??
          '',
      results: results,
      updatedAt: _readTimestamp(map[keyLastResultsUpdatedAt]),
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({Timestamp? updatedAtOverride}) {
    return <String, dynamic>{
      keyLastResultsClubId: clubId,
      keyLastResultsCompetitionId: competitionId,
      keyLastResultsResults:
          results.map((entry) => entry.toMap()).toList(growable: false),
      keyLastResultsUpdatedAt: updatedAtOverride ?? updatedAt,
    };
  }

  bool hasSameResultsAs(LastResults other) {
    if (clubId != other.clubId || competitionId != other.competitionId) {
      return false;
    }
    if (results.length != other.results.length) {
      return false;
    }
    for (var i = 0; i < results.length; i++) {
      if (results[i] != other.results[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'LastResults(clubId=$clubId, competitionId=$competitionId, '
        'results=${results.length}, updatedAt=$updatedAt)';
  }
}

class LastResultsKey {
  const LastResultsKey({
    required this.clubId,
    required this.competitionId,
  });

  final String clubId;
  final String competitionId;

  String get documentId => lastResultsDocumentId(clubId, competitionId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LastResultsKey &&
        other.clubId == clubId &&
        other.competitionId == competitionId;
  }

  @override
  int get hashCode => Object.hash(clubId, competitionId);
}

String lastResultsDocumentId(String clubId, String competitionId) {
  return '${clubId.trim()}_${competitionId.trim()}';
}

/// Parses `lastResults/{clubId}_{competitionId}`.
LastResultsKey? parseLastResultsDocumentId(String documentId) {
  final trimmed = documentId.trim();
  final separator = trimmed.indexOf('_');
  if (separator <= 0 || separator == trimmed.length - 1) {
    return null;
  }
  return LastResultsKey(
    clubId: trimmed.substring(0, separator),
    competitionId: trimmed.substring(separator + 1),
  );
}

LastResultsKey? lastResultsKeyFromIds({
  String? clubId,
  String? competitionId,
}) {
  final trimmedClubId = clubId?.trim() ?? '';
  final trimmedCompetitionId = competitionId?.trim() ?? '';
  if (trimmedClubId.isEmpty || trimmedCompetitionId.isEmpty) {
    return null;
  }
  return LastResultsKey(
    clubId: trimmedClubId,
    competitionId: trimmedCompetitionId,
  );
}

String lastResultOutcomeToString(MatchOutcome outcome) {
  return switch (outcome) {
    MatchOutcome.win => lastResultsOutcomeWin,
    MatchOutcome.draw => lastResultsOutcomeDraw,
    MatchOutcome.loss => lastResultsOutcomeLoss,
  };
}

MatchOutcome parseLastResultOutcome(dynamic raw) {
  switch (raw?.toString().trim().toLowerCase()) {
    case lastResultsOutcomeWin:
      return MatchOutcome.win;
    case lastResultsOutcomeLoss:
      return MatchOutcome.loss;
    default:
      return MatchOutcome.draw;
  }
}

String? _readNonEmptyString(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

Timestamp? _readTimestamp(dynamic raw) {
  if (raw is Timestamp) {
    return raw;
  }
  if (raw is DateTime) {
    return Timestamp.fromDate(raw);
  }
  return null;
}
