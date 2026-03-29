import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Collection Firestore
const String kTrackerOwnerCollection = 'TRACKER_Owner';

class Owner {
  final String id; // uuid.v4
  final String name;
  final String typeTracker; // "inspirit", "footbar", ...
  final bool isActive;

  final String email;
  final String firstname;
  final String lastname;

  final Timestamp? createdAt;
  final String uidCreate;
  final Timestamp? updatedAt;
  final String uidUpdate;
  List<String>? clubs;

  Owner({
    String? id,
    required this.name,
    required this.typeTracker,
    required this.isActive,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.createdAt,
    required this.uidCreate,
    this.updatedAt,
    required this.uidUpdate,
    this.clubs,
  }) : id = id ?? const Uuid().v4();

  Owner copyWith({
    String? id,
    String? name,
    String? typeTracker,
    String? email,
    String? firstname,
    String? lastname,
    bool? isActive,
    Timestamp? createdAt,
    String? uidCreate,
    Timestamp? updatedAt,
    String? uidUpdate,
    List<String>? clubs,
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      typeTracker: typeTracker ?? this.typeTracker,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      createdAt: createdAt ?? this.createdAt,
      uidCreate: uidCreate ?? this.uidCreate,
      updatedAt: updatedAt ?? this.updatedAt,
      uidUpdate: uidUpdate ?? this.uidUpdate,
      clubs:clubs ?? this.clubs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'typeTracker': typeTracker,
      'isActive': isActive,
      'email':email,
      'firstname': firstname,
      'lastname':lastname,
      'createdAt': createdAt,
      'uidCreate': uidCreate,
      'updatedAt': updatedAt,
      'uidUpdate': uidUpdate,
      'clubs':clubs,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map, {String? id}) {
    return Owner(
      id: id ?? (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      typeTracker: (map['typeTracker'] ?? '').toString(),
      isActive: (map['isActive'] ?? false) == true,
      email: (map['email'] ?? '').toString(),
      firstname: (map['firstname'] ?? '').toString(),
      lastname: (map['lastname'] ?? '').toString(),
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] as Timestamp : null,
      uidCreate: (map['uidCreate'] ?? '').toString(),
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] as Timestamp : null,
      uidUpdate: (map['uidUpdate'] ?? '').toString(),
      clubs: List<String>.from(map['clubs'] ?? []),
    );
  }

  factory Owner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final storedId = (data['id'] ?? '').toString();
    final resolvedId = storedId.isNotEmpty ? storedId : doc.id;
    return Owner.fromMap(data, id: resolvedId);
  }
}

