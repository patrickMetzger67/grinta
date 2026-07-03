import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/player.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/match_convocation_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_convocation_helper.dart';
import 'package:intl/intl.dart';

Future<bool?> showSendMatchConvocationsSheet(
  BuildContext context, {
  required models.Match match,
  required List<Player> convokedPlayers,
}) {
  if (kIsWeb) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: SendMatchConvocationsSheet(
            match: match,
            convokedPlayers: convokedPlayers,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => SendMatchConvocationsSheet(
      match: match,
      convokedPlayers: convokedPlayers,
    ),
  );
}

class SendMatchConvocationsSheet extends StatefulWidget {
  const SendMatchConvocationsSheet({
    super.key,
    required this.match,
    required this.convokedPlayers,
  });

  final models.Match match;
  final List<Player> convokedPlayers;

  @override
  State<SendMatchConvocationsSheet> createState() =>
      _SendMatchConvocationsSheetState();
}

class _SendMatchConvocationsSheetState extends State<SendMatchConvocationsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _addressController = TextEditingController();
  final _convocationService = MatchConvocationService();

  late DateTime _convocationDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _convocationDateTime = defaultMatchConvocationDateTime(widget.match);
    _messageController.text = widget.match.messageConvo?.trim() ?? '';
    _addressController.text = defaultMatchConvocationAddress(widget.match);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickConvocationTime() async {
    final initialTime = TimeOfDay.fromDateTime(_convocationDateTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: context.l10n.matchConvocationsSendTime,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _convocationDateTime = DateTime(
        _convocationDateTime.year,
        _convocationDateTime.month,
        _convocationDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      AppSnackbar.show(context, context.l10n.matchConvocationsSendErrorAuth);
      return;
    }

    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final l10n = context.l10n;

    setState(() => _isSubmitting = true);

    var didPop = false;
    try {
      final result = await _convocationService.sendConvocations(
        l10n: l10n,
        match: widget.match,
        convokedPlayers: widget.convokedPlayers,
        message: _messageController.text,
        convocationDateTime: _convocationDateTime,
        address: _addressController.text,
        managerUserId: uid,
      );

      if (!mounted) return;

      if (!result.hasAnySuccess) {
        AppSnackbar.show(context, l10n.matchConvocationsSendNoRecipients);
        return;
      }

      final message = _buildSuccessMessage(result);

      navigator.pop(true);
      didPop = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? rootContext = appNavigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          AppSnackbar.show(rootContext, message, isError: false);
        }
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          l10n.matchConvocationsSendError('$e'),
        );
      }
    } finally {
      if (mounted && !didPop) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _buildSuccessMessage(MatchConvocationSendResult result) {
    final l10n = context.l10n;
    final parts = <String>[
      l10n.matchConvocationsSendSuccess(result.notificationsCreated),
    ];

    if (result.skippedNoLinkedAccount > 0) {
      parts.add(
        l10n.matchConvocationsSendSkippedNoAccount(
          result.skippedNoLinkedAccount,
        ),
      );
    }

    if (result.skippedNoFcmToken > 0) {
      parts.add(
        l10n.matchConvocationsSendSkippedNoPush(result.skippedNoFcmToken),
      );
    }

    return parts.join(' · ');
  }

  String _formattedConvocationTime() {
    final locale = context.l10n.localeName;
    return DateFormat.Hm(locale).format(_convocationDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.matchConvocationsSendTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.matchConvocationsSendSubtitle(widget.convokedPlayers.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _messageController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: l10n.matchConvocationsSendMessage,
                          hintText: l10n.matchConvocationsSendMessageHint,
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.matchConvocationsSendMessageRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.matchConvocationsSendTime,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _formattedConvocationTime(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: Icon(
                          Icons.schedule_rounded,
                          color: colors.primary,
                        ),
                        onTap: _isSubmitting ? null : _pickConvocationTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: colors.border),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.matchConvocationsSendAddress,
                          hintText: l10n.matchConvocationsSendAddressHint,
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.matchConvocationsSendAddressRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(l10n.matchConvocationsSendSubmit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
