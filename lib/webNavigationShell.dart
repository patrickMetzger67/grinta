import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/shell_tab_analytics.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/services/account_deletion_service.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/screen/admin/admin_screen.dart';
import 'package:grinta/widget/promo_code_redeem_section.dart';
import 'core/extensions/l10n_extension.dart';
import 'util/app_theme.dart';
import 'widget/app_language_dropdown.dart';
import 'widget/app_logo.dart';
import 'widget/account_create_profile_entry.dart';
import 'widget/edit_member_profile.dart';
import 'widget/manage_profiles_settings_entry.dart';
import 'screen/my_unavailabilities_screen.dart';
import 'screen/tips_screen.dart';
import 'widget/nav_icon_count_badge.dart';
import 'widget/calendar_sync_toggle.dart';
import 'widget/biometric_lock_gate.dart';
import 'widget/devices_settings_section.dart';
import 'widget/notification_preferences_section.dart';
import 'widget/app_version_label.dart';
import 'widget/settings_infos_sheet.dart';
import 'widget/settings_menu_style.dart';
import 'widget/shop_ad_prompt.dart';
import 'widget/shop_ads_settings_tile.dart';
import 'widget/subscription_details_sheet.dart';
import 'widget/notifications_sheet.dart';
import 'widget/ask_diego/ask_diego_sidebar_entry.dart';

import 'main.dart';

const double _kWebSidebarExpandedWidth = 300;
const double _kWebSidebarCollapsedWidth = 92;
const double _kWebSettingsPanelWidth = 300;
const double _kWebSidebarNavItemHeight = 48;
const double _kWebSidebarNavItemSpacing = 4;

class WebShellItem {
  final String label;
  final IconData icon;
  final Widget page;
  final String screenName;
  final String? featureId;
  final int badgeCount;

  const WebShellItem({
    required this.label,
    required this.icon,
    required this.page,
    required this.screenName,
    this.featureId,
    this.badgeCount = 0,
  });
}

class WebNavigationShell extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<WebShellItem> items;
  final int initialIndex;
  final Widget? sidebarHeaderBottom;

  const WebNavigationShell({
    super.key,
    required this.items,
    this.appTitle = '',
    this.appIcon = Icons.dashboard_outlined,
    this.initialIndex = 0,
    required this.sidebarHeaderBottom,
  }) : assert(items.length > 0, 'items ne doit pas être vide');

  @override
  State<WebNavigationShell> createState() => _WebNavigationShellState();
}

class _WebNavigationShellState extends State<WebNavigationShell> {
  late int _selectedIndex;
  bool _collapsed = false;
  bool _settingsExpanded = false;
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  final ShellTabAnalytics _tabAnalytics = ShellTabAnalytics();

  bool get _isAccountActionBusy => _isSigningOut || _isDeletingAccount;

  bool get _sidebarCollapsed =>
      _collapsed || _settingsExpanded;

  bool get _settingsContentCollapsed =>
      _collapsed && !_settingsExpanded;

  @override
  void initState() {
    super.initState();
    ShellNavigationScope.registerGlobalNavigator(_selectTabByFeatureId);
    _selectedIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markTabFeatureVisited(_selectedIndex);
      _logTabScreen(_selectedIndex);
      unawaited(SubscriptionService.instance.refreshForActiveSession());
      unawaited(UserRootService.instance.reload());
    });
  }

  @override
  void dispose() {
    ShellNavigationScope.registerGlobalNavigator(null);
    _tabAnalytics.dispose();
    super.dispose();
  }

  void _logTabScreen(int index) {
    if (index < 0 || index >= widget.items.length) return;
    _tabAnalytics.onTabSelected(widget.items[index].screenName);
  }

  void _markTabFeatureVisited(int index) {
    if (index < 0 || index >= widget.items.length) return;
    final featureId = widget.items[index].featureId;
    if (featureId == null || featureId.isEmpty) return;
    FeatureDiscoveryService.instance.markFeatureVisited(featureId);
  }

  bool _selectTabByFeatureId(String featureId) {
    final int index = widget.items.indexWhere(
      (WebShellItem item) => item.featureId == featureId,
    );
    if (index < 0) return false;
    if (index == _selectedIndex) return true;
    setState(() => _selectedIndex = index);
    unawaited(ShopAdPrompt.maybeShow(fromFeatureChange: true));
    _markTabFeatureVisited(index);
    _logTabScreen(index);
    return true;
  }

  Set<String> get _availableTabFeatureIds => widget.items
      .map((WebShellItem item) => item.featureId)
      .whereType<String>()
      .where((String id) => id.isNotEmpty)
      .toSet();

  String? get _currentTabFeatureId {
    if (widget.items.isEmpty) return null;
    final int safeIndex = _selectedIndex.clamp(0, widget.items.length - 1);
    return widget.items[safeIndex].featureId;
  }

  @override
  void didUpdateWidget(covariant WebNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items.length != widget.items.length) {
      setState(() {
        _ensureValidSelectedIndex();
      });
    } else {
      _ensureValidSelectedIndex();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isAccountActionBusy) return;

    final colors = context.appColors;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            dialogContext.l10n.actionDeleteAccountConfirmTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            dialogContext.l10n.actionDeleteAccountConfirmMessage,
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.actionCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.warning,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.actionDeleteAccount),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    AnalyticsInteractions.logFeature(AnalyticsFeatures.deleteAccount);

    setState(() => _isDeletingAccount = true);

    try {
      await AccountDeletionService.instance.deleteCurrentAccount();
      await firebase_auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = e.code == 'requires-recent-login'
          ? context.l10n.errorDeleteAccountRequiresRecentLogin
          : context.l10n.errorDeleteAccount(e.message ?? e.code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorDeleteAccount(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isAccountActionBusy) return;

    final colors = context.appColors;


    _ensureValidSelectedIndex();

    final int safeSelectedIndex = _selectedIndex.clamp(
      0,
      widget.items.length - 1,
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            dialogContext.l10n.actionLogoutConfirmTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            dialogContext.l10n.actionLogoutConfirmMessage,
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.actionLogout),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    AnalyticsInteractions.logFeature(AnalyticsFeatures.logout);

    setState(() => _isSigningOut = true);

    try {
      await firebase_auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorLogout(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    _ensureValidSelectedIndex();

    final int safeSelectedIndex = _selectedIndex.clamp(
      0,
      widget.items.length - 1,
    );

    return ShellNavigationScope(
      availableTabFeatureIds: _availableTabFeatureIds,
      currentTabFeatureId: _currentTabFeatureId,
      onNavigateToTab: _selectTabByFeatureId,
      child: Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _sidebarCollapsed
                  ? _kWebSidebarCollapsedWidth
                  : _kWebSidebarExpandedWidth,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  right: BorderSide(color: colors.border),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  Divider(color: colors.border, height: 1),
                  if (!_sidebarCollapsed && widget.sidebarHeaderBottom != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: widget.sidebarHeaderBottom!,
                    ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: _sidebarCollapsed ? 18 : 6,
                      ),
                      children: _buildNavListItems(safeSelectedIndex),
                    ),
                  ),
                  Divider(color: colors.border, height: 1),
                  _buildSettingsToggle(context),
                ],
              ),
            ),
            if (_settingsExpanded) _buildSettingsPanel(context),
            Expanded(
              child: Container(
                color: colors.background,
                child: widget.items[safeSelectedIndex].page,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _ensureValidSelectedIndex() {
    if (widget.items.isEmpty) {
      _selectedIndex = 0;
      return;
    }

    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }

    if (_selectedIndex >= widget.items.length) {
      _selectedIndex = widget.items.length - 1;
    }
  }

  void _toggleSidebarCollapsed() {
    if (_settingsExpanded) {
      _closeSettingsPanel();
      return;
    }

    setState(() => _collapsed = !_collapsed);
  }

  void _openSettingsPanel() {
    setState(() {
      _settingsExpanded = true;
      _collapsed = true;
    });
  }

  void _closeSettingsPanel() {
    setState(() {
      _settingsExpanded = false;
      _collapsed = false;
    });
  }

  void _toggleSettingsExpanded() {
    if (_settingsExpanded) {
      _closeSettingsPanel();
    } else {
      _openSettingsPanel();
    }
  }

  List<Widget> _buildNavListItems(int safeSelectedIndex) {
    final children = <Widget>[];

    // Main tabs + notifications + Ask Diego.
    for (var index = 0; index < widget.items.length + 2; index++) {
      if (index > 0) {
        children.add(const SizedBox(height: _kWebSidebarNavItemSpacing));
      }

      if (index < widget.items.length) {
        children.add(
          _SidebarItem(
            collapsed: _sidebarCollapsed,
            selected: index == safeSelectedIndex,
            label: widget.items[index].label,
            icon: widget.items[index].icon,
            badgeCount: widget.items[index].badgeCount,
            onTap: () {
              if (index == safeSelectedIndex) return;
              setState(() {
                _selectedIndex = index;
              });
              _markTabFeatureVisited(index);
              _logTabScreen(index);
              unawaited(ShopAdPrompt.maybeShow(fromFeatureChange: true));
            },
          ),
        );
      } else if (index == widget.items.length) {
        children.add(
          NotificationSidebarEntry(
            collapsed: _sidebarCollapsed,
            itemHeight: _kWebSidebarNavItemHeight,
          ),
        );
      } else {
        children.add(
          AskDiegoSidebarEntry(
            collapsed: _sidebarCollapsed,
            itemHeight: _kWebSidebarNavItemHeight,
          ),
        );
      }
    }

    return children;
  }

  Widget _buildSettingsExpandedContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLanguageSelector(context),
        _buildThemeToggle(context),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: CalendarSyncToggle(
            contentPadding: EdgeInsets.symmetric(horizontal: 2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: BiometricUnlockSettingsTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 2),
          ),
        ),
        const DevicesSettingsSection(
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
          webCardStyle: true,
        ),
        const NotificationPreferencesSection(
          contentPadding: EdgeInsets.zero,
          webCardStyle: true,
        ),
        const ShopAdsSettingsTile(
          webCardStyle: true,
        ),
        ListenableBuilder(
          listenable: UserRootService.instance,
          builder: (context, _) {
            if (!UserRootService.instance.isRoot) {
              return const SizedBox.shrink();
            }
            return _buildAdminButton(context);
          },
        ),
        ListenableBuilder(
          listenable: Listenable.merge([
            SubscriptionService.instance,
            UserTrialService.instance,
          ]),
          builder: (context, _) {
            if (!UserTrialService.instance.shouldShowSubscriptionMenu) {
              return const SizedBox.shrink();
            }
            return _buildSubscriptionButton(context);
          },
        ),
        _buildEditProfileButton(context),
        _buildTipsButton(context),
        _buildMyUnavailabilitiesButton(context),
        AccountCreateProfileSidebarButton(
          collapsed: _settingsContentCollapsed,
          onTap: () => openAccountCreateProfileFlow(context),
        ),
        ManageProfilesSidebarButton(
          collapsed: _settingsContentCollapsed,
          onTap: () => openManageProfilesSettings(context),
        ),
        _buildInfosButton(context),
        _buildDeleteAccountButton(context),
        _buildLogoutButton(context),
        if (!_settingsContentCollapsed)
          const AppVersionLabel(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          ),
      ],
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _kWebSettingsPanelWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: colors.primary,
                  size: kWebMenuIconSize,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.navSettings,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _closeSettingsPanel,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                  ),
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSettingsExpandedContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggle(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (_sidebarCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Tooltip(
          message: l10n.navSettings,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggleSettingsExpanded,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: _settingsExpanded
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _settingsExpanded
                      ? colors.primary.withValues(alpha: 0.35)
                      : colors.border,
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _toggleSettingsExpanded,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.navSettings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    if (_settingsContentCollapsed) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: AppLanguageDropdown(compact: true),
      );
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: AppLanguageSidebarTile(),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final app = MyApp.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 220;

        if (compact) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Tooltip(
              message: app.isDarkMode
                  ? l10n.themeDisableDarkModeTooltip
                  : l10n.themeEnableDarkModeTooltip,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  app.toggleTheme(!app.isDarkMode);
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    app.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  app.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: colors.primary,
                  size: kWebMenuIconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.themeDarkModeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: settingsMenuTitleStyle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: app.isDarkMode,
                  onChanged: (value) {
                    app.toggleTheme(value);
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                  inactiveThumbColor: colors.textSecondary,
                  inactiveTrackColor: colors.border,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.subscriptionMenu,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showSubscriptionDetails(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.card_membership_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showSubscriptionDetails(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.card_membership_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.subscriptionMenu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.adminTitle,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openAdminScreen(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openAdminScreen(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.adminTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.actionEditProfile,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showEditMemberProfile(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showEditMemberProfile(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.actionEditProfile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.settingsTipsTitle,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openTipsScreen(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openTipsScreen(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.settingsTipsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfosButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.settingsInfosTitle,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showSettingsInfosSheet(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showSettingsInfosSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.settingsInfosTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyUnavailabilitiesButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.settingsMyUnavailabilities,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openMyUnavailabilitiesScreen(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.event_busy_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openMyUnavailabilitiesScreen(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_outlined,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.settingsMyUnavailabilities,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: context.l10n.actionDeleteAccount,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isAccountActionBusy ? null : _deleteAccount,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: _isDeletingAccount
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.warning,
                      ),
                    )
                  : Icon(
                      Icons.delete_forever_outlined,
                      color: colors.warning,
                      size: kWebMenuIconSize,
                    ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isAccountActionBusy ? null : _deleteAccount,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _isDeletingAccount
                  ? SizedBox(
                      width: kWebMenuIconSize,
                      height: kWebMenuIconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.warning,
                      ),
                    )
                  : Icon(
                      Icons.delete_forever_outlined,
                      color: colors.warning,
                      size: kWebMenuIconSize,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.actionDeleteAccount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context).copyWith(
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colors = context.appColors;
    if (_settingsContentCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Tooltip(
          message: context.l10n.actionLogout,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isAccountActionBusy ? null : _logout,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: _isSigningOut
                  ? Padding(
                padding: const EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.primary,
                ),
              )
                  : Icon(
                Icons.logout_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isAccountActionBusy ? null : _logout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _isSigningOut
                  ? SizedBox(
                width: kWebMenuIconSize,
                height: kWebMenuIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.primary,
                ),
              )
                  : Icon(
                Icons.logout_rounded,
                color: colors.primary,
                size: kWebMenuIconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.actionLogout,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: settingsMenuTitleStyle(context).copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;

    if (_sidebarCollapsed) {
      return Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const AppLogo(),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleSidebarCollapsed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  _settingsExpanded
                      ? Icons.expand_less_rounded
                      : Icons.chevron_right_rounded,
                  color: colors.textPrimary,
                  size: kWebMenuIconSize,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: const AppLogo(
                height: 48,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _toggleSidebarCollapsed,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: colors.textPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final bool collapsed;
  final bool selected;
  final String label;
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.collapsed,
    required this.selected,
    required this.label,
    required this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Color backgroundColor = Colors.transparent;
    if (widget.selected) {
      backgroundColor = colors.primary.withOpacity(0.12);
    } else if (_hovered) {
      backgroundColor = colors.card;
    }

    final Color foregroundColor = widget.selected
        ? colors.primary
        : colors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: _kWebSidebarNavItemHeight,
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: widget.selected
                  ? Border.all(color: colors.primary.withOpacity(0.18))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                NavIconCountBadge(
                  icon: widget.icon,
                  count: widget.badgeCount,
                  iconColor: foregroundColor,
                  iconSize: kWebMenuIconSize,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: webSidebarNavLabelStyle(
                        context,
                        selected: widget.selected,
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
}