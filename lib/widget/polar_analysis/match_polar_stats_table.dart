import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/polar_analysis/polar_player_analysis_widget.dart';

/// Team cardio stats table for Polar kits (replaces [MatchTrackerStatsTable]).
class MatchPolarStatsTable extends StatefulWidget {
  const MatchPolarStatsTable({
    super.key,
    required this.eventId,
    this.teamId,
    this.realtime = true,
    this.isMatch = true,
    this.padding = EdgeInsets.zero,
  });

  final String eventId;
  final String? teamId;
  final bool realtime;
  final bool isMatch;
  final EdgeInsetsGeometry padding;

  @override
  State<MatchPolarStatsTable> createState() => _MatchPolarStatsTableState();
}

class _MatchPolarStatsTableState extends State<MatchPolarStatsTable> {
  final _analysisService = PolarSessionAnalysisService();
  final _playerService = PlayerService();
  final Map<String, Future<Player?>> _playerFutures = {};

  int _sortColumnIndex = 2;
  bool _sortAscending = false;

  Future<Player?> _playerFuture(String playerId) {
    return _playerFutures.putIfAbsent(
      playerId,
      () => _playerService.getPlayerById(playerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.eventId.trim();
    if (eventId.isEmpty) {
      return _empty(
        context.l10n.errorMatchNotIdentified,
        context.l10n.errorNoTrackerStats,
      );
    }

    if (widget.realtime) {
      return StreamBuilder<List<PolarSessionAnalysis>>(
        stream: _analysisService.watchByEventId(eventId),
        builder: (context, snapshot) => _buildBody(context, snapshot),
      );
    }

    return FutureBuilder<List<PolarSessionAnalysis>>(
      future: _analysisService.listByEventId(eventId),
      builder: (context, snapshot) => _buildBody(context, snapshot),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<PolarSessionAnalysis>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return _empty(
        context.l10n.errorTrackerTitle,
        snapshot.error.toString(),
      );
    }

    final analyses = List<PolarSessionAnalysis>.from(snapshot.data ?? const []);
    if (analyses.isEmpty) {
      return _empty(
        context.l10n.emptyNoAnalysis,
        context.l10n.polarAnalysisEmptyTeamMessage,
      );
    }

    analyses.sort((a, b) {
      final cmp = _compare(a, b, _sortColumnIndex);
      return _sortAscending ? cmp : -cmp;
    });

    final colors = context.appColors;
    final l10n = context.l10n;

    return Padding(
      padding: widget.padding,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.polarAnalysisTeamTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    l10n.polarAnalysisTeamCount(analyses.length),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(
                    label: Text(l10n.entityPlayer),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: Text(l10n.polarAnalysisColDevice),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(l10n.polarAnalysisAvgHr),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(l10n.polarAnalysisMaxHr),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(l10n.polarAnalysisDuration),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(l10n.polarAnalysisColHighIntensity),
                    onSort: _onSort,
                  ),
                ],
                rows: [
                  for (final analysis in analyses)
                    DataRow(
                      onSelectChanged: (_) => _openPlayer(context, analysis),
                      cells: [
                        DataCell(_playerCell(analysis)),
                        DataCell(
                          Text(
                            analysis.polarDeviceId.isEmpty
                                ? '—'
                                : analysis.polarDeviceId,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataCell(Text(analysis.avgHrBpm?.toString() ?? '—')),
                        DataCell(Text(analysis.maxHrBpm?.toString() ?? '—')),
                        DataCell(
                          Text('${analysis.duration.inMinutes}'),
                        ),
                        DataCell(
                          Text(
                            _formatMinutes(
                              (analysis.hrZoneSeconds['z4'] ?? 0) +
                                  (analysis.hrZoneSeconds['z5'] ?? 0),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  int _compare(PolarSessionAnalysis a, PolarSessionAnalysis b, int column) {
    switch (column) {
      case 0:
        return a.playerId.compareTo(b.playerId);
      case 1:
        return a.polarDeviceId.compareTo(b.polarDeviceId);
      case 2:
        return (a.avgHrBpm ?? -1).compareTo(b.avgHrBpm ?? -1);
      case 3:
        return (a.maxHrBpm ?? -1).compareTo(b.maxHrBpm ?? -1);
      case 4:
        return a.duration.compareTo(b.duration);
      case 5:
        final aHigh = (a.hrZoneSeconds['z4'] ?? 0) +
            (a.hrZoneSeconds['z5'] ?? 0);
        final bHigh = (b.hrZoneSeconds['z4'] ?? 0) +
            (b.hrZoneSeconds['z5'] ?? 0);
        return aHigh.compareTo(bHigh);
      default:
        return 0;
    }
  }

  Widget _playerCell(PolarSessionAnalysis analysis) {
    final playerId = analysis.playerId.trim();
    if (playerId.isEmpty) {
      return Text(analysis.trackerId);
    }

    return FutureBuilder<Player?>(
      future: _playerFuture(playerId),
      builder: (context, snapshot) {
        final player = snapshot.data;
        final name = _formatName(player);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player != null) ...[
              PlayerPhoto(player: player, radius: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                name.isEmpty ? playerId : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPlayer(BuildContext context, PolarSessionAnalysis analysis) {
    final colors = context.appColors;
    final playerId = analysis.playerId.trim();

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
                    child: FutureBuilder<Player?>(
                      future: playerId.isEmpty
                          ? Future<Player?>.value(null)
                          : _playerFuture(playerId),
                      builder: (context, snap) {
                        final player = snap.data;
                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            PolarPlayerAnalysisWidget(
                              analysis: analysis,
                              player: player,
                              playerName: _formatName(player),
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

  String _formatName(Player? player) {
    if (player == null) return '';
    final first = (player.firstName ?? '').trim();
    final last = (player.lastName ?? '').trim();
    final letter = first.isNotEmpty ? '${first[0].toUpperCase()}. ' : '';
    if (last.isNotEmpty) return '$letter${last.toUpperCase()}'.trim();
    return first;
  }

  String _formatMinutes(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _empty(String title, String message) {
    final colors = context.appColors;
    return Padding(
      padding: widget.padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 42,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
