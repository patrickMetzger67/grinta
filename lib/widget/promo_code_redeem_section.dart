import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/promo_code_dialog.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Compact paywall link that opens [showPromoCodeDialog].
///
/// On successful redeem, closes the surrounding paywall and shows confirmation.
class PromoCodePaywallLink extends StatelessWidget {
  const PromoCodePaywallLink({super.key});

  Future<void> _onPressed(BuildContext context) async {
    final successMessage = await showPromoCodeDialog(context);
    if (successMessage == null) return;
    if (!context.mounted) return;

    // Close the paywall (same navigator that presented SubscriptionPaywall).
    Navigator.of(context).pop(true);

    final snackContext = appNavigatorKey.currentContext ?? context;
    if (!snackContext.mounted) return;
    AppSnackbar.show(
      snackContext,
      successMessage,
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () => _onPressed(context),
        icon: Icon(Icons.confirmation_number_outlined, color: colors.primary),
        label: Text(
          l10n.promoCodeMenuLabel,
          style: settingsMenuTitleStyle(context).copyWith(color: colors.primary),
        ),
      ),
    );
  }
}
