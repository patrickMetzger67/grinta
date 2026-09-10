import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/admin/admin_player_session_detail_screen.dart';
import 'package:grinta/services/admin_player_sessions_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/widget/create_personal_sport_activity_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Lists GPS / Polar / personal sessions for one player (admin).
class AdminPlayerSessionsScreen extends StatefulWidget {
  const AdminPlayerSessionsScreen({
    super.key,
    required this.player,
    this.flags = AdminPlayerSensorFlags.none,
  });

  final Player player;
  final AdminPlayerSensorFlags flags;

  @override
  State<AdminPlayerSessionsScreen> createState() =>
      _AdminPlayerSessionsScreenState();
}

class _AdminPlayerSessionsScreenState extends State<AdminPlayerSessionsScreen> {
  final AdminPlayerSessionsService _service = AdminPlayerSessionsService();

  DateTimeRange? _range;
  bool _loading = true;
  String? _error;
  List<AdminPlayerSessionItem> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRangeAndLoad();
    });
  }

  void _initRangeAndLoad() {
    final session = context.read<AppSession>();
    final season = session.selectedSeason;
    final seasonId = (season?.ref?.id ?? '').trim();
    final ranges = resolveSeasonPeriodRanges(
      seasonId: seasonId.isEmpty ? 'current' : seasonId,
      season: season,
    );
    final full = ranges.fullSeason;
    setState(() {
      _range = DateTimeRange(start: full.start, end: full.end);
    });
    _load();
  }

  Future<void> _load() async {
    final range = _range;
    if (range == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.loadSessions(
        player: widget.player,
        start: range.start,
        end: range.end,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.adminPlayerSessionsLoadError;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
    await _load();
  }

  Future<void> _openItem(AdminPlayerSessionItem item) async {
    if (item.kind == AdminPlayerSessionKind.personalSport) {
      final activity = item.personalSport;
      if (activity == null) return;
      await showCreatePersonalSportActivitySheet(
        context,
        activityToEdit: activity,
        readOnly: true,
      );
      return;
    }

    await Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.adminPlayerSessionDetail,
        builder: (_) => AdminPlayerSessionDetailScreen(
          player: widget.player,
          item: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale);
    final range = _range;
    final seasonName =
        (context.watch<AppSession>().selectedSeason?.name ?? '').trim();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminPlayerSessionsTitle(
            playerDisplayName(widget.player, unknownLabel: '—'),
          ),
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.adminPlayerSessionsPickPeriodTooltip,
            onPressed: _loading ? null : _pickRange,
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Material(
              color: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.border),
              ),
              child: InkWell(
                onTap: _loading ? null : _pickRange,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seasonName.isEmpty
                                  ? l10n.adminPlayerSessionsPeriodLabel
                                  : l10n.adminPlayerSessionsSeasonPeriodLabel(
                                      seasonName,
                                    ),
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              range == null
                                  ? '—'
                                  : '${dateFmt.format(range.start)} – ${dateFmt.format(range.end)}',
                              style: textTheme.titleSmall?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l10n.adminPlayerSessionsEmpty,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _SessionTile(
                                item: item,
                                dateLabel: dateFmt.format(item.sessionDate),
                                onTap: () => _openItem(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  final AdminPlayerSessionItem item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, String kindLabel) = switch (item.kind) {
      AdminPlayerSessionKind.gps => (
          Icons.gps_fixed_rounded,
          l10n.adminPlayerSessionKindGps,
        ),
      AdminPlayerSessionKind.polar => (
          Icons.favorite_outline_rounded,
          l10n.adminPlayerSessionKindPolar,
        ),
      AdminPlayerSessionKind.personalSport => (
          Icons.watch_outlined,
          l10n.adminPlayerSessionKindPersonal,
        ),
    };

    final personalTitle = item.personalSport?.title?.trim() ?? '';
    final eventLabel = item.kind == AdminPlayerSessionKind.personalSport
        ? (personalTitle.isNotEmpty ? personalTitle : kindLabel)
        : (item.isMatch
            ? l10n.adminPlayerSessionMatch
            : l10n.adminPlayerSessionTraining);

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$kindLabel · $eventLabel',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
