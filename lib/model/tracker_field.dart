import 'package:cloud_firestore/cloud_firestore.dart';

import 'fieldGpsCorners.dart';
import '../util/french_address_parser.dart';

const String keyTrackerFieldId = 'id';
const String keyTrackerFieldGpsCorners = 'fieldGpsCorners';
const String keyTrackerFieldTerrainNom = 'terrainNom';
const String keyTrackerFieldAdresse = 'adresse';
const String keyTrackerFieldVille = 'ville';
const String keyTrackerFieldUid = 'uid';

class TrackerField {
  final String id;
  final FieldGpsCorners fieldGpsCorners;
  final String terrainNom;
  final String adresse;
  final String ville;
  final String uid;

  const TrackerField({
    required this.id,
    required this.fieldGpsCorners,
    required this.terrainNom,
    required this.adresse,
    required this.ville,
    required this.uid,
  });

  factory TrackerField.fromMatchLocalization({
    required String terrainNom,
    required String terrainAdresse1,
    required FieldGpsCorners fieldGpsCorners,
    required String uid,
  }) {
    final parsed = FrenchAddressParser.parseTerrainAdresse1(terrainAdresse1);
    final id = FrenchAddressParser.computeFieldId(
      terrainNom: terrainNom,
      ville: parsed.ville,
    );

    return TrackerField(
      id: id,
      fieldGpsCorners: fieldGpsCorners,
      terrainNom: terrainNom.trim(),
      adresse: parsed.adresse,
      ville: parsed.ville,
      uid: uid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      keyTrackerFieldId: id,
      keyTrackerFieldGpsCorners: fieldGpsCorners.toMap(),
      keyTrackerFieldTerrainNom: terrainNom,
      keyTrackerFieldAdresse: adresse,
      keyTrackerFieldVille: ville,
      keyTrackerFieldUid: uid,
    };
  }

  factory TrackerField.fromMap(Map<String, dynamic> map) {
    return TrackerField(
      id: (map[keyTrackerFieldId] ?? '').toString(),
      fieldGpsCorners: FieldGpsCorners.fromMap(
        Map<String, dynamic>.from(map[keyTrackerFieldGpsCorners] as Map),
      ),
      terrainNom: map[keyTrackerFieldTerrainNom]?.toString() ?? '',
      adresse: map[keyTrackerFieldAdresse]?.toString() ?? '',
      ville: map[keyTrackerFieldVille]?.toString() ?? '',
      uid: map[keyTrackerFieldUid]?.toString() ?? '',
    );
  }

  factory TrackerField.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return TrackerField.fromMap({
      ...data,
      keyTrackerFieldId: data[keyTrackerFieldId]?.toString().isNotEmpty == true
          ? data[keyTrackerFieldId].toString()
          : doc.id,
    });
  }
}
