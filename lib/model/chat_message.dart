enum ChatMessageRole {
  user,
  assistant,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isLoading = false,
    this.navigationRoute,
    this.navigationParams = const <String, dynamic>{},
    this.navigationLabel,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final bool isLoading;

  /// Optional route suggested alongside this assistant message.
  final String? navigationRoute;
  final Map<String, dynamic> navigationParams;
  final String? navigationLabel;

  ChatMessage copyWith({
    String? id,
    ChatMessageRole? role,
    String? text,
    bool? isLoading,
    String? navigationRoute,
    Map<String, dynamic>? navigationParams,
    String? navigationLabel,
    bool clearNavigationRoute = false,
    bool clearNavigationLabel = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      isLoading: isLoading ?? this.isLoading,
      navigationRoute: clearNavigationRoute
          ? null
          : (navigationRoute ?? this.navigationRoute),
      navigationParams: navigationParams ?? this.navigationParams,
      navigationLabel: clearNavigationLabel
          ? null
          : (navigationLabel ?? this.navigationLabel),
    );
  }
}
