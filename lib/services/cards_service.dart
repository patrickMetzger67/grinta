import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/player_cards.dart';
import '../util/player_cards_helper.dart';
import '../util/team_stats_cards_helper.dart';

/// Firestore `cards` — one doc per member (player).
///
/// Document id: member / player id (same as `member/{id}`, highlight
/// `playerID`, convocation `playerID`).
///
/// Written when a Grinta card highlight is saved, or when a manager assigns
/// a convoked player to an FMI card highlight. Player surfaces show a badge
/// and restitution list for non-purged entries; coach restitution is available
/// on Team Stats → Analyse → Cartons.
class CardsService {
  CardsService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'cards';

  static final CardsService instance = CardsService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef(String memberId) {
    return _collection.doc(memberId.trim());
  }

  static PlayerCards fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PlayerCards.fromDocumentSnapshot(snapshot);
  }

  static Map<String, dynamic> toFirestore(
    PlayerCards playerCards, {
    Timestamp? updatedAt,
  }) {
    return playerCards.toMap(
      updatedAtOverride: updatedAt ?? playerCards.updatedAt,
    );
  }

  /// READ ONE by member / player id.
  Future<PlayerCards?> getByMemberId(String memberId) async {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final snapshot = await docRef(trimmed).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return fromFirestore(snapshot);
  }

  /// STREAM ONE by member / player id.
  Stream<PlayerCards?> streamByMemberId(String memberId) {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return Stream<PlayerCards?>.value(null);
    }
    return docRef(trimmed).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return fromFirestore(snapshot);
    });
  }

  /// READ MANY by member / player ids (chunks of 10 for Firestore `whereIn`).
  ///
  /// Missing docs are omitted from the result map (caller treats as empty).
  Future<Map<String, PlayerCards>> getByMemberIds(
    Iterable<String> memberIds,
  ) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return const <String, PlayerCards>{};
    }

    const chunkSize = 10;
    final result = <String, PlayerCards>{};
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      final snapshot = await _collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        if (!doc.exists || doc.data().isEmpty) {
          continue;
        }
        final cards = fromFirestore(doc);
        final key = cards.memberId.trim().isEmpty ? doc.id : cards.memberId;
        result[key.trim()] = cards;
      }
    }
    return result;
  }

  /// Idempotently sets [isPurged] on the entry matching [identity]
  /// (matchId + time + extraTime + type). No-op when already equal or missing.
  Future<PlayerCards> setEntryIsPurged({
    required String memberId,
    required PlayerCardEntry identity,
    required bool isPurged,
  }) async {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError(
        'CardsService.setEntryIsPurged: memberId must not be empty.',
      );
    }
    if (identity.matchId.trim().isEmpty) {
      throw ArgumentError(
        'CardsService.setEntryIsPurged: matchId must not be empty.',
      );
    }

    final normalizedIdentity = PlayerCardEntry(
      matchId: identity.matchId.trim(),
      time: identity.time,
      extraTime: identity.extraTime,
      type: parsePlayerCardType(identity.type) ?? identity.type.trim(),
      isPurged: identity.isPurged,
    );

    final ref = docRef(trimmed);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.data() == null) {
        return PlayerCards(memberId: trimmed);
      }

      final existing = fromFirestore(snapshot);
      final updatedEntries = setPlayerCardEntryPurged(
        existing.entries,
        normalizedIdentity,
        isPurged: isPurged,
      );

      var didChange = updatedEntries.length != existing.entries.length;
      if (!didChange) {
        for (var i = 0; i < updatedEntries.length; i++) {
          if (updatedEntries[i] != existing.entries[i]) {
            didChange = true;
            break;
          }
        }
      }
      if (!didChange) {
        return existing;
      }

      final updated = PlayerCards(
        memberId: trimmed,
        entries: updatedEntries,
        ref: ref,
      );
      transaction.set(
        ref,
        toFirestore(updated)
          ..[keyPlayerCardsUpdatedAt] = FieldValue.serverTimestamp(),
      );
      return updated;
    });
  }

  /// CREATE / UPSERT one list entry. Duplicate match+time+type is a no-op.
  ///
  /// [PlayerCardEntry.isPurged] defaults to false on create and is not reset
  /// when the same identity is written again.
  Future<PlayerCards> addEntry({
    required String memberId,
    required PlayerCardEntry entry,
  }) async {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('CardsService.addEntry: memberId must not be empty.');
    }
    if (entry.matchId.trim().isEmpty) {
      throw ArgumentError('CardsService.addEntry: matchId must not be empty.');
    }
    if (entry.type.trim().isEmpty) {
      throw ArgumentError('CardsService.addEntry: type must not be empty.');
    }

    final normalized = PlayerCardEntry(
      matchId: entry.matchId.trim(),
      time: entry.time,
      extraTime: entry.extraTime,
      type: parsePlayerCardType(entry.type) ?? entry.type.trim(),
      isPurged: entry.isPurged,
    );

    final ref = docRef(trimmed);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final existing = snapshot.exists
          ? fromFirestore(snapshot)
          : PlayerCards(memberId: trimmed);

      if (playerCardEntryExists(existing.entries, normalized)) {
        return existing;
      }

      final updated = PlayerCards(
        memberId: trimmed,
        entries: upsertPlayerCardEntry(existing.entries, normalized),
        ref: ref,
      );
      transaction.set(
        ref,
        toFirestore(updated)
          ..[keyPlayerCardsUpdatedAt] = FieldValue.serverTimestamp(),
      );
      return updated;
    });
  }
}
