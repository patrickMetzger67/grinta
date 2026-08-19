import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:provider/provider.dart';

import '../core/extensions/l10n_extension.dart';
import '../model/player.dart';
import '../provider/appSession.dart';
import '../services/member_photo_service.dart';
import '../services/playerService.dart';
import '../services/subscription_service.dart';
import '../services/auth_display_name_sync.dart';
import '../services/userService.dart';
import '../util/app_snackbar.dart';
import '../util/app_theme.dart';
import 'member_profile_form.dart';
import 'member_profile_photo_editor.dart';

Future<void> showEditMemberProfile(BuildContext context) async {
  final appSession = context.read<AppSession>();
  final player = appSession.selectedPlayer;
  final memberId = player?.keyMember;

  if (player == null || memberId == null || memberId.trim().isEmpty) {
    AppSnackbar.show(context, context.l10n.errorEditProfileUnavailable);
    return;
  }

  AnalyticsInteractions.logFeature(AnalyticsFeatures.editProfile);
  unawaited(SubscriptionService.instance.refreshForActiveSession());

  if (kIsWeb) {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _EditMemberProfileDialog(player: player),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _EditMemberProfileSheet(player: player),
  );
}

class _EditMemberProfileDialog extends StatelessWidget {
  const _EditMemberProfileDialog({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: _EditMemberProfileBody(
          player: player,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _EditMemberProfileSheet extends StatelessWidget {
  const _EditMemberProfileSheet({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _EditMemberProfileBody(
          player: player,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _EditMemberProfileBody extends StatefulWidget {
  const _EditMemberProfileBody({
    required this.player,
    required this.onClose,
  });

  final Player player;
  final VoidCallback onClose;

  @override
  State<_EditMemberProfileBody> createState() => _EditMemberProfileBodyState();
}

class _EditMemberProfileBodyState extends State<_EditMemberProfileBody> {
  MemberProfileFormState? _formState;
  late final Player _initialProfile;
  late final ValueNotifier<bool> _canSave;
  bool _isSaving = false;
  Uint8List? _pendingPhotoBytes;

  @override
  void initState() {
    super.initState();
    _initialProfile = widget.player.toEditableProfile();
    _canSave = ValueNotifier(_initialProfile.isProfileAndContactValid);
  }

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

    final memberId = widget.player.keyMember;
    if (memberId == null || memberId.trim().isEmpty) {
      AppSnackbar.show(context, context.l10n.errorEditProfileUnavailable);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await PlayerService().updateMemberProfile(
        memberId: memberId,
        profile: profile,
      );

      if (_pendingPhotoBytes != null) {
        await MemberPhotoService.instance.uploadMemberPhoto(
          memberId: memberId,
          profile: profile,
          imageBytes: _pendingPhotoBytes!,
          previousFilename: widget.player.photo,
        );
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.trim().isNotEmpty) {
        await UserService().updateProfileNames(
          uid: uid,
          firstName: profile.firstName?.trim() ?? '',
          lastName: profile.lastName?.trim() ?? '',
        );
        await AuthDisplayNameSync.instance.persistFromMember(profile);
      }

      if (!mounted) return;

      final appSession = context.read<AppSession>();
      await appSession.refreshPlayerAvatarUrls();

      if (!mounted) return;

      widget.onClose();
      AppSnackbar.show(
        context,
        context.l10n.memberProfileUpdateSuccess,
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.memberProfileUpdateError(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final memberId = widget.player.keyMember?.trim() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.actionEditProfile,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                ),
              ),
              IconButton(
                onPressed: _isSaving ? null : widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Center(
                  child: MemberProfilePhotoEditor(
                    player: widget.player,
                    enabled: !_isSaving,
                    onPhotoBytesChanged: (bytes) {
                      setState(() => _pendingPhotoBytes = bytes);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                MemberProfileForm(
                  key: ValueKey('edit-profile-$memberId'),
                  enabled: !_isSaving,
                  initialProfile: _initialProfile,
                  showTitle: false,
                  onFormStateCreated: _onFormStateCreated,
                  onValidityChanged: _onValidityChanged,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : widget.onClose,
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _canSave,
                  builder: (context, canSave, _) {
                    return ElevatedButton(
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
                          : Text(l10n.actionSave),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
