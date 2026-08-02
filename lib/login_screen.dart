import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'util/app_theme.dart';
import 'util/app_snackbar.dart';
import 'package:provider/provider.dart';

import 'analytics/analytics_features.dart';
import 'analytics/analytics_interactions.dart';
import 'analytics/analytics_screen_names.dart';
import 'core/extensions/l10n_extension.dart';
import 'model/player.dart';
import 'model/invitation.dart';
import 'services/invitationService.dart';
import 'services/playerService.dart';
import 'services/userService.dart';
import 'services/user_trial_service.dart';
import 'services/user_root_service.dart';
import 'util/team_creation_access.dart';
import 'util/player_photo_resolver.dart';
import 'services/active_session_service.dart';
import 'services/analytics_service.dart';
import 'navigation/app_navigator.dart';
import 'services/social_onboarding_coordinator.dart';
import 'services/social_auth_service.dart';
import 'widget/app_language_dropdown.dart';
import 'widget/app_logo.dart';
import 'widget/forgot_password_dialog.dart';
import 'widget/signup_invitation_onboarding.dart';
import 'widget/legal_links_footer.dart';
import 'widget/social_auth_button.dart';
import 'widget/subscription_paywall.dart';

bool _isPasswordValid(String password) {
  if (password.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
  if (!RegExp(r'[0-9]').hasMatch(password)) return false;
  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) return false;
  return true;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final PageController _pageController;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  int _currentPage = 0;
  bool _obscurePassword = true;
  bool _isLoading = false;

  List<_OnboardingItem> _buildItems(BuildContext context) {
    return [
      _OnboardingItem(
        title: context.l10n.slide1Title,
        subtitle: context.l10n.slide1Subtitle,
        icon: Icons.groups_rounded,
        mobileImageAsset: 'assets/images/login_slide1_mobile.png',
        webImageAsset: 'assets/images/login_slide1_web.png',
      ),
      _OnboardingItem(
        title: context.l10n.slide2Title,
        subtitle: context.l10n.slide2Subtitle,
        icon: Icons.calendar_month_rounded,
        mobileImageAsset: 'assets/images/login_slide2_mobile.png',
        webImageAsset: 'assets/images/login_slide2_web.png',
      ),
      _OnboardingItem(
        title: context.l10n.slide3Title,
        subtitle: context.l10n.slide3Subtitle,
        icon: Icons.insights_rounded,
        mobileImageAsset: 'assets/images/login_slide3_mobile.png',
        webImageAsset: 'assets/images/login_slide3_web.png',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.86,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: AnalyticsScreenNames.login,
      );
      _showForcedLogoutMessageIfNeeded();
    });
  }

  void _showForcedLogoutMessageIfNeeded() {
    if (!mounted) return;
    if (!ActiveSessionService.instance
        .consumeForcedLogoutDueToRemoteSession()) {
      return;
    }

    showLoginSnackBar(context, context.l10n.sessionReplacedOnAnotherDevice);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goNextPage(int itemCount) {
    if (!_pageController.hasClients || itemCount == 0) return;

    final next = (_currentPage + 1).clamp(0, itemCount - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _goPreviousPage(int itemCount) {
    if (!_pageController.hasClients || itemCount == 0) return;

    final previous = (_currentPage - 1).clamp(0, itemCount - 1);
    _pageController.animateToPage(
      previous,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _showSnackBar(String message, {BuildContext? snackBarContext}) {
    final messengerContext = snackBarContext ??
        (mounted ? context : null) ??
        appNavigatorKey.currentContext;
    if (messengerContext == null || !messengerContext.mounted) return;
    showLoginSnackBar(messengerContext, message);
  }

  Future<void> _submitWithCredentials(
    String email,
    String password, {
    bool manageParentLoading = true,
    BuildContext? snackBarContext,
  }) async {
    if (mounted) {
      FocusScope.of(context).unfocus();
    } else if (snackBarContext != null && snackBarContext.mounted) {
      FocusScope.of(snackBarContext).unfocus();
    }

    final rootContext = appNavigatorKey.currentContext;
    final l10n = (mounted ? context.l10n : null) ??
        (snackBarContext != null && snackBarContext.mounted
            ? snackBarContext.l10n
            : null) ??
        (rootContext != null && rootContext.mounted
            ? rootContext.l10n
            : null);
    if (l10n == null) {
      debugPrint('login: email sign-in aborted — no context for l10n');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        l10n.emailAndPasswordRequired,
        snackBarContext: snackBarContext,
      );
      return;
    }

    if (manageParentLoading) {
      if (_isLoading) return;
      if (!mounted) return;
      setState(() => _isLoading = true);
    }

    AnalyticsInteractions.logFeature(AnalyticsFeatures.loginAttempt);

    final sessionContext = mounted
        ? context
        : (snackBarContext != null && snackBarContext.mounted
            ? snackBarContext
            : rootContext);
    if (sessionContext == null || !sessionContext.mounted) {
      debugPrint('login: email sign-in aborted — no context for AppSession');
      if (manageParentLoading && mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    final appSession = sessionContext.read<AppSession>();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('login ok uid=${credential.user?.uid}');

      await AnalyticsService.instance.logLogin(method: 'email');
      await AnalyticsService.instance.logFeatureUsed(
        feature: AnalyticsFeatures.loginSuccess,
      );

      // Ferme le bottom sheet mobile avant que AuthGate retire LoginScreen.
      _dismissLoginBottomSheetIfOpen(sheetContext: snackBarContext);
      await _waitForBottomSheetDismissal();

      await appSession.init();
      await appSession.refreshPlayerAvatarUrls();
      await UserRootService.instance.reload();

      // AuthGate réagit à authStateChanges et affiche l'app sans navigation.
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Auth error method=email code=${e.code} message=${e.message}',
      );
      if (!mounted) return;

      String message = l10n.signInError;

      switch (e.code) {
        case 'user-not-found':
          message = l10n.userNotFound;
          break;
        case 'wrong-password':
          message = l10n.wrongPassword;
          break;
        case 'invalid-email':
          message = l10n.invalidEmail;
          break;
        case 'invalid-credential':
          message = l10n.invalidCredential;
          break;
        case 'too-many-requests':
          message = l10n.tooManyRequests;
          break;
        case 'user-disabled':
          message = l10n.userDisabled;
          break;
      }

      _showSnackBar(message, snackBarContext: snackBarContext);
    } catch (e) {
      debugPrint('Auth error method=email unexpected: $e');
      if (!mounted) return;

      _showSnackBar(
        '${l10n.unexpectedError} : $e',
        snackBarContext: snackBarContext,
      );
    } finally {
      if (manageParentLoading && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() => _submitWithCredentials(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );

  Future<void> _signUpWithCredentials(
    String email,
    String password, {
    bool manageParentLoading = true,
    BuildContext? snackBarContext,
  }) async {
    if (mounted) {
      FocusScope.of(context).unfocus();
    } else if (snackBarContext != null && snackBarContext.mounted) {
      FocusScope.of(snackBarContext).unfocus();
    }

    final rootContext = appNavigatorKey.currentContext;
    final l10n = (mounted ? context.l10n : null) ??
        (snackBarContext != null && snackBarContext.mounted
            ? snackBarContext.l10n
            : null) ??
        (rootContext != null && rootContext.mounted
            ? rootContext.l10n
            : null);
    if (l10n == null) {
      debugPrint('login: email signup aborted — no context for l10n');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        l10n.emailAndPasswordRequired,
        snackBarContext: snackBarContext,
      );
      return;
    }

    if (!_isPasswordValid(password)) {
      _showSnackBar(
        l10n.passwordRequirements,
        snackBarContext: snackBarContext,
      );
      return;
    }

    if (manageParentLoading) {
      if (_isLoading) return;
      if (mounted) {
        setState(() => _isLoading = true);
      }
    }

    AnalyticsInteractions.logFeature(AnalyticsFeatures.loginAttempt);

    final appSession = (mounted ? context : null)?.read<AppSession>() ??
        (rootContext != null && rootContext.mounted
            ? rootContext.read<AppSession>()
            : null);
    if (appSession == null) {
      debugPrint('login: email signup aborted — no AppSession');
      return;
    }

    try {
      final emailExists = await UserService().existsByEmail(email);
      if (emailExists) {
        _showSnackBar(
          l10n.emailAlreadyInUse,
          snackBarContext: snackBarContext,
        );
        return;
      }

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUserUid = credential.user?.uid;
      debugPrint('signup ok uid=$newUserUid');

      if (newUserUid == null) {
        throw Exception('Firebase user uid missing after signup');
      }

      await AnalyticsService.instance.logLogin(method: 'email');

      if (manageParentLoading && mounted) {
        setState(() => _isLoading = false);
      }

      _dismissLoginBottomSheetIfOpen(sheetContext: snackBarContext);
      await _waitForBottomSheetDismissal();

      final onboarding = await SignupInvitationOnboarding.run();
      debugPrint(
        'login: signup onboarding result='
        '${onboarding?.profile.firstName ?? 'cancelled'} '
        'linkedExisting=${onboarding?.linkedExistingMember ?? false}',
      );

      if (onboarding == null) {
        await _deleteNewAccountAndSignOut();
        return;
      }

      final profile = onboarding.profile;

      if (manageParentLoading && mounted) {
        setState(() => _isLoading = true);
      }

      try {
        await _createUserAccountDocument(
          uid: newUserUid,
          email: email,
          profile: profile,
        );
        if (onboarding.linkedExistingMember) {
          await _completeInvitationOnboarding(
            uid: newUserUid,
            profile: profile,
            invitation: onboarding.invitation!,
          );
        } else {
          await _completeSocialOnboarding(uid: newUserUid, profile: profile);
        }
        await _refreshSessionAvatars(appSession);
      } catch (e) {
        debugPrint('Email signup profile error: $e');
        await _deleteNewAccountAndSignOut();
        final message = e is StateError &&
                e.message == 'member profile incomplete'
            ? l10n.memberProfileIncomplete
            : '${l10n.unexpectedError} : $e';
        _showSnackBar(message, snackBarContext: snackBarContext);
        return;
      }

      await AnalyticsService.instance.logFeatureUsed(
        feature: AnalyticsFeatures.loginSuccess,
      );

      await _finishOnboardingAfterMemberCreated(
        appSession,
        profile: profile,
        linkedViaInvitation: onboarding.linkedExistingMember,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Auth error method=signup code=${e.code} message=${e.message}',
      );

      String message = l10n.signInError;

      switch (e.code) {
        case 'email-already-in-use':
          message = l10n.emailAlreadyInUse;
          break;
        case 'invalid-email':
          message = l10n.invalidEmail;
          break;
        case 'weak-password':
          message = l10n.passwordRequirements;
          break;
        case 'too-many-requests':
          message = l10n.tooManyRequests;
          break;
        case 'operation-not-allowed':
          message = l10n.signInError;
          break;
      }

      _showSnackBar(message, snackBarContext: snackBarContext);
    } catch (e) {
      debugPrint('Auth error method=signup unexpected: $e');

      _showSnackBar(
        '${l10n.unexpectedError} : $e',
        snackBarContext: snackBarContext,
      );
    } finally {
      if (manageParentLoading && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _userNeedsInvitationOnboarding(UserCredential credential) async {
    final uid = credential.user?.uid;
    if (uid == null) return true;

    final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
    if (!isNewUser) {
      final linkedPlayers = await PlayerService().getPlayersByUserId(uid);
      if (linkedPlayers.isNotEmpty) {
        return false;
      }
    }

    return true;
  }

  void _dismissLoginBottomSheetIfOpen({BuildContext? sheetContext}) {
    if (SocialOnboardingCoordinator.instance.tryDismissLoginSheet()) {
      return;
    }

    final navigatorContext = sheetContext ??
        (mounted ? context : appNavigatorKey.currentContext);
    if (navigatorContext == null || !navigatorContext.mounted) return;

    final navigator = Navigator.of(navigatorContext, rootNavigator: true);
    if (navigator.canPop()) {
      debugPrint('login: dismiss bottom sheet via navigator.pop');
      navigator.pop();
    }
  }

  Future<void> _waitForBottomSheetDismissal() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<bool?> _promptCreateTeam() async {
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      debugPrint('login: create team dialog skipped — no root context');
      return false;
    }

    debugPrint('login: showing create team dialog');

    await WidgetsBinding.instance.endOfFrame;

    if (!rootContext.mounted) {
      debugPrint(
        'login: create team dialog skipped — root context unmounted',
      );
      return false;
    }

    return showDialog<bool>(
      context: rootContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = ctx.appColors;
        return AlertDialog(
          title: Text(ctx.l10n.createTeamPromptQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.createTeamPromptLater),
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

  Future<void> _refreshSessionAvatars(AppSession appSession) async {
    await _refreshSessionAfterOnboarding(appSession);
  }

  Future<void> _finishOnboardingAfterMemberCreated(
    AppSession appSession, {
    required Player profile,
    bool linkedViaInvitation = false,
  }) async {
    final isEducator = profile.isEducatorOrCoach;

    // Resolve avatars before paywall/onboarding UI so late OAuth photoURL
    // is not missed while the web poll budget is consumed elsewhere.
    await _refreshSessionAfterOnboarding(appSession);

    final bool? wantsCreateTeam = linkedViaInvitation
        ? false
        : await _promptCreateTeam();

    await UserTrialService.instance.ensureInitialized();

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      if (!UserTrialService.instance.hasPremiumAccess) {
        await SubscriptionPaywall.show(
          rootContext,
          initialKind: isEducator
              ? SubscriptionOfferingKind.coach
              : SubscriptionOfferingKind.player,
          allowSkip: true,
        );
        await UserTrialService.instance.reload();
        await UserRootService.instance.reload();
      }

      if (wantsCreateTeam == true && rootContext.mounted) {
        await openTeamCreationFlow(rootContext);
      }
    }
  }

  Future<void> _refreshSessionAfterOnboarding(AppSession appSession) async {
    final sessionContext = appNavigatorKey.currentContext;
    if (sessionContext != null && sessionContext.mounted) {
      final session = sessionContext.read<AppSession>();
      await session.init();
      await session.refreshPlayerAvatarUrls();
      return;
    }
    await appSession.init();
    await appSession.refreshPlayerAvatarUrls();
  }

  Future<void> _completeSocialOnboarding({
    required String uid,
    required Player profile,
  }) async {
    if (!profile.isProfileAndContactValid) {
      throw StateError('member profile incomplete');
    }

    await PlayerService().createMember(
      userId: uid,
      profile: profile,
    );
  }

  Future<void> _completeInvitationOnboarding({
    required String uid,
    required Player profile,
    required Invitation invitation,
  }) async {
    if (!profile.isProfileAndContactValid) {
      throw StateError('member profile incomplete');
    }

    final memberId = invitation.extId.trim();
    if (memberId.isEmpty) {
      throw StateError('invitation member id missing');
    }

    final playerService = PlayerService();
    await playerService.linkUserToMember(memberId: memberId, uid: uid);
    await playerService.updateMemberProfile(
      memberId: memberId,
      profile: profile,
    );
    await InvitationService().validateInvitation(invitation.id, uid);
  }

  Future<void> _deleteNewAccountAndSignOut() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('login: failed to delete new account: $e');
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _createUserAccountDocument({
    required String uid,
    required String email,
    required Player profile,
  }) async {
    await UserService().createAccountIfNeeded(
      uid: uid,
      email: email,
      firstName: profile.firstName?.trim() ?? '',
      lastName: profile.lastName?.trim() ?? '',
    );
    await UserTrialService.instance.reload();
    await UserRootService.instance.reload();
  }

  Future<void> _signInWithSocial(
    SocialAuthProvider provider, {
    bool manageParentLoading = true,
    BuildContext? snackBarContext,
  }) async {
    final rootContext = appNavigatorKey.currentContext;
    final sheetContext = snackBarContext;

    if (mounted) {
      FocusScope.of(context).unfocus();
    } else if (sheetContext != null && sheetContext.mounted) {
      FocusScope.of(sheetContext).unfocus();
    }

    if (manageParentLoading) {
      if (_isLoading) return;
      if (mounted) {
        setState(() => _isLoading = true);
      }
    }

    final methodName = switch (provider) {
      SocialAuthProvider.google => 'google',
      SocialAuthProvider.apple => 'apple',
    };

    AnalyticsInteractions.logFeature(AnalyticsFeatures.loginAttempt);

    final l10n = (mounted ? context.l10n : null) ??
        (sheetContext != null && sheetContext.mounted
            ? sheetContext.l10n
            : null) ??
        (rootContext != null && rootContext.mounted
            ? rootContext.l10n
            : null);
    if (l10n == null) {
      debugPrint('login: social sign-in aborted — no context for l10n');
      return;
    }

    try {
      final credential =
          await SocialAuthService.instance.signIn(provider);
      final uid = credential.user?.uid;
      debugPrint(
        'login: social auth success uid=$uid provider=$methodName '
        'photoURL=${credential.user?.photoURL}',
      );

      if (uid == null) {
        throw Exception('Firebase user uid missing after social login');
      }

      final authUser = credential.user;
      if (authUser != null) {
        if (kIsWeb) {
          try {
            await authUser.reload().timeout(const Duration(seconds: 3));
          } catch (_) {}
        }
        final resolvedUser = FirebaseAuth.instance.currentUser ?? authUser;
        final oauthPhoto = readAuthUserPhotoUrl(resolvedUser);
        final session = (appNavigatorKey.currentContext ?? rootContext)
                ?.read<AppSession>() ??
            (mounted ? context.read<AppSession>() : null);
        session?.cacheOAuthPhotoUrl(oauthPhoto);
      }

      await AnalyticsService.instance.logLogin(method: methodName);

      final needsInvitation =
          await _userNeedsInvitationOnboarding(credential);
      debugPrint('login: needsInvitation=$needsInvitation');
      var memberJustCreated = false;
      var linkedViaInvitation = false;
      Player? createdProfile;

      if (needsInvitation) {
        if (manageParentLoading && mounted) {
          setState(() => _isLoading = false);
        }

        _dismissLoginBottomSheetIfOpen(sheetContext: sheetContext);
        await _waitForBottomSheetDismissal();

        final onboarding = await SignupInvitationOnboarding.run();
        debugPrint(
          'login: signup onboarding result='
          '${onboarding?.profile.firstName ?? 'cancelled'} '
          'linkedExisting=${onboarding?.linkedExistingMember ?? false}',
        );

        if (onboarding == null) {
          await _deleteNewAccountAndSignOut();
          return;
        }

        final profile = onboarding.profile;

        if (manageParentLoading && mounted) {
          setState(() => _isLoading = true);
        }

        try {
          await _createUserAccountDocument(
            uid: uid,
            email: credential.user?.email ?? '',
            profile: profile,
          );
          if (onboarding.linkedExistingMember) {
            await _completeInvitationOnboarding(
              uid: uid,
              profile: profile,
              invitation: onboarding.invitation!,
            );
          } else {
            await _completeSocialOnboarding(uid: uid, profile: profile);
          }
          final refreshSession = (appNavigatorKey.currentContext ?? rootContext)
                  ?.read<AppSession>() ??
              (mounted ? context.read<AppSession>() : null);
          if (refreshSession != null) {
            await _refreshSessionAvatars(refreshSession);
          }
          createdProfile = profile;
          linkedViaInvitation = onboarding.linkedExistingMember;
          memberJustCreated = true;
        } catch (e) {
          debugPrint('Social onboarding error: $e');
          await _deleteNewAccountAndSignOut();
          final message = e is StateError &&
                  e.message == 'member profile incomplete'
              ? l10n.memberProfileIncomplete
              : '${l10n.unexpectedError} : $e';
          _showSnackBar(message, snackBarContext: sheetContext);
          return;
        }
      } else {
        _dismissLoginBottomSheetIfOpen(sheetContext: sheetContext);
        await _waitForBottomSheetDismissal();
      }

      await AnalyticsService.instance.logFeatureUsed(
        feature: AnalyticsFeatures.loginSuccess,
      );

      if (memberJustCreated && createdProfile != null) {
        final appSession = (appNavigatorKey.currentContext ?? rootContext)
                ?.read<AppSession>() ??
            (mounted ? context.read<AppSession>() : null);
        if (appSession != null) {
          await _finishOnboardingAfterMemberCreated(
            appSession,
            profile: createdProfile,
            linkedViaInvitation: linkedViaInvitation,
          );
        } else {
          debugPrint(
            'login: onboarding finish skipped — no AppSession for avatar refresh',
          );
        }
      } else {
        final sessionContext = appNavigatorKey.currentContext ?? rootContext;
        if (sessionContext != null && sessionContext.mounted) {
          final session = sessionContext.read<AppSession>();
          await session.init();
          await session.refreshPlayerAvatarUrls();
          await UserRootService.instance.reload();
        } else if (mounted) {
          final session = context.read<AppSession>();
          await session.init();
          await session.refreshPlayerAvatarUrls();
          await UserRootService.instance.reload();
        }
      }
      debugPrint('login: social sign-in complete, appSession initialized');
    } on SocialAuthCancelledException {
      debugPrint('Auth cancelled provider=$methodName');
      return;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Auth error provider=$methodName code=${e.code} message=${e.message}',
      );

      _showSnackBar(
        e.message ?? l10n.signInError,
        snackBarContext: sheetContext,
      );
    } catch (e) {
      debugPrint('Auth error provider=$methodName unexpected: $e');

      _showSnackBar(
        '${l10n.unexpectedError} : $e',
        snackBarContext: sheetContext,
      );
    } finally {
      if (manageParentLoading && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLoginSheet() {
    final isTabletOrMobile = MediaQuery.of(context).size.width < 900;

    if (!isTabletOrMobile) return;

    final coordinator = SocialOnboardingCoordinator.instance;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        coordinator.registerLoginSheetCloser(() {
          if (sheetContext.mounted) {
            Navigator.of(sheetContext, rootNavigator: true).pop();
          }
        });

        return _LoginBottomSheet(
          onSignIn: _submitWithCredentials,
          onSignUp: _signUpWithCredentials,
          onSocialSignIn: _signInWithSocial,
          onForgotPassword: () => _onForgotPassword(sheetContext),
        );
      },
    ).whenComplete(coordinator.unregisterLoginSheetCloser);
  }

  Future<void> _onForgotPassword([BuildContext? dialogContext]) async {
    final ctx = dialogContext ?? context;
    if (!ctx.mounted) return;
    await showForgotPasswordDialog(
      ctx,
      initialEmail: _emailCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final items = _buildItems(context);

    if (kIsWeb || width >= 900) {
      return _WebLoginLayout(
        items: items,
        currentPage: _currentPage,
        pageController: _pageController,
        emailCtrl: _emailCtrl,
        passwordCtrl: _passwordCtrl,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        onPageChanged: (index) => setState(() => _currentPage = index),
        onToggleObscure: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
        onSignIn: _submit,
        onSignUp: (email, password) => _signUpWithCredentials(
          email,
          password,
        ),
        onSocialSignIn: _signInWithSocial,
        onForgotPassword: () => _onForgotPassword(),
        onPreviousPage: () => _goPreviousPage(items.length),
        onNextPage: () => _goNextPage(items.length),
      );
    }

    return _MobileLoginLayout(
      items: items,
      currentPage: _currentPage,
      pageController: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      onLogin: _goToLoginSheet,
    );
  }
}

class _WebLoginLayout extends StatelessWidget {
  final List<_OnboardingItem> items;
  final int currentPage;
  final PageController pageController;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final Future<void> Function(String email, String password) onSignUp;
  final Future<void> Function(SocialAuthProvider provider) onSocialSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const _WebLoginLayout({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onPageChanged,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSocialSignIn,
    required this.onForgotPassword,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.background,
                    colors.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactHeight = constraints.maxHeight < 740;
                    final carouselHeight = isCompactHeight
                        ? (constraints.maxHeight * 0.42).clamp(160.0, 280.0)
                        : 420.0;
                    final horizontalPadding = isCompactHeight ? 24.0 : 40.0;
                    final verticalPadding = isCompactHeight ? 20.0 : 40.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight -
                              (verticalPadding * 2),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: isCompactHeight ? 48 : 72,
                                  child: const Align(
                                    alignment: Alignment.topCenter,
                                    child: _BrandHeader(),
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 8 : 16),
                                Text(
                                  context.l10n.heroTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    fontSize: isCompactHeight ? 28 : null,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isCompactHeight ? 10 : 18),
                                Text(
                                  context.l10n.heroSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                  maxLines: isCompactHeight ? 6 : 8,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isCompactHeight ? 12 : 24),
                                SizedBox(
                                  height: carouselHeight,
                                  child: _OnboardingCardCarousel(
                                    items: items,
                                    controller: pageController,
                                    currentPage: currentPage,
                                    onPageChanged: onPageChanged,
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 12 : 20),
                                SizedBox(
                                  height: 56,
                                  child: _DesktopCarouselControls(
                                    itemCount: items.length,
                                    currentPage: currentPage,
                                    onPrevious: onPreviousPage,
                                    onNext: onNextPage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: colors.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _LoginCard(
                      emailCtrl: emailCtrl,
                      passwordCtrl: passwordCtrl,
                      obscurePassword: obscurePassword,
                      isLoading: isLoading,
                      onToggleObscure: onToggleObscure,
                      onSignIn: onSignIn,
                      onSignUp: onSignUp,
                      onSocialSignIn: onSocialSignIn,
                      onForgotPassword: onForgotPassword,
                      onLocaleChanged: (locale) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isMobile;

  const _BrandHeader({
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    double logoWidth;
    if (isMobile) {
      logoWidth = isLandscape ? size.height * 0.55 : size.width * 0.82;
    } else if (size.width < 1200) {
      logoWidth = size.width * 0.30;
    } else {
      logoWidth = size.width * 0.24;
    }

    final minWidth = isMobile && isLandscape ? 120.0 : 280.0;
    final maxWidth = isMobile && isLandscape ? 220.0 : 760.0;

    return AppLogo(
      width: logoWidth.clamp(minWidth, maxWidth),
    );
  }
}

class _DesktopCarouselControls extends StatelessWidget {
  final int itemCount;
  final int currentPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DesktopCarouselControls({
    required this.itemCount,
    required this.currentPage,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CarouselArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: currentPage > 0 ? onPrevious : null,
        ),
        const SizedBox(width: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            itemCount,
                (index) {
              final bool isActive = index == currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? colors.primary
                      : colors.textSecondary.withValues(alpha: 0.45),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 28),
        _CarouselArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: currentPage < itemCount - 1 ? onNext : null,
        ),
      ],
    );
  }
}

class _CarouselArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CarouselArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? colors.surface : colors.surface.withValues(alpha: 0.6),
          border: Border.all(
            color: colors.border,
          ),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Icon(
          icon,
          size: 34,
          color: enabled
              ? colors.primary
              : colors.textSecondary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  final List<_OnboardingItem> items;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onLogin;

  const _MobileLoginLayout({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 700;
    final isLandscape = size.width > size.height;
    final brandHeight = isLandscape
        ? (size.height * 0.14).clamp(40.0, 64.0)
        : size.height * 0.10;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colors.primary,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary,
              colors.background,
              colors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, isLandscape ? -8 : -18),
                    child: SizedBox(
                      height: brandHeight,
                      child: const Align(
                        alignment: Alignment.topCenter,
                        child: _BrandHeader(isMobile: true),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 28 : 16,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isLandscape ? 4 : 12),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 700 : 420,
                                ),
                                child: _MobileHeroCard(
                                  items: items,
                                  controller: pageController,
                                  currentPage: currentPage,
                                  onPageChanged: onPageChanged,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isLandscape ? 12 : 24),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 520 : double.infinity,
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: onLogin,
                                    child: Text(context.l10n.signIn),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const LegalLinksFooter(),
                                SizedBox(height: isLandscape ? 8 : 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (constraints.maxHeight < 420) {
                return SingleChildScrollView(
                  child: SizedBox(
                    height: 420,
                    child: content,
                  ),
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final Future<void> Function(String email, String password) onSignUp;
  final Future<void> Function(SocialAuthProvider provider) onSocialSignIn;
  final VoidCallback onForgotPassword;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback? onBack;

  const _LoginCard({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSocialSignIn,
    required this.onForgotPassword,
    required this.onLocaleChanged,
    this.onBack,
  });

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _confirmPasswordCtrl.clear();
    });
  }

  void _handleBack() {
    if (_isSignUpMode) {
      setState(() {
        _isSignUpMode = false;
        _confirmPasswordCtrl.clear();
      });
      return;
    }

    widget.onBack?.call();
  }

  bool get _showBackButton => widget.onBack != null || _isSignUpMode;

  Future<void> _handleSubmit() async {
    if (!mounted) return;

    final email = widget.emailCtrl.text.trim();
    final password = widget.passwordCtrl.text.trim();

    if (_isSignUpMode) {
      final confirmPassword = _confirmPasswordCtrl.text.trim();
      if (confirmPassword != password) {
        if (!mounted) return;
        showLoginSnackBar(context, context.l10n.passwordsDoNotMatch);
        return;
      }

      await widget.onSignUp(email, password);
    } else {
      if (!mounted) return;
      widget.onSignIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showBackButton) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.isLoading ? null : _handleBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(context.l10n.actionBack),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _isSignUpMode
                        ? context.l10n.createAccount
                        : context.l10n.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  width: 132,
                  child: AppLanguageDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.loginSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.email,
                hintText: context.l10n.emailHint,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: widget.passwordCtrl,
              obscureText: widget.obscurePassword,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                hintText: context.l10n.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: widget.onToggleObscure,
                  icon: Icon(
                    widget.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
            if (_isSignUpMode) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: context.l10n.confirmPassword,
                  hintText: context.l10n.confirmPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ],
            const SizedBox(height: 10),
            if (!_isSignUpMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onForgotPassword,
                  child: Text(context.l10n.forgotPassword),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _isSignUpMode
                          ? context.l10n.alreadyHaveAccount
                          : context.l10n.noAccountYet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleMode,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isSignUpMode
                          ? context.l10n.signInLink
                          : context.l10n.createOneLink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _handleSubmit,
                child: widget.isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  _isSignUpMode
                      ? context.l10n.createAccount
                      : context.l10n.signIn,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Divider(color: colors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    context.l10n.or,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                Expanded(child: Divider(color: colors.border)),
              ],
            ),
            const SizedBox(height: 22),
            SocialAuthButton(
              provider: SocialAuthProvider.google,
              label: context.l10n.continueWithGoogle,
              onPressed: widget.isLoading
                  ? null
                  : () => widget.onSocialSignIn(SocialAuthProvider.google),
            ),
            const SizedBox(height: 12),
            SocialAuthButton(
              provider: SocialAuthProvider.apple,
              label: context.l10n.continueWithApple,
              onPressed: widget.isLoading
                  ? null
                  : () => widget.onSocialSignIn(SocialAuthProvider.apple),
            ),
            const SizedBox(height: 16),
            const LegalLinksFooter(),
          ],
        ),
      ),
    );
  }
}

class _LoginBottomSheet extends StatefulWidget {
  final Future<void> Function(
    String email,
    String password, {
    bool manageParentLoading,
    BuildContext? snackBarContext,
  }) onSignIn;
  final Future<void> Function(
    String email,
    String password, {
    bool manageParentLoading,
    BuildContext? snackBarContext,
  }) onSignUp;
  final Future<void> Function(
    SocialAuthProvider provider, {
    bool manageParentLoading,
    BuildContext? snackBarContext,
  }) onSocialSignIn;
  final VoidCallback onForgotPassword;

  const _LoginBottomSheet({
    required this.onSignIn,
    required this.onSignUp,
    required this.onSocialSignIn,
    required this.onForgotPassword,
  });

  @override
  State<_LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<_LoginBottomSheet> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_isLoading || !mounted) return;

    final snackBarContext = context;
    setState(() => _isLoading = true);
    try {
      await widget.onSignIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
        manageParentLoading: false,
        snackBarContext:
            snackBarContext.mounted ? snackBarContext : null,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp(
    String email,
    String password,
  ) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSignUp(
        email,
        password,
        manageParentLoading: false,
        snackBarContext: context,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialSignIn(SocialAuthProvider provider) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSocialSignIn(
        provider,
        manageParentLoading: false,
        snackBarContext: context,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: context.l10n.actionBack,
                    ),
                    const Spacer(),
                  ],
                ),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                _LoginCard(
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onSignIn: _handleSignIn,
                  onSignUp: _handleSignUp,
                  onSocialSignIn: _handleSocialSignIn,
                  onForgotPassword: widget.onForgotPassword,
                  onLocaleChanged: (_) {},
                  onBack: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileHeroCard extends StatelessWidget {
  final List<_OnboardingItem> items;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _MobileHeroCard({
    required this.items,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _OnboardingCardCarousel(
            items: items,
            controller: controller,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
            mobileMode: true,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? colors.primary
                    : colors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingCardCarousel extends StatelessWidget {
  final List<_OnboardingItem> items;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final bool mobileMode;

  const _OnboardingCardCarousel({
    required this.items,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    this.mobileMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      padEnds: false,
      itemCount: items.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final bool isActive = index == currentPage;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            right: 16,
            top: isActive ? 4 : 8,
            bottom: isActive ? 4 : 8,
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            scale: isActive ? 1 : 0.96,
            child: _FeatureShowcaseCard(
              item: items[index],
              mobileMode: mobileMode,
            ),
          ),
        );
      },
    );
  }
}

class _FeatureShowcaseCard extends StatelessWidget {
  final _OnboardingItem item;
  final bool mobileMode;

  const _FeatureShowcaseCard({
    required this.item,
    this.mobileMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageAsset = item.imageAssetFor(mobileMode: mobileMode);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxHeight < 420;
          final bool ultraCompact = constraints.maxHeight < 240;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary.withValues(alpha: 0.10),
                  colors.card,
                  colors.secondary.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ultraCompact ? 10 : (compact ? 16 : (mobileMode ? 20 : 28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: imageAsset != null
                        ? _ShowcaseImage(assetPath: imageAsset)
                        : _ShowcasePlaceholder(
                            item: item,
                            compact: compact,
                            ultraCompact: ultraCompact,
                          ),
                  ),
                  SizedBox(height: ultraCompact ? 8 : (compact ? 12 : 20)),
                  Text(
                    item.title,
                    maxLines: ultraCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: ultraCompact ? 16 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    maxLines: ultraCompact ? 3 : (compact ? 4 : 5),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                      fontSize: ultraCompact ? 12 : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShowcaseImage extends StatelessWidget {
  const _ShowcaseImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _ShowcasePlaceholder extends StatelessWidget {
  const _ShowcasePlaceholder({
    required this.item,
    required this.compact,
    required this.ultraCompact,
  });

  final _OnboardingItem item;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: ultraCompact ? 220 : 320,
          child: Container(
            padding: EdgeInsets.all(ultraCompact ? 12 : 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(ultraCompact ? 20 : 28),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: ultraCompact ? 40 : 52,
                    height: ultraCompact ? 40 : 52,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: colors.primary,
                      size: ultraCompact ? 22 : 28,
                    ),
                  ),
                ),
                SizedBox(height: ultraCompact ? 10 : (compact ? 12 : 20)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ultraCompact ? 10 : 16),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(ultraCompact ? 14 : 18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: ultraCompact ? 10 : 12,
                        width: ultraCompact ? 90 : 110,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      SizedBox(height: ultraCompact ? 8 : 12),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: ultraCompact ? 120 : 160,
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      SizedBox(
                        height: ultraCompact ? 10 : (compact ? 12 : 16),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: ultraCompact ? 32 : 44,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: ultraCompact ? 32 : 44,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? mobileImageAsset;
  final String? webImageAsset;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.mobileImageAsset,
    this.webImageAsset,
  });

  String? imageAssetFor({required bool mobileMode}) {
    return mobileMode ? mobileImageAsset : webImageAsset;
  }
}
