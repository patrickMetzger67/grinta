import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/promo_code_dialog.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Settings row that opens [showPromoCodeDialog].
class PromoCodeRedeemSection extends StatelessWidget {
  const PromoCodeRedeemSection({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    void openDialog() => showPromoCodeDialog(context);

    if (webCardStyle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: openDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.promoCodeMenuLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: settingsMenuTitleStyle(context),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: kWebMenuIconSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: contentPadding,
      leading: Icon(
        Icons.confirmation_number_outlined,
        color: colors.primary,
      ),
      title: Text(
        l10n.promoCodeMenuLabel,
        style: settingsMenuTitleStyle(context),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textSecondary,
      ),
      onTap: openDialog,
    );
  }
}

/// Compact paywall link that opens [showPromoCodeDialog].
class PromoCodePaywallLink extends StatelessWidget {
  const PromoCodePaywallLink({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () => showPromoCodeDialog(context),
        icon: Icon(Icons.confirmation_number_outlined, color: colors.primary),
        label: Text(
          l10n.promoCodeMenuLabel,
          style: settingsMenuTitleStyle(context).copyWith(color: colors.primary),
        ),
      ),
    );
  }
}
