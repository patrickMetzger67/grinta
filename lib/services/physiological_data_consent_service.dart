import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/physiological_data_consent.dart';

/// Reads / writes physiological (HR) consent on `users/{uid}`.
class PhysiologicalDataConsentService {
  PhysiologicalDataConsentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(UserService.collectionName).doc(uid);

  Future<PhysiologicalDataConsentStatus> readStatus(String uid) async {
    final snap = await _userRef(uid).get();
    return physiologicalConsentFromUserData(snap.data());
  }

  /// Self-serve (≥15) authorize or refuse. Does not block other app features.
  Future<void> setSelfConsent({
    required String uid,
    required bool granted,
  }) async {
    await _userRef(uid).set(
      <String, dynamic>{
        UserDocumentFields.physiologicalDataConsent: granted,
        UserDocumentFields.physiologicalDataConsentAt:
            FieldValue.serverTimestamp(),
        UserDocumentFields.physiologicalDataConsentVersion:
            kPhysiologicalDataConsentVersion,
        UserDocumentFields.physiologicalDataConsentSource:
            PhysiologicalDataConsentSource.self,
      },
      SetOptions(merge: true),
    );
  }

  /// Stores a token so a legal guardian can approve physiological processing
  /// for an already-active 13–14 account (without flipping accountStatus).
  Future<void> storeParentalPhysiologicalConsentRequest({
    required String uid,
    required String parentEmail,
    required String token,
  }) async {
    await _userRef(uid).set(
      <String, dynamic>{
        UserDocumentFields.parentEmail: parentEmail.trim(),
        UserDocumentFields.parentalConsentToken: token.trim(),
        UserDocumentFields.parentalConsentRequestedAt:
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
