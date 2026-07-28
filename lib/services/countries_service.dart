import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Default country code when [Team.country] is empty.
const String kDefaultCountryCode = 'FR';

/// Country entry from Firestore `config/countries`.
class CountryDefinition {
  const CountryDefinition({
    required this.code,
    required this.available,
    required this.names,
    this.flagUrl,
  });

  final String code;
  final bool available;
  final Map<String, String> names;
  final String? flagUrl;

  String labelForLocale(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    final direct = names[language]?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final fr = names['fr']?.trim();
    if (fr != null && fr.isNotEmpty) return fr;
    final en = names['en']?.trim();
    if (en != null && en.isNotEmpty) return en;
    return code;
  }

  factory CountryDefinition.fromMap(Map<String, dynamic> map) {
    final names = <String, String>{};
    final rawNames = map['names'] ?? map['labels'] ?? map['name'];
    if (rawNames is Map) {
      for (final entry in rawNames.entries) {
        final key = entry.key.toString().trim().toLowerCase();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          names[key] = value;
        }
      }
    }

    final code = (map['code'] ?? map['id'] ?? '').toString().trim().toUpperCase();
    final flagUrl = (map['flagUrl'] ?? map['flag'] ?? '').toString().trim();

    return CountryDefinition(
      code: code,
      available: map['available'] == true,
      names: names,
      flagUrl: flagUrl.isEmpty ? null : flagUrl,
    );
  }
}

/// Loads available countries from Firestore `config/countries`.
///
/// Expected schema:
/// ```json
/// {
///   "countries": [
///     {
///       "code": "FR",
///       "available": true,
///       "flagUrl": "https://...",
///       "names": { "fr": "France", "en": "France", ... }
///     }
///   ]
/// }
/// ```
class CountriesService {
  CountriesService._();

  static final CountriesService instance = CountriesService._();

  static const String collectionName = 'config';
  static const String documentId = 'countries';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CountryDefinition> _countries = _defaultCountries();
  bool _initialized = false;
  Future<void>? _initFuture;

  List<CountryDefinition> get countries =>
      List<CountryDefinition>.unmodifiable(_countries);

  bool get isInitialized => _initialized;

  Future<void> ensureInitialized() {
    return _initFuture ??= _load();
  }

  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
  }

  Future<void> _load() async {
    try {
      final snap = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();
      if (!snap.exists) {
        _countries = _defaultCountries();
        _initialized = true;
        return;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final raw = data['countries'];
      if (raw is! List) {
        _countries = _defaultCountries();
        _initialized = true;
        return;
      }
      final parsed = <CountryDefinition>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final country = CountryDefinition.fromMap(
          Map<String, dynamic>.from(entry),
        );
        if (country.code.isEmpty) continue;
        parsed.add(country);
      }
      _countries = parsed.isEmpty ? _defaultCountries() : parsed;
      _initialized = true;
    } catch (e, st) {
      debugPrint('CountriesService load failed: $e\n$st');
      _countries = _defaultCountries();
      _initialized = true;
    }
  }

  CountryDefinition? byCode(String? code) {
    final normalized = normalizeCountryCode(code);
    for (final country in _countries) {
      if (country.code == normalized) return country;
    }
    return null;
  }

  /// Available countries sorted by localized name.
  List<CountryDefinition> availableSorted(Locale locale) {
    final list = _countries.where((c) => c.available).toList();
    list.sort(
      (a, b) => a
          .labelForLocale(locale)
          .toLowerCase()
          .compareTo(b.labelForLocale(locale).toLowerCase()),
    );
    return list;
  }

  /// Normalizes empty / null to [kDefaultCountryCode] (France).
  static String normalizeCountryCode(String? code) {
    final trimmed = code?.trim().toUpperCase() ?? '';
    if (trimmed.isEmpty) return kDefaultCountryCode;
    return trimmed;
  }

  static List<CountryDefinition> _defaultCountries() {
    return const [
      CountryDefinition(
        code: 'FR',
        available: true,
        flagUrl:
            'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/flags%2FFR.png?alt=media',
        names: {
          'fr': 'France',
          'en': 'France',
          'de': 'Frankreich',
          'es': 'Francia',
          'it': 'Francia',
        },
      ),
      CountryDefinition(
        code: 'DE',
        available: false,
        flagUrl:
            'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/flags%2FDE.png?alt=media',
        names: {
          'fr': 'Allemagne',
          'en': 'Germany',
          'de': 'Deutschland',
          'es': 'Alemania',
          'it': 'Germania',
        },
      ),
      CountryDefinition(
        code: 'IT',
        available: false,
        flagUrl:
            'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/flags%2FIT.png?alt=media',
        names: {
          'fr': 'Italie',
          'en': 'Italy',
          'de': 'Italien',
          'es': 'Italia',
          'it': 'Italia',
        },
      ),
      CountryDefinition(
        code: 'ES',
        available: false,
        flagUrl:
            'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/flags%2FES.png?alt=media',
        names: {
          'fr': 'Espagne',
          'en': 'Spain',
          'de': 'Spanien',
          'es': 'España',
          'it': 'Spagna',
        },
      ),
      CountryDefinition(
        code: 'CH',
        available: false,
        flagUrl:
            'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/flags%2FCH.png?alt=media',
        names: {
          'fr': 'Suisse',
          'en': 'Switzerland',
          'de': 'Schweiz',
          'es': 'Suiza',
          'it': 'Svizzera',
        },
      ),
    ];
  }
}
