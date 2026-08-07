import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/parental_consent_service.dart';
import 'package:grinta/services/physiological_data_consent_service.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/account_age_gate.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/physiological_data_consent.dart';
import 'package:grinta/widget/parental_consent_pending_screen.dart';

/// Result of the first-connect physiological consent gate.
enum PhysiologicalConsentGateResult {
  /// Proceed with device OAuth / Health connect.
  allowed,

  /// User refused or dismissed — do not connect HR device; keep other features.
  blocked,

  /// 13–14 without parent physio consent — parent must approve.
  needsParent,
}

/// Dedicated first-connect screen: authorize / refuse physiological data.
///
/// Returns `true` if authorized, `false` if refused, `null` if dismissed.
Future<bool?> showPhysiologicalDataConsentDialog(BuildContext context) async {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const PhysiologicalDataConsentScreen(),
    ),
  );
}

/// Full-screen CNIL-style consent for heart-rate / physiological wearables.
class PhysiologicalDataConsentScreen extends StatelessWidget {
  const PhysiologicalDataConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.physiologicalConsentTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 56,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.physiologicalConsentTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        l10n.physiologicalConsentMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.physiologicalConsentAuthorize),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.physiologicalConsentRefuse),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Explains that a legal guardian must authorize physiological data (13–14).
///
/// Returns `true` if the user asked to email the guardian.
Future<bool> showPhysiologicalParentRequiredDialog(BuildContext context) async {
  final l10n = context.l10n;
  final colors = context.appColors;
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.physiologicalConsentParentRequiredTitle),
        content: Text(
          l10n.physiologicalConsentParentRequiredMessage,
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionClose),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.physiologicalConsentRequestParentEmail),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      );
    },
  );
  return result == true;
}

/// Gate before connecting an HR-capable wearable.
///
/// - Granted → [PhysiologicalConsentGateResult.allowed]
/// - 15+ unknown/refused → show authorize/refuse screen
/// - 13–14 without grant → parental email path (integrated with account consent)
Future<PhysiologicalConsentGateResult> ensurePhysiologicalDataConsent({
  required BuildContext context,
  required String consentUid,
  Player? player,
}) async {
  final service = PhysiologicalDataConsentService();
  final status = await service.readStatus(consentUid);
  if (status == PhysiologicalDataConsentStatus.granted) {
    return PhysiologicalConsentGateResult.allowed;
  }

  final ageGate = player != null
      ? classifyPlayerAccountAge(player)
      : AccountAgeGateResult.selfServeAllowed;

  if (ageGate == AccountAgeGateResult.parentalConsentRequired ||
      ageGate == AccountAgeGateResult.blockedUnderage) {
    if (!context.mounted) return PhysiologicalConsentGateResult.needsParent;
    final wantsEmail = await showPhysiologicalParentRequiredDialog(context);
    if (wantsEmail && context.mounted) {
      await _requestParentPhysiologicalEmail(
        context: context,
        consentUid: consentUid,
        player: player,
      );
    }
    return PhysiologicalConsentGateResult.needsParent;
  }

  if (!context.mounted) return PhysiologicalConsentGateResult.blocked;

  final choice = await showPhysiologicalDataConsentDialog(context);
  if (choice == null) return PhysiologicalConsentGateResult.blocked;

  await service.setSelfConsent(uid: consentUid, granted: choice);
  return choice
      ? PhysiologicalConsentGateResult.allowed
      : PhysiologicalConsentGateResult.blocked;
}

Future<void> _requestParentPhysiologicalEmail({
  required BuildContext context,
  required String consentUid,
  Player? player,
}) async {
  final l10n = context.l10n;
  final userData = await UserService().getUserData(consentUid);
  var parentEmail =
      userData?[UserDocumentFields.parentEmail]?.toString().trim() ?? '';
  if (parentEmail.isEmpty) {
    if (!context.mounted) return;
    parentEmail = (await promptParentalConsentEmail(context))?.trim() ?? '';
  }
  if (parentEmail.isEmpty || !context.mounted) return;

  final first = player?.firstName?.trim() ?? '';
  final last = player?.lastName?.trim() ?? '';
  final name = ('$first $last').trim().isEmpty
      ? 'votre enfant'
      : ('$first $last').trim();

  final error =
      await ParentalConsentService().requestPhysiologicalConsentFromParent(
    uid: consentUid,
    parentEmail: parentEmail,
    childDisplayName: name,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error == null
            ? l10n.parentalConsentResendSuccess
            : l10n.parentalConsentSendError,
      ),
    ),
  );
}
