import 'package:flutter/foundation.dart';
import '../model/season.dart';
import '../services/seasonService.dart';

class CurrentSeasonProvider extends ChangeNotifier {
  final SeasonService _seasonService = SeasonService();

  Season? _currentSeason;
  bool _isLoading = false;

  Season? get currentSeason => _currentSeason;
  bool get isLoading => _isLoading;

  String? get currentSeasonName => _currentSeason?.name;
  String? get currentClubName => _currentSeason?.clubName;
  String? get currentAffiliateNumber => _currentSeason?.affiliateNumber;

  Future<void> loadCurrentSeason() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSeason = await _seasonService.getCurrentSeason();
    } catch (e) {
      debugPrint('Erreur loadCurrentSeason: $e');
      _currentSeason = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSeason(Season? season) {
    _currentSeason = season;
    notifyListeners();
  }

  void clear() {
    _currentSeason = null;
    notifyListeners();
  }
}