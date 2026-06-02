import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';

import '../model/matchStats.dart';
import '../model/player.dart';
import '../model/tracker/team_workload_summary.dart';
import '../services/matchStatsService.dart';
import '../services/playerService.dart';
import '../services/teamWorkloadSummaryService.dart';
import '../util/app_theme.dart';
import '../model/match.dart' as models;
import '../util/playerDisplayName.dart';
import '../widget/match_compo_widget.dart';
import '../widget/match_highlights_timeline.dart';
import '../widget/match_tracker_stats_table.dart';
import '../widget/tracker_player_analysis_widget.dart';
import 'match_detail/match_tactical_schema_tab.dart';

class MatchDetailScreen extends StatelessWidget {
  final models.Match match;

  /// Permet de remplacer le contenu de l’onglet Compo.
  final Widget Function(BuildContext context, models.Match match)? compoBuilder;

  /// Permet de remplacer le contenu de l’onglet Schéma tactique.
  final Widget Function(BuildContext context, models.Match match)? tacticalSchemaBuilder;

  /// Permet de remplacer le contenu de l’onglet Temps forts.
  final Widget Function(BuildContext context, models.Match match)? highlightsBuilder;

  /// Permet de remplacer le contenu de l’onglet Statistiques.
  final Widget Function(BuildContext context, models.Match match)? statsBuilder;

  final bool isManager;
  final String? playerId;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.compoBuilder,
    this.tacticalSchemaBuilder,
    this.highlightsBuilder,
    this.statsBuilder,
    required this.isManager,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool showStats = match.withTracker == true;

    final l10n = context.l10n;
    final tabs = <Widget>[
      _MatchDetailTab(
        icon: Icons.groups_rounded,
        label: l10n.tabCompo,
        compactLabel: l10n.tabCompo,
      ),
      _MatchDetailTab(
        icon: Icons.grid_view_rounded,
        label: l10n.tabTacticalSchema,
        compactLabel: l10n.tabTacticalSchemaShort,
      ),
      _MatchDetailTab(
        icon: Icons.flash_on_rounded,
        label: l10n.tabHighlights,
        compactLabel: l10n.tabHighlightsShort,
      ),
      if (showStats)
        _MatchDetailTab(
          icon: Icons.query_stats_rounded,
          label: l10n.navStatistics,
          compactLabel: l10n.tabStats,
        ),
    ];

    final views = <Widget>[
      compoBuilder?.call(context, match) ?? _CompoTab(match: match),
      tacticalSchemaBuilder?.call(context, match) ??
          MatchTacticalSchemaTab(match: match, isManager: isManager),
      highlightsBuilder?.call(context, match) ?? _HighlightsTab(match: match),
      if (showStats) statsBuilder?.call(context, match) ?? _StatsTab(match: match, isManager: isManager,playerId: playerId,),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(match: match),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWebLarge = constraints.maxWidth >= 900;
                    final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

                    final double horizontalPadding = isWebLarge
                        ? 8
                        : isTablet
                        ? 10
                        : 0;

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          _MatchHeader(match: match),
                          const SizedBox(height: 6),
                          _TabsContainer(tabs: tabs),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: views,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final models.Match match;

  const _TopBar({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
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
              context.l10n.matchDetailTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
    );
  }
}

class _TabsContainer extends StatelessWidget {
  final List<Widget> tabs;

  const _TabsContainer({
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        tabs: tabs,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _MatchDetailTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String compactLabel;

  const _MatchDetailTab({
    required this.icon,
    required this.label,
    required this.compactLabel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = MediaQuery.of(context).size.width < 430;

        return Tab(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: compact ? 17 : 18,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  compact ? compactLabel : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final models.Match match;

  const _MatchHeader({
    required this.match,
  });

  static bool _hasVenueInfo(models.Match match) {
    return _clean(match.nomDuTerrain).isNotEmpty ||
        _clean(match.terrainAdresse1).isNotEmpty ||
        _clean(match.terrainAddress2).isNotEmpty ||
        _clean(match.surfaceDeJeu).isNotEmpty;
  }

  static String _venueSummary(models.Match match) {
    final terrain = _clean(match.nomDuTerrain);
    final address = [
      _clean(match.terrainAdresse1),
      _clean(match.terrainAddress2),
    ].where((part) => part.isNotEmpty).join(' — ');

    if (terrain.isNotEmpty && address.isNotEmpty) {
      return '$terrain · $address';
    }
    if (terrain.isNotEmpty) return terrain;
    if (address.isNotEmpty) return address;
    return _clean(match.surfaceDeJeu);
  }

  static void _showVenueSheet(BuildContext context, models.Match match) {
    final colors = context.appColors;
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.background,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.matchDetailVenueTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_clean(match.nomDuTerrain).isNotEmpty)
                        _HeaderInfoLine(
                          icon: Icons.stadium_rounded,
                          value: match.nomDuTerrain!,
                          valueColor: colors.textPrimary,
                        ),
                      if (_clean(match.terrainAdresse1).isNotEmpty ||
                          _clean(match.terrainAddress2).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _HeaderInfoLine(
                          icon: Icons.place_outlined,
                          value: [
                            _clean(match.terrainAdresse1),
                            _clean(match.terrainAddress2),
                          ].where((s) => s.isNotEmpty).join(' — '),
                          valueColor: colors.textPrimary,
                        ),
                      ],
                      if (_clean(match.surfaceDeJeu).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _HeaderInfoLine(
                          icon: Icons.grass_rounded,
                          value: match.surfaceDeJeu!,
                          valueColor: colors.textPrimary,
                        ),
                      ],
                      if (!_hasVenueInfo(match))
                        Text(
                          l10n.entityFieldUndefined,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final l10n = context.l10n;
    final String team1 = _clean(match.team1, fallback: l10n.entityTeamWithIndex(1));
    final String team2 = _clean(match.team2, fallback: l10n.entityTeamWithIndex(2));

    final bool played = match.isMatchPlayed == true;
    final bool isReport = match.isReport == true;
    final bool hasVenue = _hasVenueInfo(match);

    final String score = played
        ? '${match.homeScore ?? 0} - ${match.outSideScore ?? 0}'
        : '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              if (_clean(match.chType).isNotEmpty)
                _InfoPill(
                  icon: Icons.emoji_events_outlined,
                  label: match.chType!,
                ),
              if ((match.day ?? 0) > 0)
                _InfoPill(
                  icon: Icons.calendar_view_day_rounded,
                  label: l10n.periodMatchDay(match.day.toString()),
                ),
              if (_clean(match.tour).isNotEmpty)
                _InfoPill(
                  icon: Icons.flag_outlined,
                  label: match.tour!,
                ),
              if (isReport)
                _InfoPill(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.periodPostponed,
                  color: colors.warning,
                ),
            ],
          ),
          const SizedBox(height: 6),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 360;

              if (compact) {
                return Column(
                  children: [
                    _TeamBlock(
                      name: team1,
                      logoUrl: match.team1UrlLogo,
                      affiliation: match.affiliationTeam1,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    _ScoreBlock(
                      score: score,
                      tab: match.tab,
                      played: played,
                    ),
                    const SizedBox(height: 6),
                    _TeamBlock(
                      name: team2,
                      logoUrl: match.team2UrlLogo,
                      affiliation: match.affiliationTeam2,
                      compact: true,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamBlock(
                      name: team1,
                      logoUrl: match.team1UrlLogo,
                      affiliation: match.affiliationTeam1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _ScoreBlock(
                      score: score,
                      tab: match.tab,
                      played: played,
                    ),
                  ),
                  Expanded(
                    child: _TeamBlock(
                      name: team2,
                      logoUrl: match.team2UrlLogo,
                      affiliation: match.affiliationTeam2,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _dateTimeLabel(context, match),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasVenue) ...[
            const SizedBox(height: 6),
            Material(
              color: colors.surface,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: colors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showVenueSheet(context, match),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _venueSummary(match),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _dateTimeLabel(BuildContext context, models.Match match) {
    final l10n = context.l10n;
    final date = _clean(match.dateCh);
    final time = _clean(match.timeCh);

    if (date.isEmpty && time.isEmpty) return l10n.dateUndefined;
    if (date.isNotEmpty && time.isNotEmpty) {
      return l10n.matchDateTimeAt(date, time);
    }
    if (date.isNotEmpty) return date;
    return time;
  }

}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final String? affiliation;
  final bool compact;

  const _TeamBlock({
    required this.name,
    required this.logoUrl,
    required this.affiliation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        _TeamLogo(
          logoUrl: logoUrl,
          size: compact ? 40 : 48,
          imageSize: compact ? 26 : 32,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        if (_clean(affiliation).isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            affiliation!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final double imageSize;

  const _TeamLogo({
    required this.logoUrl,
    this.size = 64,
    this.imageSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeUrl = (logoUrl ?? '').trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Container(
          width: imageSize,
          height: imageSize,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: safeUrl.isEmpty
              ? Icon(
            Icons.shield_outlined,
            size: imageSize * 0.55,
            color: colors.textSecondary,
          )
              : Image.network(
            safeUrl,
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('LOGO ERROR url=$safeUrl');
              debugPrint('error=$error');

              return Icon(
                Icons.broken_image_outlined,
                size: imageSize * 0.55,
                color: colors.textSecondary,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  final String score;
  final String? tab;
  final bool played;

  const _ScoreBlock({
    required this.score,
    required this.tab,
    required this.played,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: played ? 26 : 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        if (_clean(tab).isNotEmpty)
          Text(
            'TAB $tab',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
      ],
    );
  }
}

class _HeaderInfoLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? valueColor;

  const _HeaderInfoLine({
    required this.icon,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pillColor = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pillColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: pillColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: pillColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompoTab extends StatelessWidget {
  final models.Match match;

  const _CompoTab({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return _TabContainer(
      children: [
        StreamBuilder<MatchStats?>(
          stream: MatchStatsService().streamMatchStatsByMatchId(match.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.errorCompositionTitle,
                message: snapshot.error.toString(),
              );
            }

            final matchStats = snapshot.data;

            return MatchCompoWidget(
              matchStats: matchStats,
              team1: match.team1,
              team2: match.team2,
            );
          },
        ),
      ],
    );
  }
}

class _HighlightsTab extends StatelessWidget {
  final models.Match match;

  const _HighlightsTab({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return _TabContainer(
      children: [
        StreamBuilder<MatchStats?>(
          stream: MatchStatsService().streamMatchStatsByMatchId(match.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final matchStats = snapshot.data;

            return MatchHighlightsTimeline(
              matchStats: matchStats,
              team1: match.team1,
              team2: match.team2,
            );
          },
        ),
      ],
    );
  }
}

class _StatsTab extends StatefulWidget {
  final models.Match match;
  final bool isManager;
  final String? playerId;

  const _StatsTab({
    required this.match,
    required this.isManager,
    required this.playerId,
  });

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  late Future<Player?> _playerFuture;

  @override
  void initState() {
    super.initState();
    _playerFuture = _loadPlayer();
  }

  @override
  void didUpdateWidget(covariant _StatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playerId != widget.playerId) {
      _playerFuture = _loadPlayer();
    }
  }

  Future<Player?> _loadPlayer() async {
    final safePlayerId = (widget.playerId ?? '').trim();

    if (safePlayerId.isEmpty) {
      return null;
    }

    return PlayerService().getPlayerById(safePlayerId);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'dans _StatsTab isManager=${widget.isManager} playerId=${widget.playerId}',
    );

    final String eventId = (widget.match.id ?? '').trim();

    if (eventId.isEmpty) {
      return _TabContainer(
        children: [
          _EmptyState(
            icon: Icons.query_stats_rounded,
            title: context.l10n.matchStatsUnavailableTitle,
            message: context.l10n.errorMatchIdMissing,
          ),
        ],
      );
    }

    if (widget.isManager) {
      return _TabContainer(
        children: [
          MatchTrackerStatsTable(
            eventId: eventId,
            teamId: widget.match.teamID,
            realtime: true,
          ),
        ],
      );
    }

    final String safePlayerId = (widget.playerId ?? '').trim();

    if (safePlayerId.isEmpty) {
      return _TabContainer(
        children: [
          _EmptyState(
            icon: Icons.person_off_rounded,
            title: context.l10n.errorPlayerNotIdentified,
            message: context.l10n.errorNoStatsForPlayer,
          ),
        ],
      );
    }

    return _TabContainer(
      children: [
        FutureBuilder<Player?>(
          future: _playerFuture,
          builder: (context, playerSnapshot) {
            if (playerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (playerSnapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.errorPlayerTitle,
                message: playerSnapshot.error.toString(),
              );
            }

            final Player? player = playerSnapshot.data;

            if (player == null) {
              return _EmptyState(
                icon: Icons.person_off_rounded,
                title: context.l10n.errorPlayerNotFound,
                message: context.l10n.errorPlayerNotFoundMessage,
              );
            }

            return StreamBuilder<TeamWorkloadSummary?>(
              stream: TeamWorkloadSummaryService().watchByEventId(eventId),
              builder: (context, summarySnapshot) {
                if (summarySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (summarySnapshot.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: context.l10n.errorTrackerTitle,
                    message: summarySnapshot.error.toString(),
                  );
                }

                final TeamWorkloadSummary? summary = summarySnapshot.data;

                if (summary == null) {
                  return _EmptyState(
                    icon: Icons.query_stats_rounded,
                    title: context.l10n.errorNoStats,
                    message: context.l10n.errorNoTrackerData,
                  );
                }

                final TeamPlayerMetricScores? playerScore =
                _findPlayerScore(
                  summary: summary,
                  playerId: safePlayerId,
                );

                if (playerScore == null) {
                  return _EmptyState(
                    icon: Icons.person_search_rounded,
                    title: context.l10n.errorPlayerNotFoundInMatch,
                    message: context.l10n.errorPlayerNoTrackerMatch,
                  );
                }

                final String trackerId = playerScore.trackerId.trim();

                if (trackerId.isEmpty) {
                  return _EmptyState(
                    icon: Icons.sensors_off_rounded,
                    title: context.l10n.sensorNotFoundTitle,
                    message: context.l10n.sensorNotFoundMessage,
                  );
                }

                final String analysisDocId = '${eventId}_$trackerId';

                return TrackerPlayerAnalysisWidget(
                  analysisDocId: analysisDocId,
                  teamId: widget.match.teamID,
                  playerName: playerDisplayName(
                    player,
                    unknownLabel: context.l10n.entityPlayer,
                  ),
                  player: player,
                  isMatch: true,
                );
              },
            );
          },
        ),
      ],
    );
  }

  TeamPlayerMetricScores? _findPlayerScore({
    required TeamWorkloadSummary summary,
    required String playerId,
  }) {
    for (final score in summary.playerScores) {
      if (score.playerId == playerId) {
        return score;
      }
    }

    return null;
  }

}

class _TrackerStatus extends StatelessWidget {
  final models.Match match;

  const _TrackerStatus({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool uploaded = match.isTrackerDataUploaded == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: uploaded
            ? colors.success.withValues(alpha: 0.10)
            : colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: uploaded
              ? colors.success.withValues(alpha: 0.25)
              : colors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: uploaded ? colors.success : colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              uploaded
                  ? context.l10n.matchTrackerDataAvailable
                  : context.l10n.matchTrackerDataPending,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabContainer extends StatelessWidget {
  final List<Widget> children;

  const _TabContainer({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final double horizontalPadding = width >= 900
        ? 8
        : width >= 600
        ? 10
        : 12;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24,
      ),
      children: children,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTeamCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniTeamCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String minute;
  final String title;
  final String subtitle;
  final IconData icon;

  const _TimelineItem({
    required this.minute,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            minute,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}