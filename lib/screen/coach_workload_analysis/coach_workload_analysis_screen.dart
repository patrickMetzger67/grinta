import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_player_workload_detail_screen.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/coach_workload_analysis_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/coach_workload_report_email_dialog.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CoachWorkloadAnalysisScreen extends StatefulWidget {
  const CoachWorkloadAnalysisScreen({super.key});

  @override
  State<CoachWorkloadAnalysisScreen> createState() =>
      _CoachWorkloadAnalysisScreenState();
}

class _CoachWorkloadAnalysisScreenState
    extends State<CoachWorkloadAnalysisScreen> {
  final _playersService = TeamPlayersService();
  final _analysisService = CoachWorkloadAnalysisService();

  CoachWorkloadPeriod _period = CoachWorkloadPeriod.month;
  DateTimeRange? _customRange;
  String? _teamId;
  List<CoachPlayerWorkloadSummary> _summaries = const [];
  CoachTeamWorkloadAverages _teamAverages = const CoachTeamWorkloadAverages();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final teams = context.read<AppSession>().managerTeamsForSelectedSeason;
      if (teams.isEmpty) {
        setState(() {
          _loading = false;
          _error = context.l10n.coachWorkloadNoManagedTeam;
        });
        return;
      }
      _teamId = teams.first.keyTeam?.trim();
      unawaited(_reload());
    });
  }

  DateTimeRange _resolvedRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case CoachWorkloadPeriod.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case CoachWorkloadPeriod.month:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case CoachWorkloadPeriod.custom:
        return _customRange ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 29)),
              end: today,
            );
    }
  }

  Future<void> _reload() async {
    final teamId = (_teamId ?? '').trim();
    final session = context.read<AppSession>();
    final seasonId = (session.selectedSeason?.ref?.id ?? '').trim();
    if (teamId.isEmpty || seasonId.isEmpty) {
      setState(() {
        _loading = false;
        _error = context.l10n.coachWorkloadNoManagedTeam;
        _summaries = const [];
        _teamAverages = const CoachTeamWorkloadAverages();
      });
      return;
    }

    final teams = session.managerTeamsForSelectedSeason;
    Team? team;
    for (final t in teams) {
      if ((t.keyTeam?.trim() ?? '') == teamId) {
        team = t;
        break;
      }
    }
    if (team == null) {
      setState(() {
        _loading = false;
        _error = context.l10n.coachWorkloadNoManagedTeam;
        _summaries = const [];
        _teamAverages = const CoachTeamWorkloadAverages();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final players = await _playersService.loadPlayers(teamId: teamId);
      final range = _resolvedRange();
      // End exclusive for personal sports / queries: next day 00:00
      final endExclusive = range.end.add(const Duration(days: 1));
      final report = await _analysisService.loadTeamSummaries(
        team: team,
        seasonId: seasonId,
        start: range.start,
        end: endExclusive,
        players: players,
      );
      if (!mounted) return;
      setState(() {
        _summaries = report.summaries;
        _teamAverages = report.teamAverages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.coachWorkloadLoadError;
        _summaries = const [];
        _teamAverages = const CoachTeamWorkloadAverages();
      });
    }
  }

  Future<void> _sendPdfReport() async {
    if (_summaries.isEmpty) return;
    final session = context.read<AppSession>();
    final teams = session.managerTeamsForSelectedSeason;
    final teamId = (_teamId ?? '').trim();
    Team? team;
    for (final t in teams) {
      if ((t.keyTeam?.trim() ?? '') == teamId) {
        team = t;
        break;
      }
    }
    if (team == null) return;

    final range = _resolvedRange();
    await showCoachWorkloadReportEmailDialog(
      context: context,
      report: CoachTeamWorkloadReport(
        summaries: _summaries,
        teamAverages: _teamAverages,
      ),
      teamName: (team.name ?? team.keyTeam ?? '').trim(),
      teamId: teamId,
      rangeStart: range.start,
      rangeEndInclusive: range.end,
      clubId: team.clubId,
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = CoachWorkloadPeriod.custom;
      _customRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final session = context.watch<AppSession>();
    final teams = session.managerTeamsForSelectedSeason;
    final range = _resolvedRange();
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMd(locale);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.coachWorkloadAnalysisTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SubscriptionPremiumBadge(colors: colors, compact: true),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.coachWorkloadReportEmailActionTooltip,
            onPressed: _loading || _summaries.isEmpty
                ? null
                : () => unawaited(_sendPdfReport()),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (teams.length > 1) ...[
                  DropdownButtonFormField<String>(
                    value: _teamId,
                    decoration: InputDecoration(
                      labelText: l10n.entityTeam,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      for (final team in teams)
                        if ((team.keyTeam ?? '').trim().isNotEmpty)
                          DropdownMenuItem(
                            value: team.keyTeam!.trim(),
                            child: Text(
                              (team.name ?? team.keyTeam!).trim(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _teamId = value);
                      unawaited(_reload());
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PeriodChip(
                      label: l10n.periodWeek,
                      selected: _period == CoachWorkloadPeriod.week,
                      onTap: () {
                        setState(() => _period = CoachWorkloadPeriod.week);
                        unawaited(_reload());
                      },
                    ),
                    _PeriodChip(
                      label: l10n.periodMonth,
                      selected: _period == CoachWorkloadPeriod.month,
                      onTap: () {
                        setState(() => _period = CoachWorkloadPeriod.month);
                        unawaited(_reload());
                      },
                    ),
                    _PeriodChip(
                      label: _period == CoachWorkloadPeriod.custom
                          ? l10n.periodCustomRange(
                              dateFmt.format(range.start),
                              dateFmt.format(range.end),
                            )
                          : l10n.periodCustom,
                      selected: _period == CoachWorkloadPeriod.custom,
                      onTap: () => unawaited(_pickCustomRange()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.coachWorkloadCompareHint,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : _summaries.isEmpty
                        ? Center(
                            child: Text(
                              l10n.coachWorkloadEmptyPlayers,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _reload,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _summaries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final summary = _summaries[index];
                                return _PlayerSummaryTile(
                                  summary: summary,
                                  teamAverages: _teamAverages,
                                  onTap: () {
                                    final teamId = (_teamId ?? '').trim();
                                    Team? team;
                                    for (final t in teams) {
                                      if ((t.keyTeam?.trim() ?? '') == teamId) {
                                        team = t;
                                        break;
                                      }
                                    }
                                    if (team == null) return;
                                    Navigator.of(context).push<void>(
                                      analyticsMaterialRoute<void>(
                                        screenName: AnalyticsScreenNames
                                            .coachPlayerWorkloadDetail,
                                        builder: (_) =>
                                            CoachPlayerWorkloadDetailScreen(
                                          team: team!,
                                          seasonId: session
                                                  .selectedSeason?.ref?.id ??
                                              '',
                                          range: DateTimeRange(
                                            start: range.start,
                                            end: range.end
                                                .add(const Duration(days: 1)),
                                          ),
                                          player: summary.player,
                                          initialSummary: summary,
                                          teamAverages: _teamAverages,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PlayerSummaryTile extends StatelessWidget {
  const _PlayerSummaryTile({
    required this.summary,
    required this.teamAverages,
    required this.onTap,
  });

  final CoachPlayerWorkloadSummary summary;
  final CoachTeamWorkloadAverages teamAverages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final presence = summary.presencePercent;
    final presenceLabel =
        presence == null ? '—' : '${presence.toStringAsFixed(0)} %';
    final loadLabel = summary.avgWorkloadScore == null
        ? '—'
        : summary.avgWorkloadScore!.toStringAsFixed(0);
    final kmLabel = summary.totalDistanceKm == null
        ? '—'
        : summary.totalDistanceKm!.toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PlayerPhoto(
                    player: summary.player,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playerDisplayName(summary.player),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MetricChip(
                    label: l10n.coachWorkloadMetricLoad(loadLabel),
                    emphasized: true,
                    tone: teamAverages.toneFor(
                      value: summary.avgWorkloadScore,
                      teamAverage: teamAverages.avgWorkloadScore,
                    ),
                  ),
                  _MetricChip(
                    label: l10n.coachWorkloadMetricKm(kmLabel),
                    emphasized: true,
                    tone: teamAverages.toneFor(
                      value: summary.totalDistanceKm,
                      teamAverage: teamAverages.totalDistanceKm,
                    ),
                  ),
                  _MetricChip(
                    label: l10n.coachWorkloadMetricPersonalSports(
                      summary.personalSportCount,
                    ),
                    tone: summary.personalSportCount > 0
                        ? CoachMetricTone.success
                        : CoachMetricTone.neutral,
                  ),
                  _MetricChip(
                    label: l10n.coachWorkloadMetricSessions(
                      summary.sessionCount,
                    ),
                    tone: teamAverages.toneFor(
                      value: summary.sessionCount.toDouble(),
                      teamAverage: teamAverages.sessionCount,
                    ),
                  ),
                  _MetricChip(
                    label: l10n.coachWorkloadMetricPresence(presenceLabel),
                    tone: teamAverages.toneFor(
                      value: summary.presencePercent,
                      teamAverage: teamAverages.presencePercent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    this.tone = CoachMetricTone.neutral,
    this.emphasized = false,
  });

  final String label;
  final CoachMetricTone tone;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final Color accent;
    switch (tone) {
      case CoachMetricTone.success:
        accent = colors.success;
      case CoachMetricTone.warning:
        accent = colors.warning;
      case CoachMetricTone.neutral:
        accent = colors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? 10 : 8,
        vertical: emphasized ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: tone == CoachMetricTone.neutral ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: emphasized ? 12 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
