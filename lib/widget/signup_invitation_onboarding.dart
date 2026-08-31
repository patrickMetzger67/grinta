import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/invitationService.dart';
import 'package:grinta/services/invitation_deep_link_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/auth_profile_seed.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/member_profile_form.dart';

/// Outcome of the post-signup member onboarding flow.
class SignupMemberOnboardingResult {
  const SignupMemberOnboardingResult({
    required this.profile,
    this.invitation,
  });

  final Player profile;

  /// Set when an existing roster member was linked via invitation code.
  final Invitation? invitation;

  bool get linkedExistingMember => invitation != null;
}

/// Runs invitation-code and member-profile steps.
///
/// Email signup: call with [requireEmail] **before** creating Firebase Auth /
/// `users/{uid}`. Social signup may keep [requireEmail] false.
class SignupInvitationOnboarding {
  SignupInvitationOnboarding._();

  static final InvitationService _invitationService = InvitationService();
  static final PlayerService _playerService = PlayerService();
  static final UserService _userService = UserService();

  static Future<SignupMemberOnboardingResult?> run({
    bool requireEmail = false,
    /// Prefill from Firebase Auth (Apple/Google) so Review Guideline 4
    /// is satisfied — name/email already provided by the IdP.
    Player? authSeedProfile,
    /// When true (social signup), never re-ask name/email even if the seed
    /// is incomplete — Apple only sends those fields on first authorization.
    bool lockIdentityFromAuth = false,
  }) async {
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      debugPrint(
        'SignupInvitationOnboarding.run skipped — no root context',
      );
      return null;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!rootContext.mounted) return null;

    final hasInvitationCode = await _promptHasInvitationCode(rootContext);
    if (hasInvitationCode == null) {
      return null;
    }

    if (!hasInvitationCode) {
      // Drop any deep-link code the user chose not to use.
      await InvitationDeepLinkService.instance.takePendingCode();
      final profile = await _promptMemberProfile(
        rootContext,
        initialProfile: authSeedProfile,
        requireEmail: requireEmail,
        lockIdentityFromAuth: lockIdentityFromAuth,
      );
      if (profile == null) return null;
      return SignupMemberOnboardingResult(profile: profile);
    }

    String? seedCode =
        await InvitationDeepLinkService.instance.takePendingCode();

    while (rootContext.mounted) {
      final String? code;
      if (seedCode != null && seedCode.isNotEmpty) {
        code = seedCode;
        seedCode = null;
      } else {
        code = await _promptInvitationCode(rootContext);
      }
      if (code == null) {
        return null;
      }

      final lookup = await _lookupInvitation(rootContext, code);
      switch (lookup.kind) {
        case _InvitationLookupKind.found:
          final invitation = lookup.invitation!;
          final member = lookup.member!;
          // Guideline 4: even when linking an invitation after SIWA/Google,
          // never re-ask name/email — keep IdP identity locked.
          final profile = await _promptMemberProfile(
            rootContext,
            initialProfile: mergeAuthIdentityOntoMemberProfile(
              member: member.toEditableProfile(),
              authSeed: authSeedProfile,
            ),
            subtitle: await _invitationSubtitle(rootContext, invitation),
            requireEmail: requireEmail,
            lockIdentityFromAuth: lockIdentityFromAuth,
          );
          if (profile == null) return null;
          return SignupMemberOnboardingResult(
            profile: profile,
            invitation: invitation,
          );
        case _InvitationLookupKind.continueWithoutInvitation:
          final profile = await _promptMemberProfile(
            rootContext,
            initialProfile: authSeedProfile,
            requireEmail: requireEmail,
            lockIdentityFromAuth: lockIdentityFromAuth,
          );
          if (profile == null) return null;
          return SignupMemberOnboardingResult(profile: profile);
        case _InvitationLookupKind.abortSignup:
          return null;
        case _InvitationLookupKind.retry:
          continue;
      }
    }

    return null;
  }

  /// Password + confirm after profile is validated (email Auth path).
  static Future<String?> promptSignupPassword({
    required String email,
  }) async {
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return null;

    return showDialog<String>(
      context: rootContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => _SignupPasswordDialog(email: email),
    );
  }

  static Future<String?> _invitationSubtitle(
    BuildContext context,
    Invitation invitation,
  ) async {
    final inviter = await _userService.getById(invitation.uid);
    if (inviter == null) return null;
    if (!context.mounted) return null;

    final firstName = inviter.firstName.trim();
    final lastName = inviter.lastName.trim();
    if (firstName.isEmpty && lastName.isEmpty) return null;

    return context.l10n.invitationSentBy(firstName, lastName);
  }

  static Future<_InvitationLookupResult> _lookupInvitation(
    BuildContext context,
    String code,
  ) async {
    try {
      final invitation = await _invitationService.findByCode(code);
      if (invitation == null) {
        return _promptAfterMissingInvitation(context);
      }

      if (invitation.isValidated) {
        AppSnackbar.show(context, context.l10n.invitationAlreadyUsed);
        return _promptAfterMissingInvitation(context);
      }

      if (invitation.type != invitationTypeMember) {
        AppSnackbar.show(context, context.l10n.invitationNotFound);
        return _promptAfterMissingInvitation(context);
      }

      final memberId = invitation.extId.trim();
      if (memberId.isEmpty) {
        AppSnackbar.show(context, context.l10n.invitationNotFound);
        return _promptAfterMissingInvitation(context);
      }

      final member = await _playerService.getPlayerById(memberId);
      if (member == null) {
        AppSnackbar.show(context, context.l10n.invitationNotFound);
        return _promptAfterMissingInvitation(context);
      }

      if (isMemberLinkedToAppAccount(member)) {
        AppSnackbar.show(context, context.l10n.invitationAlreadyUsed);
        return _promptAfterMissingInvitation(context);
      }

      return _InvitationLookupResult.found(
        invitation: invitation,
        member: member,
      );
    } catch (e) {
      debugPrint('SignupInvitationOnboarding.lookup failed: $e');
      AppSnackbar.show(
        context,
        '${context.l10n.unexpectedError} : $e',
        isError: true,
      );
      return _InvitationLookupResult.retry;
    }
  }

  static Future<_InvitationLookupResult> _promptAfterMissingInvitation(
    BuildContext context,
  ) async {
    final continueWithoutInvitation =
        await _promptInvitationNotFoundContinue(context);
    if (continueWithoutInvitation == null) {
      return _InvitationLookupResult.retry;
    }
    if (continueWithoutInvitation) {
      return _InvitationLookupResult.continueWithoutInvitation;
    }
    return _InvitationLookupResult.abortSignup;
  }

  static Future<bool?> _promptHasInvitationCode(BuildContext context) {
    final colors = context.appColors;

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.l10n.hasInvitationCodeQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.actionNo),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.actionYes),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
        );
      },
    );
  }

  static Future<String?> _promptInvitationCode(BuildContext context) {
    final colors = context.appColors;

    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        final codeCtrl = TextEditingController();
        return AlertDialog(
          title: Text(ctx.l10n.invitationCode),
          content: TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: ctx.l10n.invitationCode,
              hintText: ctx.l10n.invitationCodeHint,
            ),
            onSubmitted: (_) => _submitInvitationCode(ctx, codeCtrl),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(ctx.l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => _submitInvitationCode(ctx, codeCtrl),
              child: Text(ctx.l10n.actionValidate),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
        );
      },
    );
  }

  static void _submitInvitationCode(
    BuildContext context,
    TextEditingController codeCtrl,
  ) {
    final code = codeCtrl.text.trim();
    if (code.isEmpty) {
      AppSnackbar.show(context, context.l10n.invitationCodeRequired);
      return;
    }
    Navigator.of(context).pop(code);
  }

  static Future<bool?> _promptInvitationNotFoundContinue(
    BuildContext context,
  ) {
    final colors = context.appColors;

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.l10n.invitationNotFound),
          content: Text(ctx.l10n.invitationNotFoundContinuePrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.actionNo),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.actionYes),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
        );
      },
    );
  }

  static Future<Player?> _promptMemberProfile(
    BuildContext context, {
    Player? initialProfile,
    String? subtitle,
    bool requireEmail = false,
    bool lockIdentityFromAuth = false,
  }) {
    final colors = context.appColors;

    return showDialog<Player?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return _SignupMemberProfileDialog(
          initialProfile: initialProfile,
          subtitle: subtitle,
          requireEmail: requireEmail,
          lockIdentityFromAuth: lockIdentityFromAuth,
          dialogShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
        );
      },
    );
  }
}

enum _InvitationLookupKind {
  found,
  continueWithoutInvitation,
  abortSignup,
  retry,
}

class _InvitationLookupResult {
  const _InvitationLookupResult._(this.kind, {this.invitation, this.member});

  final _InvitationLookupKind kind;
  final Invitation? invitation;
  final Player? member;

  factory _InvitationLookupResult.found({
    required Invitation invitation,
    required Player member,
  }) {
    return _InvitationLookupResult._(
      _InvitationLookupKind.found,
      invitation: invitation,
      member: member,
    );
  }

  static const _InvitationLookupResult continueWithoutInvitation =
      _InvitationLookupResult._(_InvitationLookupKind.continueWithoutInvitation);

  static const _InvitationLookupResult abortSignup =
      _InvitationLookupResult._(_InvitationLookupKind.abortSignup);

  static const _InvitationLookupResult retry =
      _InvitationLookupResult._(_InvitationLookupKind.retry);
}

class _SignupMemberProfileDialog extends StatefulWidget {
  const _SignupMemberProfileDialog({
    this.initialProfile,
    this.subtitle,
    this.requireEmail = false,
    this.lockIdentityFromAuth = false,
    required this.dialogShape,
  });

  final Player? initialProfile;
  final String? subtitle;
  final bool requireEmail;
  final bool lockIdentityFromAuth;
  final ShapeBorder dialogShape;

  @override
  State<_SignupMemberProfileDialog> createState() =>
      _SignupMemberProfileDialogState();
}

class _SignupMemberProfileDialogState extends State<_SignupMemberProfileDialog> {
  MemberProfileFormState? _formState;
  String? _inlineError;

  void _onFormStateCreated(MemberProfileFormState state) {
    _formState = state;
  }

  void _showError(String message) {
    setState(() => _inlineError = message);
  }

  void _submit() {
    final formState = _formState;
    if (formState == null || !formState.mounted) return;

    final validationError = formState.validateAndGetError();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    final profile = formState.buildProfile();
    if (profile == null) {
      _showError(context.l10n.memberProfileIncomplete);
      return;
    }

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: Text(context.l10n.memberProfileTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_inlineError != null) ...[
              Material(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            MemberProfileForm(
              key: ValueKey(
                'signup-member-profile-'
                '${widget.initialProfile?.keyMember?.trim().isNotEmpty == true ? widget.initialProfile!.keyMember : (widget.initialProfile?.email ?? 'new')}',
              ),
              enabled: true,
              initialProfile: widget.initialProfile,
              requireEmail: widget.requireEmail,
              lockIdentityFromAuth: widget.lockIdentityFromAuth,
              onFormStateCreated: _onFormStateCreated,
              onChanged: (_) {
                if (_inlineError != null) {
                  setState(() => _inlineError = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(context.l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.l10n.memberProfileSubmit),
        ),
      ],
      shape: widget.dialogShape,
    );
  }
}

bool _isSignupPasswordValid(String password) {
  if (password.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) return false;
  return true;
}

class _SignupPasswordDialog extends StatefulWidget {
  const _SignupPasswordDialog({required this.email});

  final String email;

  @override
  State<_SignupPasswordDialog> createState() => _SignupPasswordDialogState();
}

class _SignupPasswordDialogState extends State<_SignupPasswordDialog> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _inlineError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final l10n = context.l10n;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _inlineError = l10n.emailAndPasswordRequired);
      return;
    }
    if (password != confirm) {
      setState(() => _inlineError = l10n.passwordsDoNotMatch);
      return;
    }
    if (!_isSignupPasswordValid(password)) {
      setState(() => _inlineError = l10n.passwordRequirements);
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: AlertDialog(
      title: Text(l10n.signupPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.signupPasswordMessage(widget.email),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 12),
              Material(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _inlineError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              autofocus: true,
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_inlineError != null) setState(() => _inlineError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_inlineError != null) setState(() => _inlineError = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.createAccount),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      ),
    );
  }
}
