import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/model/fieldGpsCorners.dart';

/// Firestore collection for club pitches (FFF / scraped fields).
const String kFieldClubCollection = 'fieldClub';

/// Field names on `fieldClub/{fieldClubId}`.
abstract final class FieldClubDocumentFields {
  static const address = 'address';
  static const clubId = 'clubId';
  static const location = 'location';
  static const name = 'name';
  static const surface = 'surface';
  static const updateDate = 'updateDate';
  static const fieldGpsCorners = 'fieldGpsCorners';
}

/// A club pitch stored in [kFieldClubCollection], with optional pitch GPS
/// corners for tracker heatmaps.
class FieldClub {
  const FieldClub({
    required this.id,
    required this.address,
    required this.clubId,
    required this.name,
    this.location,
    this.surface,
    this.updateDate,
    this.fieldGpsCorners,
  });

  /// Firestore document id.
  final String id;
  final String address;
  final String clubId;
  final String name;
  final Location? location;
  final String? surface;
  final Timestamp? updateDate;

  /// Optional 4-corner GPS outline used for Intense / USB heatmaps.
  final FieldGpsCorners? fieldGpsCorners;

  bool get hasFieldGpsCorners => fieldGpsCorners?.isComplete == true;

  FieldClub copyWith({
    String? id,
    String? address,
    String? clubId,
    String? name,
    Location? location,
    String? surface,
    Timestamp? updateDate,
    FieldGpsCorners? fieldGpsCorners,
    bool clearFieldGpsCorners = false,
  }) {
    return FieldClub(
      id: id ?? this.id,
      address: address ?? this.address,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      location: location ?? this.location,
      surface: surface ?? this.surface,
      updateDate: updateDate ?? this.updateDate,
      fieldGpsCorners: clearFieldGpsCorners
          ? null
          : (fieldGpsCorners ?? this.fieldGpsCorners),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FieldClubDocumentFields.address: address,
      FieldClubDocumentFields.clubId: clubId,
      FieldClubDocumentFields.name: name,
      if (location != null)
        FieldClubDocumentFields.location: location!.toMap(),
      if (surface != null) FieldClubDocumentFields.surface: surface,
      if (updateDate != null) FieldClubDocumentFields.updateDate: updateDate,
      if (fieldGpsCorners != null)
        FieldClubDocumentFields.fieldGpsCorners: fieldGpsCorners!.toMap(),
    };
  }

  factory FieldClub.fromMap(Map<String, dynamic> map, {String? id}) {
    final cornersRaw = map[FieldClubDocumentFields.fieldGpsCorners];
    return FieldClub(
      id: (id ?? map['id'] ?? '').toString(),
      address: (map[FieldClubDocumentFields.address] ?? '').toString().trim(),
      clubId: (map[FieldClubDocumentFields.clubId] ?? '').toString().trim(),
      name: (map[FieldClubDocumentFields.name] ?? '').toString().trim(),
      location: _readLocation(map[FieldClubDocumentFields.location]),
      surface: _optionalString(map[FieldClubDocumentFields.surface]),
      updateDate: _readTimestamp(map[FieldClubDocumentFields.updateDate]),
      fieldGpsCorners: cornersRaw is Map
          ? FieldGpsCorners.fromMap(Map<String, dynamic>.from(cornersRaw))
          : null,
    );
  }

  factory FieldClub.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FieldClub.fromMap(data, id: doc.id);
  }

  static String? _optionalString(Object? value) {
    final trimmed = value?.toString().trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Supports Firestore [GeoPoint] and export maps (`__lat__` / `__lon__`).
  static Location? _readLocation(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final geohash = map[keyLocationGeoHash]?.toString();
    final gp = map[keyLocationGeoPoint];

    if (gp is GeoPoint) {
      return Location(geohash: geohash, geopoint: gp);
    }
    if (gp is Map) {
      final point = Map<String, dynamic>.from(gp);
      final lat = point['__lat__'] ?? point['latitude'] ?? point['_latitude'];
      final lon = point['__lon__'] ?? point['longitude'] ?? point['_longitude'];
      if (lat is num && lon is num) {
        return Location(
          geohash: geohash,
          geopoint: GeoPoint(lat.toDouble(), lon.toDouble()),
        );
      }
    }

    try {
      return Location.fromMap(map);
    } catch (_) {
      return Location(geohash: geohash);
    }
  }

  /// Supports Firestore [Timestamp], ISO strings, and export maps (`__time__`).
  static Timestamp? _readTimestamp(Object? raw) {
    if (raw is Timestamp) return raw;
    if (raw is DateTime) return Timestamp.fromDate(raw);
    if (raw is Map) {
      final time = raw['__time__'] ?? raw['seconds'];
      if (time is String) {
        final parsed = DateTime.tryParse(time);
        if (parsed != null) return Timestamp.fromDate(parsed);
      }
      if (time is num) {
        return Timestamp.fromMillisecondsSinceEpoch(time.toInt() * 1000);
      }
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return Timestamp.fromDate(parsed);
    }
    return null;
  }
}
