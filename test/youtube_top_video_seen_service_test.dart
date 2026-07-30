import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/youtube_top_video_seen_service.dart';

void main() {
  group('YoutubeTopVideoSeenService date helpers', () {
    test('formatLocalDate pads year month day', () {
      expect(
        YoutubeTopVideoSeenService.formatLocalDate(DateTime(2026, 7, 9)),
        '2026-07-09',
      );
    });

    test('parseLocalDate round-trips', () {
      final parsed = YoutubeTopVideoSeenService.parseLocalDate('2026-07-31');
      expect(parsed, DateTime(2026, 7, 31));
      expect(YoutubeTopVideoSeenService.parseLocalDate('bad'), isNull);
    });
  });

  group('YoutubeTopVideoSeenService.shouldShow', () {
    late YoutubeTopVideoSeenService service;

    setUp(() {
      service = YoutubeTopVideoSeenService.instance;
      service.nowLocal = () => DateTime(2026, 7, 30, 15, 0);
      service.debugSetSlotState(slot: YoutubePromptSlot.topVideo);
      service.debugSetSlotState(slot: YoutubePromptSlot.welcomePlayer);
      service.debugSetSlotState(slot: YoutubePromptSlot.welcomeCoach);
    });

    test('shows unseen video', () {
      expect(service.shouldShow('abc12345678'), isTrue);
    });

    test('hides permanently seen video', () {
      service.debugSetSlotState(
        slot: YoutubePromptSlot.topVideo,
        seenId: 'abc12345678',
      );
      expect(service.shouldShow('abc12345678'), isFalse);
    });

    test('hides snoozed video until tomorrow', () {
      service.debugSetSlotState(
        slot: YoutubePromptSlot.topVideo,
        snoozeId: 'abc12345678',
        snoozeUntilDate: '2026-07-31',
      );
      expect(service.shouldShow('abc12345678'), isFalse);

      service.nowLocal = () => DateTime(2026, 7, 31, 8, 0);
      expect(service.shouldShow('abc12345678'), isTrue);
    });

    test('welcome slots are independent from topVideo', () {
      service.debugSetSlotState(
        slot: YoutubePromptSlot.topVideo,
        seenId: 'same1111111',
      );
      expect(
        service.shouldShow(
          'same1111111',
          slot: YoutubePromptSlot.welcomePlayer,
        ),
        isTrue,
      );
    });
  });
}
