import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/subscription_limits_access.dart';
import 'package:grinta/widget/member_profile_form.dart';
import 'package:provider/provider.dart';

/// Collects profile fields and creates a new [Player] in the member collection.
Future<Player?> showCreateMemberSheet(BuildContext context) {
  return showModalBottomSheet<Player>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: false,
    builder: (_) => const CreateMemberSheet(),
  );
}

class CreateMemberSheet extends StatefulWidget {
  const CreateMemberSheet({super.key});

  @override
  State<CreateMemberSheet> createState() => _CreateMemberSheetState();
}

class _CreateMemberSheetState extends State<CreateMemberSheet> {
  MemberProfileFormState? _formState;
  final ValueNotifier<bool> _canSave = ValueNotifier(false);
  bool _isSaving = false;

  @override
  void dispose() {
    _canSave.dispose();
    super.dispose();
  }

  void _onFormStateCreated(MemberProfileFormState state) {
    _formState = state;
  }

  void _onValidityChanged(bool isValid) {
    if (_canSave.value != isValid) {
      _canSave.value = isValid;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final formState = _formState;
    if (formState == null || !formState.mounted) return;

    final validationError = formState.validateAndGetError();
    if (validationError != null) {
      AppSnackbar.show(context, validationError);
      return;
    }

    final profile = formState.buildProfile();
    if (profile == null || !profile.isProfileAndContactValid) {
      AppSnackbar.show(context, context.l10n.memberProfileIncomplete);
      return;
    }

    final creatorUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    if (creatorUserId == null || creatorUserId.isEmpty) {
      AppSnackbar.show(context, context.l10n.errorGeneric('Missing user'));
      return;
    }

    final profileCount = context.read<AppSession>().currentUserPlayers.length;
    final allowed = await SubscriptionLimitsAccess.ensureCanCreateProfile(
      context,
      currentProfileCount: profileCount,
    );
    if (!mounted || !allowed) return;

    setState(() => _isSaving = true);

    try {
      final created = await PlayerService().createInvitedMember(
        creatorUserId: creatorUserId,
        profile: profile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.actionCreatePlayer,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionCancel,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MemberProfileForm(
                  key: const ValueKey('create-member-profile'),
                  enabled: !_isSaving,
                  showTitle: false,
                  onFormStateCreated: _onFormStateCreated,
                  onValidityChanged: _onValidityChanged,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _canSave,
                      builder: (context, canSave, _) {
                        return FilledButton(
                          onPressed: _isSaving || !canSave ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.actionCreatePlayer),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
