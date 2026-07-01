import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/player_positions.dart';

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

  /// Staff function from [Effectives.type] or Grinta staff [roleCode].
  ///
  /// Legacy goaltime: 2=entraineur, 3=dirigeant. Grinta staff add stores
  /// [positionCodeEducator]/[positionCodeExecutive]/[positionCodeMedical] as type.
  String staffRoleLabel(int type) {
    switch (type) {
      case 0:
        return entityPlayer;
      case positionCodeEducator:
        return grintaStaffRoleEducator;
      case positionCodeExecutive:
        return grintaStaffRoleExecutive;
      case 3:
        return grintaStaffRoleExecutive;
      case 4:
        return grintaStaffRoleEducator;
      case positionCodeMedical:
        return grintaStaffRoleMedical;
      default:
        return entityStaff;
    }
  }
}
