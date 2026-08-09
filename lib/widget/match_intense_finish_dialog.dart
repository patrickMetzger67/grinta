import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/intense_live_data_service.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_time_event_helper.dart';

/// Dialog for finishing / re-syncing a match with Intense cloud trackers.
class MatchIntenseFinishDialog extends StatefulWidget {
  const MatchIntenseFinishDialog({
    super.key,
    required this.match,
    required this.highlights,
    required this.syncStopAt,
    this.resync = false,
  });

  final models.Match match;
  final List<Highlights> highlights;
  final DateTime syncStopAt;
  final bool resync;

  static Future<bool?> show(
    BuildContext context, {
    required models.Match match,
    required List<Highlights> highlights,
    bool resync = false,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => MatchIntenseFinishDialog(
        match: match,
        highlights: highlights,
        syncStopAt: DateTime.now(),
        resync: resync,
      ),
    );
  }

  @override
  State<MatchIntenseFinishDialog> createState() =>
      _MatchIntenseFinishDialogState();
}

class _MatchIntenseFinishDialogState extends State<MatchIntenseFinishDialog> {
  final TrainingIntenseSyncService _syncService = TrainingIntenseSyncService();

  bool _loading = true;
  bool _syncing = false;
  bool _finished = false;
  String? _loadError;

  List<IntenseTrainingDeviceTarget> _targets = <IntenseTrainingDeviceTarget>[];
  TrainingIntenseTimeWindow? _window;
  FieldGpsCorners? _fieldGpsCorners;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final matchId = widget.match.id?.trim() ?? '';
      if (matchId.isEmpty) {
        throw StateError('Match id missing');
      }

      MatchCompo? compo =
          await MatchCompoService().getFirstMatchCompoByMatchId(matchId);
      if (compo == null) {
        throw StateError('Composition introuvable pour ce match.');
      }

      final liveTargets = await IntenseLiveDataService().loadMatchTargets(
        match: widget.match,
        compo: compo,
      );

      // Fallback: include all composed players with a tracker even if
      // convocation presence list is empty (same devices as Live).
      final targets = <IntenseTrainingDeviceTarget>[];
      if (liveTargets.isNotEmpty) {
        for (final t in liveTargets) {
          targets.add(
            IntenseTrainingDeviceTarget(
              playerId: t.playerId,
              playerLabel: _playerLabel(t.player, t.playerId),
              trackerLabel: t.trackerLabel,
              insidersDeviceId: t.insidersDeviceId,
              trackerId: t.trackerId,
              deviceOwnerDocId: t.deviceOwnerDocId,
            ),
          );
        }
      } else {
        final playerService = PlayerService();
        for (final playerCompo in allPlayersFromCompo(compo)) {
          final playerId = playerCompo.playerID?.trim();
          final deviceOwnerDocId = playerCompo.deviceOwnerId?.trim();
          if (playerId == null ||
              playerId.isEmpty ||
              deviceOwnerDocId == null ||
              deviceOwnerDocId.isEmpty) {
            continue;
          }
          final player = await playerService.getPlayerById(playerId);
          final custom = playerCompo.customName?.trim();
          targets.add(
            IntenseTrainingDeviceTarget(
              playerId: playerId,
              playerLabel: _playerLabel(player, playerId),
              trackerLabel: (custom != null && custom.isNotEmpty)
                  ? custom
                  : deviceOwnerDocId,
              insidersDeviceId: '',
              trackerId: custom ?? deviceOwnerDocId,
              deviceOwnerDocId: deviceOwnerDocId,
            )..stage = IntenseDeviceSyncStage.error
              ..errorMessage =
                  'Identifiant Insiders introuvable pour ce capteur.',
          );
        }
      }

      if (!mounted) return;

      final corners =
          await FieldGpsLocalizationHelper.ensureMatchFieldGpsCorners(
        context,
        match: widget.match,
      );
      if (!mounted) return;

      final window = widget.resync
          ? resolveMatchIntenseResyncWindow(widget.match, widget.highlights)
          : resolveMatchIntenseFinishWindow(
              widget.match,
              widget.highlights,
              syncStopAt: widget.syncStopAt,
            );
      if (window == null) {
        throw StateError(
          'Fenêtre de sync invalide (coup d\'envoi / coup de sifflet final).',
        );
      }

      setState(() {
        _targets = targets;
        _window = window;
        _fieldGpsCorners = corners;
        _loading = false;
      });

      if (targets.isNotEmpty &&
          targets.any((t) => t.insidersDeviceId.trim().isNotEmpty)) {
        await _runSync();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  String _playerLabel(Player? player, String fallbackId) {
    if (player == null) return fallbackId;
    final full =
        '${player.firstName ?? ''} ${player.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : fallbackId;
  }

  bool get _allDone =>
      _targets.isNotEmpty &&
      _targets.every((t) => t.stage == IntenseDeviceSyncStage.done);

  bool get _hasErrors =>
      _targets.any((t) => t.stage == IntenseDeviceSyncStage.error);

  Future<void> _runSync({bool retry = false}) async {
    if (_syncing || _window == null) return;
    final matchId = widget.match.id?.trim() ?? '';
    if (matchId.isEmpty) return;

    setState(() {
      _syncing = true;
      _finished = false;
    });

    for (final target in _targets) {
      if (target.insidersDeviceId.trim().isEmpty) {
        target.stage = IntenseDeviceSyncStage.error;
        target.errorMessage ??=
            'Identifiant Insiders manquant pour ${target.trackerLabel}.';
        continue;
      }
      if (target.stage == IntenseDeviceSyncStage.done) continue;
      if (!retry && target.stage == IntenseDeviceSyncStage.error) continue;
      if (retry && target.stage == IntenseDeviceSyncStage.error) {
        target
          ..stage = IntenseDeviceSyncStage.pending
          ..errorMessage = null
          ..progress = 0;
      }

      try {
        await _syncService.syncMatchDevice(
          target: target,
          matchId: matchId,
          window: _window!,
          fieldGpsCorners: _fieldGpsCorners,
          onProgress: (_) {
            if (mounted) setState(() {});
          },
        );
      } catch (_) {
        if (mounted) setState(() {});
      }

      if (target != _targets.last) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    if (!mounted) return;

    if (_allDone) {
      try {
        if (widget.resync) {
          // withSyncing=false re-sync: mark uploaded once the calendar slot
          // (timestamp + duration + 15' break) is over and every device reached `done`.
          await finalizeMatchIntenseResyncSuccess(match: widget.match);
        } else {
          await markMatchTrackerDataUploadedAfterIntenseSync(
            match: widget.match,
          );
        }
        setState(() {
          _finished = true;
          _syncing = false;
        });
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
        return;
      } catch (e) {
        setState(() {
          _loadError = e.toString();
          _syncing = false;
        });
        return;
      }
    }

    setState(() => _syncing = false);
  }

  String _stageLabel(BuildContext context, IntenseTrainingDeviceTarget target) {
    final l10n = context.l10n;
    switch (target.stage) {
      case IntenseDeviceSyncStage.pending:
        return l10n.trainingIntenseFinishStagePending;
      case IntenseDeviceSyncStage.fetching:
        return l10n.trainingIntenseFinishStageFetching;
      case IntenseDeviceSyncStage.converting:
        return l10n.trainingIntenseFinishStageConverting;
      case IntenseDeviceSyncStage.analyzing:
        return l10n.trainingIntenseFinishStageAnalyzing;
      case IntenseDeviceSyncStage.done:
        return l10n.trainingIntenseFinishStageDone;
      case IntenseDeviceSyncStage.error:
        return target.errorMessage ?? l10n.trainingIntenseFinishStageError;
    }
  }

  Color _stageColor(AppColors colors, IntenseDeviceSyncStage stage) {
    switch (stage) {
      case IntenseDeviceSyncStage.done:
        return colors.success;
      case IntenseDeviceSyncStage.error:
        return colors.danger;
      case IntenseDeviceSyncStage.pending:
        return colors.textSecondary;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
        widget.resync
            ? l10n.trainingIntenseResyncTitle
            : l10n.trainingIntenseFinishTitle,
      ),
      content: SizedBox(
        width: 420,
        child: _buildContent(context, colors),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      actions: [
        TextButton(
          onPressed: _syncing
              ? null
              : () => Navigator.of(context, rootNavigator: true).pop(false),
          child: Text(l10n.actionCancel),
        ),
        if (_hasErrors && !_syncing)
          TextButton(
            onPressed: () => _runSync(retry: true),
            child: Text(l10n.actionRetry),
          ),
        if (_targets.isEmpty && !_loading && !widget.resync)
          TextButton(
            onPressed: _syncing
                ? null
                : () async {
                    await markMatchTrackerDataUploadedAfterIntenseSync(
                      match: widget.match,
                    );
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    }
                  },
            child: Text(l10n.actionValidate),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppColors colors) {
    final l10n = context.l10n;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Text(
        _loadError!,
        style: TextStyle(color: colors.danger),
      );
    }

    if (_targets.isEmpty) {
      return Text(l10n.trainingIntenseFinishNoTrackers);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.resync
              ? l10n.trainingIntenseResyncMessage
              : l10n.trainingIntenseFinishMessage,
          style: TextStyle(color: colors.textSecondary),
        ),
        if (_syncing) ...[
          const SizedBox(height: 12),
          Text(
            l10n.trainingIntenseFinishSyncing,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _targets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final target = _targets[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.playerLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.trackerLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (target.stage != IntenseDeviceSyncStage.done &&
                        target.stage != IntenseDeviceSyncStage.error &&
                        target.stage != IntenseDeviceSyncStage.pending)
                      LinearProgressIndicator(value: target.progress)
                    else
                      Text(
                        _stageLabel(context, target),
                        style: TextStyle(
                          color: _stageColor(colors, target.stage),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_hasErrors && !_syncing && !_finished) ...[
          const SizedBox(height: 12),
          Text(
            l10n.trainingIntenseFinishPartialError,
            style: TextStyle(color: colors.danger, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
