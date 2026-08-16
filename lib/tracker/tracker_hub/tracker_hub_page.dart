import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/session_feeling_notification_service.dart';
import 'package:grinta/services/trainingService.dart';

import '../../model/player.dart';
import '../../model/tracker/eventSync.dart';
import '../../model/tracker/trackerData.dart';
import '../../model/training.dart';
import '../../services/pitch_heatmap_builder.dart';
import '../../services/playerService.dart';
import '../../widget/playerPhoto.dart';
import '../../services/sensorAnalysisService.dart';
import '../../services/teamWorkloadSummaryService.dart';
import '../../services/trackerDataAnalysisService.dart';
import '../../util/heatmap_svg_generator.dart';
import '../../util/match_heatmap_service.dart';
import '../../widget/asi_converter_screen.dart';
import '../../model/timeRange.dart';
import '../../model/trackerDeviceRaw.dart';
import '../../usb/asi_models.dart';
import '../../usb/asi_protocol.dart';
import '../../usb/asi_usb_client.dart';
import '../../usb/asi_usb_factory.dart';
import '../../util/app_theme.dart';
import '../../util/match_usb_sync_window.dart';
import '../../util/training_usb_sync_window.dart';
import '../../widget/proPitchView.dart';

part 'tracker_hub_cards.dart';
part 'tracker_hub_downloader.dart';

class TrackerHubPage extends StatefulWidget {
  final List<String> trackerIds;
  final String eventId;
  final bool isMatch;
  final FieldGpsCorners? fieldGpsCorners;
  final Map<String,String> devicePlayerMap;
  final String ownerId;

  const TrackerHubPage({
    super.key,
    required this.trackerIds,
    required this.eventId,
    required this.isMatch,
    this.fieldGpsCorners,
    required this.devicePlayerMap,
    required this.ownerId,
  });

  @override
  State<TrackerHubPage> createState() => _TrackerHubPageState();
}

class _TrackerHubPageState extends State<TrackerHubPage> {
  String? selectedTrackerId;

  List<TimeRange> matchPeriods = [];

  bool isDataLoaded = false;

  StreamSubscription<EventSync?>? _eventSyncSub;
  EventSync? eventSync;
  User? user;


  bool _allowPop = false;

  late final List<String> _validTrackerIds;
  late final Map<String, String> _validDevicePlayerMap;

  @override
  void initState() {
    super.initState();
    _validTrackerIds = widget.trackerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    _validDevicePlayerMap = {
      for (final trackerId in _validTrackerIds)
        if (widget.devicePlayerMap[trackerId] != null)
          trackerId: widget.devicePlayerMap[trackerId]!,
    };
    _initEventSyncAndListen();
    user = FirebaseAuth.instance.currentUser;
    debugPrint('isMatch=${widget.isMatch} trackerIds=$_validTrackerIds');
  }

  @override
  void dispose() {
    _eventSyncSub?.cancel();
    super.dispose();
  }


  Future<void> _initEventSyncAndListen() async {
    await _ensureEventSyncExists();
    _listenEventSync();
    getData();
  }

  Future<void> _ensureEventSyncExists() async {
    final existing = await EventSyncService().getEventSync(widget.eventId);

    if (existing != null) {
      eventSync = existing;
      return;
    }

    final Map<String, DeviceSync> devices = {};

    for (final entry in _validDevicePlayerMap.entries) {
      final trackerId = entry.key.trim();
      if (trackerId.isEmpty) continue;
      devices[trackerId] = DeviceSync(deviceId: trackerId);
    }

    final newEventSync = EventSync(
      eventId: widget.eventId,
      devices: devices,
      syncStartUid: user!.uid,
      syncStartAt: Timestamp.now(),
    );

    await EventSyncService().createOrUpdateEventSync(newEventSync);
    eventSync = newEventSync;
  }

  void _listenEventSync() {
    _eventSyncSub?.cancel();

    _eventSyncSub = EventSyncService()
        .streamEventSync(widget.eventId)
        .listen((data) {
      if (!mounted) return;

      setState(() {
        eventSync = data;
      });
    });
  }


  Future<void> getData() async {
    final List<TimeRange> periods = <TimeRange>[];

    if (widget.isMatch) {
      // USB / withSyncing=true:
      // - Temps forts kickOff+end → those bounds (halves when available)
      // - else scheduled halves: [timestamp, +duration/2] then
      //   [+duration/2 + 15min, +duration + 15min]
      // Never use TimeRange(null,null): that collapses to now→now and drops
      // every sample so "Télécharger" spins then resets.
      final match = await MatchService().getMatchById(widget.eventId);
      final hls = await HighlightsService()
          .getHighlightsByMatchCalendarId(widget.eventId);
      if (match == null) {
        debugPrint(
          '[TrackerHub] match USB sync: match missing '
          '(eventId=${widget.eventId}) — samples will NOT be time-filtered',
        );
      } else {
        final resolved = resolveMatchUsbSyncPeriods(
          match: match,
          highlights: hls,
        );
        if (resolved.isEmpty) {
          debugPrint(
            '[TrackerHub] match USB sync window missing '
            '(eventId=${widget.eventId} timestamp=${match.timestamp} '
            'duration=${match.duration} highlights=${hls.length}) '
            '— samples will NOT be time-filtered',
          );
        } else {
          for (final p in resolved) {
            debugPrint(
              '[TrackerHub] match USB sync window → '
              'start=${p.start.toDate().toIso8601String()} '
              'end=${p.end.toDate().toIso8601String()}',
            );
          }
          periods.addAll(resolved);
        }
      }
    } else {
      // USB / withSyncing=true: keep only samples inside the training slot
      // [dateTime, dateTime + duration], otherwise previous pod sessions leak in.
      final training = await TrainingService().getTrainingById(widget.eventId);
      final resolved = training == null
          ? const <TimeRange>[]
          : resolveTrainingUsbSyncPeriods(training);
      if (resolved.isEmpty) {
        debugPrint(
          '[TrackerHub] training USB sync window missing '
          '(eventId=${widget.eventId} dateTime=${training?.dateTime} '
          'duration=${training?.duration}) — samples will NOT be time-filtered',
        );
      } else {
        final p = resolved.first;
        debugPrint(
          '[TrackerHub] training USB sync window → '
          'start=${p.start.toDate().toIso8601String()} '
          'end=${p.end.toDate().toIso8601String()} '
          '(${training?.duration} min)',
        );
        periods.addAll(resolved);
      }
    }

    if (!mounted) return;
    setState(() {
      matchPeriods = periods;
      isDataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmCloseSync();
      },
      child: Scaffold(
        backgroundColor: colors!.background,
        appBar: AppBar(
          title: Text(
            context.l10n.trackerSyncTitle,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: !isDataLoaded
            ? Center(
          child: CircularProgressIndicator(
            color: colors.textPrimary,
          ),
        )
            : SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;

              final remainingIds = <String>[];
              final syncedIds = <String>[];
              for (final trackerId in _validTrackerIds) {
                final deviceSync = eventSync?.devices[trackerId];
                if (deviceSync?.isSynced == true) {
                  syncedIds.add(trackerId);
                } else {
                  remainingIds.add(trackerId);
                }
              }

              final trackerGrid = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      context.l10n.trackerAvailableSensors,
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
                        syncedIds.length,
                        _validTrackerIds.length,
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _validTrackerIds.isEmpty
                        ? const _TrackerEmptyState()
                        : ListView(
                      padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        if (remainingIds.isNotEmpty) ...[
                          _TrackerSectionHeader(
                            title: context.l10n.trackerSensorsRemaining,
                            count: remainingIds.length,
                            accent: colors.warning,
                          ),
                          const SizedBox(height: 12),
                          _TrackerSectionGrid(
                            trackerIds: remainingIds,
                            maxWidth: constraints.maxWidth,
                            selectedTrackerId: selectedTrackerId,
                            devicePlayerMap: _validDevicePlayerMap,
                            eventSync: eventSync,
                            periods: matchPeriods,
                            onSelect: (trackerId) {
                              setState(() {
                                selectedTrackerId = trackerId;
                              });
                            },
                            onAlreadySynced: () =>
                                showAlreadySyncedAlert(context),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (syncedIds.isNotEmpty) ...[
                          _TrackerSectionHeader(
                            title:
                                context.l10n.trackerSensorsAlreadySynced,
                            count: syncedIds.length,
                            accent: colors.success,
                          ),
                          const SizedBox(height: 12),
                          _TrackerSectionGrid(
                            trackerIds: syncedIds,
                            maxWidth: constraints.maxWidth,
                            selectedTrackerId: selectedTrackerId,
                            devicePlayerMap: _validDevicePlayerMap,
                            eventSync: eventSync,
                            periods: matchPeriods,
                            onSelect: (trackerId) {
                              setState(() {
                                selectedTrackerId = trackerId;
                              });
                            },
                            onAlreadySynced: () =>
                                showAlreadySyncedAlert(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );

              final detailPanel = _TrackerDetailPanel(
                trackerId: selectedTrackerId,
                periods: matchPeriods,
                isMatch: widget.isMatch,
                eventId: widget.eventId,
                fieldGpsCorners: widget.fieldGpsCorners,
                playerId: selectedTrackerId == null
                    ? null
                    : _validDevicePlayerMap[selectedTrackerId],
                eventSync: eventSync,
                ownerId: widget.ownerId,
              );

              if (isMobile) {
                return Column(
                  children: [
                    Expanded(flex: 5, child: trackerGrid),
                    Container(height: 1, color: colors.border),
                    Expanded(flex: 6, child: detailPanel),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 5, child: trackerGrid),
                  Container(width: 1, color: colors.border),
                  Expanded(flex: 6, child: detailPanel),
                ],
              );
            },
          ),
        ),
      ),
    );
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

    // Dismissing the dialog cancels leave; Non leaves without permanent close.
    if (shouldClosePermanently == null) return;

    if (shouldClosePermanently) {
      final trackerAnalysis =
          await TrackerAnalysisService.getAnalysesByEvent(widget.eventId);
      final service = TeamWorkloadSummaryService();

      final summary = await service.computeAndSave(
        eventId: widget.eventId,
        playerResults: trackerAnalysis,
        sessionDuration: const Duration(minutes: 90),
      );

      await service.save(summary);

      final uid = user?.uid;
      final current = eventSync ??
          await EventSyncService().getEventSync(widget.eventId) ??
          EventSync(eventId: widget.eventId);
      final closed = current.copyWith(
        docId: current.docId ?? widget.eventId,
        isFullySynced: true,
        syncEndAt: Timestamp.now(),
        syncEndUid: uid,
      );
      await EventSyncService().createOrUpdateEventSync(closed);
      if (uid != null && uid.isNotEmpty) {
        await EventSyncService().endSync(eventId: widget.eventId, uid: uid);
      }

      if (widget.isMatch == true) {
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
    _allowPop = true;
    Navigator.of(context).pop();
  }

  Future<void> showAlreadySyncedAlert(BuildContext context) async {
    final colors = context.appColors;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trackerAlreadySyncedTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.l10n.trackerAlreadySyncedMessage,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.actionOk),
              ),
            ),
          ],
        );
      },
    );
  }

}

int _getCrossAxisCount(double width) {
  if (width < 430) return 1;
  if (width < 700) return 2;
  if (width < 1000) return 3;
  if (width < 1400) return 4;
  return 5;
}

double _getChildAspectRatio(double width) {
  if (width < 430) return 0.72;
  if (width < 700) return 0.78;
  if (width < 1000) return 0.86;
  if (width < 1400) return 0.92;
  return 0.96;
}
