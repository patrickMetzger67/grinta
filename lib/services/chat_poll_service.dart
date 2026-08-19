import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../util/chat_poll.dart';

const String kChatPollsCollection = 'chat_polls';
const String kChatPollVotesCollection = 'votes';

class ChatPollDraftOption {
  ChatPollDraftOption({
    String? id,
    this.text = '',
    this.imageBytes,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4().replaceAll('-', '');

  final String id;
  String text;
  Uint8List? imageBytes;
  String? imageUrl;

  bool get isValid => isValidPollOption(
        text: text,
        imageUrl: imageUrl,
        hasImageBytes: imageBytes != null && imageBytes!.isNotEmpty,
      );
}

/// Creates Grinta polls as Stream messages and stores live votes in Firestore.
class ChatPollService {
  ChatPollService._();

  static final ChatPollService instance = ChatPollService._();

  static const _uuid = Uuid();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<String?> uploadOptionImage({
    required String pollId,
    required String optionId,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) return null;
    final sanitizedPoll = pollId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final sanitizedOption =
        optionId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final path = 'thumbs/chat_poll_${sanitizedPoll}_$sanitizedOption.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<Message> createPoll({
    required Channel channel,
    required String currentUserId,
    required String question,
    required List<ChatPollDraftOption> options,
    required bool allowMultiple,
    required bool resultsVisible,
  }) async {
    final trimmedQuestion = question.trim();
    final validOptions = options.where((option) => option.isValid).toList();
    final error = validateChatPoll(
      question: trimmedQuestion,
      validOptionCount: validOptions.length,
    );
    if (error == 'questionRequired') {
      throw StateError('questionRequired');
    }
    if (error != null) {
      throw StateError('optionsMin');
    }

    final pollId = 'poll_${_uuid.v4().replaceAll('-', '')}';
    final resolved = <ChatPollOption>[];
    for (final option in validOptions.take(kChatPollMaxOptions)) {
      String? imageUrl = option.imageUrl?.trim();
      if (option.imageBytes != null && option.imageBytes!.isNotEmpty) {
        imageUrl = await uploadOptionImage(
          pollId: pollId,
          optionId: option.id,
          bytes: option.imageBytes!,
        );
      }
      resolved.add(
        ChatPollOption(
          id: option.id,
          text: option.text,
          imageUrl: imageUrl,
        ),
      );
    }

    final poll = ChatPollData(
      id: pollId,
      question: trimmedQuestion,
      options: resolved,
      allowMultiple: allowMultiple,
      resultsVisible: resultsVisible,
      createdBy: currentUserId.trim(),
    );

    final memberIds = <String>{
      currentUserId.trim(),
      ...?channel.state?.members
          .map((member) => member.userId)
          .whereType<String>(),
    }.where((id) => id.isNotEmpty).toList();

    final response = await channel.sendMessage(
      Message(
        text: trimmedQuestion,
        extraData: buildChatPollExtraData(poll: poll),
      ),
    );

    await _db.collection(kChatPollsCollection).doc(pollId).set({
      'channelCid': channel.cid,
      'messageId': response.message.id,
      'createdBy': poll.createdBy,
      'memberIds': memberIds,
      'question': poll.question,
      'allowMultiple': poll.allowMultiple,
      'resultsVisible': poll.resultsVisible,
      'options': poll.options.map((option) => option.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return response.message;
  }

  Future<void> castVote({
    required String pollId,
    required String userId,
    required List<String> optionIds,
  }) async {
    final trimmedPollId = pollId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedPollId.isEmpty || trimmedUserId.isEmpty) {
      throw StateError('missingVoteIdentity');
    }

    await _db
        .collection(kChatPollsCollection)
        .doc(trimmedPollId)
        .collection(kChatPollVotesCollection)
        .doc(trimmedUserId)
        .set({
      'optionIds': optionIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<ChatPollVoteTally> watchVotes({
    required String pollId,
    required Iterable<String> optionIds,
  }) {
    final trimmed = pollId.trim();
    if (trimmed.isEmpty) {
      return Stream<ChatPollVoteTally>.value(
        tallyChatPollVotes(userVotes: const {}, optionIds: optionIds),
      );
    }

    return _db
        .collection(kChatPollsCollection)
        .doc(trimmed)
        .collection(kChatPollVotesCollection)
        .snapshots()
        .map((snapshot) {
      final userVotes = <String, List<String>>{};
      for (final doc in snapshot.docs) {
        final raw = doc.data()['optionIds'];
        if (raw is! List) continue;
        userVotes[doc.id] = raw.map((value) => value.toString()).toList();
      }
      return tallyChatPollVotes(userVotes: userVotes, optionIds: optionIds);
    });
  }
}
