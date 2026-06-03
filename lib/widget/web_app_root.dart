import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/agendaScreen.dart';
import 'package:grinta/screen/dashboardScreen.dart';
import 'package:grinta/screen/teamsListScreen.dart';
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
import '../screen/compo_screen.dart';
import '../screen/field_localization_screen.dart';
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
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<List<AgendaItem>> _loadAgendaItems({
    required DateTime start,
    required DateTime end,
  }) async {
    final List<AgendaItem> allItems = [];
    final timestampNow = Timestamp.now();


    for (final t in appSession.selectedTeams) {
      if (t.keyTeam == null) continue;

      final matchsWrk = await MatchService().getMatchesByTeamIdBetweenDates(
        teamId: t.keyTeam!,
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

        if (startAt == null) continue;

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

    return unique.values.toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  void _onAddEvent() {
    debugPrint('player=${appSession.selectedPlayerId}');
    debugPrint('season=${appSession.selectedSeason?.ref?.id}');
    debugPrint(
      'teams=${appSession.selectedTeams.map((e) => e.name).toList()}',
    );
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


    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final agendaPage = AgendaScreen(
      key: ValueKey('agenda-$selectedPlayerId-$selectedSeasonId-$localeCode'),
      loadItems: _loadAgendaItems,
      onAddEvent: _onAddEvent,
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
              if (getManagedTeamsIds.isNotEmpty) ...[
                WebShellItem(
                  label: l10n.navTeams,
                  icon: Icons.groups_rounded,
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
              ],
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
              if (getManagedTeamsIds.isNotEmpty) ...[
                WebShellItem(
                  label: l10n.navFields,
                  icon: Icons.stadium_outlined,
                  page: const FootballFieldLocalizationScreen(),
                  screenName: AnalyticsScreenNames.fields,
                  featureId: FeatureDiscoveryIds.tabFields,
                ),
              ],
              if (getManagedTeamsIds.isNotEmpty) ...[
                WebShellItem(
                  label: l10n.navCompo,
                  icon: Icons.groups_outlined,
                  page: const CompoScreen(),
                  screenName: AnalyticsScreenNames.compo,
                  featureId: FeatureDiscoveryIds.tabCompo,
                ),
              ],
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