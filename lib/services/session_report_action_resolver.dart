import 'package:grinta/model/chat_action.dart';
import 'package:grinta/services/session_report_chat_context.dart';

/// Outcome of resolving a session PDF report request from Ask Gio context.
class SessionReportResolveResult {
  const SessionReportResolveResult({
    this.action,
    this.failureReason,
  });

  final ChatSendReportAction? action;

  /// Machine reason when [action] is null:
  /// `not_intent`, `missing_context`, `no_stats`, `no_email`, `no_event`.
  final String? failureReason;

  bool get canSend => action != null;
}

/// Picks a [ChatSendReportAction] from Ask Gio `sessionReports` context.
///
/// Used when Gemini does not emit `send_report` (old Cloud Function prompt)
/// but the user clearly asked for a PDF session report.
abstract final class SessionReportActionResolver {
  static SessionReportResolveResult resolveDetailed({
    required Map<String, dynamic> appContext,
    required String userMessage,
  }) {
    if (!SessionReportChatContext.detectsSessionReportIntent(userMessage)) {
      return const SessionReportResolveResult(failureReason: 'not_intent');
    }

    final reports = appContext['sessionReports'];
    if (reports is! Map) {
      return const SessionReportResolveResult(failureReason: 'missing_context');
    }

    final sessionsRaw = reports['sessions'];
    if (sessionsRaw is! List) {
      return const SessionReportResolveResult(failureReason: 'no_stats');
    }

    final sessions = sessionsRaw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) => entry['hasStats'] == true)
        .toList();

    if (sessions.isEmpty) {
      final reason = reports['dataUnavailableReason']?.toString();
      return SessionReportResolveResult(
        failureReason: reason == 'no_sessions_in_period'
            ? 'no_sessions'
            : 'no_stats',
      );
    }

    final preferredType = _preferredEventType(userMessage);
    var candidates = List<Map<String, dynamic>>.from(sessions);

    if (preferredType != null) {
      final typed = candidates
          .where((s) => (s['type']?.toString() ?? '') == preferredType)
          .toList();
      if (typed.isNotEmpty) {
        candidates = typed;
      }
    }

    final teamMatched = candidates.where((s) {
      return _sessionMatchesTeam(s, userMessage);
    }).toList();
    if (teamMatched.isNotEmpty) {
      candidates = teamMatched;
    }

    final chosen = candidates.last;
    final eventId = (chosen['eventId'] ?? '').toString().trim();
    if (eventId.isEmpty) {
      return const SessionReportResolveResult(failureReason: 'no_event');
    }

    final email = SessionReportChatContext.extractEmailFromMessage(userMessage) ??
        _readNonEmpty(reports['requestedEmail']) ??
        _readNonEmpty(reports['defaultEmail']);

    if (email == null) {
      return const SessionReportResolveResult(failureReason: 'no_email');
    }

    final eventType = (chosen['type'] ?? 'training').toString();
    return SessionReportResolveResult(
      action: ChatSendReportAction(
        params: <String, dynamic>{
          'eventId': eventId,
          'eventType': eventType,
          'email': email,
        },
      ),
    );
  }

  static ChatSendReportAction? resolve({
    required Map<String, dynamic> appContext,
    required String userMessage,
  }) {
    return resolveDetailed(
      appContext: appContext,
      userMessage: userMessage,
    ).action;
  }

  static bool _sessionMatchesTeam(
    Map<String, dynamic> session,
    String userMessage,
  ) {
    final normalizedMessage = _normalize(userMessage);
    final teamName = _normalize((session['teamName'] ?? '').toString());
    final title = _normalize((session['title'] ?? '').toString());

    if (teamName.isNotEmpty && normalizedMessage.contains(teamName)) {
      return true;
    }
    if (title.isNotEmpty && normalizedMessage.contains(title)) {
      return true;
    }

    // Match compact forms like "seniors1" inside "seniors 1".
    final compactTeam = teamName.replaceAll(RegExp(r'\s+'), '');
    final compactMessage = normalizedMessage.replaceAll(RegExp(r'\s+'), '');
    if (compactTeam.length >= 3 && compactMessage.contains(compactTeam)) {
      return true;
    }
    return false;
  }

  static String? _preferredEventType(String message) {
    final normalized = message.toLowerCase();
    final wantsMatch =
        RegExp(r'\bmatchs?\b|\brencontres?\b').hasMatch(normalized);
    final wantsTraining = RegExp(
      r'\b(?:seance|séance|session|entrainements?|entraînements?|trainings?)\b',
    ).hasMatch(normalized);
    if (wantsMatch && !wantsTraining) return 'match';
    if (wantsTraining && !wantsMatch) return 'training';
    return null;
  }

  static String? _readNonEmpty(Object? value) {
    final trimmed = value?.toString().trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
