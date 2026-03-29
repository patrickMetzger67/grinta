import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/answer.dart';

class AnswerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'answer';

  CollectionReference get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<DocumentReference> addAnswer(Answer answer) async {
    final now = Timestamp.now();

    answer.createDateTime ??= now;
    answer.updateDateTime = now;

    return await _collection.add(answer.toMap());
  }

  /// CREATE / UPDATE avec id custom
  Future<void> setAnswer(String id, Answer answer) async {
    final now = Timestamp.now();

    answer.createDateTime ??= now;
    answer.updateDateTime = now;

    await _collection.doc(id).set(answer.toMap());
  }

  /// READ ONE par id document
  Future<Answer?> getAnswerById(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists) return null;

    return Answer.fromDocumentSnapshot(doc);
  }

  /// STREAM ONE par id document
  Stream<Answer?> streamAnswerById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Answer.fromDocumentSnapshot(doc);
    });
  }

  /// READ ALL
  Future<List<Answer>> getAllAnswers() async {
    final snapshot = await _collection
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  /// STREAM ALL
  Stream<List<Answer>> streamAllAnswers() {
    return _collection
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY objectId
  Future<List<Answer>> getAnswersByObjectId(String objectId) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByObjectId(String objectId) {
    return _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY userId
  Future<List<Answer>> getAnswersByUserId(String userId) async {
    final snapshot = await _collection
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByUserId(String userId) {
    return _collection
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY objectId + userId
  Future<List<Answer>> getAnswersByObjectIdAndUserId({
    required String objectId,
    required String userId,
  }) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByObjectIdAndUserId({
    required String objectId,
    required String userId,
  }) {
    return _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ ONE BY objectId + userId
  Future<Answer?> getFirstAnswerByObjectIdAndUserId({
    required String objectId,
    required String userId,
  }) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Answer.fromDocumentSnapshot(snapshot.docs.first);
  }

  Stream<Answer?> streamFirstAnswerByObjectIdAndUserId({
    required String objectId,
    required String userId,
  }) {
    return _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerUserId, isEqualTo: userId)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Answer.fromDocumentSnapshot(snapshot.docs.first);
    });
  }

  /// READ BY training / non training
  Future<List<Answer>> getAnswersByIsTraining(bool isTraining) async {
    final snapshot = await _collection
        .where(keyAnswerIsTraining, isEqualTo: isTraining)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByIsTraining(bool isTraining) {
    return _collection
        .where(keyAnswerIsTraining, isEqualTo: isTraining)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY objectId + isTraining
  Future<List<Answer>> getAnswersByObjectIdAndIsTraining({
    required String objectId,
    required bool isTraining,
  }) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerIsTraining, isEqualTo: isTraining)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByObjectIdAndIsTraining({
    required String objectId,
    required bool isTraining,
  }) {
    return _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerIsTraining, isEqualTo: isTraining)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY objectId + presence (utile si non-training)
  Future<List<Answer>> getAnswersByObjectIdAndPresence({
    required String objectId,
    required bool isPresent,
  }) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerIsPresent, isEqualTo: isPresent)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Answer.fromDocumentSnapshot(doc))
        .toList();
  }

  Stream<List<Answer>> streamAnswersByObjectIdAndPresence({
    required String objectId,
    required bool isPresent,
  }) {
    return _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerIsPresent, isEqualTo: isPresent)
        .orderBy(keyAnswerCreateDateTime, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Answer.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// UPDATE avec ref
  Future<void> updateAnswer(Answer answer) async {
    if (answer.ref == null) {
      throw Exception("Impossible de mettre à jour : ref est null");
    }

    answer.updateDateTime = Timestamp.now();
    await answer.ref!.update(answer.toMap());
  }

  /// UPDATE par id
  Future<void> updateAnswerById(String id, Map<String, dynamic> data) async {
    data[keyAnswerUpdateDateTime] = Timestamp.now();
    await _collection.doc(id).update(data);
  }

  /// UPSERT logique sur objectId + userId
  Future<void> saveOrUpdateAnswer(Answer answer) async {
    final existing = await getFirstAnswerByObjectIdAndUserId(
      objectId: answer.objectId ?? '',
      userId: answer.userId ?? '',
    );

    final now = Timestamp.now();

    if (existing == null) {
      answer.createDateTime ??= now;
      answer.updateDateTime = now;
      await _collection.add(answer.toMap());
    } else {
      answer.ref = existing.ref;
      answer.createDateTime = existing.createDateTime ?? now;
      answer.updateDateTime = now;
      await existing.ref!.update(answer.toMap());
    }
  }

  /// DELETE avec ref
  Future<void> deleteAnswer(Answer answer) async {
    if (answer.ref == null) {
      throw Exception("Impossible de supprimer : ref est null");
    }

    await answer.ref!.delete();
  }

  /// DELETE par id
  Future<void> deleteAnswerById(String id) async {
    await _collection.doc(id).delete();
  }

  /// DELETE BY objectId + userId
  Future<void> deleteAnswerByObjectIdAndUserId({
    required String objectId,
    required String userId,
  }) async {
    final snapshot = await _collection
        .where(keyAnswerObjectId, isEqualTo: objectId)
        .where(keyAnswerUserId, isEqualTo: userId)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}