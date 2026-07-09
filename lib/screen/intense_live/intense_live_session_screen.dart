import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/training.dart';
import 'package:grinta/services/intense_live_data_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/intense_live_eligibility.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/activity_rings_card.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/tracker_player_analysis_widget.dart';
import 'package:intl/intl.dart';

/// Live Intense tracker metrics for training or match (withSyncing=false owners).
class IntenseLiveSessionScreen extends StatefulWidget {
  const IntenseLiveSessionScreen({
    super.key,
    required this.eventId,
    required this.title,
    required this.isMatch,
    required this.sessionStartUtc,
    this.fieldId,
    this.training,
    this.match,
    this.pollingInterval = kIntenseLivePollingInterval,
    this.embedded = false,
  });

  final String eventId;
  final String title;
  final bool isMatch;
  final DateTime sessionStartUtc;
  final String? fieldId;
  final Training? training;
  final models.Match? match;
  final Duration pollingInterval;
  final bool embedded;

  static Future<void> openForTraining(
    BuildContext context, {
    required Training training,
    required String title,
    required DateTime scheduledStart,
  }) {
    return Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.intenseLiveSession,
        builder: (_) => IntenseLiveSessionScreen(
          eventId: training.docId?.trim() ?? training.trainingId?.trim() ?? '',
          title: title,
          isMatch: false,
          sessionStartUtc: intenseLiveTrainingStartUtc(training),
          fieldId: training.fieldId,
          training: training,
        ),
      ),
    );
  }

  static Future<void> openForMatch(
    BuildContext context, {
    required models.Match match,
    required String title,
    required DateTime sessionStartUtc,
  }) {
    return Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.intenseLiveSession,
        builder: (_) => IntenseLiveSessionScreen(
          eventId: match.id?.trim() ?? '',
          title: title,
          isMatch: true,
          sessionStartUtc: sessionStartUtc,
          fieldId: match.fieldId,
          match: match,
        ),
      ),
    );
  }

  @override
  State<IntenseLiveSessionScreen> createState() =>
      _IntenseLiveSessionScreenState();
}

class _IntenseLiveSessionScreenState extends State<IntenseLiveSessionScreen> {
  final IntenseLiveDataService _service = IntenseLiveDataService();

  List<IntenseLivePlayerTarget> _targets = const [];
  List<IntenseLivePlayerMetrics> _metrics = const [];
  String? _selectedPlayerId;
  String? _loadError;
  bool _loading = true;
  bool _refreshing = false;
  DateTime? _lastUpdatedAt;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final targets = await _loadTargets();
      if (!mounted) return;

      setState(() {
        _targets = targets;
        _selectedPlayerId =
            targets.isNotEmpty ? targets.first.playerId : null;
        _loading = false;
      });

      if (targets.isNotEmpty) {
        await _refreshMetrics(showSpinner: true);
        _startPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<IntenseLivePlayerTarget>> _loadTargets() async {
    if (widget.isMatch) {
      final match = widget.match;
      if (match == null) return const [];
      return _service.loadMatchTargets(match: match);
    }

    final training = widget.training ??
        await loadTrainingForLive(widget.eventId);
    if (training == null) return const [];
    return _service.loadTrainingTargets(training);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(widget.pollingInterval, (_) {
      unawaited(_refreshMetrics());
    });
  }

  Future<void> _refreshMetrics({bool showSpinner = false}) async {
    if (_targets.isEmpty || !mounted) return;

    if (showSpinner) {
      setState(() => _refreshing = true);
    }

    final fieldGps = await _service.loadFieldGpsCorners(widget.fieldId);
    final stopUtc = DateTime.now().toUtc();
    final results = await _service.fetchAllLiveMetrics(
      targets: _targets,
      sessionStartUtc: widget.sessionStartUtc,
      sessionStopUtc: stopUtc,
      isMatch: widget.isMatch,
      eventId: widget.eventId,
      fieldGpsCorners: fieldGps,
    );

    if (!mounted) return;
    setState(() {
      _metrics = results;
      _lastUpdatedAt = DateTime.now();
      _refreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: l10n.intenseLiveRefresh,
              onPressed: () => _refreshMetrics(showSpinner: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.danger),
          ),
        ),
      );
    }

    if (_targets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.intenseLiveNoPlayers,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lastUpdatedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.intenseLiveLastUpdate(
                DateFormat.Hm().format(_lastUpdatedAt!.toLocal()),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return _buildGrid(context);
              }
              return _buildMobile(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final crossAxisCount = (MediaQuery.sizeOf(context).width / 220)
        .floor()
        .clamp(2, 5);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _targets.length,
      itemBuilder: (context, index) {
        final target = _targets[index];
        final metrics = _metricsForPlayer(target.playerId);
        return _IntenseLivePlayerTile(
          target: target,
          metrics: metrics,
          ringGoals: _ringGoalsForAll(_metrics),
          onTap: () => _openPlayerAnalysis(context, target, metrics),
        );
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final selectedId = _selectedPlayerId;
    final selectedTarget = _targets.cast<IntenseLivePlayerTarget?>().firstWhere(
          (t) => t!.playerId == selectedId,
          orElse: () => _targets.first,
        );
    final selectedMetrics =
        selectedTarget == null ? null : _metricsForPlayer(selectedTarget.playerId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedTarget?.playerId,
          decoration: InputDecoration(
            labelText: l10n.intenseLiveSelectPlayer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          items: [
            for (final target in _targets)
              DropdownMenuItem<String>(
                value: target.playerId,
                child: Row(
                  children: [
                    PlayerPhoto(player: target.player, radius: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formatPlayerShortName(target.player),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedPlayerId = value);
          },
        ),
        const SizedBox(height: 20),
        if (selectedTarget != null)
          SizedBox(
            height: 320,
            child: _IntenseLivePlayerTile(
              target: selectedTarget,
              metrics: selectedMetrics,
              ringGoals: _ringGoalsForAll(_metrics),
              expanded: true,
              onTap: () =>
                  _openPlayerAnalysis(context, selectedTarget, selectedMetrics),
            ),
          ),
      ],
    );
  }

  IntenseLivePlayerMetrics? _metricsForPlayer(String playerId) {
    for (final metric in _metrics) {
      if (metric.target.playerId == playerId) return metric;
    }
    return null;
  }

  String? get _teamId {
    if (widget.isMatch) {
      return widget.match?.teamID?.trim();
    }
    return widget.training?.teamId?.trim();
  }

  void _openPlayerAnalysis(
    BuildContext context,
    IntenseLivePlayerTarget target,
    IntenseLivePlayerMetrics? metrics,
  ) {
    final colors = context.appColors;
    final analysis = metrics?.analysis;

    if (metrics?.hasError == true || analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            metrics?.errorMessage ?? context.l10n.errorNoTrackerAnalysis,
          ),
        ),
      );
      return;
    }

    AnalyticsInteractions.logFeature(
      AnalyticsFeatures.openPlayerAnalysis,
      parameters: <String, Object>{
        'source': 'intense_live',
        'is_match': widget.isMatch,
      },
    );

    Navigator.of(context, rootNavigator: true).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.playerAnalysis,
        fullscreenDialog: true,
        builder: (_) {
          return Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        bottom: BorderSide(color: colors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.entityDetails,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.actionClose,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isLarge = constraints.maxWidth >= 900;

                        return ListView(
                          padding: EdgeInsets.all(isLarge ? 10 : 12),
                          children: [
                            TrackerPlayerAnalysisWidget(
                              analysis: analysis,
                              teamId: _teamId,
                              playerName: playerDisplayName(
                                target.player,
                                unknownLabel: context.l10n.entityPlayer,
                              ),
                              player: target.player,
                              isMatch: widget.isMatch,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingGoals {
  const _RingGoals({
    required this.distanceKm,
    required this.highSpeedDurationSec,
    required this.sprintCount,
    required this.maxAccelerationMps2,
  });

  final double distanceKm;
  final double highSpeedDurationSec;
  final double sprintCount;
  final double maxAccelerationMps2;
}

_RingGoals _ringGoalsForAll(List<IntenseLivePlayerMetrics> metrics) {
  double distance = 5;
  double highSpeed = 300;
  double sprints = 10;
  double accel = 4;

  for (final metric in metrics) {
    if (metric.hasError) continue;
    distance = distance < metric.distanceKm ? metric.distanceKm : distance;
    highSpeed = highSpeed < metric.highSpeedDurationSec
        ? metric.highSpeedDurationSec
        : highSpeed;
    sprints = sprints < metric.sprintCount ? metric.sprintCount : sprints;
    accel = accel < metric.maxAccelerationMps2
        ? metric.maxAccelerationMps2
        : accel;
  }

  return _RingGoals(
    distanceKm: (distance * 1.15).clamp(5, double.infinity),
    highSpeedDurationSec: (highSpeed * 1.15).clamp(60, double.infinity),
    sprintCount: (sprints * 1.15).clamp(5, double.infinity),
    maxAccelerationMps2: (accel * 1.15).clamp(3, double.infinity),
  );
}

class _IntenseLivePlayerTile extends StatelessWidget {
  const _IntenseLivePlayerTile({
    required this.target,
    required this.metrics,
    required this.ringGoals,
    required this.onTap,
    this.expanded = false,
  });

  final IntenseLivePlayerTarget target;
  final IntenseLivePlayerMetrics? metrics;
  final _RingGoals ringGoals;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final metric = metrics;
    final hasError = metric?.hasError == true;

    final workload = metric?.workloadScore ?? 0;
    final distance = metric?.distanceKm ?? 0;
    final highSpeed = metric?.highSpeedDurationSec ?? 0;
    final sprints = metric?.sprintCount ?? 0;
    final maxAccel = metric?.maxAccelerationMps2 ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerPhoto(
                player: target.player,
                radius: expanded ? 28 : 22,
              ),
              const SizedBox(height: 8),
              Text(
                formatPlayerShortName(target.player),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (hasError) ...[
                const SizedBox(height: 8),
                Text(
                  metric!.errorMessage!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.danger,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: ActivityRingsCard.detailed(
                  showWorkload: true,
                  workloadScore: workload,
                  workloadLabel: l10n.statsWorkload,
                  workloadUnit: l10n.statsScore,
                  workloadColor: Colors.orange,
                  showLegend: expanded,
                  embedded: true,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(4),
                  withgoal: false,
                  rings: [
                    ActivityRingItem(
                      label: l10n.statsDistance,
                      value: distance,
                      goal: ringGoals.distanceKm,
                      unit: l10n.statsUnitKm,
                      color: colors.success,
                      trackColor: Colors.greenAccent.withValues(alpha: 0.18),
                      icon: Icons.directions_run,
                    ),
                    ActivityRingItem(
                      label: l10n.statsHighSpeedTimeShort,
                      value: highSpeed,
                      goal: ringGoals.highSpeedDurationSec,
                      unit: l10n.statsUnitSeconds,
                      color: colors.warning,
                      trackColor: Colors.amber.withValues(alpha: 0.18),
                      icon: Icons.speed,
                    ),
                    ActivityRingItem(
                      label: l10n.statsSprints,
                      value: sprints,
                      goal: ringGoals.sprintCount,
                      unit: l10n.statsUnitCount,
                      color: colors.danger,
                      trackColor: Colors.redAccent.withValues(alpha: 0.18),
                      icon: Icons.bolt,
                    ),
                    ActivityRingItem(
                      label: l10n.statsMaxAccel,
                      value: maxAccel,
                      goal: ringGoals.maxAccelerationMps2,
                      unit: l10n.statsUnitMps2,
                      color: colors.primary,
                      trackColor: colors.primary.withValues(alpha: 0.18),
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Embedded live panel for match detail tab (no scaffold).
class IntenseLiveSessionPanel extends StatelessWidget {
  const IntenseLiveSessionPanel({
    super.key,
    required this.match,
    required this.sessionStartUtc,
  });

  final models.Match match;
  final DateTime sessionStartUtc;

  @override
  Widget build(BuildContext context) {
    final team1 = match.team1?.trim();
    final team2 = match.team2?.trim();
    final title = (team1 != null &&
            team1.isNotEmpty &&
            team2 != null &&
            team2.isNotEmpty)
        ? '$team1 vs $team2'
        : context.l10n.intenseLiveTitle;

    return IntenseLiveSessionScreen(
      eventId: match.id?.trim() ?? '',
      title: title,
      isMatch: true,
      sessionStartUtc: sessionStartUtc,
      fieldId: match.fieldId,
      match: match,
      embedded: true,
    );
  }
}
