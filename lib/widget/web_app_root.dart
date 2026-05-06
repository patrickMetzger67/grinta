import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:grinta/widget/app_session_player_season_selector.dart';
import 'package:provider/provider.dart';

import '../model/agendaItem.dart';
import '../screen/responsive_chat.dart';
import '../screen/syncScreen.dart';
import '../screen/teamDetailScreen.dart';
import '../util/app_theme.dart';
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
        start: appSession.selectedSeason!.startDate!,
        end: appSession.selectedSeason!.endDate!,
      );

      final trainingsWrk =
      await TrainingService().getTrainingsByTeamIdBetweenDates(
        teamId: t.keyTeam!,
        start: appSession.selectedSeason!.startDate!,
        end: appSession.selectedSeason!.endDate!,
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
        if(m.withTracker! && (m.id != null && m.id!.isNotEmpty)) {
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
            withTracker: m.withTracker!,
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

    final hasManagedTeamsInSelectedSeason = context.select<AppSession, bool>(
          (session) => session.hasManagedTeamsInSelectedSeason,
    );

    final getManagedTeamsIds = context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );


    return Stack(
      children: [
        WebNavigationShell(
          appTitle: 'Grinta',
          appIcon: Icons.sports_soccer_rounded,
          initialIndex: 0,
          sidebarHeaderBottom: const AppSessionPlayerSeasonSelector(),
          items: [
            const WebShellItem(
              label: 'Tableau de bord',
              icon: Icons.dashboard_outlined,
              page: DashboardScreen(),
            ),
            WebShellItem(
              label: 'Agenda',
              icon: Icons.calendar_month_outlined,
              page: AgendaScreen(
                key: ValueKey('agenda-$selectedPlayerId-$selectedSeasonId'),
                loadItems: _loadAgendaItems,
                onAddEvent: _onAddEvent,
              ),
            ),
            if(getManagedTeamsIds.isNotEmpty) ... [
              WebShellItem(
                  label: 'Equipes',
                  icon: Icons.groups_rounded,
                  page: TeamsListScreen(
                    managedTeamsIds: getManagedTeamsIds,
                    onTeamTap: (context, team, isManager) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeamDetailScreen(
                            team: team,
                            seasonId: context.read<AppSession>().selectedSeason?.ref?.id,
                            isManager: isManager,
                          ),
                        ),
                      );
                    },
                  )
              ),
            ],

            const WebShellItem(
              label: 'Chat',
              icon: Icons.chat,
              page: ResponsiveChat(),
            ),
            const WebShellItem(
              label: 'Synchronisation',
              icon: Icons.sync,
              page: SyncScreen(),
            ),
          ],
        ),

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