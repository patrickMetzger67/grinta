import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/promo_code_dialog.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Compact paywall link that opens [showPromoCodeDialog].
///
/// Promo redemption is only offered from the subscription paywall — not from
/// the settings menu.
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
