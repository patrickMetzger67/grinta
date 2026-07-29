import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/activityMetrics.dart';
import '../../model/match.dart' as match_model;
import '../../model/matchCompo.dart';
import '../../model/personal_sport_activity.dart';
import '../../model/season.dart';
import '../../model/team.dart';
import '../../model/tracker/polar_session_analysis.dart';
import '../../model/training.dart';
import '../../services/matchService.dart';
import '../../services/personal_sport_activity_service.dart';
import '../../services/polar_session_analysis_service.dart';
import '../../services/teamService.dart';
import '../../services/trainingService.dart';
import '../../model/feature_discovery_ids.dart';
import '../../util/app_theme.dart';
import '../../util/polar_tracker_eligibility.dart';
import '../../util/staff_session_access.dart';
import '../../widget/activity_rings_card.dart';
import '../../widget/feature_discovery_random_banner.dart';
import '../../widget/alternating_monetization_banner.dart';
import '../../widget/app_shell_scope.dart';
import '../../widget/ask_diego/ask_diego_speed_dial.dart';
import '../../widget/agendaMatchRow.dart';
import '../../widget/metrics_panel.dart';
import '../../widget/personal_sport_activity_summary.dart';
import '../match_detail_screen.dart';


part 'dashboard_models.dart';
part 'dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  final TrainingService _trainingService = TrainingService();
  final MatchCompoService _matchCompoService = MatchCompoService();
  // Lazy: survives hot reload when this field is added to an existing State.
  PersonalSportActivityService? _personalSportService;
  PersonalSportActivityService get _personalSports =>
      _personalSportService ??= PersonalSportActivityService();

  String? _selectedTeamId;
  Season? currentSeason;
  String? currentPlayerId;
  String? currentUserId;

  DashboardPeriod _selectedPeriod = DashboardPeriod.month;
  DashboardStatsType _selectedStatsType = DashboardStatsType.trainings;
  DashboardWhereType _selectedStatsWhere = DashboardWhereType.player;
  DateTimeRange? _customRange;

  bool _sessionWaitTimedOut = false;
  Timer? _sessionWaitTimer;

  @override
  void dispose() {
    _sessionWaitTimer?.cancel();
    super.dispose();
  }

  void _startSessionWaitTimer() {
    if (_sessionWaitTimer != null) return;
    _sessionWaitTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() => _sessionWaitTimedOut = true);
    });
  }

  void _cancelSessionWaitTimer() {
    _sessionWaitTimer?.cancel();
    _sessionWaitTimer = null;
    if (_sessionWaitTimedOut) {
      _sessionWaitTimedOut = false;
    }
  }

  void _retrySessionLoad() {
    setState(() => _sessionWaitTimedOut = false);
    _sessionWaitTimer?.cancel();
    _sessionWaitTimer = null;
    unawaited(context.read<AppSession>().init());
    _startSessionWaitTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final currentUser = FirebaseAuth.instance.currentUser;



    final appSession = context.watch<AppSession>();

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final sessionUser = appSession.user;

    currentSeason = appSession.selectedSeason;
    currentPlayerId = appSession.selectedPlayerId;
    currentUserId = sessionUser?.uid ?? firebaseUser?.uid;

    final String? userId = currentUserId;

    final List<String> managedTeamsIds =
        appSession.managedTeamsIdsForSelectedSeason;

    if (userId == null || userId.isEmpty) {
      _startSessionWaitTimer();
      return _buildWaitingUserSession(context);
    }

    _cancelSessionWaitTimer();

    final List<String> currentPlayerTeamIds = getTeamIdsForCurrentPlayerAndSeason(
      teams: appSession.teams,
      currentSeason: currentSeason,
      currentPlayerId: currentPlayerId,
      managedTeamsIds: managedTeamsIds,
    );

    final List<String> availableTeamIds = <String>{
      ...managedTeamsIds,
      ...currentPlayerTeamIds,
    }.where((teamId) => teamId.trim().isNotEmpty).toList();

    final bool selectedTeamExists =
        _selectedTeamId != null && availableTeamIds.contains(_selectedTeamId);

    final String? activeTeamId = selectedTeamExists
        ? _selectedTeamId
        : availableTeamIds.isNotEmpty
        ? availableTeamIds.first
        : null;

    if (!selectedTeamExists &&
        activeTeamId != null &&
        _selectedTeamId != activeTeamId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _selectedTeamId = activeTeamId;
        });
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: (AppShellScope.maybeOf(context)?.isMobileShell ?? false)
          ? const AskDiegoSpeedDial(heroTagPrefix: 'dashboard')
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            final bool isPhone = width < 600;
            final bool isTablet = width >= 600 && width < 1024;
            final bool isWeb = width >= 1024;

            final double maxWidth = isWeb ? 1180 : double.infinity;

            final EdgeInsets padding = EdgeInsets.all(
              isPhone
                  ? 14
                  : isTablet
                  ? 20
                  : 24,
            );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AlternatingMonetizationBanner(),
                      const FeatureDiscoveryRandomBanner(
                        parentScreenId: FeatureDiscoveryIds.tabDashboard,
                        excludeCurrentBaseScreen: true,
                      ),
                      if (managedTeamsIds.length > 1) ...[
                        _buildTeamCard(
                          context: context,
                          colors: colors,
                          textTheme: textTheme,
                          seasonId: currentSeason?.ref?.id,
                          userId: userId,
                          playerId: currentPlayerId,
                          isPhone: isPhone,
                          isManagedTeams: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (currentPlayerTeamIds.length > 1) ...[
                        _buildTeamCard(
                          context: context,
                          colors: colors,
                          textTheme: textTheme,
                          seasonId: currentSeason?.ref?.id,
                          userId: userId,
                          playerId: currentPlayerId,
                          isPhone: isPhone,
                          isManagedTeams: false,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildDashboardTopCard(
                        context: context,
                        colors: colors,
                        textTheme: textTheme,
                        isPhone: isPhone,
                        teamId: activeTeamId,
                        playerId: currentPlayerId,
                        userId: userId,
                        managedTeamsIds: managedTeamsIds,
                        currentPlayerTeamsIds: currentPlayerTeamIds
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingUserSession(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colors.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.loadingSession,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_sessionWaitTimedOut) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retrySessionLoad,
                    child: Text(l10n.actionRetry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ??
          double.tryParse(value.replaceAll(',', '.'))?.round() ??
          0;
    }

    return 0;
  }

  List<Team> getTeamsForCurrentPlayerAndSeason({
    required Map<String, Map<String, Map<String, Team>>> teams,
    required Season? currentSeason,
    required String? currentPlayerId,
  }) {
    final String? seasonId = currentSeason?.ref?.id;

    if (seasonId == null ||
        seasonId.isEmpty ||
        currentPlayerId == null ||
        currentPlayerId.isEmpty) {
      return <Team>[];
    }

    final Map<String, Team> teamsMap =
        teams[currentPlayerId]?[seasonId] ?? <String, Team>{};

    final List<Team> result = teamsMap.values.toList();

    result.sort((a, b) {
      final String nameA = (a.name ?? '').toLowerCase();
      final String nameB = (b.name ?? '').toLowerCase();

      return nameA.compareTo(nameB);
    });

    return result;
  }

  List<String> getTeamIdsForCurrentPlayerAndSeason({
    required Map<String, Map<String, Map<String, Team>>> teams,
    required Season? currentSeason,
    required String? currentPlayerId,
    required List<String>? managedTeamsIds,
  }) {
    final String? seasonId = currentSeason?.ref?.id;

    if (seasonId == null ||
        seasonId.isEmpty ||
        currentPlayerId == null ||
        currentPlayerId.isEmpty) {
      return <String>[];
    }

    final Set<String> excludedTeamIds = (managedTeamsIds ?? <String>[]).toSet();

    return teams[currentPlayerId]?[seasonId]
        ?.keys
        .where((teamId) => !excludedTeamIds.contains(teamId))
        .toList() ??
        <String>[];
  }

  Widget _buildDashboardTopCard({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required bool isPhone,
    required String? teamId,
    required String? playerId,
    required List<String>? managedTeamsIds,
    required List<String>? currentPlayerTeamsIds,
    required String? userId,
  }) {
    final AppSession session = context.watch<AppSession>();
    final bool isManager =
        userId != null && (managedTeamsIds?.contains(teamId) ?? false);
    final bool isStaff = isStaffOnTeamId(session, teamId);
    // Managers and roster staff use the team dashboard (graph + list + details).
    final bool hasTeamDashboardAccess = isManager || isStaff;
    final bool isPlayer = playerId != null &&
        (currentPlayerTeamsIds?.contains(teamId) ?? false) &&
        !isStaff;

    if (hasTeamDashboardAccess && !isPlayer) {
      _selectedStatsWhere = DashboardWhereType.team;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(
            context: context,
            colors: colors,
            textTheme: textTheme,
            isPhone: isPhone,
          ),

          SizedBox(height: isPhone ? 12 : 14),

          _buildStatsTypeSelector(
            context: context,
            colors: colors,
            textTheme: textTheme,
            isPhone: isPhone,
          ),

          SizedBox(height: isPhone ? 14 : 18),

          if (isPlayer &&
              _selectedStatsType != DashboardStatsType.personalSports) ...[
            _buildStatsWhereSelector(
              context: context,
              colors: colors,
              textTheme: textTheme,
              isPhone: isPhone,
            ),
            SizedBox(height: isPhone ? 14 : 18),
          ],

          _buildStatsStream(
            context: context,
            colors: colors,
            textTheme: textTheme,
            teamId: teamId,
            playerId: playerId,
            managedTeamsIds: managedTeamsIds,
            statsType: _selectedStatsType,
            whereType: hasTeamDashboardAccess
                ? DashboardWhereType.team
                : _selectedStatsWhere,
            userId: userId,
            useTeamTrainingAverages: hasTeamDashboardAccess,
          ),
        ],
      ),
    );
  }
  Widget _buildStatsTypeSelector({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required bool isPhone,
  }) {
    final l10n = context.l10n;
    final List<Widget> buttons = [
      _PeriodChip(
        label: l10n.entityTrainings,
        selected: _selectedStatsType == DashboardStatsType.trainings,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardStatsTypeSelect,
            parameters: const <String, Object>{'value': 'trainings'},
          );
          setState(() {
            _selectedStatsType = DashboardStatsType.trainings;
          });
        },
      ),
      _PeriodChip(
        label: l10n.entityMatches,
        selected: _selectedStatsType == DashboardStatsType.matches,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardStatsTypeSelect,
            parameters: const <String, Object>{'value': 'matches'},
          );
          setState(() {
            _selectedStatsType = DashboardStatsType.matches;
          });
        },
      ),
      _PeriodChip(
        label: l10n.entityPersonalSports,
        selected: _selectedStatsType == DashboardStatsType.personalSports,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardStatsTypeSelect,
            parameters: const <String, Object>{'value': 'personal_sports'},
          );
          setState(() {
            _selectedStatsType = DashboardStatsType.personalSports;
          });
        },
      ),
    ];

    final Widget buttonsContent = isPhone
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    )
        : Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buttonsContent,
      ],
    );
  }

  Widget _buildStatsWhereSelector({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required bool isPhone,
  }) {
    final l10n = context.l10n;
    final List<Widget> buttons = [
      _PeriodChip(
        label: l10n.entityPlayer,
        selected: _selectedStatsWhere == DashboardWhereType.player,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardStatsWhereSelect,
            parameters: const <String, Object>{'value': 'player'},
          );
          setState(() {
            _selectedStatsWhere = DashboardWhereType.player;
          });
        },
      ),
      _PeriodChip(
        label: l10n.entityTeam,
        selected: _selectedStatsWhere == DashboardWhereType.team,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardStatsWhereSelect,
            parameters: const <String, Object>{'value': 'team'},
          );
          setState(() {
            _selectedStatsWhere = DashboardWhereType.team;
          });
        },
      ),
    ];

    final Widget buttonsContent = isPhone
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    )
        : Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buttonsContent,
      ],
    );
  }

  Widget _buildStatsStream({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? teamId,
    required String? playerId,
    required List<String>? managedTeamsIds,
    required DashboardStatsType statsType,
    required DashboardWhereType whereType,
    required String? userId,
    bool useTeamTrainingAverages = false,
  }) {
    final l10n = context.l10n;
    final DateTimeRange range = getSelectedDateRange();
    final Timestamp start = Timestamp.fromDate(range.start);
    final Timestamp end = Timestamp.fromDate(range.end);

    if (statsType == DashboardStatsType.personalSports) {
      final memberId = (playerId ?? '').trim();
      if (memberId.isEmpty) {
        return _InfoMessage(
          title: l10n.entityPersonalSports,
          message: l10n.emptyNoPersonalSportToShow,
        );
      }

      return StreamBuilder<List<PersonalSportActivity>>(
        stream: _personalSports.watchForMemberBetweenDates(
          memberId: memberId,
          start: range.start,
          end: range.end,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _InfoMessage(
              title: l10n.entityPersonalSports,
              message: l10n.errorLoadingResource(l10n.entityPersonalSports),
              isError: true,
            );
          }
          if (!snapshot.hasData) {
            return _buildStatsLoading(
              context: context,
              colors: colors,
              textTheme: textTheme,
            );
          }

          final activities = List<PersonalSportActivity>.from(
            snapshot.data ?? const <PersonalSportActivity>[],
          )..sort((a, b) => b.startAt.compareTo(a.startAt));

          final now = DateTime.now();
          var done = 0;
          var planned = 0;
          for (final activity in activities) {
            if (activity.endAt.isBefore(now)) {
              done++;
            } else {
              planned++;
            }
          }

          return _buildSingleStatResponsive(
            context: context,
            colors: colors,
            textTheme: textTheme,
            icon: Icons.directions_run_rounded,
            stats: _ActivityStats(
              done: done,
              planned: planned,
              presentPecent: 0,
              personalActivities: activities,
            ),
            label: l10n.entityPersonalSports,
            accentColor: colors.success,
            matches: const <match_model.Match>[],
            teamId: teamId ?? '',
            userId: userId ?? '',
            managedTeamsIds: managedTeamsIds ?? const <String>[],
            playerId: memberId,
          );
        },
      );
    }

    if (teamId == null || teamId.isEmpty) {
      return _InfoMessage(
        title: l10n.navStatistics,
        message: l10n.emptyNoTeamForStats,
      );
    }

    if (statsType == DashboardStatsType.matches) {
      return StreamBuilder<List<match_model.Match>>(
        stream: _matchService.streamMatchesByTeamIdBetweenDates(
          teamId: teamId,
          start: start,
          end: end,
        ),
        builder: (context, matchSnapshot) {
          if (matchSnapshot.hasError) {
            return _InfoMessage(
              title: l10n.entityMatches,
              message: l10n.errorLoadingResource(l10n.entityMatches),
              isError: true,
            );
          }

          if (!matchSnapshot.hasData) {
            return _buildStatsLoading(
              context: context,
              colors: colors,
              textTheme: textTheme,
            );
          }

          final List<match_model.Match> matchesTmp =
              matchSnapshot.data ?? <match_model.Match>[];

          return FutureBuilder<List<match_model.Match>>(
            future: _filterMatchesByWhereType(
              matches: matchesTmp,
              whereType: whereType,
              playerId: playerId,
            ),
            builder: (context, filteredMatchesSnapshot) {
              if (filteredMatchesSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return _buildStatsLoading(
                  context: context,
                  colors: colors,
                  textTheme: textTheme,
                );
              }

              if (filteredMatchesSnapshot.hasError) {
                return _InfoMessage(
                  title: l10n.entityMatches,
                  message: l10n.errorFilteringResource(l10n.entityMatches),
                  isError: true,
                );
              }

              final List<match_model.Match> matches =
                  filteredMatchesSnapshot.data ?? <match_model.Match>[];

              return FutureBuilder<_ActivityStats>(
                future: _buildMatchStats(
                  matches: matches,
                  teamId: teamId,
                ),
                builder: (context, statsSnapshot) {
                  if (statsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildStatsLoading(
                      context: context,
                      colors: colors,
                      textTheme: textTheme,
                    );
                  }

                  if (statsSnapshot.hasError) {
                    return _InfoMessage(
                      title: l10n.entityMatches,
                      message: l10n.errorComputingStats(l10n.entityMatches),
                      isError: true,
                    );
                  }

                  final _ActivityStats matchStats = statsSnapshot.data ??
                      const _ActivityStats(
                        done: 0,
                        planned: 0,
                        presentPecent: 0.0
                      );

                  return _buildSingleStatResponsive(
                    context: context,
                    colors: colors,
                    textTheme: textTheme,
                    icon: Icons.sports_soccer_rounded,
                    stats: matchStats,
                    label: l10n.entityMatches,
                    accentColor: colors.danger,
                    matches: matches,
                    teamId: _selectedTeamId!,
                    userId: userId!,
                    managedTeamsIds: (managedTeamsIds != null)?managedTeamsIds:[],
                    playerId: playerId!
                  );
                },
              );
            },
          );
        },
      );
    }

    return StreamBuilder<List<Training>>(
      stream: _trainingService.streamTrainingsByTeamIdBetweenDates(
        teamId: teamId,
        start: start,
        end: end,
      ),
      builder: (context, trainingSnapshot) {
        if (trainingSnapshot.hasError) {
          return _InfoMessage(
            title: l10n.entityTrainings,
            message: l10n.errorLoadingResource(l10n.entityTrainings),
            isError: true,
          );
        }

        if (!trainingSnapshot.hasData) {
          return _buildStatsLoading(
            context: context,
            colors: colors,
            textTheme: textTheme,
          );
        }

        final List<Training> trainingsTmp = trainingSnapshot.data ?? <Training>[];
        List<Training> trainings = [];

        double passed = 0;
        double present = 0;

        for(var t in trainingsTmp) {
          if(t.dateTime!.millisecondsSinceEpoch < Timestamp.now().millisecondsSinceEpoch) {
            passed++;
          }
          if(_selectedStatsWhere == DashboardWhereType.player) {
            for(var p in t.playerTraining) {
              if(p.playerId == playerId && (p.presenceType == PresenceType.present || p.presenceType == PresenceType.late)) {
                if(t.dateTime!.millisecondsSinceEpoch < Timestamp.now().millisecondsSinceEpoch) {
                  present++;
                }
                trainings.add(t);
              }
            }
          } else {
            trainings.add(t);
          }
        }

        double presentPresent = (passed >0)?(present /passed) * 100:0;

        final Future<_ActivityStats> trainingStatsFuture =
        playerId == null || playerId.isEmpty
            ? Future<_ActivityStats>.value(
          const _ActivityStats(
            done: 0,
            planned: 0,
            presentPecent: 0.0,
          ),
        )
            : _buildTrainingStats(
          trainings: trainings,
          playerId: playerId,
          managedTeamsIds: managedTeamsIds,
          presentPercent: presentPresent,
          useTeamAverages: useTeamTrainingAverages,
        );

        return FutureBuilder<_ActivityStats>(
          future: trainingStatsFuture,
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildStatsLoading(
                context: context,
                colors: colors,
                textTheme: textTheme,
              );
            }

            if (statsSnapshot.hasError) {
              return _InfoMessage(
                title: l10n.entityTrainings,
                message: l10n.errorComputingStats(l10n.entityTrainings),
                isError: true,
              );
            }

            final _ActivityStats trainingStats = statsSnapshot.data ??
                const _ActivityStats(
                  done: 0,
                  planned: 0,
                  presentPecent: 0.0,
                );

            return _buildSingleStatResponsive(
              context: context,
              colors: colors,
              textTheme: textTheme,
              icon: Icons.fitness_center_rounded,
              stats: trainingStats,
              label: l10n.entityTrainings,
              accentColor: colors.primary,
              matches: const <match_model.Match>[],
              teamId: teamId,
              userId: userId!,
              managedTeamsIds: (managedTeamsIds != null)?managedTeamsIds:[],
              playerId: playerId
            );
          },
        );
      },
    );
  }

  Future<List<match_model.Match>> _filterMatchesByWhereType({
    required List<match_model.Match> matches,
    required DashboardWhereType whereType,
    required String? playerId,
  }) async {

    print('dans filterMatchesByWhereType whereType=${whereType.toString()}');


    if (whereType != DashboardWhereType.player) {
      return matches;
    }

    if (playerId == null || playerId.isEmpty) {
      return <match_model.Match>[];
    }

    final List<match_model.Match> filteredMatches = <match_model.Match>[];

    for (final match in matches) {
      final String? matchId = match.id;

      if (matchId == null || matchId.isEmpty) {
        continue;
      }

      final matchCompos =
      await _matchCompoService.getMatchComposByMatchId(matchId);

      bool playerFound = false;

      for (final compo in matchCompos) {
        if (_matchCompoContainsPlayer(
          matchCompo: compo,
          playerId: playerId,
        )) {
          playerFound = true;
          break;
        }
      }

      if (playerFound) {
        filteredMatches.add(match);
      }
    }

    return filteredMatches;
  }

  bool _matchCompoContainsPlayer({
    required MatchCompo matchCompo,
    required String playerId,
  }) {

    try {

      for(var p in matchCompo.substitute!) {
        if(p.playerID == playerId) return true;
      }

      for(var p in matchCompo.goalkeeper!) {
        if(p.playerID == playerId) return true;
      }

      for(var p in matchCompo.defender!) {
        if(p.playerID == playerId) return true;
      }

      for(var p in matchCompo.midfielderDefensive!) {
        if(p.playerID == playerId) return true;
      }
      for(var p in matchCompo.midfielder!) {
        if(p.playerID == playerId) return true;
      }
      for(var p in matchCompo.midfielderAttaking!) {
        if(p.playerID == playerId) return true;
      }
      for(var p in matchCompo.stricker!) {
        if(p.playerID == playerId) return true;
      }

    } catch (_) {}
    return false;
  }

  Widget _buildSingleStatResponsive({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required IconData icon,
    required _ActivityStats stats,
    required String label,
    required Color accentColor,
    required List<match_model.Match> matches,
    required String userId,
    required String teamId,
    required List<String> managedTeamsIds,
    required String? playerId,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        if (width < 520) {
          return _StatCompactCard(
            icon: icon,
            stats: stats,
            label: label,
            accentColor: accentColor,
            fillWidth: true,
            matches: matches,
            type: _selectedStatsType,
            where: _selectedStatsWhere,
            teamId: teamId,
            userId: userId,
            managedTeamsIds: managedTeamsIds,
            playerId: playerId,
          );
        }

        return SizedBox(
          width: double.infinity,
          child: _StatCompactCard(
            icon: icon,
            stats: stats,
            label: label,
            accentColor: accentColor,
            fillWidth: true,
            matches: matches,
            type: _selectedStatsType,
            where: _selectedStatsWhere,
            teamId: teamId,
            userId: userId,
            managedTeamsIds: managedTeamsIds,
            playerId: playerId,
          ),
        );
      },
    );
  }

  Future<_ActivityStats> _buildMatchStats({
    required List<match_model.Match> matches,
    required String teamId,
  }) async {
    final DateTime now = DateTime.now();

    int done = 0;
    int planned = 0;

    final Map<_MatchOutcome, int> outcomes = <_MatchOutcome, int>{
      _MatchOutcome.won: 0,
      _MatchOutcome.lost: 0,
      _MatchOutcome.draw: 0,
    };

    final team = await TeamService().getTeamById(teamId);
    final club = await ClubService().getClubById(team!.clubId!);


    for (final match in matches) {
      final DateTime? date = _dateFromValue(match.timestamp);

      if (date == null) {
        continue;
      }

      final bool isDone =
          date.millisecondsSinceEpoch <= now.millisecondsSinceEpoch;

      if (isDone) {
        done++;


        final _MatchOutcome? outcome = _getMatchOutcomeForTeam(
          match: match,
          teamId: teamId,
          clubId: club!.affiliation!,
        );

        if (outcome != null) {
          outcomes[outcome] = (outcomes[outcome] ?? 0) + 1;
        }
      } else {
        planned++;
      }
    }

    return _ActivityStats(
      done: done,
      planned: planned,
      matchOutcomes: Map<_MatchOutcome, int>.unmodifiable(outcomes),
      presentPecent: 0.0,
    );
  }

  _MatchOutcome? _getMatchOutcomeForTeam({
    required match_model.Match match,
    required String teamId,
    required String clubId,
  }) {

    bool isHomeTeam = false;
    bool isAwayTeam = false;

    if(match.clubs!.isNotEmpty) {
      if(match.clubs!.first == clubId) {
        isHomeTeam = true;
      } else {
        isAwayTeam = true;
      }
    } else {
      return null;
    }


    final int? homeScore = match.homeScore;
    final int? awayScore = match.outSideScore;

    if (homeScore == null ||
        awayScore == null) {
      return null;
    }

    if (homeScore == awayScore) {
      return _MatchOutcome.draw;
    }

    if (isHomeTeam && homeScore > awayScore) {
      return _MatchOutcome.won;
    }

    if (isAwayTeam && awayScore > homeScore) {
      return _MatchOutcome.won;
    }

    return _MatchOutcome.lost;
  }

  Future<_ActivityStats> _buildTrainingStats({
    required List<Training> trainings,
    required String playerId,
    required List<String>? managedTeamsIds,
    required double presentPercent,
    bool useTeamAverages = false,
  }) async {
    final DateTime now = DateTime.now();

    int done = 0;
    int planned = 0;

    final List<ActivityMetrics> trainingMetrics = <ActivityMetrics>[];

    for (final training in trainings) {
      final DateTime? date = _dateFromValue(training.dateTime);

      if (date == null) {
        continue;
      }

      if (date.millisecondsSinceEpoch <= now.millisecondsSinceEpoch) {
        done++;
        if (training.withTracker != true) {
          continue;
        }

        final String eventId = training.docId?.trim() ?? '';
        if (eventId.isEmpty || training.dateTime == null) {
          continue;
        }

        final workloadSummary =
            await TeamWorkloadSummaryService().getByEventId(eventId);
        if (workloadSummary != null) {
          bool isPlayerFounded = false;
          for (final ps in workloadSummary.playerScores) {
            if (ps.playerId != playerId) {
              continue;
            }
            isPlayerFounded = true;
            trainingMetrics.add(
              buildActivityMetricsFromPlayerScore(
                eventId: eventId,
                timestamp: training.dateTime!,
                playerScore: ps,
              ),
            );
            break;
          }
          // Managers / roster staff: team averages when the user is not a tracked player.
          final bool canUseTeamAverages = useTeamAverages ||
              (managedTeamsIds?.contains(training.teamId) ?? false);
          if (!isPlayerFounded && canUseTeamAverages) {
            trainingMetrics.add(
              buildActivityMetricsFromSummary(
                eventId: eventId,
                timestamp: training.dateTime!,
                tws: workloadSummary,
              ),
            );
          }
          continue;
        }

        // Polar kits write TRACKER_PolarAnalysis, not TeamWorkloadSummary.
        if (!await isPolarTrackerOwner(training.ownerId)) {
          continue;
        }
        final polarAnalyses =
            await PolarSessionAnalysisService().listByEventId(eventId);
        if (polarAnalyses.isEmpty) {
          continue;
        }

        PolarSessionAnalysis? playerAnalysis;
        for (final analysis in polarAnalyses) {
          if (analysis.playerId.trim() == playerId.trim()) {
            playerAnalysis = analysis;
            break;
          }
        }
        final bool canUseTeamAverages = useTeamAverages ||
            (managedTeamsIds?.contains(training.teamId) ?? false);
        if (playerAnalysis != null) {
          trainingMetrics.add(
            buildActivityMetricsFromPolarAnalysis(
              eventId: eventId,
              timestamp: training.dateTime!,
              analysis: playerAnalysis,
            ),
          );
        } else if (canUseTeamAverages) {
          trainingMetrics.add(
            buildActivityMetricsFromPolarAnalyses(
              eventId: eventId,
              timestamp: training.dateTime!,
              analyses: polarAnalyses,
            ),
          );
        }
      } else {
        planned++;
      }
    }

    trainingMetrics.sort((a, b) {
      return b.timestamp.millisecondsSinceEpoch.compareTo(
        a.timestamp.millisecondsSinceEpoch,
      );
    });

    return _ActivityStats(
      done: done,
      planned: planned,
      trainingMetrics: List<ActivityMetrics>.unmodifiable(
        trainingMetrics,
      ),
      presentPecent: presentPercent,
    );
  }
  DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Widget _buildStatsLoading({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
  }) {
    final l10n = context.l10n;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.loadingStats,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateFr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Widget _buildPeriodSelector({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required bool isPhone,
  }) {
    final bool hasCustomRange =
        _selectedPeriod == DashboardPeriod.custom && _customRange != null;

    final l10n = context.l10n;
    final String? customRangeLabel = hasCustomRange
        ? l10n.periodCustomRange(
            _formatDateFr(_customRange!.start),
            _formatDateFr(_customRange!.end),
          )
        : null;

    final List<Widget> buttons = [
      _PeriodChip(
        label: l10n.periodWeek,
        selected: _selectedPeriod == DashboardPeriod.week,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardPeriodSelect,
            parameters: const <String, Object>{'value': 'week'},
          );
          setState(() {
            _selectedPeriod = DashboardPeriod.week;
          });
        },
      ),
      _PeriodChip(
        label: l10n.periodMonth,
        selected: _selectedPeriod == DashboardPeriod.month,
        onTap: () {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardPeriodSelect,
            parameters: const <String, Object>{'value': 'month'},
          );
          setState(() {
            _selectedPeriod = DashboardPeriod.month;
          });
        },
      ),
      _PeriodChip(
        label: l10n.periodCustom,
        selected: _selectedPeriod == DashboardPeriod.custom,
        onTap: () async {
          AnalyticsInteractions.logFeature(
            AnalyticsFeatures.dashboardPeriodSelect,
            parameters: const <String, Object>{'value': 'custom'},
          );
          await _selectCustomRange(context);
        },
      ),
    ];

    final Widget buttonsContent = isPhone
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    )
        : Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buttonsContent,
        if (customRangeLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            customRangeLabel,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final colors = context.appColors;
    final DateTime now = DateTime.now();

    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.primary,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    setState(() {
      _selectedPeriod = DashboardPeriod.custom;
      _customRange = range;
    });
  }


  Widget _buildTeamCard({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? seasonId,
    required String? userId,
    required String? playerId,
    required bool isPhone,
    required bool isManagedTeams,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 14 : 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: _buildTeamsDropdown(
        context: context,
        colors: colors,
        textTheme: textTheme,
        seasonId: seasonId,
        userId: userId,
        playerId: playerId,
        isManagedTeams: isManagedTeams,
      ),
    );
  }

  DateTimeRange getSelectedDateRange() {
    final DateTime now = DateTime.now();

    if (_selectedPeriod == DashboardPeriod.week) {
      final int weekday = now.weekday;

      final DateTime start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));

      final DateTime end = DateTime(
        start.year,
        start.month,
        start.day + 7,
      );

      return DateTimeRange(start: start, end: end);
    }

    if (_selectedPeriod == DashboardPeriod.month) {
      final DateTime start = DateTime(now.year, now.month, 1);
      final DateTime end = DateTime(now.year, now.month + 1, 1);

      return DateTimeRange(start: start, end: end);
    }

    final DateTimeRange range = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final DateTime start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );

    final DateTime end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day + 1,
    );

    return DateTimeRange(start: start, end: end);
  }

  bool isDateInSelectedRange(DateTime date) {
    final DateTimeRange range = getSelectedDateRange();

    return date.millisecondsSinceEpoch >= range.start.millisecondsSinceEpoch &&
        date.millisecondsSinceEpoch < range.end.millisecondsSinceEpoch;
  }

  Stream<List<Team>> _getTeamsStream({
    required bool isManagedTeams,
    required String seasonId,
    required String userId,
    required String? playerId,
  }) {
    if (isManagedTeams) {
      return _teamService.streamTeamsBySeasonIdAndManager(
        seasonId: seasonId,
        userId: userId,
      );
    }

    if (playerId == null || playerId.isEmpty) {
      return Stream.value(<Team>[]);
    }

    return _teamService.streamTeamsBySeasonIdPlayerId(
      seasonId: seasonId,
      playerId: playerId,
    );
  }

  Widget _buildTeamsDropdown({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? seasonId,
    required String? userId,
    required String? playerId,
    required bool isManagedTeams,
  }) {
    final l10n = context.l10n;
    final String title =
        isManagedTeams ? l10n.dashboardMyManagedTeams : l10n.myTeams;

    if (seasonId == null || seasonId.isEmpty) {
      return _InfoMessage(
        title: title,
        message: l10n.emptyNoCurrentSeason,
      );
    }

    if (userId == null || userId.isEmpty) {
      return _InfoMessage(
        title: title,
        message: l10n.infoUserNotConnected,
      );
    }

    if (!isManagedTeams && (playerId == null || playerId.isEmpty)) {
      return _InfoMessage(
        title: title,
        message: l10n.emptyNoPlayerSelected,
      );
    }

    return StreamBuilder<List<Team>>(
      stream: _getTeamsStream(
        isManagedTeams: isManagedTeams,
        seasonId: seasonId,
        userId: userId,
        playerId: playerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: title),
              const SizedBox(height: 14),
              Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return _InfoMessage(
            title: title,
            message: l10n.errorLoadingResource(l10n.entityTeams),
            isError: true,
          );
        }

        final List<Team> teams = snapshot.data ?? <Team>[];


        if (teams.isEmpty) {
          return _InfoMessage(
            title: title,
            message: l10n.emptyNoTeamForSeason,
          );
        }



        final List<Team> cleanTeams = teams.where((team) {
          final String? teamId = team.keyTeam;
          return teamId != null && teamId.trim().isNotEmpty;
        }).toList();



        final bool selectedExists = cleanTeams.any(
              (team) => team.keyTeam == _selectedTeamId,
        );

        final String selectedValue =
        selectedExists ? _selectedTeamId! : cleanTeams.first.keyTeam!;

        if (!selectedExists && _selectedTeamId != selectedValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            setState(() {
              _selectedTeamId = selectedValue;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: title),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
              decoration: InputDecoration(
                labelText: l10n.entityTeam,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: colors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: 1.4,
                  ),
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: cleanTeams.map((team) {
                return DropdownMenuItem<String>(
                  value: team.keyTeam,
                  child: Text(
                    team.name ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedTeamId = value;
                });
              },
            ),
          ],
        );
      },
    );
  }
}
