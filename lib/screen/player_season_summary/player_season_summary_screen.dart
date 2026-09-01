import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/grinta_player_hw.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/effectivesService.dart';
import 'package:grinta/services/player_positions_service.dart';
import 'package:grinta/services/player_season_summary_service.dart';
import 'package:grinta/services/meta_share_coordinator.dart';
import 'package:grinta/services/player_season_summary_share_service.dart';
import 'package:grinta/services/share_record_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/share_sheet.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';
import 'package:grinta/util/player_age.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/share_player_access.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/preferred_foot.dart';
import 'package:grinta/widget/manage_unavailabilities_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _PlayerSeasonSummaryTab { matches, trainings, unavailabilities }

class _PreferredFootPick {
  const _PreferredFootPick(this.value);
  final String? value;
}

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
    this.isGrintaRoster = false,
    this.effectivesDocId,
  });

  final Player player;
  final List<int> positionCodes;
  final List<String> positionLabels;
  final DateTime? birthday;
  final int? heightCm;
  final double? weightKg;
  final DateTime? hwMeasuredAt;
  final String? preferredFoot;
  final bool isGrintaRoster;
  final String? effectivesDocId;
}

Future<void> openPlayerSeasonSummaryScreen(
  BuildContext context, {
  required Team team,
  required PlayerSeasonSummaryIdentity identity,
  required String initialSeasonId,
  bool isManager = false,
}) {
  return Navigator.of(context).push<void>(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.playerSeasonSummary,
      builder: (_) => PlayerSeasonSummaryScreen(
        team: team,
        identity: identity,
        initialSeasonId: initialSeasonId,
        isManager: isManager,
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
    this.isManager = false,
    PlayerSeasonSummaryService? summaryService,
  }) : _summaryService = summaryService;

  final Team team;
  final PlayerSeasonSummaryIdentity identity;
  final String initialSeasonId;
  final bool isManager;
  final PlayerSeasonSummaryService? _summaryService;

  @override
  State<PlayerSeasonSummaryScreen> createState() =>
      _PlayerSeasonSummaryScreenState();
}

class _PlayerSeasonSummaryScreenState extends State<PlayerSeasonSummaryScreen> {
  late String _selectedSeasonId;
  late String? _preferredFoot;
  _PlayerSeasonSummaryTab _selectedTab = _PlayerSeasonSummaryTab.matches;
  bool _loading = true;
  bool _didInit = false;
  bool _savingPreferredFoot = false;
  PlayerSeasonSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedSeasonId = widget.initialSeasonId.trim();
    _preferredFoot = normalizePreferredFoot(widget.identity.preferredFoot);
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

  Future<void> _shareSummary(BuildContext context) async {
    final summary = _summary;
    if (summary == null) return;

    final l10n = context.l10n;
    final playerName = playerDisplayName(
      widget.identity.player,
      unknownLabel: l10n.entityPlayerUnknown,
    );
    final teamName = (widget.team.name?.trim().isNotEmpty ?? false)
        ? widget.team.name!.trim()
        : l10n.entityTeam;

    final session = context.read<AppSession>();
    final seasons = _seasonOptions(session);
    String seasonLabel = _selectedSeasonId;
    for (final season in seasons) {
      final id = season.ref?.id?.trim() ?? '';
      if (id == _selectedSeasonId) {
        seasonLabel = _seasonLabel(context, season);
        break;
      }
    }

    final origin = shareSheetOrigin(context);

    try {
      final png = await const PlayerSeasonSummaryShareService()
          .renderShareCardPng(
        l10n: l10n,
        playerName: playerName,
        teamName: teamName,
        seasonLabel: seasonLabel,
        summary: summary,
      );
      if (png == null || png.isEmpty) {
        throw StateError('Season summary PNG render failed');
      }
      if (!context.mounted) return;
      final memberId =
          effectiveMemberId(widget.identity.player)?.trim() ?? '';
      final statId = [
        if (memberId.isNotEmpty) memberId,
        if (_selectedSeasonId.trim().isNotEmpty) _selectedSeasonId.trim(),
      ].join('_');
      await MetaShareCoordinator().shareOrPublish(
        context: context,
        pngBytes: png,
        fileName: 'grinta_season_summary.png',
        statId: statId,
        statType: ShareStatType.seasonSummary,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.playerSeasonSummaryShareFailed,
        isError: true,
      );
      debugPrint('PlayerSeasonSummary share failed: $e');
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

    final bool manageUnavailabilities =
        widget.isManager &&
        _selectedTab == _PlayerSeasonSummaryTab.unavailabilities;

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
        actions: [
          if (_summary != null &&
              !_loading &&
              canSharePlayerCardFromSession(
                session: context.watch<AppSession>(),
                teamId: widget.team.keyTeam,
                viewedPlayer: widget.identity.player,
                isManager: widget.isManager,
              ))
            Builder(
              builder: (buttonContext) {
                return IconButton(
                  tooltip: l10n.playerSeasonSummaryShareTooltip,
                  onPressed: () => _shareSummary(buttonContext),
                  icon: const Icon(Icons.ios_share_outlined),
                );
              },
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
                _buildHeader(context, playerName),
                const SizedBox(height: 10),
                _buildSeasonSelector(context),
                const SizedBox(height: 10),
                _buildTabSelector(context),
                const SizedBox(height: 8),
              ],
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
                            l10n.errorGeneric(_error!),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      )
                    : manageUnavailabilities
                        ? ManageUnavailabilitiesSheet(
                            key: ValueKey(
                              'player-summary-unavail-$_selectedSeasonId-'
                              '${effectiveMemberId(widget.identity.player)}',
                            ),
                            player: widget.identity.player,
                            seasonId: _selectedSeasonId,
                            isManager: true,
                            embeddedInScreen: true,
                            showCloseButton: false,
                            showPlayerName: false,
                            onChanged: _loadSummary,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSummary,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: _buildSelectedTabContent(context),
                            ),
                          ),
          ),
        ],
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

    final measuredLabel = measuredAt == null
        ? null
        : l10n.playerSeasonSummaryHwMeasuredAt(
            DateFormat.yMMMd(l10n.localeName).format(measuredAt),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PlayerPhoto(player: widget.identity.player, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    if (anthropometrics.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        anthropometrics,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (measuredLabel != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        measuredLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isManager)
                IconButton(
                  tooltip: l10n.actionEditPlayer,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed:
                      _savingPreferredFoot ? null : _editPreferredFoot,
                  icon: _savingPreferredFoot
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                ),
            ],
          ),
          if (positions.isNotEmpty || _preferredFoot != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final label in positions) _PositionChip(label: label),
                _PositionChip(
                  label:
                      '${l10n.preferredFootLabel}: ${preferredFootLabel(l10n, _preferredFoot)}',
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.preferredFootLabel}: ${preferredFootLabel(l10n, _preferredFoot)}',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_summary != null && _summary!.teamNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final String teamName in _summary!.teamNames)
                  _PositionChip(label: teamName),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editPreferredFoot() async {
    if (!widget.isManager || _savingPreferredFoot) return;

    final l10n = context.l10n;
    String? draft = _preferredFoot;

    final _PreferredFootPick? picked = await showDialog<_PreferredFootPick>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.preferredFootLabel),
              content: DropdownButtonFormField<String?>(
                value: draft,
                decoration: InputDecoration(
                  labelText: l10n.preferredFootLabel,
                  hintText: l10n.preferredFootHint,
                ),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.preferredFootUnspecified),
                  ),
                  for (final String code in PreferredFootCodes.selectable)
                    DropdownMenuItem<String?>(
                      value: code,
                      child: Text(preferredFootLabel(l10n, code)),
                    ),
                ],
                onChanged: (value) {
                  setDialogState(() => draft = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _PreferredFootPick(draft),
                  ),
                  child: Text(l10n.actionSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }
    await _editPreferredFootConfirmed(picked.value);
  }

  Future<void> _editPreferredFootConfirmed(String? selected) async {
    if (!mounted) return;
    if (normalizePreferredFoot(selected) ==
        normalizePreferredFoot(_preferredFoot)) {
      return;
    }

    setState(() => _savingPreferredFoot = true);
    try {
      await _persistPreferredFoot(selected);
      if (!mounted) return;
      setState(() {
        _preferredFoot = normalizePreferredFoot(selected);
        _savingPreferredFoot = false;
      });
      AppSnackbar.show(
        context,
        context.l10n.playerSeasonSummaryPreferredFootSaved,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingPreferredFoot = false);
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _persistPreferredFoot(String? preferredFoot) async {
    final teamId = widget.team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      throw StateError('Missing team id');
    }

    final memberId = effectiveMemberId(widget.identity.player)?.trim() ?? '';
    if (memberId.isEmpty) {
      throw StateError('Missing player id');
    }

    final normalized = normalizePreferredFoot(preferredFoot);

    if (widget.identity.isGrintaRoster ||
        (widget.team.grintaPlayers?.isNotEmpty ?? false)) {
      final GrintaPlayer? existing = _resolveGrintaPlayer(memberId);
      if (existing != null) {
        final updated = GrintaPlayer(
          playerId: existing.playerId,
          positions: List<int>.from(existing.positions),
          fonction: existing.fonction,
          trackers: List<String>.from(existing.trackers),
          email: existing.email,
          phoneE164: existing.phoneE164,
          birthday: existing.birthday,
          hwHistory: List<GrintaPlayerHW>.from(existing.hwHistory),
          invitationId: existing.invitationId,
          preferredFoot: normalized,
        );
        await TeamService().updateGrintaPlayer(
          teamId: teamId,
          playerId: existing.playerId,
          player: updated,
          staffEntry: isGrintaRosterStaff(
            positions: existing.positions,
            fonction: existing.fonction,
            listedInManagers: false,
          ),
        );

        final list = List<GrintaPlayer>.from(
          widget.team.grintaPlayers ?? const <GrintaPlayer>[],
        );
        final index = list.indexWhere(
          (entry) => entry.playerId.trim() == existing.playerId.trim(),
        );
        if (index >= 0) {
          list[index] = updated;
          widget.team.grintaPlayers = list;
        }
        return;
      }
    }

    final effectivesId = widget.identity.effectivesDocId?.trim() ?? '';
    final EffectivesService effectivesService = EffectivesService();
    Effectives? effectives;
    if (effectivesId.isNotEmpty) {
      effectives = await effectivesService.getEffectivesById(effectivesId);
    }
    effectives ??= await effectivesService.getEffectivesByMemberIdAndTeamId(
      memberId,
      teamId,
    );
    if (effectives == null) {
      throw StateError('Unable to update preferred foot for this player');
    }

    effectives.piedFort = normalized ?? '';
    await effectivesService.updateEffectives(effectives);
  }

  GrintaPlayer? _resolveGrintaPlayer(String memberId) {
    final lookupIds = playerMemberLookupIds(widget.identity.player);
    for (final GrintaPlayer entry
        in widget.team.grintaPlayers ?? const <GrintaPlayer>[]) {
      final id = entry.playerId.trim();
      if (id.isEmpty) continue;
      if (id == memberId || lookupIds.contains(id)) {
        return entry;
      }
    }
    return null;
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
            _SummaryMetricCard(
              label: l10n.highlightTypeYellowCard,
              value: '${summary.yellowCards}',
              valueColor: colors.warning,
            ),
            _SummaryMetricCard(
              label: l10n.highlightTypeRedCard,
              value: '${summary.redCards}',
              valueColor: colors.danger,
            ),
            _SummaryMetricCard(
              label: l10n.playerSeasonSummaryTeamMatches,
              value: '${summary.teamMatchCount}',
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
    final colors = context.appColors;
    if (averages.sessionsWithData <= 0 || averages.averages.isEmpty) {
      return Text(
        l10n.playerSeasonSummaryNoTrackerData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
      );
    }

    final metrics = <_TrackerMetricDisplay>[
      for (final key in kPlayerActivityTrackerMetricKeys)
        if (averages.averages[key] != null)
          _metricDisplay(l10n, colors, key, averages.averages[key]!),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 4 : (width >= 420 ? 3 : 2);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: width >= 720 ? 1.25 : 1.05,
      children: [
        for (final metric in metrics)
          _PerformanceMetricTile(
            icon: metric.icon,
            label: metric.label,
            value: metric.value,
            unit: metric.unit,
            color: metric.color,
          ),
      ],
    );
  }

  _TrackerMetricDisplay _metricDisplay(
    AppLocalizations l10n,
    AppColors colors,
    String key,
    double value,
  ) {
    switch (key) {
      case TeamWorkloadMetricKeys.distanceKm:
        return _TrackerMetricDisplay(
          icon: Icons.route_rounded,
          label: l10n.statsDistance,
          value: value.toStringAsFixed(2),
          unit: l10n.statsUnitKm,
          color: colors.primary,
        );
      case TeamWorkloadMetricKeys.maxValidatedSpeedKmh:
        return _TrackerMetricDisplay(
          icon: Icons.bolt_rounded,
          label: l10n.statsMaxSpeed,
          value: value.toStringAsFixed(1),
          unit: l10n.statsUnitKmh,
          color: colors.success,
        );
      case TeamWorkloadMetricKeys.sprintCount:
        return _TrackerMetricDisplay(
          icon: Icons.directions_run_rounded,
          label: l10n.statsSprints,
          value: value.toStringAsFixed(0),
          unit: l10n.statsUnitCount,
          color: colors.primary,
        );
      case TeamWorkloadMetricKeys.highAccelerationCount:
        return _TrackerMetricDisplay(
          icon: Icons.flash_on_rounded,
          label: l10n.statsHighAccel,
          value: value.toStringAsFixed(0),
          unit: l10n.statsUnitCount,
          color: colors.warning,
        );
      case TeamWorkloadMetricKeys.highSpeedDuration:
        return _TrackerMetricDisplay(
          icon: Icons.timer_rounded,
          label: l10n.statsHighSpeedTime,
          value: _formatSeconds(value),
          unit: '',
          color: colors.secondary,
        );
      case TeamWorkloadMetricKeys.maxAccelerationMps2:
        return _TrackerMetricDisplay(
          icon: Icons.trending_up_rounded,
          label: l10n.statsMaxAccel,
          value: value.toStringAsFixed(2),
          unit: l10n.statsUnitMps2,
          color: colors.warning,
        );
      case TeamWorkloadMetricKeys.workloadScore:
        return _TrackerMetricDisplay(
          icon: Icons.fitness_center_rounded,
          label: l10n.statsWorkload,
          value: value.toStringAsFixed(0),
          unit: 'pts',
          color: colors.success,
        );
      default:
        return _TrackerMetricDisplay(
          icon: Icons.query_stats_rounded,
          label: key,
          value: value.toStringAsFixed(1),
          unit: '',
          color: colors.textSecondary,
        );
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
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
}

/// Same visual language as tracker analysis `_MetricTile`.
class _PerformanceMetricTile extends StatelessWidget {
  const _PerformanceMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    alignment: Alignment.center,
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              unit,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              height: 1.1,
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
