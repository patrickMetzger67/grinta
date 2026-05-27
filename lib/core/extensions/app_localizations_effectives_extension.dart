import 'package:grinta/l10n/app_localizations.dart';

extension AppLocalizationsEffectives on AppLocalizations {
  String positionLabel(int position) {
    switch (position) {
      case 1:
        return positionEducator;
      case 2:
        return positionExecutive;
      case 3:
        return positionGoalkeeper;
      case 4:
        return positionDefender;
      case 5:
        return positionMidfielder;
      case 6:
        return positionForward;
      case 0:
      default:
        return entityPlayer;
    }
  }

  String staffRoleLabel(int type) {
    switch (type) {
      case 0:
        return entityPlayer;
      case 1:
        return roleCoach;
      case 2:
        return roleExecutive;
      default:
        return entityStaff;
    }
  }
}
