import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/promo_code_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/promo_redeem_errors.dart';
import 'package:intl/intl.dart';

/// Opens promo code redemption in a dialog (web) or bottom sheet (mobile).
Future<void> showPromoCodeDialog(BuildContext context) {
  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: const SizedBox(
          width: 420,
          child: PromoCodeDialogContent(),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const PromoCodeDialogContent(),
  );
}

class PromoCodeDialogContent extends StatefulWidget {
  const PromoCodeDialogContent({super.key});

  @override
  State<PromoCodeDialogContent> createState() => _PromoCodeDialogContentState();
}

class _PromoCodeDialogContentState extends State<PromoCodeDialogContent> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _feedbackMessage = context.l10n.promoCodeRedeemEmpty;
        _feedbackIsError = true;
      });
      return;
    }

    setState(() {
      _busy = true;
      _feedbackMessage = null;
    });

    try {
      final result = await PromoCodeService.instance.redeemCode(code);
      final subscription = SubscriptionService.instance;
      final verified = await subscription.refreshAfterPromoRedeem(
        expectedEntitlement: result.entitlement,
      );
      if (!mounted) return;

      if (verified) {
        final expiresAt = subscription.subscriptionExpiresAt ?? result.expiresAt;
        setState(() {
          _feedbackMessage = expiresAt != null
              ? context.l10n.promoCodeRedeemSuccessVerified(
                  _entitlementLabel(context, result.entitlement),
                  _formatExpiry(context, expiresAt),
                  result.durationDays,
                )
              : context.l10n.promoCodeRedeemSuccess(
                  result.durationDays,
                  _entitlementLabel(context, result.entitlement),
                );
          _feedbackIsError = false;
          _controller.clear();
        });
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (kDebugMode) {
        debugPrint(
          'promo redeem: server OK but entitlement not visible locally '
          '(entitlement=${result.entitlement} uid=$uid '
          'rcConfigured=${subscription.isPurchaseAvailable})',
        );
      }

      setState(() {
        _feedbackMessage = subscription.isPurchaseAvailable
            ? context.l10n.promoCodeRedeemSyncPending
            : context.l10n.promoCodeRedeemRcUnavailable;
        _feedbackIsError = true;
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'promo redeem CF error: code=${e.code} message=${e.message} '
        'details=${e.details} promoError=${PromoCodeService.extractPromoErrorCode(e)} '
        'callableMissing=${PromoCodeService.isCallableMissing(e)}',
      );
      if (!mounted) return;
      setState(() {
        _feedbackMessage = _messageForError(context, e);
        _feedbackIsError = true;
      });
    } catch (e, st) {
      debugPrint('promo redeem failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _feedbackMessage = context.l10n.promoCodeRedeemFailed;
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatExpiry(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date.toLocal());
  }

  String _entitlementLabel(BuildContext context, String entitlement) {
    final l10n = context.l10n;
    return switch (entitlement) {
      'player' => l10n.subscriptionOfferingPlayer,
      'coach_basic' => l10n.subscriptionTierCoachBasic,
      'coach_elite' => l10n.subscriptionTierCoachElite,
      'coach_pro' => l10n.subscriptionTierCoachPro,
      _ => entitlement,
    };
  }

  String _messageForError(BuildContext context, FirebaseFunctionsException e) {
    final l10n = context.l10n;
    final promoCode = PromoCodeService.extractPromoErrorCode(e);
    if (promoCode != null) {
      return switch (promoCode) {
        'ALREADY_REDEEMED' => l10n.promoCodeRedeemAlreadyRedeemed,
        'PROMO_NOT_FOUND' => l10n.promoCodeRedeemNotFound,
        // Function undeployed / wrong region — never show "code introuvable".
        'PROMO_CALLABLE_MISSING' => l10n.promoCodeRedeemFailed,
        'PROMO_INACTIVE' => l10n.promoCodeRedeemInactive,
        'PROMO_EXPIRED' => l10n.promoCodeRedeemExpired,
        'PROMO_EXHAUSTED' => l10n.promoCodeRedeemExhausted,
        'PROMO_TEAM_MISMATCH' => l10n.promoCodeRedeemTeamMismatch,
        'PROMO_UNAUTHENTICATED' => l10n.promoCodeRedeemUnauthenticated,
        'PROMO_EMPTY' => l10n.promoCodeRedeemEmpty,
        'PROMO_INVALID' => l10n.promoCodeRedeemInvalid,
        _ => null,
      } ??
          _messageForHttpsCode(l10n, e);
    }

    return _messageForHttpsCode(l10n, e);
  }

  String _messageForHttpsCode(
    AppLocalizations l10n,
    FirebaseFunctionsException e,
  ) {
    if (PromoCodeService.isCallableMissing(e)) {
      return l10n.promoCodeRedeemFailed;
    }
    return switch (PromoCodeService.formatFunctionsError(e)) {
      // Only map not-found → "introuvable" when the CF confirmed PROMO_NOT_FOUND.
      'not-found' => PromoRedeemErrors.shouldShowNotFoundMessage(
          httpsCode: e.code,
          message: e.message,
          details: e.details,
        )
          ? l10n.promoCodeRedeemNotFound
          : l10n.promoCodeRedeemFailed,
      'failed-precondition' => l10n.promoCodeRedeemInvalid,
      'resource-exhausted' => l10n.promoCodeRedeemExhausted,
      'permission-denied' => l10n.promoCodeRedeemTeamMismatch,
      'unauthenticated' => l10n.promoCodeRedeemUnauthenticated,
      'invalid-argument' => l10n.promoCodeRedeemEmpty,
      'unavailable' => l10n.promoCodeRedeemFailed,
      _ => l10n.promoCodeRedeemFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.promoCodeMenuLabel,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionClose,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                ),
              ],
            ),
            Text(
              l10n.promoCodeRedeemTitle,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l10n.promoCodeRedeemHint,
                prefixIcon: Icon(Icons.tag_rounded, color: colors.primary),
              ),
              onSubmitted: _busy ? null : (_) => _redeem(),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (_feedbackIsError ? colors.danger : colors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_feedbackIsError ? colors.danger : colors.success)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _feedbackIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _feedbackIsError ? colors.danger : colors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: _feedbackIsError
                              ? colors.danger
                              : colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.actionClose),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _redeem,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.promoCodeDialogValidate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
