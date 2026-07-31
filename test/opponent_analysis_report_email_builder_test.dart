import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations_fr.dart';
import 'package:grinta/services/opponent_analysis_report_email_builder.dart';

void main() {
  test('OpponentAnalysisReportEmailBuilder uses Grinta branding and content',
      () {
    final l10n = AppLocalizationsFr();
    final content = OpponentAnalysisReportEmailBuilder.build(
      l10n: l10n,
      config: const InvitationRuntimeConfig(
        contactPrefixCode: 'GT',
        appDisplayName: 'Grinta',
        appleStoreUrl: 'https://example.com/ios',
        googlePlayUrl: 'https://example.com/android',
        logoUrl: 'https://example.com/logo.png',
        fromEmail: 'noreply@example.com',
        replyToEmail: 'support@example.com',
      ),
      teamName: 'myTeam 1',
      opponentName: 'DRUSENHEIM FC',
      kickoffLabel: 'samedi 2 août 2026 15:00',
      pdfDownloadUrl: 'https://example.com/report.pdf',
    );

    expect(content.subject, contains('Grinta'));
    expect(content.subject, contains('DRUSENHEIM FC'));
    expect(content.text, contains('DRUSENHEIM FC'));
    expect(content.text, contains('https://example.com/report.pdf'));
    expect(content.html, contains('https://example.com/logo.png'));
    expect(content.html, contains('DRUSENHEIM FC'));
    expect(content.html.toUpperCase(), contains('#F95C1B'));
  });
}
