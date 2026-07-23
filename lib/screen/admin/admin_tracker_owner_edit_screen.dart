import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/tracker_owner_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

class AdminTrackerOwnerEditScreen extends StatefulWidget {
  const AdminTrackerOwnerEditScreen({super.key, this.owner});

  /// null => create, non-null => edit.
  final TrackerOwner? owner;

  @override
  State<AdminTrackerOwnerEditScreen> createState() =>
      _AdminTrackerOwnerEditScreenState();
}

class _AdminTrackerOwnerEditScreenState
    extends State<AdminTrackerOwnerEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();

  late String _typeTracker;
  late bool _isActive;
  late bool _isIndividual;
  bool _saving = false;

  bool get _isEdit => widget.owner != null;

  @override
  void initState() {
    super.initState();
    final owner = widget.owner;
    _nameCtrl.text = owner?.name ?? '';
    _emailCtrl.text = owner?.email ?? '';
    _firstnameCtrl.text = owner?.firstname ?? '';
    _lastnameCtrl.text = owner?.lastname ?? '';
    _isActive = owner?.isActive ?? true;
    _isIndividual = owner?.isIndividual ?? false;

    final currentType = (owner?.typeTracker ?? '').trim();
    _typeTracker = TrackerOwner.typeTrackers.contains(currentType)
        ? currentType
        : TrackerOwner.typeTrackers.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? l10n.adminTrackerOwnerEditTitle
              : l10n.adminTrackerOwnerCreateTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.adminTrackerOwnerFieldName,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.adminTrackerOwnerFieldRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.adminTrackerOwnerFieldEmail,
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return l10n.adminTrackerOwnerFieldRequired;
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return l10n.adminTrackerOwnerFieldEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstnameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.adminTrackerOwnerFieldFirstname,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.adminTrackerOwnerFieldRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastnameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.adminTrackerOwnerFieldLastname,
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.adminTrackerOwnerFieldRequired
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _typeTracker,
                  decoration: InputDecoration(
                    labelText: l10n.adminTrackerOwnerFieldTypeTracker,
                  ),
                  items: TrackerOwner.typeTrackers
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(l10n.adminTrackerOwnerTypeLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _typeTracker =
                                value ?? TrackerOwner.typeTrackers.first,
                          ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adminTrackerOwnerFieldActive,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isActive = value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adminTrackerOwnerFieldIndividual,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.adminTrackerOwnerFieldIndividualHint,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  value: _isIndividual,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isIndividual = value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.adminTrackerOwnerSave),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                    label: Text(
                      l10n.adminTrackerOwnerDelete,
                      style: TextStyle(color: colors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colors.danger.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar.show(context, context.l10n.adminTrackerOwnerPermissionDenied);
      return;
    }

    setState(() => _saving = true);

    final successMessage = _isEdit
        ? context.l10n.adminTrackerOwnerUpdated
        : context.l10n.adminTrackerOwnerCreated;

    try {
      final now = Timestamp.now();
      final userId = user.uid;
      final existing = widget.owner;

      final withSyncing = TrackerOwner.withSyncingForType(_typeTracker);

      final owner = _isEdit
          ? existing!.copyWith(
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              firstname: _firstnameCtrl.text.trim(),
              lastname: _lastnameCtrl.text.trim(),
              isActive: _isActive,
              isIndividual: _isIndividual,
              typeTracker: _typeTracker,
              withSyncing: withSyncing,
              updatedAt: now,
              uidUpdate: userId,
            )
          : TrackerOwner(
              name: _nameCtrl.text.trim(),
              typeTracker: _typeTracker,
              isActive: _isActive,
              isIndividual: _isIndividual,
              withSyncing: withSyncing,
              email: _emailCtrl.text.trim(),
              firstname: _firstnameCtrl.text.trim(),
              lastname: _lastnameCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
              uidCreate: userId,
              uidUpdate: userId,
            );

      await TrackerOwnerService.instance.saveOwner(owner);

      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.show(context, successMessage, isError: false);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, _errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final owner = widget.owner;
    if (owner == null) return;

    final l10n = context.l10n;
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminTrackerOwnerDeleteConfirmTitle),
        content: Text(l10n.adminTrackerOwnerDeleteConfirmMessage(owner.name)),
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
              l10n.adminTrackerOwnerDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final deletedMessage = context.l10n.adminTrackerOwnerDeleted;
    try {
      await TrackerOwnerService.instance.deleteOwner(owner.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.show(context, deletedMessage, isError: false);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, _errorMessage(e, isDelete: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object error, {bool isDelete = false}) {
    final l10n = context.l10n;
    if (error is StateError && error.message == 'permission-denied') {
      return l10n.adminTrackerOwnerPermissionDenied;
    }
    return isDelete
        ? l10n.adminTrackerOwnerDeleteFailed
        : l10n.adminTrackerOwnerSaveFailed;
  }
}
