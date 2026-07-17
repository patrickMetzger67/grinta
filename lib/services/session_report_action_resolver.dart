import 'package:grinta/model/chat_action.dart';
import 'package:grinta/services/session_report_chat_context.dart';

/// Picks a [ChatSendReportAction] from Ask Gio `sessionReports` context.
///
/// Used when Gemini does not emit `send_report` (old Cloud Function prompt)
/// but the user clearly asked for a PDF session report.
abstract final class SessionReportActionResolver {
  static ChatSendReportAction? resolve({
    required Map<String, dynamic> appContext,
    required String userMessage,
  }) {
    if (!SessionReportChatContext.detectsSessionReportIntent(userMessage)) {
      return null;
    }

    final reports = appContext['sessionReports'];
    if (reports is! Map) {
      return null;
    }

    final sessionsRaw = reports['sessions'];
    if (sessionsRaw is! List) {
      return null;
    }

    final sessions = sessionsRaw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) => entry['hasStats'] == true)
        .toList();

    if (sessions.isEmpty) {
      return null;
    }

    final preferredType = _preferredEventType(userMessage);
    final teamHint = _teamHint(userMessage);

    var candidates = List<Map<String, dynamic>>.from(sessions);
    if (preferredType != null) {
      final typed = candidates
          .where((s) => (s['type']?.toString() ?? '') == preferredType)
          .toList();
      if (typed.isNotEmpty) {
        candidates = typed;
      }
    }

    if (teamHint != null && teamHint.isNotEmpty) {
      final filtered = candidates.where((s) {
        final teamName = (s['teamName'] ?? '').toString().toLowerCase();
        final title = (s['title'] ?? '').toString().toLowerCase();
        return teamName.contains(teamHint) || title.contains(teamHint);
      }).toList();
      if (filtered.isNotEmpty) {
        candidates = filtered;
      }
    }

    final chosen = candidates.last;
    final eventId = (chosen['eventId'] ?? '').toString().trim();
    if (eventId.isEmpty) {
      return null;
    }

    final email = SessionReportChatContext.extractEmailFromMessage(userMessage) ??
        (reports['requestedEmail']?.toString().trim().isNotEmpty == true
            ? reports['requestedEmail'].toString().trim()
            : null) ??
        (reports['defaultEmail']?.toString().trim().isNotEmpty == true
            ? reports['defaultEmail'].toString().trim()
            : null);

    if (email == null || email.isEmpty) {
      return null;
    }

    final eventType = (chosen['type'] ?? 'training').toString();
    return ChatSendReportAction(
      params: <String, dynamic>{
        'eventId': eventId,
        'eventType': eventType,
        'email': email,
      },
    );
  }

  static String? _preferredEventType(String message) {
    final normalized = message.toLowerCase();
    final wantsMatch = RegExp(r'\bmatchs?\b|\brencontres?\b').hasMatch(normalized);
    final wantsTraining = RegExp(
      r'\b(?:seance|séance|session|entrainements?|entraînements?|trainings?)\b',
    ).hasMatch(normalized);
    if (wantsMatch && !wantsTraining) return 'match';
    if (wantsTraining && !wantsMatch) return 'training';
    return null;
  }

  static String? _teamHint(String message) {
    final match = RegExp(
      r"(?:equipe|équipe|team)\s+([a-zA-Z0-9À-ÿ][\wÀ-ÿ\s\-']{1,40})",
      caseSensitive: false,
    ).firstMatch(message);
    final raw = match?.group(1)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return raw
        .replaceAll(RegExp(r'[?!.,;:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
