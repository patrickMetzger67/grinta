import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/delete_error_message.dart';

/// Confirmation dialog that runs [onConfirm] in-place and shows failures
/// inside the dialog (not on the scaffold behind the barrier).
Future<bool?> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return ConfirmDeleteDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
      );
    },
  );
}

class ConfirmDeleteDialog extends StatefulWidget {
  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final Future<void> Function() onConfirm;

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _onDeletePressed() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _isDeleting = false;
        _error = DeleteErrorMessage.isPermissionDenied(e)
            ? l10n.errorDeletePermissionDenied
            : l10n.errorDeleteFailed(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: appColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: appColors.border),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: appColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 15,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: appColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: appColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        key: const Key('confirmDeleteDialogError'),
                        style: textTheme.bodyMedium?.copyWith(
                          color: appColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.of(context).pop(false);
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: appColors.textSecondary,
              side: BorderSide(color: appColors.border),
            ),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: _isDeleting ? null : _onDeletePressed,
            style: FilledButton.styleFrom(
              backgroundColor: appColors.danger,
              foregroundColor: Colors.white,
            ),
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
