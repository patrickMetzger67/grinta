import 'package:cloud_firestore/cloud_firestore.dart';

const String keyPlayerCardsMemberId = 'memberId';
const String keyPlayerCardsEntries = 'entries';
const String keyPlayerCardsUpdatedAt = 'updatedAt';

const String keyPlayerCardMatchId = 'matchId';
const String keyPlayerCardTime = 'time';
const String keyPlayerCardExtraTime = 'extraTime';
const String keyPlayerCardType = 'type';
const String keyPlayerCardIsPurged = 'isPurged';

/// Stored in `cards.entries[].type` — same yellow / red notion as [CardType]
/// on Grinta highlights, without the `CardType.` prefix.
const String playerCardTypeYellow = 'yellow';
const String playerCardTypeRed = 'red';

/// One disciplinary card for a player (one match event).
///
/// Identity for idempotent writes: [matchId] + [time] + [extraTime] + [type].
/// The player is the parent document id (`cards/{memberId}`).
class PlayerCardEntry {
  const PlayerCardEntry({
    required this.matchId,
    required this.time,
    this.extraTime = 0,
    required this.type,
    this.isPurged = false,
  });

  final String matchId;

  /// Regulation minute of play — same unit as [Highlights.minute].
  final int time;

  /// Stoppage time — same unit as [Highlights.extraTime]. Defaults to 0.
  final int extraTime;

  /// `yellow` | `red` (see [playerCardTypeYellow] / [playerCardTypeRed]).
  final String type;

  final bool isPurged;

  factory PlayerCardEntry.fromMap(Map<String, dynamic> map) {
    return PlayerCardEntry(
      matchId: _readNonEmptyString(map[keyPlayerCardMatchId]) ?? '',
      time: _readInt(map[keyPlayerCardTime]) ?? 0,
      extraTime: _readInt(map[keyPlayerCardExtraTime]) ?? 0,
      type: _readNonEmptyString(map[keyPlayerCardType]) ?? '',
      isPurged: map[keyPlayerCardIsPurged] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyPlayerCardMatchId: matchId,
      keyPlayerCardTime: time,
      keyPlayerCardExtraTime: extraTime,
      keyPlayerCardType: type,
      keyPlayerCardIsPurged: isPurged,
    };
  }

  bool hasSameIdentityAs(PlayerCardEntry other) {
    return matchId == other.matchId &&
        time == other.time &&
        extraTime == other.extraTime &&
        type == other.type;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerCardEntry &&
        other.matchId == matchId &&
        other.time == time &&
        other.extraTime == extraTime &&
        other.type == type &&
        other.isPurged == isPurged;
  }

  @override
  int get hashCode => Object.hash(matchId, time, extraTime, type, isPurged);
}

/// Disciplinary cards for one member (player).
///
/// Firestore `cards/{memberId}` — one document per player, not per season
/// (a sanction can span seasons).
///
/// Document id = member / player id: the same `playerID` used on
/// `highLights` (`YellowRedCard.playerID`) and match convocations
/// (`PlayerConvo.playerID` / `member.keyMember`).
///
/// ```
/// {
///   memberId: 'abc123',
///   updatedAt: Timestamp,
///   entries: [
///     {
///       matchId: '56174440',
///       time: 67,            // Highlights.minute
///       extraTime: 0,        // Highlights.extraTime
///       type: 'yellow'|'red',
///       isPurged: false,
///     }
///   ],
/// }
/// ```
class PlayerCards {
  const PlayerCards({
    required this.memberId,
    this.entries = const <PlayerCardEntry>[],
    this.updatedAt,
    this.ref,
  });

  final String memberId;
  final List<PlayerCardEntry> entries;
  final Timestamp? updatedAt;
  final DocumentReference? ref;

  String get documentId => memberId.trim();

  factory PlayerCards.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final map = snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return PlayerCards.fromMap(
      map,
      fallbackMemberId: snapshot.id,
      ref: snapshot.reference,
    );
  }

  factory PlayerCards.fromMap(
    Map<String, dynamic> map, {
    String? fallbackMemberId,
    DocumentReference? ref,
  }) {
    final rawEntries = map[keyPlayerCardsEntries];
    final entries = <PlayerCardEntry>[];
    if (rawEntries is List) {
      for (final entry in rawEntries) {
        if (entry is Map) {
          entries.add(
            PlayerCardEntry.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return PlayerCards(
      memberId: _readNonEmptyString(map[keyPlayerCardsMemberId]) ??
          fallbackMemberId?.trim() ??
          '',
      entries: entries,
      updatedAt: _readTimestamp(map[keyPlayerCardsUpdatedAt]),
      ref: ref,
    );
  }

  Map<String, dynamic> toMap({Timestamp? updatedAtOverride}) {
    return <String, dynamic>{
      keyPlayerCardsMemberId: memberId,
      keyPlayerCardsEntries:
          entries.map((entry) => entry.toMap()).toList(growable: false),
      keyPlayerCardsUpdatedAt: updatedAtOverride ?? updatedAt,
    };
  }

  @override
  String toString() {
    return 'PlayerCards(memberId=$memberId, entries=${entries.length}, '
        'updatedAt=$updatedAt)';
  }
}

String? _readNonEmptyString(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

int? _readInt(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  return int.tryParse(raw?.toString() ?? '');
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
