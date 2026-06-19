import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'users';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<bool> existsByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;

    final snapshot = await _collection
        .where('email', isEqualTo: trimmed)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<UserProfile?> getById(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    return UserProfile(
      uid: uid,
      firstName: _readNameField(data, 'firstName', 'firstname'),
      lastName: _readNameField(data, 'lastName', 'lastname'),
      email: data['email']?.toString() ?? '',
    );
  }

  String _readNameField(
    Map<String, dynamic> data,
    String primaryKey,
    String fallbackKey,
  ) {
    final primary = data[primaryKey]?.toString().trim();
    if (primary != null && primary.isNotEmpty) return primary;

    return data[fallbackKey]?.toString().trim() ?? '';
  }
}
