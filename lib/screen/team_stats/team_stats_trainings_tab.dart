import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/widget/team_stats_trainings_players_table.dart';
import 'package:grinta/widget/team_stats_wdl_trend_indicator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TeamStatsTrainingsTab extends StatefulWidget {
  const TeamStatsTrainingsTab({
    super.key,
    required this.team,
    required this.isManager,
    this.fallbackSeasonId,
    TeamTrainingStatsService? teamTrainingStatsService,
  }) : _teamTrainingStatsService = teamTrainingStatsService;

  final Team team;
  final bool isManager;
  final String? fallbackSeasonId;
  final TeamTrainingStatsService? _teamTrainingStatsService;

  @override
  State<TeamStatsTrainingsTab> createState() => _TeamStatsTrainingsTabState();
}

class _TeamStatsTrainingsTabState extends State<TeamStatsTrainingsTab> {
  bool _loading = true;
  bool _statsLoading = false;
  bool _didInit = false;
  String _selectedMonthValue = kTeamStatsAllMonthsValue;
  TeamTrainingStatsResult? _statsResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadStats();
    }
  }

  String? _seasonIdForTeam() {
    final teamSeasonId = widget.team.seasonID?.trim() ?? '';
    if (teamSeasonId.isNotEmpty) return teamSeasonId;
    final fallback = widget.fallbackSeasonId?.trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }

  Future<void> _loadStats() async {
    final seasonId = _seasonIdForTeam();
    if (seasonId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statsResult = null;
      });
      return;
    }

    setState(() {
      if (_statsResult == null) {
        _loading = true;
      } else {
        _statsLoading = true;
      }
    });

    final service =
        widget._teamTrainingStatsService ?? TeamTrainingStatsService();
    final result = await service.computeStatsForTeam(
      team: widget.team,
      seasonId: seasonId,
      monthValue: _selectedMonthValue,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _statsLoading = false;
      _statsResult = result;
    });
  }

  String? _currentPlayerId(BuildContext context) {
    return context.read<AppSession>().selectedPlayerId;
  }

  List<TeamTrainingPlayerStats> _playerStatsRows() {
    final result = _statsResult;
    if (result == null) {
      return const [];
    }

    final rows = result.statsByPlayerId.values.toList()
      ..sort((a, b) {
        final last = (a.player?.lastName ?? '')
            .toLowerCase()
            .compareTo((b.player?.lastName ?? '').toLowerCase());
        if (last != 0) {
          return last;
        }
        return (a.player?.firstName ?? '')
            .toLowerCase()
            .compareTo((b.player?.firstName ?? '').toLowerCase());
      });
    return rows;
  }

  String _monthLabel(AppLocalizations l10n, TeamStatsMonthOption option) {
    final date = DateTime(option.year, option.month);
    final formatted = DateFormat.yMMMM(l10n.localeName).format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _attendanceRateLabel(AppLocalizations l10n, double? rate) {
    if (rate == null) {
      return '—';
    }
    final formatted = NumberFormat.decimalPatternDigits(
      decimalDigits: 0,
    ).format(rate);
    return l10n.teamStatsTrainingsAttendanceRateValue(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthOptions = _statsResult?.monthOptions ?? const [];
    if (monthOptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.teamStatsTrainingsNoSeasonMonths,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.teamStatsTabTrainings,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonthValue,
              isExpanded: true,
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: kTeamStatsAllMonthsValue,
                  child: Text(
                    l10n.teamStatsAllMonths,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...monthOptions.map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(
                      _monthLabel(l10n, option),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedMonthValue = value);
                _loadStats();
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_statsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_statsResult != null) ...[
          _buildGlobalSummary(context, l10n),
          const SizedBox(height: 24),
          if (!widget.isManager) ...[
            Text(
              l10n.teamStatsTrainingsPersonalSection,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TeamStatsTrainingsPlayersTable(
              stats: _playerStatsRows(),
              visiblePlayerId: _currentPlayerId(context),
            ),
          ] else ...[
            Text(
              l10n.teamStatsSubTabPlayers,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TeamStatsTrainingsPlayersTable(
              stats: _playerStatsRows(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildGlobalSummary(BuildContext context, AppLocalizations l10n) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final stats = _statsResult!.globalStats;
    final trend = stats.trend;

    if (stats.trainingCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.teamStatsTrainingsNoData,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isManager) ...[
          Text(
            l10n.teamStatsTrainingsGlobalSection,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _SummaryMetricCard(
                label: l10n.entityTrainings,
                value: l10n.teamStatsTrainingsCount(stats.trainingCount),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricCard(
                label: l10n.teamStatsTrainingsAttendanceRate,
                value: _attendanceRateLabel(l10n, stats.attendanceRate),
                valueColor: _attendanceColor(colors, stats.attendanceRate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TeamStatsWdlTrendIndicator(
          trend: TeamWdlHalfTrend(
            direction: trend.direction,
            firstHalfPointsPerMatch: trend.firstHalfRate,
            secondHalfPointsPerMatch: trend.secondHalfRate,
          ),
        ),
      ],
    );
  }

  Color? _attendanceColor(AppColors colors, double? rate) {
    if (rate == null) {
      return null;
    }
    return rate >= 50 ? colors.success : colors.danger;
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: valueColor ?? colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
