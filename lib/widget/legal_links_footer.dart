import 'package:flutter/material.dart';
import 'package:grinta/config/legal_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy policy and terms links for login and subscription surfaces.
class LegalLinksFooter extends StatelessWidget {
  const LegalLinksFooter({
    super.key,
    this.alignment = WrapAlignment.center,
    this.padding = EdgeInsets.zero,
  });

  final WrapAlignment alignment;
  final EdgeInsetsGeometry padding;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final linkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary.withValues(alpha: 0.6),
        );

    return Padding(
      padding: padding,
      child: Wrap(
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _openUrl(context, LegalConfig.privacyPolicyUrl),
            child: Text(l10n.legalPrivacyPolicy, style: linkStyle),
          ),
          Text(
            '·',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _openUrl(context, LegalConfig.termsOfServiceUrl),
            child: Text(l10n.legalTermsOfService, style: linkStyle),
          ),
        ],
      ),
    );
  }
}
