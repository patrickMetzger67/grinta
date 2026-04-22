import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

import 'core/extensions/l10n_extension.dart';
import 'main.dart';

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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emailAndPasswordRequired)),
      );
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('login ok uid=${credential.user?.uid}');
      await context.read<AppSession>().init();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/',
            (route) => false,
      );

      // AuthGate fera la navigation automatiquement
    } on FirebaseAuthException catch (e) {
      String message = context.l10n.signInError;

      switch (e.code) {
        case 'user-not-found':
          message = context.l10n.userNotFound;
          break;
        case 'wrong-password':
          message = context.l10n.wrongPassword;
          break;
        case 'invalid-email':
          message = context.l10n.invalidEmail;
          break;
        case 'invalid-credential':
          message = context.l10n.invalidCredential;
          break;
        case 'too-many-requests':
          message = context.l10n.tooManyRequests;
          break;
        case 'user-disabled':
          message = context.l10n.userDisabled;
          break;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.unexpectedError} : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLoginSheet() {
    final isTabletOrMobile = MediaQuery.of(context).size.width < 900;

    if (!isTabletOrMobile) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginBottomSheet(
        emailCtrl: _emailCtrl,
        passwordCtrl: _passwordCtrl,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        onToggleObscure: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
        onSubmit: _submit,
        onCreateAccount: () {
          Navigator.pop(context);
          // TODO: navigation create account
        },
        onForgotPassword: () {
          // TODO: forgot password
        },
      ),
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
        onSubmit: _submit,
        onCreateAccount: () {},
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
      onCreateAccount: () {},
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
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;
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
    required this.onSubmit,
    required this.onCreateAccount,
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
                      onSubmit: onSubmit,
                      onCreateAccount: onCreateAccount,
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

    return Image.asset(
      'assets/images/logoFondOrange.png',
      width: logoWidth.clamp(280.0, 760.0),
      fit: BoxFit.contain,
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
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const _MobileLoginLayout({
    required this.items,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onCreateAccount,
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
                                onPressed: onCreateAccount,
                                child: Text(context.l10n.createAccount),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: onLogin,
                                child: Text(context.l10n.loginTitle),
                              ),
                            ),
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

class _LoginCard extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;
  final ValueChanged<Locale> onLocaleChanged;

  const _LoginCard({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onCreateAccount,
    required this.onForgotPassword,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    context.l10n.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const _LanguageDropdown(),
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
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.email,
                hintText: context.l10n.you,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(context.l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(context.l10n.signIn),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(context.l10n.hasATeamCode),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreateAccount,
                child: Text(context.l10n.createAccount),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Google Sign-In
                },
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: Text(context.l10n.continueWithGoogle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBottomSheet extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;

  const _LoginBottomSheet({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onCreateAccount,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              _LoginCard(
                emailCtrl: emailCtrl,
                passwordCtrl: passwordCtrl,
                obscurePassword: obscurePassword,
                isLoading: isLoading,
                onToggleObscure: onToggleObscure,
                onSubmit: onSubmit,
                onCreateAccount: onCreateAccount,
                onForgotPassword: onForgotPassword,
                onLocaleChanged: (locale) {},
              ),
            ],
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

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown();

  static const List<_LanguageItem> _languages = [
    _LanguageItem(locale: Locale('fr'), flag: '🇫🇷', label: 'FR'),
    _LanguageItem(locale: Locale('en'), flag: '🇬🇧', label: 'EN'),
    _LanguageItem(locale: Locale('de'), flag: '🇩🇪', label: 'DE'),
    _LanguageItem(locale: Locale('es'), flag: '🇪🇸', label: 'ES'),
    _LanguageItem(locale: Locale('it'), flag: '🇮🇹', label: 'IT'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentLocale = Localizations.localeOf(context);

    final selected = _languages.firstWhere(
          (e) => e.locale.languageCode == currentLocale.languageCode,
      orElse: () => _languages.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.locale.languageCode,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(14),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          items: _languages.map((language) {
            return DropdownMenuItem<String>(
              value: language.locale.languageCode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    language.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(language.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final locale = _languages.firstWhere(
                  (e) => e.locale.languageCode == value,
            ).locale;

            MyApp.of(context).changeLocale(locale);
          },
        ),
      ),
    );
  }
}

class _LanguageItem {
  final Locale locale;
  final String flag;
  final String label;

  const _LanguageItem({
    required this.locale,
    required this.flag,
    required this.label,
  });
}