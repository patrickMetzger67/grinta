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
import 'services/playerService.dart';
import 'services/userService.dart';
import 'services/user_trial_service.dart';
import 'util/player_positions.dart';
import 'services/active_session_service.dart';
import 'services/analytics_service.dart';
import 'navigation/app_navigator.dart';
import 'services/social_onboarding_coordinator.dart';
import 'services/social_auth_service.dart';
import 'widget/app_language_dropdown.dart';
import 'widget/app_logo.dart';
import 'widget/member_profile_form.dart';
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
      ),
      _OnboardingItem(
        title: context.l10n.slide2Title,
        subtitle: context.l10n.slide2Subtitle,
        icon: Icons.calendar_month_rounded,
      ),
      _OnboardingItem(
        title: context.l10n.slide3Title,
        subtitle: context.l10n.slide3Subtitle,
        icon: Icons.insights_rounded,
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
    FocusScope.of(context).unfocus();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        context.l10n.emailAndPasswordRequired,
        snackBarContext: snackBarContext,
      );
      return;
    }

    if (manageParentLoading) {
      if (_isLoading) return;
      setState(() => _isLoading = true);
    }

    AnalyticsInteractions.logFeature(AnalyticsFeatures.loginAttempt);

    final appSession = context.read<AppSession>();
    final l10n = context.l10n;

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

      if (!mounted) return;

      // Ferme le bottom sheet mobile avant que AuthGate retire LoginScreen.
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }

      await appSession.init();
      await appSession.refreshPlayerAvatarUrls();

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

      final profile = await _promptMemberProfile();
      debugPrint(
        'login: member profile dialog result=${profile?.firstName ?? 'cancelled'}',
      );

      if (profile == null) {
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (manageParentLoading && mounted) {
        setState(() => _isLoading = true);
      }

      try {
        await _createUserAccountDocument(
          uid: newUserUid,
          email: email,
          profile: profile,
        );
        await _completeSocialOnboarding(uid: newUserUid, profile: profile);
        await _refreshSessionAvatars(appSession);
      } catch (e) {
        debugPrint('Email signup profile error: $e');
        await FirebaseAuth.instance.signOut();
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
    final sessionContext = appNavigatorKey.currentContext;
    if (sessionContext != null && sessionContext.mounted) {
      await sessionContext.read<AppSession>().refreshPlayerAvatarUrls();
      return;
    }
    await appSession.refreshPlayerAvatarUrls();
  }

  Future<void> _finishOnboardingAfterMemberCreated(
    AppSession appSession, {
    required Player profile,
  }) async {
    final isEducator = profile.positionCodes.contains(positionCodeEducator);
    bool? wantsCreateTeam;
    if (isEducator) {
      wantsCreateTeam = await _promptCreateTeam();
    }

    await UserTrialService.instance.ensureInitialized();

    if (!UserTrialService.instance.hasPremiumAccess) {
      final rootContext = appNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        await SubscriptionPaywall.show(
          rootContext,
          initialKind: wantsCreateTeam == true
              ? SubscriptionOfferingKind.coach
              : SubscriptionOfferingKind.player,
          allowSkip: true,
        );
      }
    }

    if (wantsCreateTeam == true) {
      final rootContext = appNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        showLoginSnackBar(
          rootContext,
          rootContext.l10n.signupWithoutInvitationComingSoon,
          isError: false,
        );
      }
      // TODO: navigate to team creation flow
    }

    final sessionContext = appNavigatorKey.currentContext;
    if (sessionContext != null && sessionContext.mounted) {
      final session = sessionContext.read<AppSession>();
      await session.init();
      await session.refreshPlayerAvatarUrls();
    } else {
      await appSession.init();
      await appSession.refreshPlayerAvatarUrls();
    }
  }

  Future<Player?> _promptMemberProfile() async {
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      debugPrint('login: member profile dialog skipped — no root context');
      return null;
    }

    debugPrint('login: showing member profile dialog');

    await WidgetsBinding.instance.endOfFrame;

    if (!rootContext.mounted) {
      debugPrint(
        'login: member profile dialog skipped — root context unmounted',
      );
      return null;
    }

    return showDialog<Player?>(
      context: rootContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => const _MemberProfileDialog(),
    );
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

      await AnalyticsService.instance.logLogin(method: methodName);

      final needsInvitation =
          await _userNeedsInvitationOnboarding(credential);
      debugPrint('login: needsInvitation=$needsInvitation');
      var memberJustCreated = false;
      Player? createdProfile;

      if (needsInvitation) {
        if (manageParentLoading && mounted) {
          setState(() => _isLoading = false);
        }

        _dismissLoginBottomSheetIfOpen(sheetContext: sheetContext);
        await _waitForBottomSheetDismissal();

        final profile = await _promptMemberProfile();
        debugPrint(
          'login: member profile dialog result=${profile?.firstName ?? 'cancelled'}',
        );

        if (profile == null) {
          await FirebaseAuth.instance.signOut();
          return;
        }

        if (manageParentLoading && mounted) {
          setState(() => _isLoading = true);
        }

        try {
          await _createUserAccountDocument(
            uid: uid,
            email: credential.user?.email ?? '',
            profile: profile,
          );
          await _completeSocialOnboarding(uid: uid, profile: profile);
          final refreshSession = (appNavigatorKey.currentContext ?? rootContext)
                  ?.read<AppSession>() ??
              (mounted ? context.read<AppSession>() : null);
          if (refreshSession != null) {
            await _refreshSessionAvatars(refreshSession);
          }
          createdProfile = profile;
          memberJustCreated = true;
        } catch (e) {
          debugPrint('Social onboarding error: $e');
          await FirebaseAuth.instance.signOut();
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
        } else if (mounted) {
          final session = context.read<AppSession>();
          await session.init();
          await session.refreshPlayerAvatarUrls();
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
          onForgotPassword: () {
            // TODO: forgot password
          },
        );
      },
    ).whenComplete(coordinator.unregisterLoginSheetCloser);
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
        onForgotPassword: () {},
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
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 72,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _BrandHeader(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.heroTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  context.l10n.heroSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.5,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 420,
                                  child: _OnboardingCardCarousel(
                                    items: items,
                                    controller: pageController,
                                    currentPage: currentPage,
                                    onPageChanged: onPageChanged,
                                  ),
                                ),
                                const SizedBox(height: 20),
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
                    ],
                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;

    double logoWidth;
    if (isMobile) {
      logoWidth = screenWidth * 0.82;
    } else if (screenWidth < 1200) {
      logoWidth = screenWidth * 0.30;
    } else {
      logoWidth = screenWidth * 0.24;
    }

    return AppLogo(
      width: logoWidth.clamp(280.0, 760.0),
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
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, -18),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.10,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: _BrandHeader(isMobile: true),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 24),
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
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberProfileDialog extends StatefulWidget {
  const _MemberProfileDialog();

  @override
  State<_MemberProfileDialog> createState() => _MemberProfileDialogState();
}

class _MemberProfileDialogState extends State<_MemberProfileDialog> {
  MemberProfileFormState? _formState;

  void _onFormStateCreated(MemberProfileFormState state) {
    _formState = state;
  }

  void _submit() {
    final formState = _formState;
    if (formState == null || !formState.mounted) return;

    final validationError = formState.validateAndGetError();
    if (validationError != null) {
      AppSnackbar.show(context, validationError);
      return;
    }

    final profile = formState.buildProfile();
    if (profile == null) {
      AppSnackbar.show(context, context.l10n.memberProfileIncomplete);
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
        child: MemberProfileForm(
          key: const ValueKey('signup-member-profile'),
          enabled: true,
          onFormStateCreated: _onFormStateCreated,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
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
    final email = widget.emailCtrl.text.trim();
    final password = widget.passwordCtrl.text.trim();

    if (_isSignUpMode) {
      final confirmPassword = _confirmPasswordCtrl.text.trim();
      if (confirmPassword != password) {
        showLoginSnackBar(context, context.l10n.passwordsDoNotMatch);
        return;
      }

      await widget.onSignUp(email, password);
    } else {
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
                  Text(
                    _isSignUpMode
                        ? context.l10n.alreadyHaveAccount
                        : context.l10n.noAccountYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
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
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSignIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
        manageParentLoading: false,
        snackBarContext: context,
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
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: ultraCompact ? 220 : 320,
                          child: Container(
                            padding: EdgeInsets.all(ultraCompact ? 12 : 20),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(
                                ultraCompact ? 20 : 28,
                              ),
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
                                SizedBox(
                                  height: ultraCompact
                                      ? 10
                                      : (compact ? 12 : 20),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(ultraCompact ? 10 : 16),
                                  decoration: BoxDecoration(
                                    color: colors.background,
                                    borderRadius: BorderRadius.circular(
                                      ultraCompact ? 14 : 18,
                                    ),
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
                                        height: ultraCompact
                                            ? 10
                                            : (compact ? 12 : 16),
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
                    maxLines: ultraCompact ? 2 : (compact ? 3 : 4),
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

class _OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
