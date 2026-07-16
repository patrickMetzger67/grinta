import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/team_players/training_team_players_tracker.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/insiders_device_resolver.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// Dialog shown when finishing (or re-syncing) a training with Intense/SIM
/// trackers ([Owner.withSyncing] == false): lists present players, syncs each
/// assigned device via Insiders API, then marks the training finished on full
/// success (finish mode) or refreshes team workload (resync mode).
class TrainingIntenseFinishDialog extends StatefulWidget {
  const TrainingIntenseFinishDialog({
    super.key,
    required this.training,
    required this.syncStopAt,
    this.resync = false,
  });

  final Training training;
  final DateTime syncStopAt;
  final bool resync;

  static Future<bool?> show(
    BuildContext context, {
    required Training training,
    bool resync = false,
  }) {
    final syncStopAt = resync
        ? (training.trainingEndAt?.toDate() ?? DateTime.now())
        : DateTime.now();
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => TrainingIntenseFinishDialog(
        training: training,
        syncStopAt: syncStopAt,
        resync: resync,
      ),
    );
  }

  @override
  State<TrainingIntenseFinishDialog> createState() =>
      _TrainingIntenseFinishDialogState();
}

class _TrainingIntenseFinishDialogState extends State<TrainingIntenseFinishDialog> {
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
      final trainingId =
          widget.training.docId?.trim() ?? widget.training.trainingId?.trim();
      if (trainingId == null || trainingId.isEmpty) {
        throw StateError('Training id missing');
      }

      final trackerContext =
          await TrainingTrackerContext.loadForTraining(widget.training);
      if (trackerContext == null) {
        throw StateError('Tracker context unavailable');
      }

      final playerService = PlayerService();
      final targets = <IntenseTrainingDeviceTarget>[];

      for (final pt in widget.training.playerTraining) {
        if (!isPresentOrDefaultPresence(pt.presenceType)) continue;

        final playerId = pt.playerId?.trim();
        if (playerId == null || playerId.isEmpty) continue;

        final deviceOwnerDocId = pt.deviceId?.trim();
        if (deviceOwnerDocId == null || deviceOwnerDocId.isEmpty) continue;

        final deviceOwner = trackerContext.ownerDeviceByDocId[deviceOwnerDocId];
        if (deviceOwner == null) continue;

        final player = await playerService.getPlayerById(playerId);
        final playerLabel = _playerLabel(player, playerId);
        final trackerLabel = trackerContext.displayLabel(pt);
        final trackerId = trackerIdForAnalysis(deviceOwner);
        final resolution = resolveInsidersDeviceIdentifierFromOwner(deviceOwner);

        if (trackerId.isEmpty) continue;
        if (resolution == null || resolution.identifier.isEmpty) {
          debugPrint(
            '[TrainingIntenseFinish] unresolved identifier for '
            'deviceOwnerDocId=$deviceOwnerDocId tracker=$trackerLabel '
            'deviceOwner.deviceId=${deviceOwner.deviceId}',
          );
          targets.add(
            IntenseTrainingDeviceTarget(
              playerId: playerId,
              playerLabel: playerLabel,
              trackerLabel: trackerLabel,
              insidersDeviceId: '',
              trackerId: trackerId,
              deviceOwnerDocId: deviceOwnerDocId,
              deviceOwnerDeviceId: deviceOwner.deviceId.trim(),
            )..stage = IntenseDeviceSyncStage.error
              ..errorMessage =
                  'Identifiant Insiders introuvable pour le capteur « $trackerLabel ». '
                  'Vérifiez que deviceId (identifiant numérique Insiders) est '
                  'renseigné dans TRACKER_DeviceOwner.',
          );
          continue;
        }

        final insidersDeviceId = resolution.identifier;
        final deviceOwnerDeviceId = deviceOwner.deviceId.trim();
        debugPrint(
          '[TrainingIntenseFinish] resolved Insiders identifier for '
          'tracker=$trackerLabel → insidersDeviceId=$insidersDeviceId '
          'deviceOwner.deviceId=$deviceOwnerDeviceId '
          '(field=${resolution.fieldUsed.name}, deviceOwnerDocId=$deviceOwnerDocId)',
        );

        targets.add(
          IntenseTrainingDeviceTarget(
            playerId: playerId,
            playerLabel: playerLabel,
            trackerLabel: trackerLabel,
            insidersDeviceId: insidersDeviceId,
            trackerId: trackerId,
            deviceOwnerDocId: deviceOwnerDocId,
            deviceOwnerDeviceId: deviceOwnerDeviceId,
          ),
        );
      }

      FieldGpsCorners? fieldGpsCorners;
      final fieldId = widget.training.fieldId?.trim();
      if (fieldId != null && fieldId.isNotEmpty) {
        final trackerField =
            await TrackerFieldService().getById(fieldId);
        fieldGpsCorners = trackerField?.fieldGpsCorners;
      }

      final window = widget.resync
          ? resolveTrainingIntenseResyncWindow(widget.training)
          : resolveTrainingIntenseTimeWindow(
              widget.training,
              syncStopAt: widget.syncStopAt,
            );
      if (window == null) {
        throw StateError(
          'Fenêtre de sync invalide (dateTime / trainingEndAt manquants).',
        );
      }

      if (!mounted) return;
      setState(() {
        _targets = targets;
        _window = window;
        _fieldGpsCorners = fieldGpsCorners;
        _loading = false;
      });

      if (targets.isNotEmpty) {
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

    setState(() {
      _syncing = true;
      _finished = false;
    });

    for (final target in _targets) {
      if (target.stage == IntenseDeviceSyncStage.done) continue;
      if (!retry && target.stage == IntenseDeviceSyncStage.error) continue;
      if (retry && target.stage == IntenseDeviceSyncStage.error) {
        target
          ..stage = IntenseDeviceSyncStage.pending
          ..errorMessage = null
          ..progress = 0;
      }

      debugPrint(
        '[TrainingIntenseFinish] sync start → '
        'player=${target.playerLabel} tracker=${target.trackerLabel} '
        'insidersDeviceId=${target.insidersDeviceId} trackerId=${target.trackerId}',
      );

      try {
        await _syncService.syncDevice(
          target: target,
          training: widget.training,
          window: _window!,
          fieldGpsCorners: _fieldGpsCorners,
          onProgress: (updated) {
            debugPrint(
              '[TrainingIntenseFinish] stage → '
              'tracker=${updated.trackerLabel} '
              'stage=${updated.stage.name} progress=${updated.progress}',
            );
            if (mounted) setState(() {});
          },
        );
        debugPrint(
          '[TrainingIntenseFinish] sync done → tracker=${target.trackerLabel}',
        );
      } catch (_) {
        debugPrint(
          '[TrainingIntenseFinish] sync error → '
          'tracker=${target.trackerLabel} '
          'errorMessage=${target.errorMessage}',
        );
        if (mounted) setState(() {});
      }
    }

    if (!mounted) return;

    if (_allDone) {
      try {
        if (widget.resync) {
          final trainingId = widget.training.docId?.trim() ??
              widget.training.trainingId?.trim() ??
              '';
          if (trainingId.isNotEmpty) {
            await computeTeamWorkloadSummaryForEvent(
              eventId: trainingId,
              training: widget.training,
            );
          }
        } else {
          await finishTrainingAfterConfirm(
            training: widget.training,
            markTrackerDataUploaded: true,
            aggregateTeamWorkload: true,
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
            onPressed: () async {
              try {
                await finishTrainingAfterConfirm(
                  training: widget.training,
                  markTrackerDataUploaded: true,
                );
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(true);
                }
              } catch (_) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(false);
                }
              }
            },
            child: Text(
              l10n.finishTrainingTitle,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        const SizedBox(height: 16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _targets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final target = _targets[index];
              final stageColor = _stageColor(colors, target.stage);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.playerLabel,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    target.trackerLabel,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: target.stage == IntenseDeviceSyncStage.pending
                          ? null
                          : target.progress.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: colors.border,
                      color: stageColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stageLabel(context, target),
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_syncing) ...[
          const SizedBox(height: 12),
          Text(
            l10n.trainingIntenseFinishSyncing,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
        if (_hasErrors && !_syncing) ...[
          const SizedBox(height: 12),
          Text(
            l10n.trainingIntenseFinishPartialError,
            style: TextStyle(color: colors.danger, fontSize: 12),
          ),
        ],
        if (_finished) ...[
          const SizedBox(height: 12),
          Text(
            widget.resync
                ? l10n.trainingIntenseResyncSuccess
                : l10n.trainingFinished,
            style: TextStyle(color: colors.success, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
