import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

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

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Gérez votre équipe',
      subtitle:
      'Centralisez vos membres, vos informations et votre organisation dans une seule application.',
      icon: Icons.groups_rounded,
    ),
    _OnboardingItem(
      title: 'Planifiez vos matchs',
      subtitle:
      'Créez vos événements, convoquez vos joueurs et suivez facilement les disponibilités.',
      icon: Icons.calendar_month_rounded,
    ),
    _OnboardingItem(
      title: 'Suivez vos performances',
      subtitle:
      'Consultez les statistiques, l’activité et les résultats depuis une interface claire.',
      icon: Icons.insights_rounded,
    ),
  ];

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

  void _goNextPage() {
    if (!_pageController.hasClients) return;

    final next = (_currentPage + 1).clamp(0, _items.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _goPreviousPage() {
    if (!_pageController.hasClients) return;

    final previous = (_currentPage - 1).clamp(0, _items.length - 1);
    _pageController.animateToPage(
      previous,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // TODO: branchement Firebase Auth / backend
      // await FirebaseAuth.instance.signInWithEmailAndPassword(
      //   email: _emailCtrl.text.trim(),
      //   password: _passwordCtrl.text.trim(),
      // );
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

    if (kIsWeb || width >= 900) {
      return _WebLoginLayout(
        items: _items,
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
        onCreateAccount: () {
          // TODO: navigation create account
        },
        onForgotPassword: () {
          // TODO: forgot password
        },
        onPreviousPage: _goPreviousPage,
        onNextPage: _goNextPage,
      );
    }

    return _MobileLoginLayout(
      items: _items,
      currentPage: _currentPage,
      pageController: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      onCreateAccount: () {
        // TODO: navigation create account
      },
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


    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight * 0.5;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: colors.background,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(alpha: 0.12),
                    colors.background,
                    colors.secondary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandHeader(),
                      const SizedBox(height: 40),
                      Expanded(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height - 120,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 620),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Pilotez votre activité sportive simplement',
                                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Organisez vos événements, gérez vos membres et suivez votre activité depuis une interface claire, moderne et responsive.',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: colors.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        SizedBox(
                                          height: carouselHeight.clamp(280.0, 520.0),
                                          child: _OnboardingCardCarousel(
                                            items: items,
                                            controller: pageController,
                                            currentPage: currentPage,
                                            onPageChanged: onPageChanged,
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        _DesktopCarouselControls(
                                          itemCount: items.length,
                                          currentPage: currentPage,
                                          onPrevious: onPreviousPage,
                                          onNext: onNextPage,
                                        ),
                                      ],
                                    ),
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
          color: colors.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.10),
              colors.background,
              colors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 12,
                ),
                child: const _BrandHeader(),
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
                                child: const Text('Créer un compte'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: onLogin,
                                child: const Text('Connexion'),
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

  const _LoginCard({
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connexion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour accéder à votre espace.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                hintText: 'vous@exemple.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
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
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text('Mot de passe oublié ?'),
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
                    : const Text('Se connecter'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreateAccount,
                child: const Text('Créer un compte'),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Divider(color: colors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
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
                label: const Text('Continuer avec Google'),
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
            top: isActive ? 4 : 18,
            bottom: isActive ? 4 : 18,
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : (mobileMode ? 20 : 28)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      (compact ? 32 : (mobileMode ? 40 : 56)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 320,
                          minHeight: compact ? 180 : 250,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(28),
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
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  color: colors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 12,
                                    width: 110,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
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
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: colors.border.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 12 : 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: colors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 44,
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
                    SizedBox(height: compact ? 16 : 20),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mon App',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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