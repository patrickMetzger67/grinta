import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitation_deep_link_service.dart';
import 'package:grinta/services/invitation_link_builder.dart';
import 'package:grinta/services/member_invitation_service.dart';
import 'package:grinta/services/player_season_summary_service.dart';
import 'package:grinta/services/player_season_summary_share_service.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';

void main() {
  group('InvitationLinkBuilder', () {
    test('builds invite URL with code query', () {
      final url = InvitationLinkBuilder.inviteUrl(
        config: InvitationConfig.defaults,
        invitationCode: 'GT1234',
      );
      expect(url, 'https://grinta.io/invite?code=GT1234');
    });

    test('digitsOnlyPhone strips formatting', () {
      expect(
        InvitationLinkBuilder.digitsOnlyPhone('+33 6 12-34-56-78'),
        '33612345678',
      );
      expect(InvitationLinkBuilder.digitsOnlyPhone('123'), isNull);
    });

    test('waMeUri includes prefilled text', () {
      final uri = InvitationLinkBuilder.waMeUri(
        phoneE164: '+33612345678',
        text: 'Code GT1234',
      );
      expect(uri, isNotNull);
      expect(uri!.host, 'wa.me');
      expect(uri.path, '/33612345678');
      expect(uri.queryParameters['text'], 'Code GT1234');
    });
  });

  group('InvitationDeepLinkService', () {
    test('detects grinta invite scheme', () {
      expect(
        InvitationDeepLinkService.isInviteLinkForTest(
          Uri.parse('grinta://invite?code=GT42'),
        ),
        isTrue,
      );
    });

    test('detects https invite path', () {
      expect(
        InvitationDeepLinkService.isInviteLinkForTest(
          Uri.parse('https://grinta.io/invite?code=GT42'),
        ),
        isTrue,
      );
    });

    test('rejects unrelated links', () {
      expect(
        InvitationDeepLinkService.isInviteLinkForTest(
          Uri.parse('grinta://event?type=match&id=1'),
        ),
        isFalse,
      );
    });
  });

  group('MemberInvitationResult', () {
    test('sent flags channels independently', () {
      final both = MemberInvitationResult.sent(
        invitationCode: 'GT1',
        invitationId: 'id',
        emailSent: true,
        whatsappSent: true,
      );
      expect(both.success, isTrue);
      expect(both.emailSent, isTrue);
      expect(both.whatsappSent, isTrue);
    });
  });

  group('PlayerSeasonSummaryShareService', () {
    testWidgets('builds share text with season stats', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const summary = PlayerSeasonSummary(
        teamMatchCount: 10,
        convocations: 8,
        starts: 5,
        minutesPlayed: 420,
        yellowCards: 1,
        redCards: 0,
        teamTrainingCount: 20,
        presentCount: 18,
        absentCount: 2,
        attendanceRate: 90,
        teamNames: <String>['U17'],
        matchTrackerAverages: PlayerTrackerMetricAverages(
          sessionsWithData: 0,
          averages: <String, double>{},
        ),
        trainingTrackerAverages: PlayerTrackerMetricAverages(
          sessionsWithData: 0,
          averages: <String, double>{},
        ),
        unavailabilities: <Unavailability>[],
      );

      final text = const PlayerSeasonSummaryShareService().buildShareText(
        l10n: l10n,
        playerName: 'Alex Player',
        teamName: 'U17',
        seasonLabel: '2025-2026',
        summary: summary,
      );

      expect(text, contains('Alex Player'));
      expect(text, contains('8'));
      expect(text, contains('90%'));
      expect(text, contains('#GrintaPerformance'));
    });
  });
}
