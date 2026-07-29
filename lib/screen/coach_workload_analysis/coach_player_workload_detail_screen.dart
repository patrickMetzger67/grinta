import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/screen/team_players/team_players_screen.dart';
import 'package:grinta/services/coach_workload_analysis_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/polar_import_navigation.dart';
import 'package:grinta/util/session_tracker_kit.dart';
import 'package:grinta/widget/create_personal_sport_activity_sheet.dart';
import 'package:grinta/widget/personal_sport_activity_summary.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/session_player_analysis_view.dart';
import 'package:intl/intl.dart';

class CoachPlayerWorkloadDetailScreen extends StatefulWidget {
  const CoachPlayerWorkloadDetailScreen({
    super.key,
    required this.team,
    required this.seasonId,
    required this.range,
    required this.player,
    this.initialSummary,
    this.teamAverages = const CoachTeamWorkloadAverages(),
  });

  final Team team;
  final String seasonId;
  final DateTimeRange range;
  final Player player;
  final CoachPlayerWorkloadSummary? initialSummary;
  final CoachTeamWorkloadAverages teamAverages;

  @override
  State<CoachPlayerWorkloadDetailScreen> createState() =>
      _CoachPlayerWorkloadDetailScreenState();
}

class _CoachPlayerWorkloadDetailScreenState
    extends State<CoachPlayerWorkloadDetailScreen> {
  final _service = CoachWorkloadAnalysisService();
  late CoachPlayerWorkloadSummary _summary;
  List<CoachWorkloadActivityItem> _activities = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialSummary ??
        CoachPlayerWorkloadSummary(
          player: widget.player,
          memberId: '',
          trainingPresent: 0,
          trainingAbsent: 0,
          matchCount: 0,
          personalSportCount: 0,
          volumeMinutes: 0,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.loadPlayerDetail(
        team: widget.team,
        seasonId: widget.seasonId,
        start: widget.range.start,
        end: widget.range.end,
        player: widget.player,
      );
      if (!mounted) return;
      setState(() {
        _summary = detail.summary;
        _activities = detail.activities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.coachWorkloadLoadError;
      });
    }
  }

  Future<void> _openActivity(CoachWorkloadActivityItem item) async {
    switch (item.kind) {
      case CoachWorkloadActivityKind.personalSport:
        if (item.personalSport == null) return;
        await showCreatePersonalSportActivitySheet(
          context,
          activityToEdit: item.personalSport,
          readOnly: true,
        );
      case CoachWorkloadActivityKind.match:
        final match = item.match;
        if (match == null) return;
        AnalyticsInteractions.logFeature(
          AnalyticsFeatures.openMatchDetail,
          parameters: <String, Object>{
            'has_tracker': match.withTracker == true,
            'source': 'coach_workload_detail',
          },
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          analyticsMaterialRoute<void>(
            screenName: AnalyticsScreenNames.matchDetail,
            fullscreenDialog: true,
            builder: (_) => MatchDetailScreen(
              match: match,
              isManager: false,
              playerId: effectiveMemberId(widget.player),
              initialTabIndex: MatchDetailScreen.statsTabIndexFor(match),
            ),
          ),
        );
      case CoachWorkloadActivityKind.training:
        final training = item.training;
        if (training == null) return;
        await _openTrainingDetail(training);
    }
  }

  Future<void> _openTrainingDetail(Training training) async {
    final eventId = trainingEventId(training);
    final playerId = effectiveMemberId(widget.player)?.trim() ?? '';
    final hasTracker = training.withTracker == true &&
        eventId != null &&
        eventId.isNotEmpty &&
        playerId.isNotEmpty;

    if (!hasTracker) {
      await TeamPlayersScreen.open(
        context,
        training: training,
        seasonId: widget.seasonId,
        readOnly: true,
      );
      return;
    }

    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.openPlayerAnalysis,
      parameters: const <String, Object>{
        'source': 'coach_workload_detail',
        'is_match': false,
      },
    );

    final isPolar = await eventUsesPolarTeamKit(
      eventId: eventId,
      ownerId: training.ownerId,
    );
    if (!mounted) return;

    String? analysisDocId;
    String? trackerId;
    if (!isPolar) {
      final summary =
          await TeamWorkloadSummaryService().getByEventId(eventId);
      final score = summary == null
          ? null
          : _findPlayerScore(summary, widget.player);
      trackerId = score?.trackerId.trim();
      if (trackerId != null && trackerId.isNotEmpty) {
        analysisDocId = '${eventId}_$trackerId';
      }
    }

    if (!mounted) return;

    // No GPS tracker row for this player → fall back to training roster.
    if (!isPolar && (analysisDocId == null || analysisDocId.isEmpty)) {
      await TeamPlayersScreen.open(
        context,
        training: training,
        seasonId: widget.seasonId,
        readOnly: true,
      );
      return;
    }

    final colors = context.appColors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.background,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          playerDisplayName(
                            widget.player,
                            unknownLabel: sheetContext.l10n.entityPlayer,
                          ),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.border),
                Expanded(
                  child: SessionPlayerAnalysisView(
                    eventId: eventId,
                    ownerId: training.ownerId,
                    analysisDocId: analysisDocId,
                    trackerId: trackerId,
                    playerId: playerId,
                    teamId: training.teamId ?? widget.team.keyTeam,
                    playerName: playerDisplayName(
                      widget.player,
                      unknownLabel: sheetContext.l10n.entityPlayer,
                    ),
                    player: widget.player,
                    isMatch: false,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TeamPlayerMetricScores? _findPlayerScore(
    TeamWorkloadSummary summary,
    Player player,
  ) {
    final ids = playerMemberLookupIds(player);
    for (final score in summary.playerScores) {
      if (ids.contains(score.playerId.trim())) {
        return score;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    final presence = _summary.presencePercent;
    final presenceLabel =
        presence == null ? '—' : '${presence.toStringAsFixed(0)} %';
    final loadLabel = _summary.avgWorkloadScore == null
        ? '—'
        : _summary.avgWorkloadScore!.toStringAsFixed(0);
    final kmLabel = _summary.totalDistanceKm == null
        ? '—'
        : _summary.totalDistanceKm!.toStringAsFixed(1);
    final averages = widget.teamAverages;

    Color toneColor(CoachMetricTone tone, Color fallback) {
      switch (tone) {
        case CoachMetricTone.success:
          return colors.success;
        case CoachMetricTone.warning:
          return colors.warning;
        case CoachMetricTone.neutral:
          return fallback;
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Text(
          playerDisplayName(widget.player),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading && _activities.isEmpty
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Row(
                    children: [
                      PlayerPhoto(player: widget.player, radius: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.coachWorkloadPlayerRecapTitle,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RecapStat(
                        label: l10n.coachWorkloadMetricLoad(loadLabel),
                        accent: toneColor(
                          averages.toneFor(
                            value: _summary.avgWorkloadScore,
                            teamAverage: averages.avgWorkloadScore,
                          ),
                          colors.primary,
                        ),
                      ),
                      _RecapStat(
                        label: l10n.coachWorkloadMetricKm(kmLabel),
                        accent: toneColor(
                          averages.toneFor(
                            value: _summary.totalDistanceKm,
                            teamAverage: averages.totalDistanceKm,
                          ),
                          colors.primary,
                        ),
                      ),
                      _RecapStat(
                        label: l10n.coachWorkloadMetricSessions(
                          _summary.trainingPresent,
                        ),
                        accent: toneColor(
                          averages.toneFor(
                            value: _summary.trainingPresent.toDouble(),
                            teamAverage: averages.trainingCount,
                          ),
                          colors.primary,
                        ),
                      ),
                      _RecapStat(
                        label: l10n.coachWorkloadMetricPersonalSports(
                          _summary.personalSportCount,
                        ),
                        accent: _summary.personalSportCount > 0
                            ? colors.success
                            : colors.textSecondary,
                      ),
                      _RecapStat(
                        label: l10n.coachWorkloadMetricMatches(
                          _summary.matchCount,
                        ),
                        accent: toneColor(
                          averages.toneFor(
                            value: _summary.matchCount.toDouble(),
                            teamAverage: averages.matchCount,
                          ),
                          colors.primary,
                        ),
                      ),
                      _RecapStat(
                        label: l10n.coachWorkloadMetricPresence(presenceLabel),
                        accent: toneColor(
                          averages.toneFor(
                            value: _summary.presencePercent,
                            teamAverage: averages.presencePercent,
                          ),
                          colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.coachWorkloadBreakdown(
                      _summary.trainingPresent,
                      _summary.matchCount,
                      _summary.personalSportCount,
                    ),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.coachWorkloadActivitiesTitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (_activities.isEmpty)
                    Text(
                      l10n.coachWorkloadEmptyActivities,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    for (final item in _activities) ...[
                      _ActivityTile(
                        item: item,
                        dateLabel: dateFmt.format(item.startAt),
                        onTap: () => unawaited(_openActivity(item)),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  const _RecapStat({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  final CoachWorkloadActivityItem item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    String title;
    Widget leading;
    switch (item.kind) {
      case CoachWorkloadActivityKind.training:
        title = l10n.entityTraining;
        leading = Icon(Icons.fitness_center_rounded, color: colors.primary);
      case CoachWorkloadActivityKind.match:
        title = l10n.entityMatch;
        leading = Icon(Icons.sports_soccer_rounded, color: colors.primary);
      case CoachWorkloadActivityKind.personalSport:
        title = (item.personalSport?.title ?? '').trim().isEmpty
            ? l10n.agendaAddEventPersonalSport
            : item.personalSport!.title!.trim();
        leading = PersonalSportSourceLogo(
          externalSource: item.personalSport?.externalSource,
          size: 26,
        );
    }

    final chips = <String>[];
    if (item.wasPresent == false) {
      chips.add(l10n.presenceAbsent);
    }
    if (item.kind == CoachWorkloadActivityKind.training ||
        item.kind == CoachWorkloadActivityKind.match) {
      // Same tracker indicators as the session stats table.
      if (item.workloadScore != null) {
        chips.add(
          '${l10n.statsWorkload} ${item.workloadScore!.toStringAsFixed(0)}',
        );
      }
      if (item.distanceKm != null) {
        chips.add(
          '${l10n.statsDistance} ${item.distanceKm!.toStringAsFixed(2)} km',
        );
      }
      if (item.maxValidatedSpeedKmh != null) {
        chips.add(
          '${l10n.statsMaxSpeed} '
          '${item.maxValidatedSpeedKmh!.toStringAsFixed(1)} km/h',
        );
      }
      if (item.highAccelerationCount != null) {
        chips.add(
          '${l10n.statsHighAccel} '
          '${item.highAccelerationCount!.toStringAsFixed(0)}',
        );
      }
      if (item.highSpeedDurationSec != null) {
        chips.add(
          '${l10n.statsHighSpeedTime} '
          '${item.highSpeedDurationSec!.toStringAsFixed(1)} sec',
        );
      }
      if (item.maxAccelerationMps2 != null) {
        chips.add(
          '${l10n.statsMaxAccel} '
          '${item.maxAccelerationMps2!.toStringAsFixed(2)} m/s²',
        );
      }
      if (item.durationMinutes != null && item.durationMinutes! > 0) {
        chips.add('${item.durationMinutes} min');
      }
    } else {
      if (item.durationMinutes != null && item.durationMinutes! > 0) {
        chips.add('${item.durationMinutes} min');
      }
      if (item.workloadScore != null) {
        chips.add(l10n.coachWorkloadMetricLoad(
          item.workloadScore!.toStringAsFixed(0),
        ));
      }
      if (item.distanceKm != null && item.distanceKm! > 0) {
        chips.add('${item.distanceKm!.toStringAsFixed(1)} km');
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final chip in chips)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                chip,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (item.kind == CoachWorkloadActivityKind.personalSport &&
                        item.personalSport != null) ...[
                      const SizedBox(height: 8),
                      PersonalSportActivitySummaryChips(
                        activity: item.personalSport!,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
