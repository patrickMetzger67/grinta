import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';

import '../../model/answer.dart';
import '../../model/player.dart';
import '../../model/training.dart';
import '../../provider/appSession.dart';
import '../../services/answerService.dart';
import '../../services/trainingService.dart';
import '../../util/app_theme.dart';
import '../../util/playerDisplayName.dart';
import '../../widget/playerPhoto.dart';
import 'training_team_players_loader.dart';
import 'training_team_players_presence.dart';
import 'training_team_players_tracker.dart';

/// Liste des joueurs d'un entraînement (présences, récap) — ouvert depuis l'agenda.
class TeamPlayersScreen extends StatefulWidget {
  final Training training;
  final String? title;
  final String? subtitle;
  final bool readOnly;
  final String? seasonId;

  const TeamPlayersScreen({
    super.key,
    required this.training,
    this.title,
    this.subtitle,
    this.readOnly = false,
    this.seasonId,
  });

  static Future<void> open(
    BuildContext context, {
    required Training training,
    String? title,
    String? subtitle,
    bool readOnly = false,
    String? seasonId,
  }) {
    final resolvedSeasonId = seasonId ??
        context.read<AppSession>().selectedSeason?.ref?.id;

    return Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamPlayers,
        builder: (_) => TeamPlayersScreen(
          training: training,
          title: title,
          subtitle: subtitle,
          readOnly: readOnly,
          seasonId: resolvedSeasonId,
        ),
      ),
    );
  }

  @override
  State<TeamPlayersScreen> createState() => _TeamPlayersScreenState();
}

class _TeamPlayersScreenState extends State<TeamPlayersScreen> {
  late final TrainingTeamPlayersLoader _loader;

  bool _loading = true;
  Object? _loadError;
  List<TrainingPlayerRowVm> _rows = [];
  bool _saving = false;
  TrainingTrackerContext? _trackerContext;
  Set<String> _devicesAffected = {};

  bool get _canEdit => !widget.readOnly;

  bool get _showTracker =>
      widget.training.withTracker == true &&
      widget.training.ownerId != null &&
      widget.training.ownerId!.trim().isNotEmpty;

  DateTime? get _trainingDate => widget.training.dateTime?.toDate();

  bool _isPlayerUnavailableOnTrainingDate(Player player) {
    return isPlayerUnavailableOnTrainingDate(
      player,
      _trainingDate,
      seasonId: widget.seasonId,
    );
  }

  @override
  void initState() {
    super.initState();
    _loader = TrainingTeamPlayersLoader();
    _initTrackerAndReload();
  }

  Future<void> _initTrackerAndReload() async {
    _trackerContext = await TrainingTrackerContext.loadForTraining(widget.training);
    await _reload();
  }

  Future<void> _reload() async {
    try {
      final rows = await _loader.load(
        training: widget.training,
        seasonId: widget.seasonId,
      );

      _applyTrackerDefaults(rows);

      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e;
        });
      }
    }
  }

  void _applyTrackerDefaults(List<TrainingPlayerRowVm> rows) {
    if (_trackerContext == null || !_showTracker) return;

    final ownerId = widget.training.ownerId!.trim();
    final affected = _trackerContext!.collectAffectedDeviceIds(
      rows.map((r) => r.playerTraining),
    );
    for (final row in rows) {
      _trackerContext!.applyDefaultFromEffectives(
        playerTraining: row.playerTraining,
        effectives: row.effectives,
        ownerId: ownerId,
        devicesAffected: affected,
      );
    }
    _devicesAffected = affected;
  }

  void _sortRows(List<TrainingPlayerRowVm> rows) {
    rows.sort((a, b) {
      final last = (a.player.lastName ?? '').toLowerCase().compareTo(
        (b.player.lastName ?? '').toLowerCase(),
      );
      if (last != 0) return last;
      return (a.player.firstName ?? '').toLowerCase().compareTo(
        (b.player.firstName ?? '').toLowerCase(),
      );
    });
  }

  Widget _buildLoadingBody(AppColors colors, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  String? get _firestoreTrainingDocId {
    final docId = widget.training.docId?.trim();
    if (docId != null && docId.isNotEmpty) return docId;
    return widget.training.ref?.id;
  }

  String? get _answerObjectId {
    final trainingId = widget.training.trainingId?.trim();
    if (trainingId != null && trainingId.isNotEmpty) return trainingId;
    return _firestoreTrainingDocId;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final screenTitle = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : l10n.entityPlayers;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              screenTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
            ),
            if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty)
              Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
          ],
        ),
        actions: [
          if (!_loading && _rows.isNotEmpty)
            IconButton(
              tooltip: l10n.trainingPlayersRecap,
              onPressed: () => _showRecapSheet(
                context,
                _loader.countPresence(_rows),
              ),
              icon: Icon(Icons.info_outline, color: colors.primary),
            ),
        ],
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              tooltip: l10n.trainingPlayersAddPlayer,
              onPressed: _saving ? null : _addPlayer,
              child: const Icon(Icons.person_add_outlined),
            )
          : null,
      body: _buildBody(context, colors),
    );
  }

  Widget _buildBody(BuildContext context, AppColors colors) {
    final l10n = context.l10n;

    if (_loading) {
      return _buildLoadingBody(colors, l10n.trainingPlayersLoading);
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$_loadError',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.danger),
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.emptyNoPlayerForTeam,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ),
      );
    }

    final counts = _loader.countPresence(_rows);

    return Column(
      children: [
        _PresenceSummaryStrip(counts: counts, colors: colors),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              final row = _rows[index];
                    final unavailable = _isPlayerUnavailableOnTrainingDate(row.player);
                    final style = _presenceStyle(
                      context,
                      row.playerTraining.presenceType,
                    );
                    final trackerLabel = _trackerDisplayLabel(row);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: style.cardColor,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colors.border),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: style.accentColor,
                                width: 4,
                              ),
                            ),
                          ),
                          child: _PlayerPresenceTile(
                            player: row.player,
                            presenceLabel: style.label,
                            colors: colors,
                            badgeBackground: style.badgeBackground,
                            badgeForeground: style.badgeForeground,
                            trackerLabel: trackerLabel,
                            showTracker: _showTracker,
                            canEditTracker: _canEdit && _showTracker,
                            onAssignTracker: () => _assignTracker(row),
                            onRemoveTracker: () => _unassignTracker(row),
                            onPresenceTap: _canEdit && !unavailable
                                ? () => _showPresencePicker(row)
                                : null,
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  TrainingPresenceStyle _presenceStyle(
    BuildContext context,
    PresenceType? type,
  ) {
    final l10n = context.l10n;
    return presenceStyleFor(
      context.appColors,
      type,
      labelPresent: l10n.presencePresent,
      labelInjured: l10n.presenceInjured,
      labelExcused: l10n.presenceExcused,
      labelAbsent: l10n.presenceAbsent,
      labelLate: l10n.presenceLate,
      labelUnknown: l10n.presenceUnknown,
    );
  }

  String? _trackerDisplayLabel(TrainingPlayerRowVm row) {
    if (!_showTracker) return null;

    final deviceId = row.playerTraining.deviceId?.trim();
    if (deviceId == null || deviceId.isEmpty) return null;

    if (_trackerContext != null) {
      final label = _trackerContext!.displayLabel(row.playerTraining);
      if (label.isNotEmpty) return label;
    }

    final name = row.playerTraining.customName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return deviceId;
  }

  Future<void> _showPresencePicker(TrainingPlayerRowVm row) async {
    if (!_canEdit || _saving) return;
    if (_isPlayerUnavailableOnTrainingDate(row.player)) return;

    final colors = context.appColors;
    final l10n = context.l10n;
    final current = row.playerTraining.presenceType;

    final selected = await showModalBottomSheet<PresenceType>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.trainingPlayersChangePresence,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                ..._presenceChoices(ctx).map((choice) {
                  final style = _presenceStyle(ctx, choice.type);
                  final selectedTile = current == choice.type;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: selectedTile
                        ? style.badgeBackground
                        : colors.card,
                    title: Text(
                      choice.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight:
                            selectedTile ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop(choice.type),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == current) return;
    await _setPresence(row: row, presenceType: selected);
  }

  List<({PresenceType type, String label})> _presenceChoices(BuildContext context) {
    final l10n = context.l10n;
    return [
      (type: PresenceType.present, label: l10n.presencePresent),
      (type: PresenceType.absent, label: l10n.presenceAbsent),
      (type: PresenceType.excuse, label: l10n.presenceExcused),
      (type: PresenceType.blesse, label: l10n.presenceInjured),
      (type: PresenceType.late, label: l10n.presenceLate),
    ];
  }

  Future<void> _persistPlayerTraining(TrainingPlayerRowVm row) async {
    final objectId = _answerObjectId;
    final playerId = row.player.ref?.id ?? row.playerTraining.playerId;
    if (objectId == null || playerId == null || playerId.isEmpty) {
      throw StateError('Missing training or player id');
    }

    final presenceType = row.playerTraining.presenceType;

    final answer = row.answer ??
        Answer(
          objectId: objectId,
          userId: playerId,
          createDateTime: Timestamp.now(),
          isTraining: true,
          isPresent: presenceType == PresenceType.present ||
              presenceType == PresenceType.late,
          playerTraining: row.playerTraining,
          dateTimEvent: widget.training.dateTime,
        );

    answer.playerTraining = row.playerTraining;
    answer.isPresent = presenceType == PresenceType.present ||
        presenceType == PresenceType.late;
    answer.updateDateTime = Timestamp.now();
    answer.dateTimEvent = widget.training.dateTime;

    if (answer.ref != null) {
      await AnswerService().updateAnswer(answer);
    } else {
      final ref = await AnswerService().addAnswer(answer);
      answer.ref = ref;
    }

    final docId = _firestoreTrainingDocId;
    if (docId != null && docId.isNotEmpty) {
      await TrainingService().upsertOnePlayerTraining(
        trainingId: docId,
        player: row.playerTraining,
      );
    }
  }

  Future<void> _setPresence({
    required TrainingPlayerRowVm row,
    required PresenceType presenceType,
  }) async {
    if (!_canEdit || _saving) return;
    if (_isPlayerUnavailableOnTrainingDate(row.player)) return;

    setState(() => _saving = true);

    try {
      row.playerTraining.presenceType = presenceType;
      await _persistPlayerTraining(row);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignTracker(TrainingPlayerRowVm row) async {
    if (!_canEdit || _saving || _trackerContext == null || !_showTracker) {
      return;
    }

    final ownerId = widget.training.ownerId!.trim();
    final available = _trackerContext!.availableDevices(
      ownerId,
      _devicesAffected,
    );

    final device = await showAssignTrackerDialog(
      context: context,
      availableDevices: available,
    );
    if (device == null || !mounted) return;

    setState(() => _saving = true);

    try {
      row.playerTraining.deviceId = device.id;
      final name = device.customName?.trim();
      row.playerTraining.customName =
          (name != null && name.isNotEmpty) ? name : device.deviceId;
      _devicesAffected.add(device.id);
      await _persistPlayerTraining(row);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unassignTracker(TrainingPlayerRowVm row) async {
    if (!_canEdit || _saving) return;

    final deviceId = row.playerTraining.deviceId?.trim();
    if (deviceId == null || deviceId.isEmpty) return;

    setState(() => _saving = true);

    try {
      _devicesAffected.remove(deviceId);
      row.playerTraining.deviceId = null;
      row.playerTraining.customName = null;
      await _persistPlayerTraining(row);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPlayer() async {
    if (!_canEdit || _saving) return;

    final candidates = await _loader.loadCandidatesToAdd(
      training: widget.training,
      seasonId: widget.seasonId,
    );

    if (!mounted) return;

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trainingPlayersNoCandidates)),
      );
      return;
    }

    final l10n = context.l10n;
    final colors = context.appColors;

    final player = await showModalBottomSheet<Player>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.trainingPlayersAddPlayerTitle,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: candidates.length,
                    itemBuilder: (ctx, index) {
                      final p = candidates[index];
                      return ListTile(
                        leading: PlayerPhoto(player: p, radius: 20),
                        title: Text(
                          playerDisplayName(
                            p,
                            unknownLabel: l10n.entityPlayer,
                          ),
                          style: TextStyle(color: colors.textPrimary),
                        ),
                        onTap: () => Navigator.of(ctx).pop(p),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (player == null) return;

    final playerId = player.ref?.id.trim();
    if (playerId == null || playerId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final trainingDate = widget.training.dateTime?.toDate();
      final pt = PlayerTraining(
        playerId: playerId,
        presenceType: defaultPresenceForPlayer(
          player,
          trainingDate,
          seasonId: widget.seasonId,
        ),
      );

      widget.training.playerTraining.add(pt);

      final docId = _firestoreTrainingDocId;
      if (docId != null && docId.isNotEmpty) {
        await TrainingService().upsertOnePlayerTraining(
          trainingId: docId,
          player: pt,
        );
      }

      final newRow = TrainingPlayerRowVm(
        player: player,
        playerTraining: pt,
      );
      final updated = [..._rows, newRow];
      _applyTrackerDefaults(updated);
      _sortRows(updated);

      if (mounted) {
        setState(() {
          _rows = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showRecapSheet(
    BuildContext context,
    TrainingPresenceCounts counts,
  ) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.trainingPlayersRecap,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 20),
              _RecapRow(
                label: l10n.presencePresent,
                count: counts.present,
                tint: presenceTint(colors, PresenceType.present),
                accent: presenceAccent(colors, PresenceType.present),
                textColor: colors.textPrimary,
              ),
              _RecapRow(
                label: l10n.presenceInjured,
                count: counts.injured,
                tint: presenceTint(colors, PresenceType.blesse),
                accent: presenceAccent(colors, PresenceType.blesse),
                textColor: colors.textPrimary,
              ),
              _RecapRow(
                label: l10n.presenceExcused,
                count: counts.excused,
                tint: presenceTint(colors, PresenceType.excuse),
                accent: presenceAccent(colors, PresenceType.excuse),
                textColor: colors.textPrimary,
              ),
              _RecapRow(
                label: l10n.presenceAbsent,
                count: counts.absent,
                tint: presenceTint(colors, PresenceType.absent),
                accent: presenceAccent(colors, PresenceType.absent),
                textColor: colors.textPrimary,
              ),
              _RecapRow(
                label: l10n.presenceLate,
                count: counts.late,
                tint: presenceTint(colors, PresenceType.late),
                accent: presenceAccent(colors, PresenceType.late),
                textColor: colors.textPrimary,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.trainingPlayersClose),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresenceSummaryStrip extends StatelessWidget {
  const _PresenceSummaryStrip({
    required this.counts,
    required this.colors,
  });

  final TrainingPresenceCounts counts;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _SummaryChip(
            label: l10n.presencePresent,
            count: counts.present,
            background: presenceTint(colors, PresenceType.present),
            foreground: presenceAccent(colors, PresenceType.present),
          ),
          _SummaryChip(
            label: l10n.presenceAbsent,
            count: counts.absent,
            background: presenceTint(colors, PresenceType.absent),
            foreground: presenceAccent(colors, PresenceType.absent),
          ),
          _SummaryChip(
            label: l10n.presenceExcused,
            count: counts.excused,
            background: presenceTint(colors, PresenceType.excuse),
            foreground: presenceAccent(colors, PresenceType.excuse),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int count;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// Fixed trailing column widths so tracker (+) and presence badges align across rows.
const double _kTrackerColumnWidth = 88;
const double _kPresenceColumnWidth = 118;

class _PlayerPresenceTile extends StatelessWidget {
  const _PlayerPresenceTile({
    required this.player,
    required this.presenceLabel,
    required this.colors,
    required this.badgeBackground,
    required this.badgeForeground,
    this.trackerLabel,
    this.showTracker = false,
    this.canEditTracker = false,
    this.onAssignTracker,
    this.onRemoveTracker,
    this.onPresenceTap,
  });

  final Player player;
  final String presenceLabel;
  final AppColors colors;
  final Color badgeBackground;
  final Color badgeForeground;
  final String? trackerLabel;
  final bool showTracker;
  final bool canEditTracker;
  final VoidCallback? onAssignTracker;
  final VoidCallback? onRemoveTracker;
  final VoidCallback? onPresenceTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          PlayerPhoto(player: player, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              playerDisplayName(player, unknownLabel: l10n.entityPlayer),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (showTracker) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: _kTrackerColumnWidth,
              child: Align(
                alignment: Alignment.center,
                child: trackerLabel != null
                    ? InkWell(
                        onTap: canEditTracker ? onRemoveTracker : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: _kTrackerColumnWidth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trackerLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              if (canEditTracker) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.close,
                                  size: 14,
                                  color: colors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : canEditTracker
                        ? IconButton(
                            tooltip: l10n.trainingPlayersAssignTracker,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: onAssignTracker,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: colors.primary,
                            ),
                          )
                        : null,
              ),
            ),
          ],
          const SizedBox(width: 8),
          SizedBox(
            width: _kPresenceColumnWidth,
            child: Material(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onPresenceTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          presenceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: badgeForeground,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (onPresenceTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: badgeForeground,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.label,
    required this.count,
    required this.tint,
    required this.accent,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color tint;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 48,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
