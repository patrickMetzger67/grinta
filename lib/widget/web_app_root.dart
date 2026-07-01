import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/agendaScreen.dart';
import 'package:grinta/screen/dashboardScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
import 'package:grinta/services/calendar_sync_service.dart';
import 'package:grinta/services/calendar_deep_link_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';
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
import '../webNavigationShell.dart';

class WebAppRoot extends StatefulWidget {
  const WebAppRoot({super.key});

  @override
  State<WebAppRoot> createState() => _WebAppRootState();
}

class _WebAppRootState extends State<WebAppRoot> {
  bool _isLoading = true;

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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CalendarDeepLinkService.instance.notifyShellReady();
      unawaited(CalendarDeepLinkService.instance.processPendingIfReady());
    });
  }

  Future<List<AgendaItem>> _loadAgendaItems({
    required DateTime start,
    required DateTime end,
  }) async {
    final List<AgendaItem> allItems = [];
    final timestampNow = Timestamp.now();


    final seasonId = appSession.selectedSeason?.ref?.id;
    final teams = appSession.teamsForAgendaSelectedSeason;

    if (kDebugMode) {
      debugPrint(
        'Agenda load: seasonId=$seasonId teams=${teams.length} '
        'memberTeams=${appSession.memberTeamsForSelectedSeason.length} '
        'range=$start → $end',
      );
    }

    var totalMatches = 0;
    var totalTrainings = 0;

    for (final t in teams) {
      if (t.keyTeam == null) continue;

      if (kDebugMode) {
        debugPrint(
          'Agenda load team: name=${t.name} keyTeam=${t.keyTeam} '
          'clubId=${t.clubId ?? '(empty)'}',
        );
      }

      final matchsWrk =
          await MatchService().getMatchesForTeamEngagementsBetweenDates(
        teamId: t.keyTeam!,
        clubId: t.clubId ?? '',
        seasonId: seasonId,
        start: Timestamp.fromDate(start),
        end: Timestamp.fromDate(end),
        /*
        start: appSession.selectedSeason!.startDate!,
        end: appSession.selectedSeason!.endDate!,
         */
      );

      final trainingsWrk =
      await TrainingService().getTrainingsByTeamIdBetweenDates(
        teamId: t.keyTeam!,
        start: Timestamp.fromDate(start),
        end: Timestamp.fromDate(end),
        /*
        start: appSession.selectedSeason!.startDate!,
        end: appSession.selectedSeason!.endDate!,

         */
      );

      totalMatches += matchsWrk.length;

      for (final m in matchsWrk) {
        DateTime? startAt;
        if (m.timestamp != null) {
          startAt = m.timestamp!.toDate();
        } else if (m.dateCh != null && m.timeCh != null) {
          startAt = buildTimestampFromDateAndTime(
            date: m.dateCh!,
            time: m.timeCh!,
          ).toDate();
        }

        if (startAt == null) {
          if (kDebugMode) {
            debugPrint(
              'Agenda match skip: id=${m.id} no timestamp/dateCh+timeCh',
            );
          }
          continue;
        }

        final DateTime endAt = startAt.add(const Duration(minutes: 90));

        TeamWorkloadSummary? teamWorkloadSummary;
        if(m.withTracker == true && (m.id != null && m.id!.isNotEmpty)) {
          teamWorkloadSummary = await TeamWorkloadSummaryService().getByEventId(m.id!);
        }

        allItems.add(
          AgendaItem(
            id: m.id!,
            startAt: startAt,
            endAt: endAt,
            title: '${t.name}',
            type: AgendaItemType.match,
            match: m,
            isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
                timestampNow.millisecondsSinceEpoch,
            withTracker: m.withTracker,
            areTrackersSynchronized: m.isTrackerDataUploaded!,
            teamWorkloadSummary: teamWorkloadSummary,
          ),
        );
      }

      totalTrainings += trainingsWrk.length;

      for (final tr in trainingsWrk) {
        if (tr.dateTime == null) continue;

        final DateTime endAt =
        tr.dateTime!.toDate().add(const Duration(minutes: 90));


        TeamWorkloadSummary? teamWorkloadSummary;
        if(tr.withTracker && (tr.docId != null && tr.docId!.isNotEmpty)) {
          teamWorkloadSummary = await TeamWorkloadSummaryService().getByEventId(tr.docId!);
        }


        allItems.add(
          AgendaItem(
            id: tr.ref!.id,
            startAt: tr.dateTime!.toDate(),
            endAt: endAt,
            title: '${t.name}: Entraînement',
            type: AgendaItemType.entrainement,
            training: tr,
            isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
                timestampNow.millisecondsSinceEpoch,
            withTracker: tr.withTracker,
            areTrackersSynchronized: tr.isTrackerDataUploaded,
            teamWorkloadSummary: teamWorkloadSummary,
          ),
        );
      }
    }

    final unique = <String, AgendaItem>{};
    for (final item in allItems) {
      unique['${item.type.name}_${item.id}'] = item;
    }

    final items = unique.values.toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (kDebugMode) {
      debugPrint(
        'Agenda load done: rawMatches=$totalMatches rawTrainings=$totalTrainings '
        'agendaItems=${items.length}',
      );
    }

    unawaited(
      CalendarSyncService.instance.maybeSyncAfterAgendaLoad(
        appSession: appSession,
      ),
    );

    return items;
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
      loadItems: _loadAgendaItems,
      initialDate: pendingAgendaDate,
    );

    final bool isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    final Widget shell = kIsWeb
        ? WebNavigationShell(
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
                page: const ResponsiveChat(),
                screenName: AnalyticsScreenNames.chat,
                featureId: FeatureDiscoveryIds.tabChat,
              ),
              WebShellItem(
                label: l10n.navSync,
                icon: Icons.sync,
                page: const SyncScreen(),
                screenName: AnalyticsScreenNames.sync,
                featureId: FeatureDiscoveryIds.tabSync,
              ),
            ],
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