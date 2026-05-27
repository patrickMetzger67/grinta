import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/main.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/compo_screen.dart';
import 'package:grinta/screen/field_localization_screen.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/app_language_dropdown.dart';
import 'package:grinta/widget/app_session_player_avatar.dart';
import 'package:grinta/widget/app_session_player_season_selector.dart';
import 'package:grinta/widget/app_logo.dart';
import 'package:grinta/widget/app_shell_scope.dart';
import 'package:provider/provider.dart';

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

  Future<void> _logout() async {
    if (_isSigningOut) return;

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
        final app = MyApp.of(sheetContext);

        return Consumer<AppSession>(
          builder: (context, appSession, _) {
            final managedTeamsIds =
                appSession.managedTeamsIdsForSelectedSeason;
            final showManagerMenu = managedTeamsIds.isNotEmpty;

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
                    if (showManagerMenu) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.groups_rounded,
                          color: colors.primary,
                        ),
                        title: Text(l10n.navTeams),
                        onTap: () {
                          closeSheetThen(
                            () => navigator.push(
                              MaterialPageRoute<void>(
                                builder: (_) => TeamsListScreen(
                                  managedTeamsIds: managedTeamsIds,
                                  onTeamTap: (ctx, team, isManager) {
                                    Navigator.of(ctx).push(
                                      MaterialPageRoute<void>(
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
                      ListTile(
                        leading: Icon(
                          Icons.stadium_outlined,
                          color: colors.primary,
                        ),
                        title: Text(l10n.navFields),
                        onTap: () {
                          closeSheetThen(
                            () => navigator.push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const FootballFieldLocalizationScreen(),
                              ),
                            ),
                            sheetContext,
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.groups_outlined,
                          color: colors.primary,
                        ),
                        title: Text(l10n.navCompo),
                        onTap: () {
                          closeSheetThen(
                            () => navigator.push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CompoScreen(),
                              ),
                            ),
                            sheetContext,
                          );
                        },
                      ),
                    ],
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
                    const Divider(height: 1),
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
                      onTap: _isSigningOut
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

    return AppShellScope(
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
            setState(() => _selectedIndex = index);
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
        if (player == null || player.keyMember == null) {
          return IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.account_circle_outlined),
          );
        }

        final imageProvider =
            appSession.playersPhoto[player.keyMember!];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AppSessionPlayerAvatar(
              player: player,
              imageProvider: imageProvider,
              radius: 20,
            ),
          ),
        );
      },
    );
  }
}

/// Avatar joueur (initiales ou photo) réutilisable hors sélecteur sidebar.