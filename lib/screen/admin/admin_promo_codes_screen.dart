import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/promo_code.dart';
import 'package:grinta/services/promo_code_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

class AdminPromoCodesScreen extends StatefulWidget {
  const AdminPromoCodesScreen({super.key});

  @override
  State<AdminPromoCodesScreen> createState() => _AdminPromoCodesScreenState();
}

class _AdminPromoCodesScreenState extends State<AdminPromoCodesScreen> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminPromoCodesTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.adminPromoCodeCreate,
        onPressed: _sheetOpen ? null : () => _openFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<PromoCode>>(
        stream: PromoCodeService.instance.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminPromoCodesLoadError,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                ),
              ),
            );
          }

          final codes = snapshot.data ?? const <PromoCode>[];
          if (codes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminPromoCodesEmpty,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: codes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final promo = codes[index];
              return _PromoCodeCard(
                promo: promo,
                onToggleActive: (active) => _setActive(promo, active),
                onEdit: () => _openFormSheet(context, existing: promo),
                onDelete: () => _confirmDelete(context, promo),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setActive(PromoCode promo, bool active) async {
    try {
      await PromoCodeService.instance.setActive(
        codeId: promo.id,
        active: active,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e is StateError && e.message == 'permission-denied'
            ? context.l10n.adminPromoCodePermissionDenied
            : context.l10n.adminPromoCodeUpdateFailed,
      );
    }
  }

  Future<void> _openFormSheet(
    BuildContext context, {
    PromoCode? existing,
  }) async {
    setState(() => _sheetOpen = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.appColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _PromoCodeFormSheet(
          existing: existing,
          onSuccess: () {
            if (!mounted) return;
            AppSnackbar.show(
              context,
              existing == null
                  ? context.l10n.adminPromoCodeCreated
                  : context.l10n.adminPromoCodeUpdated,
            );
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, PromoCode promo) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.adminPromoCodeDeleteConfirmTitle),
          content: Text(l10n.adminPromoCodeDeleteConfirmMessage(promo.code)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.actionDelete,
                style: TextStyle(
                  color: colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final deletedMessage = l10n.adminPromoCodeDeleted;
    final permissionDeniedMessage = l10n.adminPromoCodePermissionDenied;
    final deleteFailedMessage = l10n.adminPromoCodeDeleteFailed;

    try {
      await PromoCodeService.instance.deletePromoCode(codeId: promo.id);
      if (!mounted) return;
      AppSnackbar.show(context, deletedMessage);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e is StateError && e.message == 'permission-denied'
            ? permissionDeniedMessage
            : deleteFailedMessage,
      );
    }
  }
}

enum _PromoCodeCardAction { edit, delete }

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({
    required this.promo,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final PromoCode promo;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = !promo.active
        ? colors.textSecondary
        : promo.isRedeemable
            ? colors.success
            : colors.warning;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    promo.code,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Switch(
                  value: promo.active,
                  onChanged: onToggleActive,
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                ),
                PopupMenuButton<_PromoCodeCardAction>(
                  tooltip: l10n.adminPromoCodeActions,
                  icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
                  onSelected: (action) {
                    switch (action) {
                      case _PromoCodeCardAction.edit:
                        onEdit();
                      case _PromoCodeCardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PromoCodeCardAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: colors.textPrimary),
                          const SizedBox(width: 12),
                          Text(l10n.adminPromoCodeEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _PromoCodeCardAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: colors.danger),
                          const SizedBox(width: 12),
                          Text(
                            l10n.adminPromoCodeDelete,
                            style: TextStyle(color: colors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminPromoCodeEntitlementLabel(
                _entitlementLabel(l10n, promo.entitlement),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminPromoCodeUsageLabel(promo.usedCount, promo.maxUses),
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adminPromoCodeDurationLabel(promo.durationDays),
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            if (promo.teamId != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminPromoCodeTeamLabel(promo.teamId!),
                style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
            if (promo.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminPromoCodeExpiresLabel(
                  MaterialLocalizations.of(context).formatShortDate(
                    promo.expiresAt!,
                  ),
                ),
                style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _statusLabel(l10n, promo),
              style: textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _entitlementLabel(dynamic l10n, String entitlement) {
    return switch (entitlement) {
      SubscriptionEntitlementIds.player => l10n.subscriptionOfferingPlayer,
      SubscriptionEntitlementIds.playerGps => l10n.subscriptionTierPlayerGps,
      SubscriptionEntitlementIds.coachBasic => l10n.subscriptionTierCoachBasic,
      SubscriptionEntitlementIds.coachElite => l10n.subscriptionTierCoachElite,
      SubscriptionEntitlementIds.coachPro => l10n.subscriptionTierCoachPro,
      _ => entitlement,
    };
  }

  String _statusLabel(dynamic l10n, PromoCode promo) {
    if (!promo.active) return l10n.adminPromoCodeStatusInactive;
    if (promo.isExpired) return l10n.adminPromoCodeStatusExpired;
    if (promo.isExhausted) return l10n.adminPromoCodeStatusExhausted;
    return l10n.adminPromoCodeStatusActive;
  }
}

class _PromoCodeFormSheet extends StatefulWidget {
  const _PromoCodeFormSheet({
    this.existing,
    required this.onSuccess,
  });

  final PromoCode? existing;
  final VoidCallback onSuccess;

  bool get isEdit => existing != null;

  @override
  State<_PromoCodeFormSheet> createState() => _PromoCodeFormSheetState();
}

class _PromoCodeFormSheetState extends State<_PromoCodeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _maxUsesController;
  late final TextEditingController _durationDaysController;
  late final TextEditingController _teamIdController;

  late String _entitlement;
  DateTime? _expiresAt;
  late bool _active;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _codeController = TextEditingController(text: existing?.code ?? '');
    _maxUsesController = TextEditingController(
      text: existing?.maxUses.toString() ?? '10',
    );
    _durationDaysController = TextEditingController(
      text: existing?.durationDays.toString() ?? '30',
    );
    _teamIdController = TextEditingController(text: existing?.teamId ?? '');
    _entitlement = existing?.entitlement ?? SubscriptionEntitlementIds.player;
    _expiresAt = existing?.expiresAt;
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _maxUsesController.dispose();
    _durationDaysController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  int? get _minMaxUses => widget.existing?.usedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.isEdit;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? l10n.adminPromoCodeEditTitle : l10n.adminPromoCodeCreate,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  readOnly: isEdit,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.adminPromoCodeFieldCode,
                    helperText: isEdit ? l10n.adminPromoCodeFieldCodeReadOnly : null,
                  ),
                  validator: (value) {
                    if (isEdit) return null;
                    final normalized = PromoCode.normalizeCode(value ?? '');
                    if (normalized.length < 4) {
                      return l10n.adminPromoCodeFieldCodeInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _entitlement,
                  decoration: InputDecoration(
                    labelText: l10n.adminPromoCodeFieldEntitlement,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: SubscriptionEntitlementIds.player,
                      child: Text(l10n.subscriptionOfferingPlayer),
                    ),
                    DropdownMenuItem(
                      value: SubscriptionEntitlementIds.playerGps,
                      child: Text(l10n.subscriptionTierPlayerGps),
                    ),
                    DropdownMenuItem(
                      value: SubscriptionEntitlementIds.coachBasic,
                      child: Text(l10n.subscriptionTierCoachBasic),
                    ),
                    DropdownMenuItem(
                      value: SubscriptionEntitlementIds.coachElite,
                      child: Text(l10n.subscriptionTierCoachElite),
                    ),
                    DropdownMenuItem(
                      value: SubscriptionEntitlementIds.coachPro,
                      child: Text(l10n.subscriptionTierCoachPro),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _entitlement = value);
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxUsesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.adminPromoCodeFieldMaxUses,
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    final minUses = _minMaxUses ?? 1;
                    if (parsed == null || parsed < minUses) {
                      return minUses > 1
                          ? l10n.adminPromoCodeFieldMaxUsesBelowUsed(minUses)
                          : l10n.adminPromoCodeFieldMaxUsesInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationDaysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.adminPromoCodeFieldDurationDays,
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1) {
                      return l10n.adminPromoCodeFieldDurationDaysInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teamIdController,
                  decoration: InputDecoration(
                    labelText: l10n.adminPromoCodeFieldTeamId,
                    helperText: l10n.adminPromoCodeFieldTeamIdHint,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickExpiryDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _expiresAt == null
                        ? l10n.adminPromoCodeFieldExpiresOptional
                        : l10n.adminPromoCodeExpiresLabel(
                            MaterialLocalizations.of(context).formatShortDate(
                              _expiresAt!,
                            ),
                          ),
                  ),
                ),
                if (_expiresAt != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _expiresAt = null),
                    child: Text(l10n.adminPromoCodeClearExpiry),
                  ),
                ],
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.adminPromoCodeFieldActive,
                      style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                    ),
                    value: _active,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _active = value),
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.primary,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? l10n.adminPromoCodeSave : l10n.adminPromoCodeCreate,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(
      () => _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final maxUses = int.parse(_maxUsesController.text);
      final durationDays = int.parse(_durationDaysController.text);
      final teamId = _teamIdController.text;
      final hadExpiry = widget.existing?.expiresAt != null;

      if (widget.isEdit) {
        await PromoCodeService.instance.updatePromoCode(
          codeId: widget.existing!.id,
          maxUses: maxUses,
          entitlement: _entitlement,
          durationDays: durationDays,
          expiresAt: _expiresAt,
          teamId: teamId,
          active: _active,
          clearExpiresAt: hadExpiry && _expiresAt == null,
        );
      } else {
        await PromoCodeService.instance.createPromoCode(
          code: _codeController.text,
          maxUses: maxUses,
          entitlement: _entitlement,
          durationDays: durationDays,
          expiresAt: _expiresAt,
          teamId: teamId,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError &&
              e.message == 'max-uses-below-used' &&
              widget.existing != null
          ? context.l10n.adminPromoCodeFieldMaxUsesBelowUsed(
              widget.existing!.usedCount,
            )
          : _promoCodeErrorMessage(
              context.l10n,
              e,
              isEdit: widget.isEdit,
            );
      setState(() => _errorMessage = message);
      AppSnackbar.show(
        context,
        message,
        preferDialog: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

String _promoCodeErrorMessage(
  dynamic l10n,
  Object error, {
  required bool isEdit,
}) {
  if (error is StateError) {
    switch (error.message) {
      case 'Promo code already exists.':
        return l10n.adminPromoCodeAlreadyExists;
      case 'permission-denied':
        return l10n.adminPromoCodePermissionDenied;
      case 'authentication-required':
        return l10n.adminPromoCodeAuthRequired;
      case 'invalid-document-id':
        return l10n.adminPromoCodeFieldCodeInvalid;
      case 'not-found':
        return l10n.adminPromoCodeNotFound;
    }
  }

  if (error is FirebaseException) {
    switch (PromoCodeService.formatFirestoreError(error)) {
      case 'permission-denied':
        return l10n.adminPromoCodePermissionDenied;
      case 'already-exists':
        return l10n.adminPromoCodeAlreadyExists;
    }
  }

  return isEdit ? l10n.adminPromoCodeUpdateFailed : l10n.adminPromoCodeCreateFailed;
}
