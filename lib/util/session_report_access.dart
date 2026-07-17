import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/user_root_service.dart';

/// Whether the current user may generate/send a session PDF report.
///
/// Allowed for platform root and managers of [teamId] (or when
/// [canManageEvent] is already true for the match/training).
bool canSendSessionPdfReport({
  required AppSession session,
  String? teamId,
  bool canManageEvent = false,
}) {
  if (UserRootService.instance.isRoot) {
    return true;
  }
  if (canManageEvent) {
    return true;
  }

  final String safeTeamId = teamId?.trim() ?? '';
  if (safeTeamId.isEmpty) {
    return false;
  }

  return session.managedTeamsIdsForSelectedSeason.contains(safeTeamId);
}
