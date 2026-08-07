import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Gère la fermeture du bottom sheet de connexion mobile pendant le flux social,
/// et indique si la création / validation du profil membre est en cours.
class SocialOnboardingCoordinator extends ChangeNotifier {
  SocialOnboardingCoordinator._();

  static final SocialOnboardingCoordinator instance =
      SocialOnboardingCoordinator._();

  VoidCallback? _closeLoginSheet;
  bool _profileOnboardingActive = false;

  /// True while invitation / member profile steps run after Auth signup.
  /// Welcome / tip videos must not show during this window.
  bool get isProfileOnboardingActive => _profileOnboardingActive;

  void beginProfileOnboarding() {
    if (_profileOnboardingActive) return;
    _profileOnboardingActive = true;
    debugPrint('social_onboarding: profile onboarding began');
    notifyListeners();
  }

  void endProfileOnboarding() {
    if (!_profileOnboardingActive) return;
    _profileOnboardingActive = false;
    debugPrint('social_onboarding: profile onboarding ended');
    notifyListeners();
  }

  void registerLoginSheetCloser(VoidCallback close) {
    _closeLoginSheet = close;
  }

  void unregisterLoginSheetCloser() {
    _closeLoginSheet = null;
  }

  void dismissLoginSheet() {
    debugPrint('social_onboarding: dismiss bottom sheet attempted');
    final close = _closeLoginSheet;
    _closeLoginSheet = null;
    close?.call();
  }

  /// Ferme le sheet si un closer est enregistré. Retourne true si fermé.
  bool tryDismissLoginSheet() {
    if (_closeLoginSheet == null) return false;
    dismissLoginSheet();
    return true;
  }
}
