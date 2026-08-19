/// Custom Grinta chat poll stored on a Stream message (`extraData`).
const String kChatPollExtraFlag = 'grinta_poll';
const String kChatPollIdKey = 'grinta_poll_id';
const String kChatPollAllowMultipleKey = 'grinta_poll_allow_multiple';
const String kChatPollResultsVisibleKey = 'grinta_poll_results_visible';
const String kChatPollCreatedByKey = 'grinta_poll_created_by';
const String kChatPollOptionsKey = 'grinta_poll_options';

const int kChatPollMinOptions = 2;
const int kChatPollMaxOptions = 10;

class ChatPollOption {
  const ChatPollOption({
    required this.id,
    this.text = '',
    this.imageUrl,
  });

  final String id;
  final String text;
  final String? imageUrl;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;
  bool get isValid => hasText || hasImage;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      if (hasText) 'text': text.trim(),
      if (hasImage) 'image': imageUrl!.trim(),
    };
  }
}

class ChatPollData {
  const ChatPollData({
    required this.id,
    required this.question,
    required this.options,
    required this.allowMultiple,
    required this.resultsVisible,
    required this.createdBy,
  });

  final String id;
  final String question;
  final List<ChatPollOption> options;
  final bool allowMultiple;
  final bool resultsVisible;
  final String createdBy;

  List<String> get optionIds =>
      options.map((option) => option.id).toList(growable: false);
}

class ChatPollVoteTally {
  const ChatPollVoteTally({
    required this.userVotes,
    required this.optionVoters,
  });

  /// `uid → selected option ids`
  final Map<String, List<String>> userVotes;

  /// `optionId → voter uids`
  final Map<String, List<String>> optionVoters;

  int countFor(String optionId) => optionVoters[optionId]?.length ?? 0;

  int get voterCount => userVotes.length;

  int get totalVotes =>
      optionVoters.values.fold<int>(0, (sum, voters) => sum + voters.length);

  Set<String> selectedBy(String? uid) {
    final trimmed = uid?.trim() ?? '';
    if (trimmed.isEmpty) return const {};
    return {...?userVotes[trimmed]};
  }

  double ratioFor(String optionId) {
    if (totalVotes <= 0) return 0;
    return countFor(optionId) / totalVotes;
  }
}

bool readChatPollFlag(Object? value) {
  if (value == true) return true;
  if (value is String) return value.trim().toLowerCase() == 'true';
  return false;
}

bool isGrintaPollExtra(Map<String, Object?> extraData) {
  return readChatPollFlag(extraData[kChatPollExtraFlag]);
}

bool isGrintaPollMessage(Map<String, Object?> extraData) {
  return isGrintaPollExtra(extraData) &&
      (extraData[kChatPollIdKey]?.toString().trim().isNotEmpty ?? false);
}

String? firstNonEmptyPollText(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

ChatPollOption? parseChatPollOption(Object? raw) {
  if (raw is! Map) return null;
  final map = Map<String, Object?>.from(raw);
  final id = firstNonEmptyPollText([
    map['id']?.toString(),
    map['optionId']?.toString(),
  ]);
  if (id == null) return null;
  final text = (map['text'] ?? map['label'] ?? '').toString();
  final image = firstNonEmptyPollText([
    map['image']?.toString(),
    map['imageUrl']?.toString(),
  ]);
  return ChatPollOption(id: id, text: text, imageUrl: image);
}

List<ChatPollOption> parseChatPollOptions(Object? raw) {
  if (raw is! List) return const [];
  final options = <ChatPollOption>[];
  for (final entry in raw) {
    final option = parseChatPollOption(entry);
    if (option == null || !option.isValid) continue;
    options.add(option);
  }
  return options;
}

ChatPollData? parseChatPollData({
  required Map<String, Object?> extraData,
  String? fallbackQuestion,
}) {
  if (!isGrintaPollExtra(extraData)) return null;
  final id = extraData[kChatPollIdKey]?.toString().trim() ?? '';
  if (id.isEmpty) return null;
  final options = parseChatPollOptions(extraData[kChatPollOptionsKey]);
  if (options.length < kChatPollMinOptions) return null;
  final question = firstNonEmptyPollText([
        extraData['question']?.toString(),
        fallbackQuestion,
      ]) ??
      '';
  if (question.isEmpty) return null;
  final createdBy = extraData[kChatPollCreatedByKey]?.toString().trim() ?? '';
  return ChatPollData(
    id: id,
    question: question,
    options: options,
    allowMultiple: readChatPollFlag(extraData[kChatPollAllowMultipleKey]),
    resultsVisible: readChatPollFlag(extraData[kChatPollResultsVisibleKey]),
    createdBy: createdBy,
  );
}

Map<String, Object?> buildChatPollExtraData({
  required ChatPollData poll,
}) {
  return {
    kChatPollExtraFlag: true,
    kChatPollIdKey: poll.id,
    kChatPollAllowMultipleKey: poll.allowMultiple,
    kChatPollResultsVisibleKey: poll.resultsVisible,
    kChatPollCreatedByKey: poll.createdBy,
    'question': poll.question,
    kChatPollOptionsKey: poll.options.map((option) => option.toMap()).toList(),
  };
}

bool isValidPollOption({
  String? text,
  String? imageUrl,
  bool hasImageBytes = false,
}) {
  return (text?.trim().isNotEmpty ?? false) ||
      hasImageBytes ||
      (imageUrl?.trim().isNotEmpty ?? false);
}

/// Returns a stable error code: `questionRequired` or `optionsMin`.
String? validateChatPoll({
  required String question,
  required int validOptionCount,
}) {
  if (question.trim().isEmpty) return 'questionRequired';
  if (validOptionCount < kChatPollMinOptions) return 'optionsMin';
  return null;
}

bool canSeeChatPollResults({
  required bool resultsVisible,
  required String createdBy,
  required String? currentUserId,
}) {
  final uid = currentUserId?.trim() ?? '';
  if (uid.isNotEmpty && uid == createdBy.trim()) return true;
  return resultsVisible;
}

List<String> normalizePollVote({
  required Iterable<String> selectedOptionIds,
  required Iterable<String> validOptionIds,
  required bool allowMultiple,
  String? toggledOptionId,
}) {
  final valid = validOptionIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  var selected = selectedOptionIds
      .map((id) => id.trim())
      .where(valid.contains)
      .toList();

  final toggled = toggledOptionId?.trim() ?? '';
  if (toggled.isEmpty || !valid.contains(toggled)) {
    return allowMultiple ? selected : selected.take(1).toList();
  }

  if (allowMultiple) {
    if (selected.contains(toggled)) {
      selected = [...selected.where((id) => id != toggled)];
    } else {
      selected = [...selected, toggled];
    }
    return selected;
  }
  return [toggled];
}

/// Reorder helper for [ReorderableListView.onReorder] (newIndex is unadjusted).
List<T> reorderChatPollOptions<T>(
  List<T> items,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= items.length) return List<T>.from(items);
  var target = newIndex;
  if (oldIndex < target) target -= 1;
  final next = List<T>.from(items);
  final item = next.removeAt(oldIndex);
  if (target < 0) target = 0;
  if (target > next.length) target = next.length;
  next.insert(target, item);
  return next;
}

ChatPollVoteTally tallyChatPollVotes({
  required Map<String, List<String>> userVotes,
  required Iterable<String> optionIds,
}) {
  final optionVoters = <String, List<String>>{
    for (final id in optionIds) id: <String>[],
  };
  final sanitizedUserVotes = <String, List<String>>{};
  for (final entry in userVotes.entries) {
    final uid = entry.key.trim();
    if (uid.isEmpty) continue;
    final selected = entry.value
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && optionVoters.containsKey(id))
        .toList();
    if (selected.isEmpty) continue;
    sanitizedUserVotes[uid] = selected;
    for (final optionId in selected) {
      optionVoters[optionId]!.add(uid);
    }
  }
  return ChatPollVoteTally(
    userVotes: sanitizedUserVotes,
    optionVoters: optionVoters,
  );
}
