import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:provider/provider.dart';

import '../model/activityMetrics.dart';
import '../model/match.dart' as match_model;
import '../model/season.dart';
import '../model/team.dart';
import '../model/training.dart';
import '../services/matchService.dart';
import '../services/teamService.dart';
import '../services/trainingService.dart';
import '../util/app_theme.dart';
import '../widget/activity_rings_card.dart';
import '../widget/metrics_panel.dart';

enum DashboardPeriod {
  week,
  month,
  custom,
}

enum _MatchOutcome {
  won,
  lost,
  draw,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  final TrainingService _trainingService = TrainingService();

  String? _selectedTeamId;
  Season? currentSeason;
  String? currentPlayerId;
  String? currentUserId;

  DashboardPeriod _selectedPeriod = DashboardPeriod.week;
  DateTimeRange? _customRange;

  Future<void> _logOpenProduct() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'open_product',
      parameters: {
        'source': 'home',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final currentUser = FirebaseAuth.instance.currentUser;
    final String? userId = currentUser?.uid;

    final List<String> managedTeamsIds =
    context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );

    currentSeason = context.watch<AppSession>().selectedSeason;
    currentPlayerId = context.watch<AppSession>().selectedPlayerId;
    currentUserId = context.watch<AppSession>().user!.uid;

    final List<String> currentPlayerTeamIds = getTeamIdsForCurrentPlayerAndSeason(
      teams: context.watch<AppSession>().teams,
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
                        managedTeamsIds: managedTeamsIds
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
  }) {
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
          SizedBox(height: isPhone ? 14 : 18),
          _buildStatsStream(
            context: context,
            colors: colors,
            textTheme: textTheme,
            teamId: teamId,
            playerId: playerId,
            managedTeamsIds: managedTeamsIds,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStream({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? teamId,
    required String? playerId,
    required List<String>? managedTeamsIds,
  }) {
    if (teamId == null || teamId.isEmpty) {
      return const _InfoMessage(
        title: 'Statistiques',
        message: 'Aucune équipe disponible pour afficher les statistiques.',
      );
    }

    final DateTimeRange range = getSelectedDateRange();

    final Timestamp start = Timestamp.fromDate(range.start);
    final Timestamp end = Timestamp.fromDate(range.end);

    return StreamBuilder<List<match_model.Match>>(
      stream: _matchService.streamMatchesByTeamIdBetweenDates(
        teamId: teamId,
        start: start,
        end: end,
      ),
      builder: (context, matchSnapshot) {
        if (matchSnapshot.hasError) {
          return const _InfoMessage(
            title: 'Statistiques',
            message: 'Erreur lors du chargement des matchs.',
            isError: true,
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
              return const _InfoMessage(
                title: 'Statistiques',
                message: 'Erreur lors du chargement des entraînements.',
                isError: true,
              );
            }

            final bool isLoading =
                !matchSnapshot.hasData || !trainingSnapshot.hasData;

            if (isLoading) {
              return _buildStatsLoading(
                context: context,
                colors: colors,
                textTheme: textTheme,
              );
            }

            final List<match_model.Match> matches =
                matchSnapshot.data ?? <match_model.Match>[];

            final List<Training> trainings =
                trainingSnapshot.data ?? <Training>[];

            final Future<_ActivityStats> matchStatsFuture = _buildMatchStats(
              matches: matches,
              teamId: teamId,
            );

            final Future<_ActivityStats> trainingStatsFuture =
            playerId == null || playerId.isEmpty
                ? Future<_ActivityStats>.value(
              const _ActivityStats(
                done: 0,
                planned: 0,
              ),
            )
                : _buildTrainingStats(
              trainings: trainings,
              playerId: playerId,
              managedTeamsIds: managedTeamsIds,
            );

            return FutureBuilder<List<_ActivityStats>>(
              future: Future.wait<_ActivityStats>([
                matchStatsFuture,
                trainingStatsFuture,
              ]),
              builder: (context, statsSnapshot) {
                if (statsSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildStatsLoading(
                    context: context,
                    colors: colors,
                    textTheme: textTheme,
                  );
                }

                if (statsSnapshot.hasError) {
                  return const _InfoMessage(
                    title: 'Statistiques',
                    message: 'Erreur lors du calcul des statistiques.',
                    isError: true,
                  );
                }

                final List<_ActivityStats> stats =
                    statsSnapshot.data ?? <_ActivityStats>[];

                final _ActivityStats matchStats = stats.isNotEmpty
                    ? stats[0]
                    : const _ActivityStats(
                  done: 0,
                  planned: 0,
                );

                final _ActivityStats trainingStats = stats.length > 1
                    ? stats[1]
                    : const _ActivityStats(
                  done: 0,
                  planned: 0,
                );

                return _buildStatsResponsive(
                  context: context,
                  colors: colors,
                  textTheme: textTheme,
                  matchStats: matchStats,
                  trainingStats: trainingStats,
                  physicalPrepStats: const _ActivityStats(
                    done: 0,
                    planned: 0,
                  ),
                );
              },
            );
          },
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
        if(training.withTracker) {
          final workloadSummary = await TeamWorkloadSummaryService().getByEventId(training.docId!);
          if(workloadSummary != null) {
            bool isPlayerFounded = false;
            for (final ps in workloadSummary.playerScores) {
              if (ps.playerId != playerId) {
                continue;
              }
              isPlayerFounded = true;
              final String eventId = training.docId ?? '';
              if (eventId.isEmpty) {
                continue;
              }
              final ActivityMetrics activityMetrics = buildActivityMetricsFromPlayerScore(
                eventId: eventId,
                timestamp: training.dateTime!,
                playerScore: ps,
              );
              trainingMetrics.add(activityMetrics);
              break;
            }
            // si joueur non trouvé dans la liste et si l'équipe est managé par le user courrant alors on prend la moyenne de chaqye metrics
            if(isPlayerFounded == false && managedTeamsIds!.contains(training.teamId)) {

            }
          }
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
            'Chargement des statistiques...',
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

    final String? customRangeLabel = hasCustomRange
        ? 'du ${_formatDateFr(_customRange!.start)} au ${_formatDateFr(_customRange!.end)}'
        : null;

    final List<Widget> buttons = [
      _PeriodChip(
        label: 'Semaine',
        selected: _selectedPeriod == DashboardPeriod.week,
        onTap: () {
          setState(() {
            _selectedPeriod = DashboardPeriod.week;
          });
        },
      ),
      _PeriodChip(
        label: 'Mois',
        selected: _selectedPeriod == DashboardPeriod.month,
        onTap: () {
          setState(() {
            _selectedPeriod = DashboardPeriod.month;
          });
        },
      ),
      _PeriodChip(
        label: 'Période',
        selected: _selectedPeriod == DashboardPeriod.custom,
        onTap: () async {
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

  Widget _buildStatsResponsive({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required _ActivityStats matchStats,
    required _ActivityStats trainingStats,
    required _ActivityStats physicalPrepStats,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        if (width < 520) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _StatCompactCard(
                  icon: Icons.sports_soccer_rounded,
                  stats: matchStats,
                  label: 'Matchs',
                  accentColor: colors.danger,
                  minWidth: 270,
                ),
                const SizedBox(width: 10),
                _StatCompactCard(
                  icon: Icons.fitness_center_rounded,
                  stats: trainingStats,
                  label: 'Entraînements',
                  accentColor: colors.primary,
                  minWidth: 285,
                ),
                if (physicalPrepStats.total > 0) ...[
                  const SizedBox(width: 10),
                  _StatCompactCard(
                    icon: Icons.directions_run_rounded,
                    stats: physicalPrepStats,
                    label: 'Prépa physique',
                    accentColor: colors.success,
                    minWidth: 280,
                  ),
                ],
              ],
            ),
          );
        }

        if (width < 850) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: (width - 10) / 2,
                child: _StatCompactCard(
                  icon: Icons.sports_soccer_rounded,
                  stats: matchStats,
                  label: 'Matchs',
                  accentColor: colors.danger,
                  fillWidth: true,
                ),
              ),
              SizedBox(
                width: (width - 10) / 2,
                child: _StatCompactCard(
                  icon: Icons.fitness_center_rounded,
                  stats: trainingStats,
                  label: 'Entraînements',
                  accentColor: colors.primary,
                  fillWidth: true,
                ),
              ),
              if (physicalPrepStats.total > 0)
                SizedBox(
                  width: width,
                  child: _StatCompactCard(
                    icon: Icons.directions_run_rounded,
                    stats: physicalPrepStats,
                    label: 'Prépa physique',
                    accentColor: colors.success,
                    fillWidth: true,
                  ),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCompactCard(
                icon: Icons.sports_soccer_rounded,
                stats: matchStats,
                label: 'Matchs',
                accentColor: colors.danger,
                fillWidth: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCompactCard(
                icon: Icons.fitness_center_rounded,
                stats: trainingStats,
                label: 'Entraînements',
                accentColor: colors.primary,
                fillWidth: true,
              ),
            ),
            if (physicalPrepStats.total > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _StatCompactCard(
                  icon: Icons.directions_run_rounded,
                  stats: physicalPrepStats,
                  label: 'Prépa physique',
                  accentColor: colors.success,
                  fillWidth: true,
                ),
              ),
            ],
          ],
        );
      },
    );
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
    final String title =
    isManagedTeams ? 'Mes équipes managées' : 'Mes équipes';

    if (seasonId == null || seasonId.isEmpty) {
      return _InfoMessage(
        title: title,
        message: 'Aucune saison en cours disponible.',
      );
    }

    if (userId == null || userId.isEmpty) {
      return _InfoMessage(
        title: title,
        message: 'Utilisateur non connecté.',
      );
    }

    if (!isManagedTeams && (playerId == null || playerId.isEmpty)) {
      return _InfoMessage(
        title: title,
        message: 'Aucun joueur sélectionné.',
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
            message: 'Erreur lors du chargement des équipes.',
            isError: true,
          );
        }

        final List<Team> teams = snapshot.data ?? <Team>[];


        if (teams.isEmpty) {
          return _InfoMessage(
            title: title,
            message: 'Aucune équipe trouvée pour cette saison.',
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
                labelText: 'Équipe',
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

class _ActivityStats {
  const _ActivityStats({
    required this.done,
    required this.planned,
    this.matchOutcomes = const <_MatchOutcome, int>{},
    this.trainingMetrics = const <ActivityMetrics>[],
  });

  final int done;
  final int planned;
  final Map<_MatchOutcome, int> matchOutcomes;

  /// Utilisé uniquement pour les entraînements.
  final List<ActivityMetrics> trainingMetrics;

  int get total => done + planned;

  int get won => matchOutcomes[_MatchOutcome.won] ?? 0;
  int get lost => matchOutcomes[_MatchOutcome.lost] ?? 0;
  int get draw => matchOutcomes[_MatchOutcome.draw] ?? 0;

  int get totalOutcomes => won + lost + draw;

  bool get hasMatchOutcomes => totalOutcomes > 0;

  bool get hasTrainingMetrics => trainingMetrics.isNotEmpty;
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: selected ? colorScheme.onPrimary : colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}



class _StatCompactCard extends StatefulWidget {
  const _StatCompactCard({
    required this.icon,
    required this.stats,
    required this.label,
    required this.accentColor,
    this.minWidth = 255,
    this.fillWidth = false,
  });

  final IconData icon;
  final _ActivityStats stats;
  final String label;
  final Color accentColor;
  final double minWidth;
  final bool fillWidth;

  @override
  State<_StatCompactCard> createState() => _StatCompactCardState();
}

class _StatCompactCardState extends State<_StatCompactCard> {
  MetricType _selectedTrainingMetric = MetricType.workloadScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final bool hasMatchOutcomes = widget.stats.hasMatchOutcomes;
    final bool hasTrainingMetrics = widget.stats.hasTrainingMetrics;

    final double minHeight = hasMatchOutcomes
        ? 232
        : hasTrainingMetrics
        ? 0
        : 92;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.fillWidth ? 0 : widget.minWidth,
        minHeight: minHeight,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(
              context: context,
              colors: colors,
              textTheme: textTheme,
            ),
            const SizedBox(height: 9),
            _StatProgressBar(stats: widget.stats),
            const SizedBox(height: 7),
            _buildDonePlannedLegend(colors),

            if (hasMatchOutcomes) ...[
              const SizedBox(height: 12),
              _MatchOutcomeRingsCard(stats: widget.stats),
            ],

            if (hasTrainingMetrics) ...[
              const SizedBox(height: 12),
              MetricsPanel(
                metrics: widget.stats.trainingMetrics,
                initialMetricType: MetricType.workloadScore,
                maxVisibleRows: 10,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
  }) {
    return Row(
      mainAxisSize: widget.fillWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${widget.stats.total}',
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonePlannedLegend(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: _StatLegendItem(
            value: widget.stats.done,
            singularLabel: 'réalisé',
            pluralLabel: 'réalisés',
            color: colors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatLegendItem(
            value: widget.stats.planned,
            singularLabel: 'planifié',
            pluralLabel: 'planifiés',
            color: colors.warning,
            alignRight: true,
          ),
        ),
      ],
    );
  }

}



class _MatchOutcomeRingsCard extends StatelessWidget {
  const _MatchOutcomeRingsCard({
    required this.stats,
  });

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final double goal =
    stats.totalOutcomes <= 0 ? 1 : stats.totalOutcomes.toDouble();

    return Container(
      width: double.infinity,
      height: 126,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: ActivityRingsCard.compact(
              backgroundColor: colors.card,
              borderRadius: 12,
              padding: EdgeInsets.zero,
              withgoal: true,
              rings: [
                ActivityRingItem(
                  label: 'Victoires',
                  value: stats.won.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.success,
                  trackColor: colors.success.withValues(alpha: 0.16),
                ),
                ActivityRingItem(
                  label: 'Défaites',
                  value: stats.lost.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.danger,
                  trackColor: colors.danger.withValues(alpha: 0.16),
                ),
                ActivityRingItem(
                  label: 'Nuls',
                  value: stats.draw.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.warning,
                  trackColor: colors.warning.withValues(alpha: 0.16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MatchOutcomeLegendRow(
                  label: 'Victoires',
                  value: stats.won,
                  total: stats.totalOutcomes,
                  color: colors.success,
                ),
                const SizedBox(height: 8),
                _MatchOutcomeLegendRow(
                  label: 'Défaites',
                  value: stats.lost,
                  total: stats.totalOutcomes,
                  color: colors.danger,
                ),
                const SizedBox(height: 8),
                _MatchOutcomeLegendRow(
                  label: 'Nuls',
                  value: stats.draw,
                  total: stats.totalOutcomes,
                  color: colors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchOutcomeLegendRow extends StatelessWidget {
  const _MatchOutcomeLegendRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value/$total',
          style: textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatProgressBar extends StatelessWidget {
  const _StatProgressBar({
    required this.stats,
  });

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: Row(
          children: [
            if (stats.total == 0)
              Expanded(
                child: Container(
                  color: colors.border.withValues(alpha: 0.65),
                ),
              ),
            if (stats.done > 0)
              Expanded(
                flex: stats.done,
                child: Container(
                  color: colors.success,
                ),
              ),
            if (stats.planned > 0)
              Expanded(
                flex: stats.planned,
                child: Container(
                  color: colors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatLegendItem extends StatelessWidget {
  const _StatLegendItem({
    required this.value,
    required this.singularLabel,
    required this.pluralLabel,
    required this.color,
    this.alignRight = false,
  });

  final int value;
  final String singularLabel;
  final String pluralLabel;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final String label = value == 1 ? singularLabel : pluralLabel;

    return Row(
      mainAxisAlignment:
      alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$value $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.title,
    required this.message,
    this.isError = false,
  });

  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isError ? colors.danger : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}