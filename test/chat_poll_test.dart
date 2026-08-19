import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/chat_poll.dart';

void main() {
  group('parseChatPollData', () {
    test('reads a text-and-image poll from Stream extraData', () {
      final poll = parseChatPollData(
        extraData: {
          kChatPollExtraFlag: true,
          kChatPollIdKey: 'poll_1',
          kChatPollAllowMultipleKey: true,
          kChatPollResultsVisibleKey: 'true',
          kChatPollCreatedByKey: 'alice',
          'question': 'Qui joue ?',
          kChatPollOptionsKey: [
            {'id': 'a', 'text': 'Samedi'},
            {'id': 'b', 'image': 'https://example.com/b.jpg'},
          ],
        },
      );

      expect(poll, isNotNull);
      expect(poll!.question, 'Qui joue ?');
      expect(poll.allowMultiple, isTrue);
      expect(poll.resultsVisible, isTrue);
      expect(poll.options[0].hasText, isTrue);
      expect(poll.options[1].hasImage, isTrue);
    });

    test('rejects a payload without the Grinta flag or two options', () {
      expect(
        parseChatPollData(
          extraData: {
            kChatPollIdKey: 'poll_1',
            kChatPollOptionsKey: [
              {'id': 'a', 'text': 'A'},
              {'id': 'b', 'text': 'B'},
            ],
          },
          fallbackQuestion: 'Q',
        ),
        isNull,
      );
      expect(
        parseChatPollData(
          extraData: {
            kChatPollExtraFlag: true,
            kChatPollIdKey: 'poll_1',
            kChatPollOptionsKey: [
              {'id': 'a', 'text': 'A'},
            ],
          },
          fallbackQuestion: 'Q',
        ),
        isNull,
      );
    });
  });

  group('validateChatPoll', () {
    test('requires a question and two valid options', () {
      expect(validateChatPoll(question: '', validOptionCount: 2), 'questionRequired');
      expect(validateChatPoll(question: 'Q', validOptionCount: 1), 'optionsMin');
      expect(validateChatPoll(question: 'Q', validOptionCount: 2), isNull);
    });

    test('accepts an image-only option', () {
      expect(
        isValidPollOption(text: '', imageUrl: 'https://x/a.jpg'),
        isTrue,
      );
      expect(isValidPollOption(text: 'Oui', hasImageBytes: false), isTrue);
      expect(isValidPollOption(text: '  ', hasImageBytes: false), isFalse);
    });
  });

  group('canSeeChatPollResults', () {
    test('always shows results to the author', () {
      expect(
        canSeeChatPollResults(
          resultsVisible: false,
          createdBy: 'alice',
          currentUserId: 'alice',
        ),
        isTrue,
      );
    });

    test('shows results to members only when the setting is on', () {
      expect(
        canSeeChatPollResults(
          resultsVisible: true,
          createdBy: 'alice',
          currentUserId: 'bob',
        ),
        isTrue,
      );
      expect(
        canSeeChatPollResults(
          resultsVisible: false,
          createdBy: 'alice',
          currentUserId: 'bob',
        ),
        isFalse,
      );
    });
  });

  group('normalizePollVote', () {
    test('replaces the choice when multiple answers are off', () {
      expect(
        normalizePollVote(
          selectedOptionIds: ['a'],
          validOptionIds: ['a', 'b'],
          allowMultiple: false,
          toggledOptionId: 'b',
        ),
        ['b'],
      );
    });

    test('toggles extra choices when multiple answers are on', () {
      expect(
        normalizePollVote(
          selectedOptionIds: ['a'],
          validOptionIds: ['a', 'b', 'c'],
          allowMultiple: true,
          toggledOptionId: 'c',
        ),
        ['a', 'c'],
      );
      expect(
        normalizePollVote(
          selectedOptionIds: ['a', 'c'],
          validOptionIds: ['a', 'b', 'c'],
          allowMultiple: true,
          toggledOptionId: 'a',
        ),
        ['c'],
      );
    });
  });

  group('reorderChatPollOptions', () {
    test('moves an option down and up', () {
      expect(reorderChatPollOptions(['a', 'b', 'c'], 0, 1), ['b', 'a', 'c']);
      expect(reorderChatPollOptions(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
    });
  });

  group('tallyChatPollVotes', () {
    test('counts voters and option totals', () {
      final tally = tallyChatPollVotes(
        userVotes: {
          'u1': ['a'],
          'u2': ['a', 'b'],
        },
        optionIds: ['a', 'b'],
      );
      expect(tally.countFor('a'), 2);
      expect(tally.countFor('b'), 1);
      expect(tally.voterCount, 2);
      expect(tally.totalVotes, 3);
      expect(tally.selectedBy('u2'), {'a', 'b'});
    });
  });
}
