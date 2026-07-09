import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Remote e-shop feature flags from Firestore `config/eshop`.
///
/// ## Firestore schema
/// Document: `config/eshop`
/// ```json
/// {
///   "isOpen": false,
///   "commerceNotificationsEnabled": false
/// }
/// ```
///
/// Edit this document in the Firebase console to change shop visibility and
/// commerce notifications without redeploying the app.
class EshopConfig {
  const EshopConfig({
    required this.isOpen,
    required this.commerceNotificationsEnabled,
  });

  static const EshopConfig defaults = EshopConfig(
    isOpen: false,
    commerceNotificationsEnabled: false,
  );

  final bool isOpen;
  final bool commerceNotificationsEnabled;

  factory EshopConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    return EshopConfig(
      isOpen: _readBool(data['isOpen']),
      commerceNotificationsEnabled:
          _readBool(data['commerceNotificationsEnabled']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    return false;
  }
}

/// Loads and streams `config/eshop` with cached defaults when missing.
class EshopConfigService extends ChangeNotifier {
  EshopConfigService._();

  static final EshopConfigService instance = EshopConfigService._();

  static const String collectionName = 'config';
  static const String documentId = 'eshop';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<EshopConfig> _configController =
      StreamController<EshopConfig>.broadcast();

  EshopConfig _config = EshopConfig.defaults;
  bool _initialized = false;
  Future<void>? _initFuture;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// Whether the e-shop / boutique is open for browsing and purchase.
  bool get isOpen => _config.isOpen;

  /// Whether commerce push, local, and in-app notifications are enabled.
  bool get commerceNotificationsEnabled =>
      _config.commerceNotificationsEnabled;

  EshopConfig get config => _config;

  bool get isInitialized => _initialized;

  /// Live stream of config updates (emits cached value after [ensureInitialized]).
  Stream<EshopConfig> get configStream => _configController.stream;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> reload() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
    notifyListeners();
  }

  Future<void> _load() async {
    await _subscription?.cancel();

    try {
      final docRef =
          _firestore.collection(collectionName).doc(documentId);
      final doc = await docRef.get();
      if (doc.exists) {
        _applyConfig(EshopConfig.fromMap(doc.data()), notify: false);
      } else if (kDebugMode) {
        debugPrint(
          'EshopConfigService: $collectionName/$documentId missing — '
          'using defaults',
        );
      }

      _subscription = docRef.snapshots().listen(
        (snapshot) {
          if (!snapshot.exists) return;
          _applyConfig(EshopConfig.fromMap(snapshot.data()));
        },
        onError: (Object e, StackTrace st) {
          debugPrint('EshopConfigService snapshot error: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('EshopConfigService load failed: $e\n$st');
    }

    _initialized = true;
    _configController.add(_config);
    notifyListeners();
    _logLoadedConfig();
  }

  void _applyConfig(EshopConfig next, {bool notify = true}) {
    if (_config.isOpen == next.isOpen &&
        _config.commerceNotificationsEnabled ==
            next.commerceNotificationsEnabled) {
      return;
    }
    _config = next;
    _configController.add(_config);
    if (notify) {
      notifyListeners();
      _logLoadedConfig();
    }
  }

  void _logLoadedConfig() {
    if (!kDebugMode) return;
    debugPrint(
      'EshopConfigService: isOpen=$isOpen, '
      'commerceNotificationsEnabled=$commerceNotificationsEnabled',
    );
  }
}
