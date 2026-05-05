import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/club.dart';

class ClubService {
  static const String defaultCollectionName = 'club';

  final FirebaseFirestore _firestore;
  final String collectionName;

  ClubService({
    FirebaseFirestore? firestore,
    this.collectionName = defaultCollectionName,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(collectionName);
  }

  Future<String> createClub({
    required Club club,
    String? documentId,
  }) async {
    final Map<String, dynamic> data = _clubToFirestoreMap(club);

    if (documentId != null && documentId.trim().isNotEmpty) {
      await _collection.doc(documentId.trim()).set(data);
      return documentId.trim();
    }

    final docRef = await _collection.add(data);
    return docRef.id;
  }

  Future<void> setClub({
    required String clubId,
    required Club club,
    bool merge = true,
  }) async {
    await _collection.doc(clubId).set(
      _clubToFirestoreMap(club),
      SetOptions(merge: merge),
    );
  }

  Future<void> updateClub({
    required String clubId,
    required Club club,
  }) async {
    await _collection.doc(clubId).update(
      _clubToFirestoreMap(club),
    );
  }

  Future<void> updateClubFields({
    required String clubId,
    required Map<String, dynamic> fields,
  }) async {
    await _collection.doc(clubId).update(fields);
  }

  Future<void> deleteClub(String clubId) async {
    await _collection.doc(clubId).delete();
  }

  Future<Club?> getClubById(String clubId) async {
    final snapshot = await _collection.doc(clubId).get();

    if (!snapshot.exists) {
      return null;
    }

    return Club.fromDocumentSnapshot(snapshot);
  }

  Stream<Club?> watchClubById(String clubId) {
    return _collection.doc(clubId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return Club.fromDocumentSnapshot(snapshot);
    });
  }

  Stream<List<Club>> watchClubs({
    int limit = 100,
  }) {
    return _collection
        .orderBy(keyClubName)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Club.fromDocumentSnapshot(doc);
      }).toList();
    });
  }

  Future<List<Club>> getClubs({
    int limit = 100,
  }) async {
    final snapshot = await _collection
        .orderBy(keyClubName)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return Club.fromDocumentSnapshot(doc);
    }).toList();
  }

  Stream<List<Club>> searchClubs(String query) {
    final String normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return watchClubs();
    }

    return _collection
        .where(
      keyClubSearchTerms,
      arrayContains: normalizedQuery,
    )
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Club.fromDocumentSnapshot(doc);
      }).toList();
    });
  }

  Future<void> addGround({
    required String clubId,
    required Ground ground,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Ground> grounds = <Ground>[
      ...(club.grounds ?? <Ground>[]),
      ground,
    ];

    await _collection.doc(clubId).update({
      keyClubGrounds: grounds.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> updateGroundAtIndex({
    required String clubId,
    required int index,
    required Ground ground,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Ground> grounds = <Ground>[
      ...(club.grounds ?? <Ground>[]),
    ];

    if (index < 0 || index >= grounds.length) {
      throw Exception('Index terrain invalide : $index');
    }

    grounds[index] = ground;

    await _collection.doc(clubId).update({
      keyClubGrounds: grounds.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> removeGroundAtIndex({
    required String clubId,
    required int index,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Ground> grounds = <Ground>[
      ...(club.grounds ?? <Ground>[]),
    ];

    if (index < 0 || index >= grounds.length) {
      throw Exception('Index terrain invalide : $index');
    }

    grounds.removeAt(index);

    await _collection.doc(clubId).update({
      keyClubGrounds: grounds.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> addStaff({
    required String clubId,
    required Staff staff,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Staff> staffList = <Staff>[
      ...(club.staff ?? <Staff>[]),
      staff,
    ];

    await _collection.doc(clubId).update({
      keyClubStaff: staffList.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> updateStaffAtIndex({
    required String clubId,
    required int index,
    required Staff staff,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Staff> staffList = <Staff>[
      ...(club.staff ?? <Staff>[]),
    ];

    if (index < 0 || index >= staffList.length) {
      throw Exception('Index staff invalide : $index');
    }

    staffList[index] = staff;

    await _collection.doc(clubId).update({
      keyClubStaff: staffList.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> removeStaffAtIndex({
    required String clubId,
    required int index,
  }) async {
    final Club? club = await getClubById(clubId);

    if (club == null) {
      throw Exception('Club introuvable : $clubId');
    }

    final List<Staff> staffList = <Staff>[
      ...(club.staff ?? <Staff>[]),
    ];

    if (index < 0 || index >= staffList.length) {
      throw Exception('Index staff invalide : $index');
    }

    staffList.removeAt(index);

    await _collection.doc(clubId).update({
      keyClubStaff: staffList.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> updateTeams({
    required String clubId,
    required Map<dynamic, dynamic> teams,
  }) async {
    await _collection.doc(clubId).update({
      keyClubTeams: teams,
    });
  }

  Future<void> updateColors({
    required String clubId,
    required List<Color> colors,
  }) async {
    await _collection.doc(clubId).update({
      keyClubColors: _colorsToFirestore(colors),
    });
  }

  Future<void> updateSearchTerms({
    required String clubId,
    required String name,
    String? city,
    String? affiliation,
  }) async {
    await _collection.doc(clubId).update({
      keyClubSearchTerms: buildSearchTerms(
        name: name,
        city: city,
        affiliation: affiliation,
      ),
    });
  }

  Map<String, dynamic> _clubToFirestoreMap(Club club) {
    final List<Ground> grounds = club.grounds ?? <Ground>[];
    final List<Staff> staff = club.staff ?? <Staff>[];

    final List<dynamic> searchTerms = club.searchTerms?.isNotEmpty == true
        ? club.searchTerms!
        : buildSearchTerms(
      name: club.name ?? '',
      city: club.city,
      affiliation: club.affiliation,
    );

    return {
      keyClubName: club.name ?? '',
      keyClubAffiliation: club.affiliation ?? '',
      keyCubLogo: club.logo ?? '',
      keyClubAddress: club.address ?? '',
      keyClubZipCode: club.zipCode ?? '',
      keyClubCity: club.city ?? '',
      keyClubGrounds: grounds.map((ground) => ground.toMap()).toList(),
      keyClubLocation: club.location?.toMap(),
      keyClubParticulars: club.particulars ?? <dynamic>[],
      keyClubStaff: staff.map((item) => item.toMap()).toList(),
      keyClubTeams: club.teams ?? <dynamic, dynamic>{},
      keyClubSearchTerms: searchTerms,
      keyClubColors: _colorsToFirestore(club.colors ?? <Color>[]),
    };
  }

  static List<Map<String, dynamic>> _colorsToFirestore(List<Color> colors) {
    return colors.map((color) {
      return {
        'R': color.red.toString(),
        'G': color.green.toString(),
        'B': color.blue.toString(),
      };
    }).toList();
  }

  static List<String> buildSearchTerms({
    required String name,
    String? city,
    String? affiliation,
  }) {
    final Set<String> terms = <String>{};

    void addTerms(String value) {
      final String normalized = value.trim().toLowerCase();

      if (normalized.isEmpty) return;

      terms.add(normalized);

      final parts = normalized
          .split(RegExp(r'\s+'))
          .where((part) => part.trim().isNotEmpty)
          .toList();

      for (final part in parts) {
        terms.add(part);

        for (int i = 1; i <= part.length; i++) {
          terms.add(part.substring(0, i));
        }
      }
    }

    addTerms(name);
    addTerms(city ?? '');
    addTerms(affiliation ?? '');

    return terms.toList();
  }
}