import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_group_channel.dart';

void main() {
  group('parseChatGroupColor', () {
    test('parses a 6-digit hex color', () {
      expect(parseChatGroupColor('#E67E22')?.toARGB32(), 0xFFE67E22);
    });

    test('returns null for invalid values', () {
      expect(parseChatGroupColor(''), isNull);
      expect(parseChatGroupColor('nope'), isNull);
    });

    test('round-trips any RGB color to #RRGGBB', () {
      const color = Color(0xFF1A2B3C);
      expect(colorToCssHex(color), '#1A2B3C');
      expect(parseChatGroupColor(colorToCssHex(color))?.toARGB32(), 0xFF1A2B3C);
    });
  });

  group('chatGroupInitials', () {
    test('uses two letters from a two-word name', () {
      expect(chatGroupInitials('Séniors 1'), 'S1');
    });

    test('falls back to G when empty', () {
      expect(chatGroupInitials('  '), 'G');
    });
  });

  group('canManageGrintaUserGroupData', () {
    test('requires the grinta group flag and the creator uid', () {
      expect(
        canManageGrintaUserGroupData(
          extraData: const {
            kChatGroupExtraFlag: true,
            kChatGroupCreatedByKey: 'creator',
          },
          currentUserId: 'creator',
        ),
        isTrue,
      );
      expect(
        canManageGrintaUserGroupData(
          extraData: const {
            kChatGroupExtraFlag: true,
            kChatGroupCreatedByKey: 'creator',
          },
          currentUserId: 'other',
        ),
        isFalse,
      );
      expect(
        canManageGrintaUserGroupData(
          extraData: const {'name': 'myTeam 1'},
          currentUserId: 'creator',
        ),
        isFalse,
      );
    });
  });
}
