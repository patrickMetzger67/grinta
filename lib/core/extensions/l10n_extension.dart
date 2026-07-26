import 'package:flutter/widgets.dart';
import 'package:grinta/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension TrackerOwnerTypeL10n on AppLocalizations {
  String adminTrackerOwnerTypeLabel(String type) {
    switch (type) {
      case 'inspirit':
        return adminTrackerOwnerTypeInspirit;
      case 'footbar':
        return adminTrackerOwnerTypeFootbar;
      case 'intense':
        return adminTrackerOwnerTypeIntense;
      case 'polar':
        return adminTrackerOwnerTypePolar;
      default:
        return type;
    }
  }
}