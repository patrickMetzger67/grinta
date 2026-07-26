import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/device.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/eventSync.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/polar_session_import_service.dart';
import 'package:grinta/services/session_feeling_notification_service.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/playerPhoto.dart';

/// End-of-session Polar kit import hub (cardio → `TRACKER_PolarAnalysis`).
class PolarImportHubPage extends StatefulWidget {
  const PolarImportHubPage({
    super.key,
    required this.trackerIds,
    required this.eventId,
    required this.isMatch,
    required this.devicePlayerMap,
    required this.ownerId,
    required this.eventAt,
  });

  final List<String> trackerIds;
  final String eventId;
  final bool isMatch;
  final Map<String, String> devicePlayerMap;
  final String ownerId;
  final DateTime eventAt;

  @override
  State<PolarImportHubPage> createState() => _PolarImportHubPageState();
}

class _PolarImportHubPageState extends State<PolarImportHubPage> {
  final PolarSessionImportService _import = PolarSessionImportService();
  final EventSyncService _eventSync = EventSyncService();
  final PlayerService _players = PlayerService();

  StreamSubscription<EventSync?>? _eventSyncSub;
  EventSync? _eventSyncDoc;
  User? _user;
  String? _selectedTrackerId;
  bool _busy = false;
  bool _allowPop = false;

  late final List<String> _validTrackerIds;
  late final Map<String, String> _validDevicePlayerMap;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _validTrackerIds = widget.trackerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    _validDevicePlayerMap = {
      for (final trackerId in _validTrackerIds)
        if (widget.devicePlayerMap[trackerId] != null)
          trackerId: widget.devicePlayerMap[trackerId]!,
    };
    _init();
  }

  Future<void> _init() async {
    final uid = _user?.uid ?? '';
    final sync = await _import.ensureEventSync(
      eventId: widget.eventId,
      devicePlayerMap: _validDevicePlayerMap,
      uid: uid,
    );
    if (!mounted) return;
    setState(() => _eventSyncDoc = sync);
    _eventSyncSub = _eventSync.streamEventSync(widget.eventId).listen((data) {
      if (!mounted || data == null) return;
      setState(() => _eventSyncDoc = data);
    });
  }

  @override
  void dispose() {
    _eventSyncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final remaining = <String>[];
    final synced = <String>[];
    for (final id in _validTrackerIds) {
      if (_eventSyncDoc?.devices[id]?.isSynced == true) {
        synced.add(id);
      } else {
        remaining.add(id);
      }
    }

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmCloseSync();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            context.l10n.polarImportTitle,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              final list = _buildDeviceList(
                colors: colors,
                textTheme: textTheme,
                remaining: remaining,
                synced: synced,
              );
              final detail = _buildDetailPanel(colors: colors);

              if (isMobile) {
                return Column(
                  children: [
                    Expanded(flex: 5, child: list),
                    Container(height: 1, color: colors.border),
                    Expanded(flex: 6, child: detail),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 5, child: list),
                  Container(width: 1, color: colors.border),
                  Expanded(flex: 6, child: detail),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList({
    required AppColors colors,
    required TextTheme textTheme,
    required List<String> remaining,
    required List<String> synced,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            context.l10n.polarImportSensorsHeader,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.l10n.trackerSyncedProgress(
              synced.length,
              _validTrackerIds.length,
            ),
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.l10n.polarImportHint,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _validTrackerIds.isEmpty
              ? Center(child: Text(context.l10n.emptyNoTrackers))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (remaining.isNotEmpty) ...[
                      _sectionLabel(
                        context.l10n.trackerSensorsRemaining,
                        remaining.length,
                        colors.warning,
                      ),
                      const SizedBox(height: 8),
                      ...remaining.map(_deviceTile),
                      const SizedBox(height: 20),
                    ],
                    if (synced.isNotEmpty) ...[
                      _sectionLabel(
                        context.l10n.trackerSensorsAlreadySynced,
                        synced.length,
                        colors.success,
                      ),
                      const SizedBox(height: 8),
                      ...synced.map(_deviceTile),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, int count, Color accent) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _deviceTile(String trackerId) {
    final colors = context.appColors;
    final playerId = _validDevicePlayerMap[trackerId] ?? '';
    final done = _eventSyncDoc?.devices[trackerId]?.isSynced == true;
    final selected = trackerId == _selectedTrackerId;

    return FutureBuilder<Player?>(
      future: playerId.isEmpty ? null : _players.getPlayerById(playerId),
      builder: (context, snap) {
        final player = snap.data;
        final name = _formatPlayerName(player);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (done) {
                  AppSnackbar.show(
                    context,
                    context.l10n.trackerAlreadySyncedTitle,
                  );
                  return;
                }
                setState(() => _selectedTrackerId = trackerId);
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: done
                      ? colors.success.withValues(alpha: 0.08)
                      : (selected
                          ? colors.primary.withValues(alpha: 0.10)
                          : colors.card),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: done
                        ? colors.success
                        : (selected ? colors.warning : colors.border),
                    width: (done || selected) ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: player == null
                      ? CircleAvatar(
                          backgroundColor: colors.border,
                          child: Icon(
                            Icons.favorite,
                            color: colors.textSecondary,
                            size: 18,
                          ),
                        )
                      : PlayerPhoto(player: player, radius: 20),
                  title: Text(
                    name.isEmpty ? trackerId : name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    done
                        ? context.l10n.polarImportStatusDone
                        : context.l10n.polarImportStatusPending,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  trailing: Icon(
                    done ? Icons.check_circle : Icons.chevron_right,
                    color: done ? colors.success : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel({required AppColors colors}) {
    final trackerId = _selectedTrackerId;
    if (trackerId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.polarImportSelectSensor,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ),
      );
    }

    final playerId = _validDevicePlayerMap[trackerId] ?? '';
    final bleSupported = _import.isBleImportSupported && !kIsWeb;

    return FutureBuilder<_PolarDetailBundle>(
      future: _loadDetail(trackerId, playerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final polarDeviceId = data.deviceOwner?.deviceId.trim().toUpperCase();
        final deviceType = (data.device?.deviceType ?? 'other').trim();
        final customName = data.deviceOwner?.customName?.trim();
        final playerName = _formatPlayerName(data.player);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              playerName.isEmpty
                  ? context.l10n.polarImportUntitledPlayer
                  : playerName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.polarImportDeviceLine(
                (polarDeviceId == null || polarDeviceId.isEmpty)
                    ? '—'
                    : polarDeviceId,
                deviceType.isEmpty ? 'other' : deviceType,
                (customName == null || customName.isEmpty) ? '—' : customName,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (bleSupported) ...[
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _runBleImport(
                          trackerId: trackerId,
                          playerId: playerId,
                        ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(context.l10n.polarImportBleAction),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                context.l10n.polarImportBleUnavailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _runManualImport(
                        trackerId: trackerId,
                        playerId: playerId,
                      ),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(context.l10n.polarImportManualAction),
            ),
          ],
        );
      },
    );
  }

  Future<_PolarDetailBundle> _loadDetail(
    String trackerId,
    String playerId,
  ) async {
    final deviceOwner = await _import.loadDeviceOwner(trackerId);
    final device = await _import.loadDeviceForTracker(trackerId);
    final player =
        playerId.isEmpty ? null : await _players.getPlayerById(playerId);
    return _PolarDetailBundle(
      deviceOwner: deviceOwner,
      device: device,
      player: player,
    );
  }

  Future<void> _runBleImport({
    required String trackerId,
    required String playerId,
  }) async {
    final uid = _user?.uid;
    if (uid == null || uid.isEmpty) return;
    if (playerId.isEmpty) {
      AppSnackbar.show(context, context.l10n.polarImportMissingPlayer);
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _import.importFromBle(
        eventId: widget.eventId,
        trackerId: trackerId,
        playerId: playerId,
        importedUid: uid,
        eventAt: widget.eventAt,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.polarImportSuccess(
          result.analysis.avgHrBpm?.toString() ?? '—',
          result.analysis.duration.inMinutes.toString(),
        ),
        isError: false,
      );
      setState(() => _selectedTrackerId = null);
    } catch (e, st) {
      debugPrint('[PolarImport] BLE failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.polarImportBleError(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runManualImport({
    required String trackerId,
    required String playerId,
  }) async {
    final uid = _user?.uid;
    if (uid == null || uid.isEmpty) return;
    if (playerId.isEmpty) {
      AppSnackbar.show(context, context.l10n.polarImportMissingPlayer);
      return;
    }

    final draft = await showDialog<_ManualPolarDraft>(
      context: context,
      builder: (ctx) => const _ManualPolarImportDialog(),
    );
    if (draft == null || !mounted) return;

    setState(() => _busy = true);
    try {
      const channel = kIsWeb
          ? PolarImportChannel.bleChrome
          : PolarImportChannel.manual;
      final result = await _import.importManual(
        eventId: widget.eventId,
        trackerId: trackerId,
        playerId: playerId,
        importedUid: uid,
        duration: Duration(minutes: draft.durationMinutes),
        avgHrBpm: draft.avgHr,
        maxHrBpm: draft.maxHr,
        minHrBpm: draft.minHr,
        caloriesKcal: draft.calories,
        distanceMeters: draft.distanceMeters,
        steps: draft.steps,
        channel: channel,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.polarImportSuccess(
          result.analysis.avgHrBpm?.toString() ?? '—',
          result.analysis.duration.inMinutes.toString(),
        ),
        isError: false,
      );
      setState(() => _selectedTrackerId = null);
    } catch (e, st) {
      debugPrint('[PolarImport] manual failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.polarImportBleError(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCloseSync() async {
    final shouldClosePermanently = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.dialogCloseSyncTitle),
        content: Text(dialogContext.l10n.dialogCloseSyncMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.actionYes),
          ),
        ],
      ),
    );

    if (shouldClosePermanently == null) return;

    if (shouldClosePermanently) {
      final uid = _user?.uid;
      final current = _eventSyncDoc ??
          await _eventSync.getEventSync(widget.eventId) ??
          EventSync(eventId: widget.eventId);
      final closed = current.copyWith(
        docId: current.docId ?? widget.eventId,
        isFullySynced: true,
        syncEndAt: Timestamp.now(),
        syncEndUid: uid,
      );
      await _eventSync.createOrUpdateEventSync(closed);
      if (uid != null && uid.isNotEmpty) {
        await _eventSync.endSync(eventId: widget.eventId, uid: uid);
      }

      if (widget.isMatch) {
        final match = await MatchService().getMatchById(widget.eventId);
        if (match != null) {
          match.isTrackerDataUploaded = true;
          await MatchService().updateMatch(match);
          if (mounted) {
            unawaited(
              SessionFeelingNotificationService().maybeNotifyAfterMatchSynced(
                match: match,
                l10n: context.l10n,
              ),
            );
          }
        }
      } else {
        final training =
            await TrainingService().getTrainingById(widget.eventId);
        if (training != null) {
          training.isTrackerDataUploaded = true;
          await TrainingService().updateTraining(training);
          if (mounted) {
            unawaited(
              SessionFeelingNotificationService()
                  .maybeNotifyAfterTrainingSynced(
                training: training,
                l10n: context.l10n,
              ),
            );
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  String _formatPlayerName(Player? player) {
    if (player == null) return '';
    final firstName = (player.firstName ?? '').trim();
    final lastName = (player.lastName ?? '').trim();
    final firstLetter =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final upperLast = lastName.toUpperCase();
    if (firstLetter.isNotEmpty && upperLast.isNotEmpty) {
      return '$firstLetter. $upperLast';
    }
    if (upperLast.isNotEmpty) return upperLast;
    return firstName;
  }
}

class _PolarDetailBundle {
  const _PolarDetailBundle({
    required this.deviceOwner,
    required this.device,
    required this.player,
  });

  final DeviceOwner? deviceOwner;
  final Device? device;
  final Player? player;
}

class _ManualPolarDraft {
  const _ManualPolarDraft({
    required this.durationMinutes,
    this.avgHr,
    this.maxHr,
    this.minHr,
    this.calories,
    this.distanceMeters,
    this.steps,
  });

  final int durationMinutes;
  final int? avgHr;
  final int? maxHr;
  final int? minHr;
  final double? calories;
  final double? distanceMeters;
  final int? steps;
}

class _ManualPolarImportDialog extends StatefulWidget {
  const _ManualPolarImportDialog();

  @override
  State<_ManualPolarImportDialog> createState() =>
      _ManualPolarImportDialogState();
}

class _ManualPolarImportDialogState extends State<_ManualPolarImportDialog> {
  final _duration = TextEditingController(text: '90');
  final _avg = TextEditingController();
  final _max = TextEditingController();
  final _min = TextEditingController();
  final _calories = TextEditingController();
  final _distance = TextEditingController();
  final _steps = TextEditingController();

  @override
  void dispose() {
    _duration.dispose();
    _avg.dispose();
    _max.dispose();
    _min.dispose();
    _calories.dispose();
    _distance.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.polarImportManualTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.polarImportManualSubtitle),
            const SizedBox(height: 12),
            _numField(_duration, context.l10n.polarImportFieldDurationMin),
            _numField(_avg, context.l10n.polarImportFieldAvgHr),
            _numField(_max, context.l10n.polarImportFieldMaxHr),
            _numField(_min, context.l10n.polarImportFieldMinHr),
            _numField(_calories, context.l10n.polarImportFieldCalories),
            _numField(_distance, context.l10n.polarImportFieldDistanceM),
            _numField(_steps, context.l10n.polarImportFieldSteps),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final minutes = int.tryParse(_duration.text.trim()) ?? 0;
            if (minutes <= 0) return;
            Navigator.of(context).pop(
              _ManualPolarDraft(
                durationMinutes: minutes,
                avgHr: int.tryParse(_avg.text.trim()),
                maxHr: int.tryParse(_max.text.trim()),
                minHr: int.tryParse(_min.text.trim()),
                calories: double.tryParse(
                  _calories.text.trim().replaceAll(',', '.'),
                ),
                distanceMeters: double.tryParse(
                  _distance.text.trim().replaceAll(',', '.'),
                ),
                steps: int.tryParse(_steps.text.trim()),
              ),
            );
          },
          child: Text(context.l10n.actionSave),
        ),
      ],
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
      ),
    );
  }
}
