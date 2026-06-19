import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Gère la fermeture du bottom sheet de connexion mobile pendant le flux social.
class SocialOnboardingCoordinator extends ChangeNotifier {
  SocialOnboardingCoordinator._();

  static final SocialOnboardingCoordinator instance =
      SocialOnboardingCoordinator._();

  VoidCallback? _closeLoginSheet;

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
