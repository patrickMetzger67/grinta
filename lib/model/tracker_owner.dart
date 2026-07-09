import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Firestore collection shared with goaltimefootball (same Firebase project).
/// Must stay in sync with goaltimefootball's `TRACKER_Owner` documents.
const String kTrackerOwnerCollection = 'TRACKER_Owner';

/// Field names on `TRACKER_Owner/{ownerId}`.
abstract final class TrackerOwnerDocumentFields {
  static const id = 'id';
  static const name = 'name';
  static const typeTracker = 'typeTracker';
  static const isActive = 'isActive';
  static const email = 'email';
  static const firstname = 'firstname';
  static const lastname = 'lastname';
  static const createdAt = 'createdAt';
  static const uidCreate = 'uidCreate';
  static const updatedAt = 'updatedAt';
  static const uidUpdate = 'uidUpdate';
  static const clubs = 'clubs';
  static const withSyncing = 'withSyncing';
}

/// A tracker owner ("responsable") as stored in the shared `TRACKER_Owner`
/// collection. Mirrors the goaltimefootball `Owner` model.
class TrackerOwner {
  TrackerOwner({
    String? id,
    required this.name,
    required this.typeTracker,
    required this.isActive,
    this.withSyncing = true,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.createdAt,
    required this.uidCreate,
    this.updatedAt,
    required this.uidUpdate,
    this.clubs,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final String typeTracker; // "inspirit", "footbar", "intense", ...
  final bool isActive;
  final bool withSyncing;
  final String email;
  final String firstname;
  final String lastname;
  final Timestamp? createdAt;
  final String uidCreate;
  final Timestamp? updatedAt;
  final String uidUpdate;
  final List<String>? clubs;

  /// Tracker types supported by the shared owner records.
  static const List<String> typeTrackers = <String>[
    'inspirit',
    'footbar',
    'intense',
  ];

  static const String typeIntense = 'intense';

  /// Intense trackers stream via SIM (no USB sync); all other types sync via USB.
  static bool withSyncingForType(String typeTracker) =>
      typeTracker.trim().toLowerCase() != typeIntense;

  TrackerOwner copyWith({
    String? id,
    String? name,
    String? typeTracker,
    bool? isActive,
    bool? withSyncing,
    String? email,
    String? firstname,
    String? lastname,
    Timestamp? createdAt,
    String? uidCreate,
    Timestamp? updatedAt,
    String? uidUpdate,
    List<String>? clubs,
  }) {
    return TrackerOwner(
      id: id ?? this.id,
      name: name ?? this.name,
      typeTracker: typeTracker ?? this.typeTracker,
      isActive: isActive ?? this.isActive,
      withSyncing: withSyncing ?? this.withSyncing,
      email: email ?? this.email,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      createdAt: createdAt ?? this.createdAt,
      uidCreate: uidCreate ?? this.uidCreate,
      updatedAt: updatedAt ?? this.updatedAt,
      uidUpdate: uidUpdate ?? this.uidUpdate,
      clubs: clubs ?? this.clubs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      TrackerOwnerDocumentFields.id: id,
      TrackerOwnerDocumentFields.name: name,
      TrackerOwnerDocumentFields.typeTracker: typeTracker,
      TrackerOwnerDocumentFields.isActive: isActive,
      TrackerOwnerDocumentFields.withSyncing: withSyncing,
      TrackerOwnerDocumentFields.email: email,
      TrackerOwnerDocumentFields.firstname: firstname,
      TrackerOwnerDocumentFields.lastname: lastname,
      TrackerOwnerDocumentFields.createdAt: createdAt,
      TrackerOwnerDocumentFields.uidCreate: uidCreate,
      TrackerOwnerDocumentFields.updatedAt: updatedAt,
      TrackerOwnerDocumentFields.uidUpdate: uidUpdate,
      TrackerOwnerDocumentFields.clubs: clubs,
    };
  }

  factory TrackerOwner.fromMap(Map<String, dynamic> map, {String? id}) {
    return TrackerOwner(
      id: id ?? (map[TrackerOwnerDocumentFields.id] ?? '').toString(),
      name: (map[TrackerOwnerDocumentFields.name] ?? '').toString(),
      typeTracker: (map[TrackerOwnerDocumentFields.typeTracker] ?? '').toString(),
      isActive: (map[TrackerOwnerDocumentFields.isActive] ?? false) == true,
      withSyncing:
          (map[TrackerOwnerDocumentFields.withSyncing] ?? true) == true,
      email: (map[TrackerOwnerDocumentFields.email] ?? '').toString(),
      firstname: (map[TrackerOwnerDocumentFields.firstname] ?? '').toString(),
      lastname: (map[TrackerOwnerDocumentFields.lastname] ?? '').toString(),
      createdAt: map[TrackerOwnerDocumentFields.createdAt] is Timestamp
          ? map[TrackerOwnerDocumentFields.createdAt] as Timestamp
          : null,
      uidCreate: (map[TrackerOwnerDocumentFields.uidCreate] ?? '').toString(),
      updatedAt: map[TrackerOwnerDocumentFields.updatedAt] is Timestamp
          ? map[TrackerOwnerDocumentFields.updatedAt] as Timestamp
          : null,
      uidUpdate: (map[TrackerOwnerDocumentFields.uidUpdate] ?? '').toString(),
      clubs: (map[TrackerOwnerDocumentFields.clubs] is List)
          ? List<String>.from(map[TrackerOwnerDocumentFields.clubs] as List)
          : null,
    );
  }

  factory TrackerOwner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final storedId = (data[TrackerOwnerDocumentFields.id] ?? '').toString();
    final resolvedId = storedId.isNotEmpty ? storedId : doc.id;
    return TrackerOwner.fromMap(data, id: resolvedId);
  }
}
