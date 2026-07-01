import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/main.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/app_language_dropdown.dart';
import 'package:grinta/widget/app_session_player_avatar.dart';
import 'package:grinta/widget/app_session_player_season_selector.dart';
import 'package:grinta/widget/app_logo.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/analytics/shell_tab_analytics.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/services/account_deletion_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/widget/app_shell_scope.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/edit_member_profile.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:grinta/widget/calendar_sync_toggle.dart';
import 'package:grinta/widget/subscription_details_sheet.dart';
import 'package:provider/provider.dart';

const List<String> _kMobileTabFeatureIds = <String>[
  FeatureDiscoveryIds.tabAgenda,
  FeatureDiscoveryIds.tabDashboard,
  FeatureDiscoveryIds.tabChat,
];

const List<String> _kMobileTabScreenNames = <String>[
  AnalyticsScreenNames.agenda,
  AnalyticsScreenNames.dashboard,
  AnalyticsScreenNames.chat,
];

class MobileNavigationShell extends StatefulWidget {
  const MobileNavigationShell({
    super.key,
    required this.agendaPage,
    required this.dashboardPage,
    required this.chatPage,
  });

  final Widget agendaPage;
  final Widget dashboardPage;
  final Widget chatPage;

  @override
  State<MobileNavigationShell> createState() => _MobileNavigationShellState();
}

class _MobileNavigationShellState extends State<MobileNavigationShell> {
  int _selectedIndex = 0;
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  final ShellTabAnalytics _tabAnalytics = ShellTabAnalytics();

  bool get _isAccountActionBusy => _isSigningOut || _isDeletingAccount;

  @override
  void initState() {
    super.initState();
    ShellNavigationScope.registerGlobalNavigator(_selectTabByFeatureId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markTabFeatureVisited(_selectedIndex);
      _logTabScreen(_selectedIndex);
      unawaited(SubscriptionService.instance.refreshForActiveSession());
    });
  }

  @override
  void dispose() {
    ShellNavigationScope.registerGlobalNavigator(null);
    _tabAnalytics.dispose();
    super.dispose();
  }

  void _logTabScreen(int index) {
    if (index < 0 || index >= _kMobileTabScreenNames.length) return;
    _tabAnalytics.onTabSelected(_kMobileTabScreenNames[index]);
  }

  void _markTabFeatureVisited(int index) {
    if (index < 0 || index >= _kMobileTabFeatureIds.length) return;
    FeatureDiscoveryService.instance
        .markFeatureVisited(_kMobileTabFeatureIds[index]);
  }

  bool _selectTabByFeatureId(String featureId) {
    final int index = _kMobileTabFeatureIds.indexOf(featureId);
    if (index < 0) return false;
    if (index == _selectedIndex) return true;
    setState(() => _selectedIndex = index);
    _markTabFeatureVisited(index);
    _logTabScreen(index);
    return true;
  }

  Future<void> _logout() async {
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

  void _openSettingsSheet(BuildContext parentContext) {
    final l10n = context.l10n;
    final colors = context.appColors;

    void closeSheetThen(void Function() action, BuildContext sheetContext) {
      Navigator.of(sheetContext).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        action();
      });
    }

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final app = MyApp.of(sheetContext);

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.settings_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    l10n.navSettings,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AppLanguageSidebarTile(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      app.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: colors.primary,
                    ),
                    title: Text(
                      l10n.themeDarkModeLabel,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Switch(
                      value: app.isDarkMode,
                      onChanged: (value) {
                        app.toggleTheme(value);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: colors.primary,
                      inactiveThumbColor: colors.textSecondary,
                      inactiveTrackColor: colors.border,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CalendarSyncToggle(contentPadding: EdgeInsets.zero),
                ),
                const Divider(height: 1),
                ListenableBuilder(
                  listenable: SubscriptionService.instance,
                  builder: (context, _) {
                    if (!SubscriptionService.instance
                        .hasActivePaidSubscription) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      leading: Icon(
                        Icons.card_membership_outlined,
                        color: colors.primary,
                      ),
                      title: Text(
                        l10n.subscriptionMenu,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        closeSheetThen(
                          () => showSubscriptionDetails(context),
                          sheetContext,
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person_outline_rounded,
                    color: colors.primary,
                  ),
                  title: Text(
                    l10n.actionEditProfile,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    closeSheetThen(
                      () => showEditMemberProfile(context),
                      sheetContext,
                    );
                  },
                ),
                AccountCreateProfileListTile(
                  onTap: () {
                    closeSheetThen(
                      () => openAccountCreateProfileFlow(context),
                      sheetContext,
                    );
                  },
                ),
                ListTile(
                  leading: _isSigningOut
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(Icons.logout_rounded, color: colors.primary),
                  title: Text(
                    l10n.actionLogout,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _isAccountActionBusy
                      ? null
                      : () {
                          closeSheetThen(() => _logout(), sheetContext);
                        },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAccountMenu() {
    if (!mounted) return;

    final l10n = context.l10n;
    final colors = context.appColors;
    final navigator = Navigator.of(context, rootNavigator: true);

    void closeSheetThen(void Function() action, BuildContext sheetContext) {
      Navigator.of(sheetContext).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        action();
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<AppSession>(
          builder: (context, appSession, _) {
            final managedTeamsIds =
                appSession.managedTeamsIdsForSelectedSeason;
            final teamCount = appSession.selectedTeams.length;

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppSessionPlayerSeasonSelector(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    ListTile(
                      leading: NavIconCountBadge(
                        icon: Icons.groups_rounded,
                        count: teamCount,
                        iconColor: colors.primary,
                      ),
                      title: Text(l10n.navTeams),
                      onTap: () {
                        closeSheetThen(
                          () => navigator.push(
                            analyticsMaterialRoute<void>(
                              screenName: AnalyticsScreenNames.teamsList,
                              builder: (_) => TeamsListScreen(
                                managedTeamsIds: managedTeamsIds,
                                onTeamTap: (ctx, team, isManager) {
                                  AnalyticsInteractions.logFeature(
                                    AnalyticsFeatures.openTeamDetail,
                                    parameters: <String, Object>{
                                      'is_manager': isManager,
                                      'source': 'teams_list',
                                    },
                                  );
                                  Navigator.of(ctx).push(
                                    analyticsMaterialRoute<void>(
                                      screenName:
                                          AnalyticsScreenNames.teamDetail,
                                      builder: (_) => TeamDetailScreen(
                                        team: team,
                                        seasonId: appSession
                                            .selectedSeason
                                            ?.ref
                                            ?.id,
                                        isManager: isManager,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          sheetContext,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: colors.primary,
                      ),
                      title: Text(
                        l10n.navSettings,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textSecondary,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _openSettingsSheet(context);
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: _isDeletingAccount
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: colors.warning,
                              ),
                            )
                          : Icon(
                              Icons.delete_forever_outlined,
                              color: colors.warning,
                            ),
                      title: Text(
                        l10n.actionDeleteAccount,
                        style: TextStyle(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _isAccountActionBusy
                          ? null
                          : () {
                              closeSheetThen(
                                () => _deleteAccount(),
                                sheetContext,
                              );
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final pages = <Widget>[
      widget.agendaPage,
      widget.dashboardPage,
      widget.chatPage,
    ];

    return ShellNavigationScope(
      availableTabFeatureIds: _kMobileTabFeatureIds.toSet(),
      currentTabFeatureId: _kMobileTabFeatureIds[_selectedIndex],
      onNavigateToTab: _selectTabByFeatureId,
      child: AppShellScope(
      isMobileShell: true,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const AppLogo(
            height: 32,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _MobileAvatarMenuButton(
                onTap: _openAccountMenu,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: colors.border),
          ),
        ),
        body: IndexedStack(
          key: ValueKey('mobile-shell-tabs-$localeCode'),
          index: _selectedIndex,
          children: pages
              .map(
                (page) => AppShellScope(
                  isMobileShell: true,
                  child: page,
                ),
              )
              .toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (index == _selectedIndex) return;
            setState(() => _selectedIndex = index);
            _markTabFeatureVisited(index);
            _logTabScreen(index);
          },
          backgroundColor: colors.surface,
          indicatorColor: colors.primary.withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: colors.primary),
              label: l10n.navAgenda,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: colors.primary),
              label: l10n.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: colors.primary),
              label: l10n.navChat,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _MobileAvatarMenuButton extends StatelessWidget {
  const _MobileAvatarMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        final Player? player = appSession.selectedPlayer;
        if (player == null) {
          return IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.account_circle_outlined),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AppSessionPlayerAvatar(
              player: player,
              radius: 20,
              watchSessionForStaleWebAvatar: true,
            ),
          ),
        );
      },
    );
  }
}

/// Avatar joueur (initiales ou photo) réutilisable hors sélecteur sidebar.