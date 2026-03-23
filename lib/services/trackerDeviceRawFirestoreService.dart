import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/trackerDeviceRaw.dart';

class TrackerDeviceRawFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveAll(List<TrackerDeviceRaw> items) async {
    if (items.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final item in items) {
      final doc = _firestore.collection('TRACKER_DeviceRaw').doc(item.id);
      batch.set(doc, item.toMap(), SetOptions(merge: true));
      count++;

      if (count == 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}