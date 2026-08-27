import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection for shop.grinta.io product ads.
const String kShopAdsCollection = 'ads';

/// Storage prefix for ad visuals (`ads/{adId}/…`).
const String kShopAdsStoragePrefix = 'ads';

/// `ads/{adId}.target` values.
enum ShopAdTarget {
  all,
  coach,
  player,
  coachWithoutTracker,
  playerWithoutTracker,
}

extension ShopAdTargetWire on ShopAdTarget {
  String get wireValue {
    switch (this) {
      case ShopAdTarget.all:
        return 'all';
      case ShopAdTarget.coach:
        return 'coach';
      case ShopAdTarget.player:
        return 'player';
      case ShopAdTarget.coachWithoutTracker:
        return 'coachWithoutTracker';
      case ShopAdTarget.playerWithoutTracker:
        return 'playerWithoutTracker';
    }
  }

  /// Returns null when [raw] is missing or not a known target.
  static ShopAdTarget? tryParse(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'all':
        return ShopAdTarget.all;
      case 'coach':
        return ShopAdTarget.coach;
      case 'player':
        return ShopAdTarget.player;
      case 'coachWithoutTracker':
        return ShopAdTarget.coachWithoutTracker;
      case 'playerWithoutTracker':
        return ShopAdTarget.playerWithoutTracker;
      default:
        return null;
    }
  }
}

/// One shop advertisement stored in Firestore `ads/{id}`.
///
/// ## Schema
/// ```json
/// {
///   "id": "<docId>",
///   "name": "GPS Insiders",
///   "url": "https://shop.grinta.io/products/…",
///   "storagePath": "ads/<docId>/1710000000000.jpg",
///   "imageUrl": "https://firebasestorage.googleapis.com/…",
///   "startDate": "<Timestamp>",
///   "endDate": "<Timestamp>",
///   "target": "all|coach|player|coachWithoutTracker|playerWithoutTracker",
///   "nbDisplay": 0,
///   "nbClicks": 0
/// }
/// ```
class ShopAd {
  const ShopAd({
    required this.id,
    required this.name,
    required this.url,
    required this.target,
    this.storagePath,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.nbDisplay = 0,
    this.nbClicks = 0,
  });

  final String id;
  final String name;
  final String url;
  final ShopAdTarget target;
  final String? storagePath;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int nbDisplay;
  final int nbClicks;

  String? get resolvedImageUrl {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  factory ShopAd.fromDoc(
    String docId,
    Map<String, dynamic>? data,
  ) {
    final map = data ?? const <String, dynamic>{};
    final id = (map['id'] ?? docId).toString().trim();
    return ShopAd(
      id: id.isEmpty ? docId : id,
      name: (map['name'] ?? '').toString().trim(),
      url: (map['url'] ?? '').toString().trim(),
      target: ShopAdTargetWire.tryParse(map['target']?.toString()) ??
          ShopAdTarget.all,
      storagePath: _optionalString(map['storagePath']),
      imageUrl: _optionalString(map['imageUrl']),
      startDate: parseShopAdDate(map['startDate']),
      endDate: parseShopAdDate(map['endDate']),
      nbDisplay: _readInt(map['nbDisplay']),
      nbClicks: _readInt(map['nbClicks']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name.trim(),
      'url': url.trim(),
      'target': target.wireValue,
      'storagePath': storagePath?.trim() ?? '',
      'imageUrl': imageUrl?.trim() ?? '',
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'nbDisplay': nbDisplay,
      'nbClicks': nbClicks,
    };
  }

  ShopAd copyWith({
    String? id,
    String? name,
    String? url,
    ShopAdTarget? target,
    String? storagePath,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    int? nbDisplay,
    int? nbClicks,
    bool clearStorage = false,
    bool clearImageUrl = false,
  }) {
    return ShopAd(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      target: target ?? this.target,
      storagePath: clearStorage ? null : (storagePath ?? this.storagePath),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nbDisplay: nbDisplay ?? this.nbDisplay,
      nbClicks: nbClicks ?? this.nbClicks,
    );
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

/// Parses Firestore Timestamp, DateTime, epoch millis, or ISO-8601 strings.
DateTime? parseShopAdDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
