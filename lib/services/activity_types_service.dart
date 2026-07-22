import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Activity type from Firestore `config/activity`.
class ActivityTypeDefinition {
  const ActivityTypeDefinition({
    required this.id,
    required this.order,
    required this.labels,
    this.iconName,
  });

  final String id;
  final int order;
  final Map<String, String> labels;
  final String? iconName;

  String labelForLocale(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    final direct = labels[language]?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final en = labels['en']?.trim();
    if (en != null && en.isNotEmpty) return en;
    final fr = labels['fr']?.trim();
    if (fr != null && fr.isNotEmpty) return fr;
    return id;
  }

  IconData get icon {
    switch (iconName) {
      case 'hiking':
        return Icons.hiking;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'directions_bike':
        return Icons.directions_bike_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'directions_run':
      default:
        return Icons.directions_run_rounded;
    }
  }

  factory ActivityTypeDefinition.fromMap(Map<String, dynamic> map) {
    final labels = <String, String>{};
    final rawLabels = map['labels'];
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          labels[key] = value;
        }
      }
    }
    return ActivityTypeDefinition(
      id: (map['id'] ?? '').toString().trim(),
      order: _readInt(map['order']),
      labels: labels,
      iconName: (map['icon'] ?? '').toString().trim().isEmpty
          ? null
          : (map['icon'] as Object?).toString().trim(),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

/// Loads personal sport activity types from `config/activity`.
class ActivityTypesService {
  ActivityTypesService._();

  static final ActivityTypesService instance = ActivityTypesService._();

  static const String collectionName = 'config';
  static const String documentId = 'activity';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ActivityTypeDefinition> _types = _defaultTypes();
  bool _initialized = false;
  Future<void>? _initFuture;

  List<ActivityTypeDefinition> get types =>
      List<ActivityTypeDefinition>.unmodifiable(_types);

  Future<void> ensureInitialized() {
    return _initFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();
      if (!snap.exists) {
        _types = _defaultTypes();
        _initialized = true;
        return;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final rawTypes = data['types'];
      if (rawTypes is! List) {
        _types = _defaultTypes();
        _initialized = true;
        return;
      }
      final parsed = <ActivityTypeDefinition>[];
      for (final entry in rawTypes) {
        if (entry is! Map) continue;
        final type = ActivityTypeDefinition.fromMap(
          Map<String, dynamic>.from(entry),
        );
        if (type.id.isEmpty) continue;
        parsed.add(type);
      }
      parsed.sort((a, b) => a.order.compareTo(b.order));
      _types = parsed.isEmpty ? _defaultTypes() : parsed;
      _initialized = true;
    } catch (e, st) {
      debugPrint('ActivityTypesService load failed: $e\n$st');
      _types = _defaultTypes();
      _initialized = true;
    }
  }

  ActivityTypeDefinition? byId(String id) {
    final trimmed = id.trim();
    for (final type in _types) {
      if (type.id == trimmed) return type;
    }
    return null;
  }

  bool get isInitialized => _initialized;

  static List<ActivityTypeDefinition> _defaultTypes() {
    return [
      const ActivityTypeDefinition(
        id: 'course',
        order: 1,
        iconName: 'directions_run',
        labels: {
          'fr': 'Course',
          'en': 'Run',
          'de': 'Lauf',
          'es': 'Carrera',
          'it': 'Corsa',
        },
      ),
      const ActivityTypeDefinition(
        id: 'sortie_longue',
        order: 2,
        iconName: 'hiking',
        labels: {
          'fr': 'Sortie longue',
          'en': 'Long run',
          'de': 'Langer Lauf',
          'es': 'Salida larga',
          'it': 'Uscita lunga',
        },
      ),
      const ActivityTypeDefinition(
        id: 'entrainement',
        order: 3,
        iconName: 'fitness_center',
        labels: {
          'fr': 'Entraînement',
          'en': 'Workout',
          'de': 'Training',
          'es': 'Entrenamiento',
          'it': 'Allenamento',
        },
      ),
      const ActivityTypeDefinition(
        id: 'natation',
        order: 4,
        iconName: 'pool',
        labels: {
          'fr': 'Natation',
          'en': 'Swimming',
          'de': 'Schwimmen',
          'es': 'Natación',
          'it': 'Nuoto',
        },
      ),
      const ActivityTypeDefinition(
        id: 'velo',
        order: 5,
        iconName: 'directions_bike',
        labels: {
          'fr': 'Vélo',
          'en': 'Cycling',
          'de': 'Radfahren',
          'es': 'Ciclismo',
          'it': 'Ciclismo',
        },
      ),
      const ActivityTypeDefinition(
        id: 'recuperation',
        order: 6,
        iconName: 'self_improvement',
        labels: {
          'fr': 'Récupération',
          'en': 'Recovery',
          'de': 'Regeneration',
          'es': 'Recuperación',
          'it': 'Recupero',
        },
      ),
    ];
  }
}
