import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/player_positions_service.dart';
import 'package:grinta/services/player_season_summary_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';
import 'package:grinta/util/player_age.dart';
import 'package:grinta/util/preferred_foot.dart';
import 'package:grinta/widget/manage_unavailabilities_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _PlayerSeasonSummaryTab { matches, trainings, unavailabilities }

/// Identity + anthropometrics passed from the team roster into the summary.
class PlayerSeasonSummaryIdentity {
  const PlayerSeasonSummaryIdentity({
    required this.player,
    this.positionCodes = const <int>[],
    this.positionLabels = const <String>[],
    this.birthday,
    this.heightCm,
    this.weightKg,
    this.hwMeasuredAt,
    this.preferredFoot,
  });

  final Player player;
  final List<int> positionCodes;
  final List<String> positionLabels;
  final DateTime? birthday;
  final int? heightCm;
  final double? weightKg;
  final DateTime? hwMeasuredAt;
  final String? preferredFoot;
}

Future<void> openPlayerSeasonSummaryScreen(
  BuildContext context, {
  required Team team,
  required PlayerSeasonSummaryIdentity identity,
  required String initialSeasonId,
}) {
  return Navigator.of(context).push<void>(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.playerSeasonSummary,
      builder: (_) => PlayerSeasonSummaryScreen(
        team: team,
        identity: identity,
        initialSeasonId: initialSeasonId,
      ),
    ),
  );
}

class PlayerSeasonSummaryScreen extends StatefulWidget {
  const PlayerSeasonSummaryScreen({
    super.key,
    required this.team,
    required this.identity,
    required this.initialSeasonId,
    PlayerSeasonSummaryService? summaryService,
  }) : _summaryService = summaryService;

  final Team team;
  final PlayerSeasonSummaryIdentity identity;
  final String initialSeasonId;
  final PlayerSeasonSummaryService? _summaryService;

  @override
  State<PlayerSeasonSummaryScreen> createState() =>
      _PlayerSeasonSummaryScreenState();
}

class _PlayerSeasonSummaryScreenState extends State<PlayerSeasonSummaryScreen> {
  late String _selectedSeasonId;
  _PlayerSeasonSummaryTab _selectedTab = _PlayerSeasonSummaryTab.matches;
  bool _loading = true;
  bool _didInit = false;
  PlayerSeasonSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedSeasonId = widget.initialSeasonId.trim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    final seasonId = _selectedSeasonId.trim();
    if (seasonId.isEmpty) {
      setState(() {
        _loading = false;
        _summary = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service =
          widget._summaryService ?? PlayerSeasonSummaryService();
      final summary = await service.loadSummary(
        team: widget.team,
        player: widget.identity.player,
        seasonId: seasonId,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _summary = null;
        _error = e.toString();
      });
    }
  }

  List<Season> _seasonOptions(AppSession session) {
    final seasons = session.getSeasonsForPlayer(
      session.selectedPlayerId ?? '',
    );
    final list = seasons.values.toList();
    final selected = session.selectedSeason;
    final selectedId = selected?.ref?.id?.trim() ?? '';
    if (selected != null &&
        selectedId.isNotEmpty &&
        !seasons.containsKey(selectedId)) {
      list.add(selected);
    }
    list.sort((a, b) {
      final aStart = a.startDate;
      final bStart = b.startDate;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return bStart.compareTo(aStart);
    });
    return list;
  }

  String _seasonLabel(BuildContext context, Season season) {
    final name = season.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final id = season.ref?.id;
    return id == null || id.isEmpty ? context.l10n.entitySeason : id;
  }

  int? _ageYears() {
    final birthday = widget.identity.birthday;
    if (birthday != null) {
      final now = DateTime.now();
      var age = now.year - birthday.year;
      if (now.month < birthday.month ||
          (now.month == birthday.month && now.day < birthday.day)) {
        age--;
      }
      return age;
    }
    return playerAgeYears(widget.identity.player);
  }

  List<String> _positionChipLabels(AppLocalizations l10n) {
    if (widget.identity.positionLabels.isNotEmpty) {
      return widget.identity.positionLabels;
    }
    if (widget.identity.positionCodes.isEmpty) {
      return const <String>[];
    }
    final service = PlayerPositionsService.instance;
    return widget.identity.positionCodes
        .map((code) => service.labelForCode(code, l10n))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final playerName = playerDisplayName(
      widget.identity.player,
      unknownLabel: l10n.entityPlayerUnknown,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.playerSeasonSummaryTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeader(context, playerName),
            const SizedBox(height: 16),
            _buildSeasonSelector(context),
            const SizedBox(height: 16),
            _buildTabSelector(context),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.errorGeneric(_error!),
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              )
            else
              _buildSelectedTabContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String playerName) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final age = _ageYears();
    final heightCm = widget.identity.heightCm;
    final weightKg = widget.identity.weightKg;
    final measuredAt = widget.identity.hwMeasuredAt;
    final positions = _positionChipLabels(l10n);

    final anthropometrics = <String>[
      if (age != null) l10n.playerSeasonSummaryAgeValue(age),
      if (heightCm != null && heightCm > 0) l10n.teamDetailHeightCm(heightCm),
      if (weightKg != null && weightKg > 0)
        l10n.teamDetailWeightKg(weightKg.round()),
    ].join(' · ');

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PlayerPhoto(player: widget.identity.player, radius: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  playerName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (anthropometrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              anthropometrics,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (measuredAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.playerSeasonSummaryHwMeasuredAt(
                DateFormat.yMMMd(l10n.localeName).format(measuredAt),
              ),
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (positions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in positions) _PositionChip(label: label),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '${l10n.preferredFootLabel}: '
            '${preferredFootLabel(l10n, widget.identity.preferredFoot)}',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<AppSession>();
    final seasons = _seasonOptions(session);
    final seasonIds = seasons
        .map((season) => season.ref?.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    String? value = _selectedSeasonId;
    if (value.isEmpty || !seasonIds.contains(value)) {
      value = seasonIds.contains(widget.initialSeasonId.trim())
          ? widget.initialSeasonId.trim()
          : (seasons.isNotEmpty ? seasons.first.ref?.id : null);
    }

    final items = <DropdownMenuItem<String>>[
      for (final season in seasons)
        if ((season.ref?.id ?? '').isNotEmpty)
          DropdownMenuItem<String>(
            value: season.ref!.id,
            child: Text(
              _seasonLabel(context, season),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    ];
    if (_selectedSeasonId.isNotEmpty &&
        !items.any((item) => item.value == _selectedSeasonId)) {
      items.insert(
        0,
        DropdownMenuItem<String>(
          value: _selectedSeasonId,
          child: Text(_selectedSeasonId),
        ),
      );
      seasonIds.add(_selectedSeasonId);
      value = _selectedSeasonId;
    }

    return DropdownButtonFormField<String>(
      value: value != null && seasonIds.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.entitySeason,
        hintText: l10n.hintSelectSeason,
        filled: true,
        fillColor: context.appColors.surface,
      ),
      items: items,
      onChanged: (next) {
        if (next == null || next == _selectedSeasonId) return;
        setState(() {
          _selectedSeasonId = next;
          _summary = null;
        });
        _loadSummary();
      },
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TabButton(
          label: l10n.entityMatches,
          selected: _selectedTab == _PlayerSeasonSummaryTab.matches,
          onTap: () => setState(
            () => _selectedTab = _PlayerSeasonSummaryTab.matches,
          ),
        ),
        _TabButton(
          label: l10n.entityTrainings,
          selected: _selectedTab == _PlayerSeasonSummaryTab.trainings,
          onTap: () => setState(
            () => _selectedTab = _PlayerSeasonSummaryTab.trainings,
          ),
        ),
        _TabButton(
          label: l10n.playerSeasonSummaryTabUnavailabilities,
          selected: _selectedTab == _PlayerSeasonSummaryTab.unavailabilities,
          onTap: () => setState(
            () => _selectedTab = _PlayerSeasonSummaryTab.unavailabilities,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTabContent(BuildContext context) {
    final summary = _summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    switch (_selectedTab) {
      case _PlayerSeasonSummaryTab.matches:
        return _MatchesTab(summary: summary);
      case _PlayerSeasonSummaryTab.trainings:
        return _TrainingsTab(summary: summary);
      case _PlayerSeasonSummaryTab.unavailabilities:
        return _UnavailabilitiesTab(entries: summary.unavailabilities);
    }
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.summary});

  final PlayerSeasonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryMetricCard(
              label: l10n.playerSeasonSummaryTeamMatches,
              value: '${summary.teamMatchCount}',
            ),
            _SummaryMetricCard(
              label: l10n.teamStatsPlayersColumnConvocations,
              value: '${summary.convocations}',
            ),
            _SummaryMetricCard(
              label: l10n.teamStatsPlayersColumnStarts,
              value: '${summary.starts}',
            ),
            _SummaryMetricCard(
              label: l10n.teamStatsPlayersColumnPlayTime,
              value: l10n.teamStatsPlayersPlayTimeMinutes(summary.minutesPlayed),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.playerSeasonSummaryTrackerAverages,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        _TrackerAveragesGrid(averages: summary.matchTrackerAverages),
      ],
    );
  }
}

class _TrainingsTab extends StatelessWidget {
  const _TrainingsTab({required this.summary});

  final PlayerSeasonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final rate = summary.attendanceRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryMetricCard(
              label: l10n.playerSeasonSummaryTeamTrainings,
              value: '${summary.teamTrainingCount}',
            ),
            _SummaryMetricCard(
              label: l10n.teamStatsTrainingsColumnPresent,
              value: '${summary.presentCount}',
            ),
            _SummaryMetricCard(
              label: l10n.teamStatsTrainingsAttendanceRate,
              value: rate == null
                  ? '-'
                  : l10n.teamStatsTrainingsAttendanceRateValue(
                      rate.toStringAsFixed(0),
                    ),
              valueColor: rate == null
                  ? null
                  : (rate >= 50 ? colors.success : colors.danger),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.playerSeasonSummaryTrackerAverages,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        _TrackerAveragesGrid(averages: summary.trainingTrackerAverages),
      ],
    );
  }
}

class _UnavailabilitiesTab extends StatelessWidget {
  const _UnavailabilitiesTab({required this.entries});

  final List<Unavailability> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.manageUnavailabilitiesEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final sorted = List<Unavailability>.from(entries)
      ..sort((a, b) {
        final aMs = a.from?.millisecondsSinceEpoch ?? 0;
        final bMs = b.from?.millisecondsSinceEpoch ?? 0;
        return bMs.compareTo(aMs);
      });

    return Column(
      children: [
        for (final entry in sorted) ...[
          _UnavailabilityTile(entry: entry),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _UnavailabilityTile extends StatelessWidget {
  const _UnavailabilityTile({required this.entry});

  final Unavailability entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final type = entry.unavailabilityType;
    final typeLabel =
        type == null ? '-' : unavailabilityTypeLabel(l10n, type);
    final dateRange = _formatDateRange(context, entry);
    final details = entry.details?.trim() ?? '';
    final hidden = entry.isVisible == false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            typeLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(details, style: theme.textTheme.bodyMedium),
          ],
          if (hidden) ...[
            const SizedBox(height: 6),
            Text(
              l10n.manageUnavailabilitiesHidden,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(BuildContext context, Unavailability entry) {
    final locale = context.l10n.localeName;
    final formatter = DateFormat.yMMMd(locale);
    final from = entry.from?.toDate();
    final to = entry.to?.toDate();
    if (from == null && to == null) {
      return '-';
    }
    final fromLabel = from == null ? '-' : formatter.format(from);
    final toLabel = to == null ? '-' : formatter.format(to);
    return context.l10n.manageUnavailabilitiesDateRange(fromLabel, toLabel);
  }
}

class _TrackerAveragesGrid extends StatelessWidget {
  const _TrackerAveragesGrid({required this.averages});

  final PlayerTrackerMetricAverages averages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (averages.sessionsWithData <= 0 || averages.averages.isEmpty) {
      return Text(
        l10n.playerSeasonSummaryNoTrackerData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
      );
    }

    final metrics = <_TrackerMetricDisplay>[
      for (final key in kPlayerActivityTrackerMetricKeys)
        if (averages.averages[key] != null)
          _TrackerMetricDisplay(
            label: _metricLabel(l10n, key),
            value: _metricValue(l10n, key, averages.averages[key]!),
          ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final metric in metrics)
          _SummaryMetricCard(
            label: metric.label,
            value: metric.value,
          ),
      ],
    );
  }

  String _metricLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case TeamWorkloadMetricKeys.distanceKm:
        return l10n.statsDistance;
      case TeamWorkloadMetricKeys.maxValidatedSpeedKmh:
        return l10n.statsMaxSpeed;
      case TeamWorkloadMetricKeys.sprintCount:
        return l10n.statsSprints;
      case TeamWorkloadMetricKeys.highAccelerationCount:
        return l10n.statsHighAccel;
      case TeamWorkloadMetricKeys.highSpeedDuration:
        return l10n.statsHighSpeedTime;
      case TeamWorkloadMetricKeys.maxAccelerationMps2:
        return l10n.statsMaxAccel;
      case TeamWorkloadMetricKeys.workloadScore:
        return l10n.statsWorkload;
      default:
        return key;
    }
  }

  String _metricValue(AppLocalizations l10n, String key, double value) {
    switch (key) {
      case TeamWorkloadMetricKeys.distanceKm:
        return '${value.toStringAsFixed(2)} ${l10n.statsUnitKm}';
      case TeamWorkloadMetricKeys.maxValidatedSpeedKmh:
        return '${value.toStringAsFixed(1)} ${l10n.statsUnitKmh}';
      case TeamWorkloadMetricKeys.sprintCount:
      case TeamWorkloadMetricKeys.highAccelerationCount:
        return value.toStringAsFixed(0);
      case TeamWorkloadMetricKeys.highSpeedDuration:
        return _formatSeconds(value);
      case TeamWorkloadMetricKeys.maxAccelerationMps2:
        return '${value.toStringAsFixed(2)} ${l10n.statsUnitMps2}';
      case TeamWorkloadMetricKeys.workloadScore:
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _formatSeconds(double seconds) {
    if (!seconds.isFinite || seconds < 0) {
      return '-';
    }
    final total = seconds.round();
    final minutes = total ~/ 60;
    final secs = total % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

class _TrackerMetricDisplay {
  const _TrackerMetricDisplay({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
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

    return SizedBox(
      width: 160,
      child: Container(
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
      ),
    );
  }
}

class _PositionChip extends StatelessWidget {
  const _PositionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
    return Material(
      color: selected ? colors.primary : colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
