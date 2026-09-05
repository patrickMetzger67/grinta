import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/player_cards.dart';
import '../util/player_cards_helper.dart';

/// Firestore `cards` — one doc per member (player).
///
/// Document id: member / player id (same as `member/{id}`, highlight
/// `playerID`, convocation `playerID`).
///
/// Written when a Grinta card highlight is saved, or when a manager assigns
/// a convoked player to an FMI card highlight. The app does not yet render
/// these cards on player / coach surfaces.
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
