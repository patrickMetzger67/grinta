import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/player_positions.dart';

/// Field position entry from Firestore `config/playerPositions`.
class PlayerPositionDefinition {
  const PlayerPositionDefinition({
    required this.code,
    this.order = 0,
    this.label,
    this.labelKey,
  });

  final int code;
  final int order;
  final String? label;
  final String? labelKey;

  factory PlayerPositionDefinition.fromMap(Map<String, dynamic> map) {
    final code = _readInt(map['code'] ?? map['id'] ?? map['position']);
    return PlayerPositionDefinition(
      code: code,
      order: _readInt(map['order'], fallback: code),
      label: _readOptionalString(map['label'] ?? map['name'] ?? map['title']),
      labelKey: _readOptionalString(map['labelKey'] ?? map['l10nKey']),
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static String? _readOptionalString(Object? value) {
    if (value == null) return null;
    final String trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Loads selectable player positions from Firestore `config/playerPositions`.
///
/// Expected schema:
/// ```json
/// {
///   "positions": [
///     { "code": 1, "order": 1, "labelKey": "positionGoalkeeper" },
///     { "code": 2, "order": 2, "labelKey": "positionCenterBack" }
///   ]
/// }
/// ```
///
/// Label resolution order: Firestore `label`, then `labelKey` → l10n, then
/// legacy [playerPositionLabel] by code, then [AppLocalizations.entityPlayer].
///
/// When the document is missing, [defaultGrintaPlayerPositionEntries] is used.
class PlayerPositionsService {
  PlayerPositionsService._();

  static final PlayerPositionsService instance = PlayerPositionsService._();

  static const String collectionName = 'config';
  static const String documentId = 'playerPositions';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PlayerPositionDefinition> _positions = _defaultDefinitions();
  Map<int, PlayerPositionDefinition> _positionsByCode = _indexByCode(
    _defaultDefinitions(),
  );
  bool _initialized = false;
  Future<void>? _initFuture;

  List<PlayerPositionDefinition> get positions =>
      List<PlayerPositionDefinition>.unmodifiable(_positions);

  List<int> get selectableCodes =>
      _positions.map((position) => position.code).toList(growable: false);

  bool get isInitialized => _initialized;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
  }

  Future<void> _load() async {
    var resolved = _defaultDefinitions();

    try {
      final doc =
          await _firestore.collection(collectionName).doc(documentId).get();
      if (doc.exists) {
        resolved = _parseDocument(doc.data());
      } else if (kDebugMode) {
        debugPrint(
          'PlayerPositionsService: $collectionName/$documentId missing — '
          'using built-in defaults',
        );
      }
    } catch (e, st) {
      debugPrint('PlayerPositionsService load failed: $e\n$st');
    }

    _positions = resolved;
    _positionsByCode = _indexByCode(resolved);
    _initialized = true;
  }

  List<PlayerPositionDefinition> _parseDocument(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return _defaultDefinitions();
    }

    final dynamic raw = data['positions'] ?? data['items'] ?? data['values'];
    if (raw is! List || raw.isEmpty) {
      return _defaultDefinitions();
    }

    final parsed = <PlayerPositionDefinition>[];
    for (final dynamic entry in raw) {
      if (entry is Map) {
        parsed.add(
          PlayerPositionDefinition.fromMap(Map<String, dynamic>.from(entry)),
        );
      } else {
        final int code = _readPositionCode(entry);
        if (code > 0) {
          parsed.add(PlayerPositionDefinition(code: code, order: code));
        }
      }
    }

    if (parsed.isEmpty) {
      return _defaultDefinitions();
    }

    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed;
  }

  static List<PlayerPositionDefinition> _defaultDefinitions() {
    return defaultGrintaPlayerPositionEntries
        .map(
          (entry) => PlayerPositionDefinition.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  static Map<int, PlayerPositionDefinition> _indexByCode(
    List<PlayerPositionDefinition> positions,
  ) {
    return {
      for (final PlayerPositionDefinition position in positions)
        position.code: position,
    };
  }

  String labelForCode(int code, AppLocalizations l10n) {
    final PlayerPositionDefinition? definition = _positionsByCode[code];

    final String? firestoreLabel = definition?.label?.trim();
    if (firestoreLabel != null && firestoreLabel.isNotEmpty) {
      return firestoreLabel;
    }

    final String? keyLabel =
        playerPositionLabelFromKey(definition?.labelKey, l10n);
    if (keyLabel != null && keyLabel.isNotEmpty) {
      return keyLabel;
    }

    final String legacyLabel = playerPositionLabel(code, l10n);
    if (legacyLabel != l10n.entityPlayer) {
      return legacyLabel;
    }

    if (definition == null && kDebugMode) {
      debugPrint('PlayerPositionsService: unknown position code $code');
    }
    return l10n.entityPlayer;
  }

  static int _readPositionCode(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String labelsForCodes(List<int> codes, AppLocalizations l10n) {
    if (codes.isEmpty) {
      return '';
    }

    return codes.map((code) => labelForCode(code, l10n)).join(', ');
  }
}
