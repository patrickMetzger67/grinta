import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/util/staff_session_access.dart';

/// Whether the current user may generate/send a session PDF report.
///
/// Allowed for platform root, managers/owners, and roster staff of [teamId]
/// (or when [canManageEvent] is already true for the match/training).
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

  return canAccessTeamSessionDetails(session, teamId);
}
