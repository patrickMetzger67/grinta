import 'package:grinta/services/eshop_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which monetization banner to show on home tabs for non-subscribers.
enum MonetizationBannerKind {
  trialStatus,
  subscription,
  shopPromo,
}

/// Persists visit counter so subscription and shop promo banners alternate.
class MonetizationBannerRotationService {
  MonetizationBannerRotationService._();

  static final MonetizationBannerRotationService instance =
      MonetizationBannerRotationService._();

  static const _visitCountKey = 'monetization_banner_visit_count';

  int _visitCount = 0;
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _visitCount = prefs.getInt(_visitCountKey) ?? 0;
    _initialized = true;
  }

  /// Increments visit counter and returns the new count.
  Future<int> recordVisit() async {
    await ensureInitialized();
    _visitCount += 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_visitCountKey, _visitCount);
    return _visitCount;
  }

  /// Banner kind for the current visit count (call after [recordVisit]).
  MonetizationBannerKind bannerKindForCurrentVisit() {
    if (!EshopConfigService.instance.isOpen) {
      return MonetizationBannerKind.subscription;
    }
    return _visitCount.isEven
        ? MonetizationBannerKind.subscription
        : MonetizationBannerKind.shopPromo;
  }

  /// Product index for rotating promo items within the current visit.
  int promoProductIndex(int productCount) {
    if (productCount <= 0) return 0;
    return (_visitCount - 1) % productCount;
  }
}
