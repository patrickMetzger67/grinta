import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/agendaScreen.dart';
import 'package:grinta/screen/dashboardScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
import 'package:grinta/services/calendar_sync_service.dart';
import 'package:grinta/services/internal_reminder_service.dart';
import 'package:grinta/services/calendar_deep_link_service.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/sync_pending_count_service.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/widget/app_session_player_season_selector.dart';
import 'package:provider/provider.dart';

import '../model/agendaItem.dart';
import '../screen/responsive_chat.dart';
import '../screen/syncScreen.dart';
import '../screen/teamDetailScreen.dart';
import '../util/app_theme.dart';
import '../core/extensions/l10n_extension.dart';
import 'mobile_navigation_shell.dart';
import 'stream_chat_nav_unread_badge.dart';
import 'youtube_top_video_prompt.dart';
import 'opponent_analysis_report_prompt.dart';
import '../webNavigationShell.dart';

class WebAppRoot extends StatefulWidget {
  const WebAppRoot({super.key});

  @override
  State<WebAppRoot> createState() => _WebAppRootState();
}

class _WebAppRootState extends State<WebAppRoot> {
  bool _isLoading = true;
  bool _tipVideoPromptScheduled = false;
  final AgendaService _agendaService = AgendaService();

  AppSession get appSession => context.read<AppSession>();

  @override
  void initState() {
    super.initState();
    CalendarDeepLinkService.instance.pendingAgendaDate.addListener(
      _onPendingAgendaDateChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(CalendarDeepLinkService.instance.processPendingIfReady());
    });
    _initApp();
  }

  @override
  void dispose() {
    CalendarDeepLinkService.instance.pendingAgendaDate.removeListener(
      _onPendingAgendaDateChanged,
    );
    super.dispose();
  }

  void _onPendingAgendaDateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initApp() async {
    // Let the first Flutter frame paint (replacing the HTML boot splash),
    // then drop this short overlay. Avoids a long artificial white/blank wait.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CalendarDeepLinkService.instance.notifyShellReady();
      unawaited(CalendarDeepLinkService.instance.processPendingIfReady());
      // Tip video and opponent analysis are independent features.
      _scheduleTipVideoPrompt();
    });
  }

  void _scheduleTipVideoPrompt() {
    if (_tipVideoPromptScheduled) return;
    _tipVideoPromptScheduled = true;
    unawaited(YoutubeTopVideoPrompt.maybeShow());
  }

  Stream<List<AgendaItem>> _watchAgendaItems({
    required DateTime start,
    required DateTime end,
    List<String> coachVisibleMemberIds = const [],
  }) {
    final stream = _agendaService.watchAgendaItems(
      teams: appSession.teamsForAgendaSelectedSeason,
      seasonId: appSession.selectedSeason?.ref?.id,
      start: start,
      end: end,
      memberId: appSession.selectedPlayerId,
      coachVisibleMemberIds: coachVisibleMemberIds,
    );

    var didTriggerCalendarSync = false;

    return stream.map((List<AgendaItem> items) {
      if (!didTriggerCalendarSync) {
        didTriggerCalendarSync = true;
        unawaited(
          CalendarSyncService.instance.maybeSyncAfterAgendaLoad(
            appSession: appSession,
          ),
        );
      }
      // Same match list as the agenda UI — drives the opponent-analysis prompt.
      OpponentAnalysisReportPrompt.noteAgendaItems(items);
      InternalReminderService.instance.onAgendaChanged();
      return items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlayerId = context.select<AppSession, String?>(
          (session) => session.selectedPlayerId,
    );

    final selectedSeasonId = context.select<AppSession, String?>(
          (session) => session.selectedSeason?.ref?.id,
    );

    final getManagedTeamsIds = context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );

    final selectedTeamCount = context.select<AppSession, int>(
          (session) => session.selectedTeams.length,
    );

    final managedTeamIds = context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );

    final agendaTeamsKey = context.select<AppSession, String>(
          (session) => session.agendaTeamsKey,
    );

    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final pendingAgendaDate =
        CalendarDeepLinkService.instance.pendingAgendaDate.value;
    if (pendingAgendaDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = CalendarDeepLinkService.instance.pendingAgendaDate;
        if (notifier.value != null) {
          notifier.value = null;
        }
      });
    }

    final agendaPage = AgendaScreen(
      key: ValueKey(
        'agenda-$selectedPlayerId-$selectedSeasonId-$agendaTeamsKey-$localeCode'
        '-${pendingAgendaDate?.millisecondsSinceEpoch ?? 0}',
      ),
      watchItems: _watchAgendaItems,
      initialDate: pendingAgendaDate,
      onTrackerWorkloadUpdated: (String eventId) {
        _agendaService.invalidateWorkloadSummaryCache(eventId);
      },
    );

    final bool isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    final Widget shell = kIsWeb
        ? StreamBuilder<int>(
            stream: const SyncPendingCountService()
                .watchPendingEventsCount(managedTeamIds),
            initialData: 0,
            builder: (context, pendingSyncSnapshot) {
              final pendingSyncCount = pendingSyncSnapshot.data ?? 0;

              return StreamChatUnreadCountBuilder(
                builder: (context, unreadChatCount) {
                  return WebNavigationShell(
                    appTitle: l10n.appName,
                    appIcon: Icons.sports_soccer_rounded,
                    initialIndex: 0,
                    sidebarHeaderBottom: const AppSessionPlayerSeasonSelector(),
                    items: [
                      WebShellItem(
                        label: l10n.navDashboard,
                        icon: Icons.dashboard_outlined,
                        page: const DashboardScreen(),
                        screenName: AnalyticsScreenNames.dashboard,
                        featureId: FeatureDiscoveryIds.tabDashboard,
                      ),
                      WebShellItem(
                        label: l10n.navAgenda,
                        icon: Icons.calendar_month_outlined,
                        page: agendaPage,
                        screenName: AnalyticsScreenNames.agenda,
                        featureId: FeatureDiscoveryIds.tabAgenda,
                      ),
                      WebShellItem(
                        label: l10n.navTeams,
                        icon: Icons.groups_rounded,
                        badgeCount: selectedTeamCount,
                        screenName: AnalyticsScreenNames.teams,
                        featureId: FeatureDiscoveryIds.tabTeams,
                        page: TeamsListScreen(
                          managedTeamsIds: getManagedTeamsIds,
                          onTeamTap: (context, team, isManager) {
                            AnalyticsInteractions.logFeature(
                              AnalyticsFeatures.openTeamDetail,
                              parameters: <String, Object>{
                                'is_manager': isManager,
                                'source': 'teams_list',
                              },
                            );
                            Navigator.of(context).push(
                              analyticsMaterialRoute<void>(
                                screenName: AnalyticsScreenNames.teamDetail,
                                builder: (_) => TeamDetailScreen(
                                  team: team,
                                  seasonId: context
                                      .read<AppSession>()
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
                      WebShellItem(
                        label: l10n.navChat,
                        icon: Icons.chat,
                        badgeCount: unreadChatCount,
                        page: const ResponsiveChat(),
                        screenName: AnalyticsScreenNames.chat,
                        featureId: FeatureDiscoveryIds.tabChat,
                      ),
                      WebShellItem(
                        label: l10n.navSync,
                        icon: Icons.sync,
                        badgeCount: pendingSyncCount,
                        page: const SyncScreen(),
                        screenName: AnalyticsScreenNames.sync,
                        featureId: FeatureDiscoveryIds.tabSync,
                      ),
                    ],
                  );
                },
              );
            },
          )
        : isMobileNative
            ? MobileNavigationShell(
                agendaPage: agendaPage,
                dashboardPage: DashboardScreen(
                  key: ValueKey('dashboard-$localeCode'),
                ),
                chatPage: ResponsiveChat(
                  key: ValueKey('chat-$localeCode'),
                ),
              )
            : agendaPage;

    return Stack(
      children: [
        shell,
        const OpponentAnalysisPromptHost(),

        if (_isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: context.appColors.background.withValues(alpha: 0.70),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.appColors.primary,
                    backgroundColor:
                    context.appColors.border.withValues(alpha: 0.35),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}