import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/subscription_paywall.dart';
import 'package:provider/provider.dart';

/// Explains that creating a group requires a subscription, with a paywall link.
Future<void> showChatGroupSubscriptionRequiredDialog(BuildContext context) {
  final colors = context.appColors;
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.chatCreateGroup),
        content: Text(l10n.chatGroupRequiredSubscription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              final appSession = context.read<AppSession>();
              await SubscriptionPaywall.show(
                context,
                allowSkip: true,
                initialKind: prefersCoachSubscriptionOffering(appSession)
                    ? SubscriptionOfferingKind.coach
                    : SubscriptionOfferingKind.player,
              );
            },
            child: Text(l10n.chatGroupOpenSubscription),
          ),
        ],
      );
    },
  );
}
