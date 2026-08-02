import 'package:flutter/material.dart';
import 'package:grinta/config/legal_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Infos sheet from the settings menu (website, email, legal).
Future<void> showSettingsInfosSheet(BuildContext context) {
  final colors = context.appColors;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;

      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.settingsInfosTitle,
                        style: settingsMenuTitleStyle(sheetContext),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                      ),
                      child: Text(l10n.actionClose),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _InfosLinkTile(
                icon: Icons.language_rounded,
                title: l10n.settingsInfosWebsite,
                subtitle: LegalConfig.websiteDisplayHost,
                onTap: () => _openUrl(sheetContext, LegalConfig.websiteUrl),
              ),
              _InfosLinkTile(
                icon: Icons.mail_outline_rounded,
                title: l10n.settingsInfosEmail,
                subtitle: LegalConfig.supportEmail,
                onTap: () => _openEmail(sheetContext, LegalConfig.supportEmail),
              ),
              _InfosLinkTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.legalPrivacyPolicy,
                onTap: () =>
                    _openUrl(sheetContext, LegalConfig.privacyPolicyUrl),
              ),
              _InfosLinkTile(
                icon: Icons.description_outlined,
                title: l10n.legalTermsOfService,
                onTap: () =>
                    _openUrl(sheetContext, LegalConfig.termsOfServiceUrl),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(url)),
    );
  }
}

Future<void> _openEmail(BuildContext context, String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(email)),
    );
  }
}

class _InfosLinkTile extends StatelessWidget {
  const _InfosLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: settingsMenuTitleStyle(context)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: settingsMenuSubtitleStyle(context),
            ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
