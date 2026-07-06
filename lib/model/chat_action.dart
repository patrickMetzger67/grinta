/// Parsed assistant action from Gemini (via Cloud Function).
///
/// New **navigation** routes require code here and in [ChatNavigationService].
/// New **question types** are added via prompt config + context — not new action classes.
sealed class ChatAction {
  const ChatAction();
}

class ChatAnswerAction extends ChatAction {
  const ChatAnswerAction({required this.text});

  final String text;
}

class ChatNavigateAction extends ChatAction {
  const ChatNavigateAction({
    required this.route,
    this.params = const <String, dynamic>{},
  });

  final String route;
  final Map<String, dynamic> params;
}

List<ChatAction> parseChatActions(dynamic raw) {
  if (raw is! Map) {
    return const <ChatAction>[];
  }

  final actions = raw['actions'];
  if (actions is! List) {
    return const <ChatAction>[];
  }

  final parsed = <ChatAction>[];

  for (final entry in actions) {
    if (entry is! Map) continue;

    final type = (entry['type'] ?? '').toString().toLowerCase();

    if (type == 'answer') {
      final text = (entry['text'] ?? '').toString().trim();
      if (text.isNotEmpty) {
        parsed.add(ChatAnswerAction(text: text));
      }
      continue;
    }

    if (type == 'navigate') {
      final route = (entry['route'] ?? '').toString().trim();
      if (route.isEmpty) continue;

      final paramsRaw = entry['params'];
      final params = paramsRaw is Map
          ? Map<String, dynamic>.from(paramsRaw)
          : const <String, dynamic>{};

      parsed.add(ChatNavigateAction(route: route, params: params));
    }
  }

  return parsed;
}

String? firstNavigateRoute(List<ChatAction> actions) {
  for (final action in actions) {
    if (action is ChatNavigateAction) {
      return action.route;
    }
  }
  return null;
}

String joinAnswerTexts(List<ChatAction> actions) {
  return actions
      .whereType<ChatAnswerAction>()
      .map((ChatAnswerAction a) => a.text)
      .join('\n\n')
      .trim();
}
