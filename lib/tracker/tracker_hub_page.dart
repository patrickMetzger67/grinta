import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';

import '../model/player.dart';
import '../model/tracker/eventSync.dart';
import '../model/tracker/trackerData.dart';
import '../model/training.dart';
import '../services/pitch_heatmap_builder.dart';
import '../services/playerService.dart';
import '../services/sensorAnalysisService.dart';
import '../services/teamWorkloadSummaryService.dart';
import '../services/trackerDataAnalysisService.dart';
import '../util/heatmap_svg_generator.dart';
import '../widget/asi_converter_screen.dart';
import '../model/timeRange.dart';
import '../model/trackerDeviceRaw.dart';
import '../usb/asi_models.dart';
import '../usb/asi_usb_client.dart';
import '../usb/asi_usb_factory.dart';
import '../util/app_theme.dart';
import '../widget/proPitchView.dart';


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

  @override
  void initState() {
    super.initState();
    _initEventSyncAndListen();
    user = FirebaseAuth.instance.currentUser;
    debugPrint('isMatch=${widget.isMatch}');
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

    for (final entry in widget.devicePlayerMap.entries) {
      devices[entry.key] = DeviceSync(deviceId: entry.key);
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

    TimeRange firsthalf = TimeRange(start: null, end: null);
    TimeRange senddHalf = TimeRange(start: null, end: null);

    if(widget.isMatch) {
      final hls = await HighlightsService().getHighlightsByMatchCalendarId(widget.eventId);
      for(var hl in hls) {
        if(hl.actionType == ActionType.timeEvent) {
          final timeEvent = hl.value as TimeEvent;
          switch(timeEvent.type) {
            case  TimeType.kickOff: // début match
              firsthalf.start = hl.dateTime!;
              break;
            case TimeType.startExtraTime:
              break;
            case TimeType.halTime: // mi-temps
              firsthalf.end = hl.dateTime!;
              break;
            case TimeType.secondHalf: // debut 2ème mi-temps
              senddHalf.start = hl.dateTime!;
              break;
            case TimeType.end: // fin match
              senddHalf.end = hl.dateTime!;
              break;
            case null:
              throw UnimplementedError();

          }
        }
      }
      matchPeriods.add(firsthalf);
      matchPeriods.add(senddHalf);
    }

    setState(() {
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
            'Synchronisation des capteurs',
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

              final trackerGrid = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Capteurs disponibles',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${widget.trackerIds.length} tracker(s)',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: widget.trackerIds.isEmpty
                        ? const _TrackerEmptyState()
                        : GridView.builder(
                      padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: widget.trackerIds.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        _getCrossAxisCount(constraints.maxWidth),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                        _getChildAspectRatio(constraints.maxWidth),
                      ),
                      itemBuilder: (context, index) {
                        final trackerId = widget.trackerIds[index];
                        final isSelected =
                            trackerId == selectedTrackerId;

                        final isDone =
                            (eventSync!.devices[trackerId]!
                                .dataDownloaded &&
                                eventSync!
                                    .devices[trackerId]!.erased) ||
                                eventSync!
                                    .devices[trackerId]!.withAsiFile;

                        return _TrackerCard(
                          trackerId: trackerId,
                          isSelected: isSelected,
                          isDone: isDone,
                          periods: matchPeriods,
                          playerId:
                          widget.devicePlayerMap[trackerId]!,
                          onTap: () async {
                            if (isDone) {
                              await showAlreadySyncedAlert(context);
                              return;
                            }
                            setState(() {
                              selectedTrackerId = trackerId;
                            });
                          },
                        );
                      },
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
                playerId: widget.devicePlayerMap[selectedTrackerId],
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
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clôturer la synchronisation'),
        content: const Text('Souhaitez-vous clôturer la synchronisation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (shouldLeave != true) return;
    
    List<TrackerAnalysisResult> trackerAnalysis = await TrackerAnalysisService.getAnalysesByEvent(widget.eventId);
    final service = TeamWorkloadSummaryService();

    final summary = await service.computeAndSave(
      eventId: widget.eventId, // id du match ou de l'entraînement
      playerResults: trackerAnalysis,
      sessionDuration: const Duration(minutes: 90), // optionnel
    );

    await service.save(summary);

    if (widget.isMatch == true) {
      final match = await MatchService().getMatchById(widget.eventId);
      if (match != null) {
        match.isTrackerDataUploaded = true;
        await MatchService().updateMatch(match);
      }
    } else {
      final training = await TrainingService().getTrainingById(widget.eventId);
      if (training != null) {
        training.isTrackerDataUploaded = true;
        await TrainingService().updateTraining(training);
      }
    }

    if (!mounted) return;
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
                  'Synchronisation déjà effectuée',
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
            'Le capteur a déjà été synchronisé pour cette session.',
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
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
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
}


class _TrackerCard extends StatelessWidget {
  final String trackerId;
  final bool isSelected;
  final bool isDone;
  final VoidCallback onTap;
  final List<TimeRange> periods;
  final String playerId;

  const _TrackerCard({
    required this.trackerId,
    required this.isSelected,
    required this.isDone,
    required this.onTap,
    required this.periods,
    required this.playerId,
  });

  String _formatPlayerName(Player? player) {
    if (player == null) return '';

    final String firstName = (player.firstName ?? '').trim();
    final String lastName = (player.lastName ?? '').trim();

    final String firstLetter =
    firstName.isNotEmpty ? firstName[0].toUpperCase() : '';

    final String upperLastName = lastName.toUpperCase();

    if (firstLetter.isNotEmpty && upperLastName.isNotEmpty) {
      return '$firstLetter. $upperLastName';
    } else if (upperLastName.isNotEmpty) {
      return upperLastName;
    } else if (firstName.isNotEmpty) {
      return firstName;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final PlayerService playerService = PlayerService();

    return FutureBuilder<Player?>(
      future: playerService.getPlayerById(playerId),
      builder: (context, playerSnapshot) {
        final Player? player = playerSnapshot.data;
        final String playerName = _formatPlayerName(player);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.10)
                    : colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? colors.success : colors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            trackerId,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Flexible(
                      flex: 4,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 60,
                              maxHeight: 60,
                            ),
                            child: player == null
                                ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: isDone
                                        ? colors.success
                                        : colors.danger,
                                  ),
                                ),
                              ),
                            )
                                : FutureBuilder<String>(
                              future: playerService.getUrlPlayer(player,"portrait_1920x1920.jpg"),
                              builder: (context, photoSnapshot) {
                                final String? imageUrl = photoSnapshot.data;

                                if (imageUrl != null &&
                                    imageUrl.isNotEmpty) {
                                  return CircleAvatar(
                                    radius: 30,
                                    backgroundColor: colors.primary
                                        .withValues(alpha: 0.12),
                                    backgroundImage:
                                    NetworkImage(imageUrl),
                                  );
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: isDone
                                            ? colors.success
                                            : colors.danger,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (playerName.isNotEmpty)
                      Flexible(
                        flex: 2,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              playerName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Flexible(
                      flex: 3,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.success.withValues(alpha: 0.18)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                isSelected ? colors.success : colors.border,
                              ),
                            ),
                            child: Text(
                              isSelected
                                  ? 'Sélectionné'
                                  : (isDone ? 'Synchronisé' : 'Ouvrir'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: (isSelected || isDone)
                                    ? colors.success
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _TrackerDetailPanel extends StatelessWidget {
  final String? trackerId;
  final List<TimeRange> periods;
  final bool isMatch;
  final String eventId;
  final FieldGpsCorners? fieldGpsCorners;
  final String? playerId;
  final EventSync? eventSync;
  final String? ownerId;

  const _TrackerDetailPanel({
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
    required this.fieldGpsCorners,
    required this.playerId,
    required this.eventSync,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (trackerId == null) {
      return Container(
        color: colors.background,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gps_not_fixed_rounded,
                  size: 46,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun tracker sélectionné',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionne un tracker pour afficher les actions de connexion, téléchargement et effacement.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AsiDownloaderPanel(
      trackerId: trackerId!,
      periods: periods,
      isMatch: isMatch,
      eventId: eventId,
      fieldGpsCorners:fieldGpsCorners,
      playerId: playerId ?? '',
      eventSync: eventSync!,
      ownerId: ownerId,
    );
  }
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_off_rounded,
              size: 46,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun tracker à afficher',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AsiDownloaderPanel extends StatefulWidget {
  final String trackerId;
  final List<TimeRange> periods;
  final bool isMatch;
  final String eventId;
  final FieldGpsCorners? fieldGpsCorners;
  final String playerId;
  final EventSync eventSync;
  final String? ownerId;

  const AsiDownloaderPanel({
    super.key,
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
    required this.fieldGpsCorners,
    required this.playerId,
    required this.eventSync,
    required this.ownerId,
  });

  @override
  State<AsiDownloaderPanel> createState() => _AsiDownloaderPanelState();
}

class _AsiDownloaderPanelState extends State<AsiDownloaderPanel> {
  late final AsiUsbClient client;
  List<AsiDeviceInfo> availableDevices = [];
  AsiDeviceInfo? selectedDevice;
  AsiSession? session;

  String logs = '';
  bool loading = false;
  bool deviceConnected = false;
  bool dataDownloaded = false;
  bool dataErased = false;
  String? deviceId;

  FootballFieldGps? footballFieldGps;
  EventSync? eventSync;


  static const double _sprintThresholdKmh = 20.0;
  static const int _minSprintPoints = 4;

  @override
  void initState() {
    super.initState();
    eventSync = widget.eventSync;
    client = createAsiUsbClient();
    appendLog('Tracker sélectionné: ${widget.trackerId}');
  }

  @override
  void didUpdateWidget(covariant AsiDownloaderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackerId != widget.trackerId) {
      setState(() {
        logs = '';
        loading = false;
        availableDevices = [];
        selectedDevice = null;
        session = null;
        deviceId = null;
        deviceConnected = false;
        dataDownloaded = false;
        dataErased = false;
      });
      appendLog('Tracker sélectionné: ${widget.trackerId}');
    }
  }

  void appendLog(String text) {
    if (!mounted) return;
    setState(() {
      logs = '$logs$text\n';
    });
  }

  Future<String> convertAsiToCsv(Uint8List asiBytes) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('insidersConvertAsiToCsv');

    final result = await callable.call({
      'asiBase64': base64Encode(asiBytes),
      'filename': 'inspirit_data.ASI',
    });

    final data = Map<String, dynamic>.from(result.data['data'] as Map);
    return data['csv'] as String;
  }



  Future<void> loadAuthorizedDevices() async {
    setState(() => loading = true);

    try {
      final devices = await client.listDevices();

      setState(() {
        availableDevices = devices;
        if (devices.isNotEmpty && selectedDevice == null) {
          selectedDevice = devices.first;
        }
      });

      if (devices.isEmpty) {
        appendLog('Aucun périphérique autorisé');
      } else {
        appendLog('${devices.length} périphérique(s) autorisé(s) trouvé(s)');
        for (final d in devices) {
          appendLog('- ${d.productName ?? "Sans nom"} (${d.id})');
        }
      }
    } catch (e) {
      appendLog('Erreur lecture périphériques: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<String?> readDeviceIdInFreshSession() async {
    if (selectedDevice == null) return null;

    AsiSession? tempSession;

    try {
      tempSession = await client.open(selectedDevice!);
      final uuid = await client.readDeviceId(tempSession);
      return uuid;
    } catch (e) {
      appendLog('Lecture UUID impossible: $e');
      return null;
    } finally {
      if (tempSession != null) {
        try {
          await client.close(tempSession);
        } catch (_) {}
      }
    }
  }
  Future<void> connectDevice() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      AsiDeviceInfo? deviceToUse;

      // Si on a déjà un device sélectionné et qu'on est déjà connecté, on évite de redemander.
      if (selectedDevice != null && session == null) {
        deviceToUse = selectedDevice;
      }

      // Sinon on demande explicitement la permission utilisateur.
      if (deviceToUse == null) {
        final grantedDevice = await client.requestDevicePermission();

        if (grantedDevice == null) {
          appendLog('Aucun périphérique sélectionné dans la popup Chrome');
          return;
        }

        deviceToUse = grantedDevice;
        appendLog(
          'Autorisation accordée: ${deviceToUse.productName ?? deviceToUse.id}',
        );
      }

      // Ferme une ancienne session si besoin
      if (session != null) {
        try {
          await client.close(session!);
        } catch (_) {}
        session = null;
      }

      // IMPORTANT : ouvrir exactement le device renvoyé / retenu
      final openedSession = await client.open(deviceToUse);

      // Petit délai pour laisser le périphérique devenir réellement prêt
      await Future.delayed(const Duration(milliseconds: 1200));

      // Validation réelle du dialogue avec le device
      final uuid = await client.readDeviceId(openedSession);

      final deviceTmp = await DeviceService().getDeviceByDeviceName(uuid);
      if (deviceTmp == null) {
        appendLog('Tracker ${widget.trackerId} inexistant !');
        await client.close(openedSession);
        return;
      }

      final deviceOwner = await DeviceOwnerService().getByDeviceId(deviceTmp.id);
      if (deviceOwner == null ||
          (deviceOwner.customName?.trim() ?? '') != widget.trackerId.trim()) {
        appendLog('Le tracker branché ne correspond pas à celui sélectionné');
        await client.close(openedSession);
        return;
      }

      setState(() {
        session = openedSession;
        selectedDevice = deviceToUse;
        deviceConnected = true;
        deviceId = uuid;
        dataDownloaded = false;
        dataErased = false;

      });

      appendLog('UUID: $uuid');
      appendLog('Connecté: ${deviceToUse.productName ?? deviceToUse.id}');
    } catch (e, st) {
      setState(() {
        deviceConnected = false;
        session = null;
        deviceId = null;
      });
      appendLog('Erreur connexion: $e');
      debugPrint('CONNECT_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> download() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    bool success = false;

    try {
      final watch = Stopwatch()..start();

      await Future.delayed(const Duration(milliseconds: 500));

      final Uint8List data = await client.downloadData(session!);

      watch.stop();
      appendLog('Lecture RAW terminée en ${watch.elapsed.inSeconds}s');
      appendLog('Téléchargé: ${data.length} octets');
      appendLog('Hash OK');

      if (data.isEmpty) {
        appendLog('Pas de données');
        return;
      }

      if (deviceId == null || deviceId!.trim().isEmpty) {
        try {
          final uuid = await client.readDeviceId(session!);
          if (uuid.trim().isNotEmpty) {
            setState(() {
              deviceId = uuid;
            });
            appendLog('UUID: $uuid');
          }
        } catch (e) {
          appendLog('Lecture UUID impossible: $e');
        }
      }

      if (deviceId == null || deviceId!.trim().isEmpty) {
        appendLog('UUID introuvable, parsing annulé');
        return;
      }

      final String csv = await convertAsiToCsv(data);
      appendLog('CSV reçu (${csv.length} caractères)');

      final rawLines = csv
          .split(RegExp(r'\r\n|\n|\r'))
          .where((e) => e.trim().isNotEmpty)
          .toList();

      appendLog('Lignes brutes non vides: ${rawLines.length}');

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId!,
        periods: widget.periods,
      );

      appendLog('${rows.length} point(s) brut(s) parsé(s)');

      if (rows.isEmpty) {
        appendLog('Aucune donnée exploitable trouvée dans le CSV');
        return;
      }

      final trackerSamples = rows.map((row) {
        return TrackerRaw(
          trackerId: widget.trackerId,
          timeMs: row.timestamp.millisecondsSinceEpoch,
          latitude: row.latitude!,
          longitude: row.longitude!,
          speedMps: row.speed ?? 0,
        );
      }).toList(growable: false);

      if (widget.isMatch == true && widget.fieldGpsCorners != null) {
        footballFieldGps = FootballFieldGps.fromFieldGpsCorners(
          widget.fieldGpsCorners!,
        );
      } else {
        footballFieldGps = null;
      }

      final analysisResult = SensorAnalysisService.analyzeSensorData(
        trackerId: widget.trackerId,
        allSamples: trackerSamples,
        isMatch: widget.isMatch,
        playerId: widget.playerId,
        fieldGps: footballFieldGps,
        eventId: widget.eventId,
      );

      await TrackerAnalysisService.saveAnalysis(
        docId: '${widget.eventId}_${widget.trackerId}',
        analysisResult,
        eventId: widget.eventId,
        isMatch: widget.isMatch,
      );

      if (widget.isMatch == true && footballFieldGps != null) {
        final String svgFullMatch = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: analysisResult.heatmapPoints,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.trackerId}-${widget.eventId}_fullMatch',
          svg: svgFullMatch,
        );

        final fullMatchSprintPolylines = _buildSprintPolylines(trackerSamples);

        final String svgFullMatchWithSprints = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: analysisResult.heatmapPoints,
          sprintPolylines: fullMatchSprintPolylines,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.trackerId}-${widget.eventId}_fullMatchWithSprints',
          svg: svgFullMatchWithSprints,
        );

        final firstHalfSamples = _getSamplesForPeriod(
          period: _firstHalfPeriod,
          allTrackerSamples: trackerSamples,
        );

        final secondHalfSamples = _getSamplesForPeriod(
          period: _secondHalfPeriod,
          allTrackerSamples: trackerSamples,
        );

        TrackerAnalysisResult? firstHalfAnalysis;
        TrackerAnalysisResult? secondHalfAnalysis;

        if (firstHalfSamples.isNotEmpty) {
          firstHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: widget.trackerId,
            allSamples: firstHalfSamples,
            isMatch: widget.isMatch,
            playerId: widget.playerId,
            fieldGps: footballFieldGps,
            eventId: widget.eventId,
          );
        }

        if (secondHalfSamples.isNotEmpty) {
          secondHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: widget.trackerId,
            allSamples: secondHalfSamples,
            isMatch: widget.isMatch,
            playerId: widget.playerId,
            fieldGps: footballFieldGps,
            eventId: widget.eventId,
          );
        }

        const bool flipFirstHalfY = false;
        const bool flipSecondHalfY = false;

        if (firstHalfAnalysis != null) {
          final firstHalfPointsForDisplay = flipFirstHalfY
              ? _flipHeatmapPointsY(
            points: firstHalfAnalysis.heatmapPoints,
            field: footballFieldGps!,
          )
              : firstHalfAnalysis.heatmapPoints;

          final firstHalfSprintsRaw = _buildSprintPolylines(firstHalfSamples);

          final firstHalfSprintsForDisplay = flipFirstHalfY
              ? _flipPolylinesY(
            polylines: firstHalfSprintsRaw,
            field: footballFieldGps!,
          )
              : firstHalfSprintsRaw;

          final String svgFirstHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_firstHalf',
            svg: svgFirstHalf,
          );

          final String svgFirstHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: firstHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_firstHalfWithSprints',
            svg: svgFirstHalfWithSprints,
          );
        }

        if (secondHalfAnalysis != null) {
          final secondHalfPointsForDisplay = flipSecondHalfY
              ? _flipHeatmapPointsY(
            points: secondHalfAnalysis.heatmapPoints,
            field: footballFieldGps!,
          )
              : secondHalfAnalysis.heatmapPoints;

          final secondHalfSprintsRaw = _buildSprintPolylines(secondHalfSamples);

          final secondHalfSprintsForDisplay = flipSecondHalfY
              ? _flipPolylinesY(
            polylines: secondHalfSprintsRaw,
            field: footballFieldGps!,
          )
              : secondHalfSprintsRaw;

          final String svgSecondHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_secondHalf',
            svg: svgSecondHalf,
          );

          final String svgSecondHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: secondHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_secondHalfWithSprints',
            svg: svgSecondHalfWithSprints,
          );
        }
      }

      final start = rows.first.timestamp.toDate();
      final end = rows.last.timestamp.toDate();
      final duration = end.difference(start);

      appendLog('Début: ${start.toIso8601String()}');
      appendLog('Fin: ${end.toIso8601String()}');
      appendLog(
        'Durée: ${duration.inMinutes} min ${duration.inSeconds % 60} s',
      );

      if (duration.inMilliseconds > 0 && rows.length > 1) {
        final hz = ((rows.length - 1) / (duration.inMilliseconds / 1000))
            .toStringAsFixed(2);
        appendLog('Fréquence estimée: $hz Hz');
      }
      success = true;

      if(eventSync != null) {
        Map<String, DeviceSync> devices = eventSync!.devices;
        DeviceSync? deviceSync = devices[widget.trackerId];
        if(deviceSync != null) {
          deviceSync.dataDownloaded = true;
          deviceSync.dataDownloadedAt = Timestamp.now();
          deviceSync.dataDownloadedUid = FirebaseAuth.instance.currentUser?.uid;
          devices[widget.trackerId] = deviceSync;
          await EventSyncService().createOrUpdateEventSync(eventSync!);
        }
      }


    } on AsiDownloadTimeoutException catch (e) {
      appendLog(e.message);
      appendLog(e.userInstructions);
      debugPrint('DOWNLOAD_TIMEOUT: $e');
    } catch (e, st) {
      appendLog('Erreur download: $e');
      debugPrint('DOWNLOAD_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          dataDownloaded = success;
        });
      }
    }
  }

  List<HeatmapPoint> _flipHeatmapPointsY({
    required List<HeatmapPoint> points,
    required FootballFieldGps field,
  }) {
    return points.map((p) {
      return HeatmapPoint(
        xMeters: p.xMeters,
        yMeters: field.fieldWidthMeters - p.yMeters,
        timeMs: p.timeMs,
        intensity: p.intensity,
      );
    }).toList(growable: false);
  }

  List<PitchPolyline> _flipPolylinesY({
    required List<PitchPolyline> polylines,
    required FootballFieldGps field,
  }) {
    return polylines.map((polyline) {
      return PitchPolyline(
        pointsM: polyline.pointsM.map((p) {
          return Offset(p.dx, field.fieldWidthMeters - p.dy);
        }).toList(growable: false),
        segmentIntensity01: polyline.segmentIntensity01,
        strokeWidth: polyline.strokeWidth,
        showArrow: polyline.showArrow,
        showStartEndDots: polyline.showStartEndDots,
      );
    }).toList(growable: false);
  }

  List<TimeRange> get _sortedPeriods {
    final list = [...widget.periods];
    list.sort((a, b) {
      final aMs = a.start.toDate().millisecondsSinceEpoch ?? 0;
      final bMs = b.start.toDate().millisecondsSinceEpoch ?? 0;
      return aMs.compareTo(bMs);
    });
    return list;
  }

  TimeRange? get _firstHalfPeriod {
    if (_sortedPeriods.isEmpty) return null;
    return _sortedPeriods.first;
  }

  TimeRange? get _secondHalfPeriod {
    if (_sortedPeriods.length < 2) return null;
    return _sortedPeriods[1];
  }

  List<TrackerRaw> _getSamplesForPeriod({required TimeRange? period, required List<TrackerRaw> allTrackerSamples}) {
    if (period == null || allTrackerSamples.isEmpty) return const [];

    final startMs = period.start.toDate().millisecondsSinceEpoch;
    final endMs = period.end.toDate().millisecondsSinceEpoch;

    return allTrackerSamples.where((sample) {
      return sample.timeMs >= startMs && sample.timeMs <= endMs;
    }).toList(growable: false);
  }

  List<List<TrackerRaw>> _extractSprintSegments(List<TrackerRaw> samples) {
    final List<List<TrackerRaw>> segments = [];
    List<TrackerRaw> current = [];

    for (final sample in samples) {
      final speedKmh = sample.speedMps * 3.6;

      if (speedKmh >= _sprintThresholdKmh) {
        current.add(sample);
      } else {
        if (current.length >= _minSprintPoints) {
          segments.add(List<TrackerRaw>.from(current));
        }
        current = [];
      }
    }

    if (current.length >= _minSprintPoints) {
      segments.add(List<TrackerRaw>.from(current));
    }

    return segments;
  }

  List<PitchPolyline> _buildSprintPolylines(List<TrackerRaw> samples) {
    final segments = _extractSprintSegments(samples);
    if (segments.isEmpty) return const [];

    final List<PitchPolyline> polylines = [];

    for (final segment in segments) {
      final sprintAnalysis = SensorAnalysisService.analyzeSensorData(
        trackerId: widget.trackerId,
        allSamples: segment,
        isMatch: widget.isMatch,
        playerId: widget.playerId,
        fieldGps: footballFieldGps,
        eventId: widget.eventId,
      );

      if (sprintAnalysis.heatmapPoints.length < 2) continue;

      polylines.add(
        PitchPolyline(
          pointsM: PitchHeatmapBuilder.polylineFromHeatmapPoints(
            sprintAnalysis.heatmapPoints,
          ),
          segmentIntensity01:
          PitchHeatmapBuilder.segmentIntensityFromHeatmapPoints(
            sprintAnalysis.heatmapPoints,
          ),
          strokeWidth: 3.2,
          showArrow: true,
          showStartEndDots: false,
        ),
      );
    }

    return polylines;
  }

  Future<void> eraseData() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    bool success = false;



    try {
      appendLog('Effacement en cours...');
      await client.eraseData(session!);
      appendLog('Effacement terminé ou aucune donnée à effacer');
      success = true;
    } catch (e, st) {
      appendLog('Erreur erase data: $e');
      debugPrint('ERASE_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        if(success == true) {
          if(eventSync != null) {
            Map<String, DeviceSync> devices = eventSync!.devices;
            DeviceSync? deviceSync = devices[widget.trackerId];
            if(deviceSync != null) {
              deviceSync.erased = true;
              deviceSync.erasedAt = Timestamp.now();
              deviceSync.erasedUid = FirebaseAuth.instance.currentUser?.uid;
              devices[widget.trackerId] = deviceSync;
              await EventSyncService().createOrUpdateEventSync(eventSync!);
            }
          }

        }
        setState(() {
          loading = false;
          dataErased = success;
        });
      }
    }
  }
  Future<void> eraseAll() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);
    try {
      await client.eraseAll(session!);
      appendLog('Pod fully erased');
    } catch (e) {
      appendLog('Erreur erase all: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }



  @override
  void dispose() {
    final currentSession = session;
    if (currentSession != null) {
      client.close(currentSession).catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracker sélectionné',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.trackerId,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final safeDeviceId = widget.trackerId;
                  final safePeriods = widget.periods ?? <TimeRange>[];
                  if (safeDeviceId.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucun deviceId disponible'),
                      ),
                    );
                    return;
                  }
                  showAsiConverterDialog(
                    context: context,
                    deviceId: safeDeviceId,
                    periods: safePeriods,
                    isMatch: widget.isMatch,
                    eventId: widget.eventId,
                    fieldGpsCorners: widget.fieldGpsCorners,
                    playerId: widget.playerId,
                    eventSync: widget.eventSync,
                    ownerId: widget.ownerId,
                  );
                },
                icon: const Icon(Icons.insert_drive_file),
                label: const Text('Fichier .asi'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: (deviceConnected) ? null : connectDevice,
                icon: const Icon(Icons.usb_rounded),
                label: const Text('Connecter'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && !loading) ? download : null,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Télécharger'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && dataDownloaded && !loading) ? eraseData : null,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Effacer les données'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && !loading) ? disconnect : null,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Déconnecter'),
              ),

            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  loading ? Icons.sync_rounded : Icons.memory_rounded,
                  color: loading ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDevice == null
                        ? 'Aucun périphérique connecté'
                        : 'Périphérique: ${selectedDevice!.productName ?? selectedDevice!.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: logs.trim().isEmpty
                  ? Center(
                child: Text(
                  'Les logs apparaîtront ici.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              )
                  : SingleChildScrollView(
                child: SelectableText(
                  logs,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> disconnect() async {
    try {
      if (session != null) {
        await client.close(session!);
      }

      appendLog('Device déconnecté');

      if (mounted) {
        setState(() {
          session = null;
          deviceConnected = false;
          deviceId = null;
          loading = false;
          selectedDevice = null;
          dataDownloaded = false;
          dataErased = false;
          footballFieldGps = null;
        });
      }
    } catch (e) {
      appendLog('Erreur déconnexion: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

}