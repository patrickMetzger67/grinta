import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/services/highlightsService.dart';

import '../widget/asi_converter_screen.dart';
import '../model/timeRange.dart';
import '../model/trackerDeviceRaw.dart';
import '../usb/asi_models.dart';
import '../usb/asi_usb_client.dart';
import '../usb/asi_usb_factory.dart';
import '../util/app_theme.dart';

import 'package:path_provider/path_provider.dart';

import '../util/downloadWeb.dart';


class TrackerHubPage extends StatefulWidget {
  final List<String> trackerIds;
  final String eventId;
  final bool isMatch;

  const TrackerHubPage({
    super.key,
    required this.trackerIds,
    required this.eventId,
    required this.isMatch,
  });

  @override
  State<TrackerHubPage> createState() => _TrackerHubPageState();
}

class _TrackerHubPageState extends State<TrackerHubPage> {
  String? selectedTrackerId;
  final List<String> trackerIdsDone = [];


  List<TimeRange> matchPeriods = [];

  bool isDataLoaded = false;

  @override
  void initState() {

    debugPrint('isMatch=${widget.isMatch}');
    getData();
    super.initState();
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

    return Scaffold(
      backgroundColor: colors!.background,
      appBar: AppBar(
        title: Text(
          'Trackers USB',
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
                    'Trackers disponibles',
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: widget.trackerIds.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
                    ),
                    itemBuilder: (context, index) {
                      final trackerId = widget.trackerIds[index];
                      final isSelected = trackerId == selectedTrackerId;
                      final isDone = trackerIdsDone.contains(trackerId);

                      return _TrackerCard(
                        trackerId: trackerId,
                        isSelected: isSelected,
                        isDone: isDone,
                        periods: matchPeriods,
                        onTap: () {
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
            );

            if (isMobile) {
              return Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: trackerGrid,
                  ),
                  Container(
                    height: 1,
                    color: colors.border,
                  ),
                  Expanded(
                    flex: 6,
                    child: detailPanel,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: trackerGrid,
                ),
                Container(
                  width: 1,
                  color: colors.border,
                ),
                Expanded(
                  flex: 6,
                  child: detailPanel,
                ),
              ],
            );
          },
        ),
      ),
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

  const _TrackerCard({
    required this.trackerId,
    required this.isSelected,
    required this.isDone,
    required this.onTap,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
              color: isSelected ? colors.primary : colors.border,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.gps_fixed_rounded,
                              color: isDone ? colors.success : colors.danger,
                            ),
                          ),
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
                              ? colors.primary.withValues(alpha: 0.18)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.border,
                          ),
                        ),
                        child: Text(
                          isSelected ? 'Sélectionné' : 'Ouvrir',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colors.primary
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
  }
}

class _TrackerDetailPanel extends StatelessWidget {
  final String? trackerId;
  final List<TimeRange> periods;
  final bool isMatch;
  final String eventId;

  const _TrackerDetailPanel({
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
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

  const AsiDownloaderPanel({
    super.key,
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
  });

  @override
  State<AsiDownloaderPanel> createState() => _AsiDownloaderPanelState();
}

class _AsiDownloaderPanelState extends State<AsiDownloaderPanel> {
  late final AsiUsbClient client;
  AsiDeviceInfo? selectedDevice;
  AsiSession? session;

  String logs = '';
  bool loading = false;
  String? deviceId;

  @override
  void initState() {
    super.initState();
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
        selectedDevice = null;
        session = null;
        deviceId = null;
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

  Future<void> connectDevice() async {
    setState(() => loading = true);
    try {
      final devices = await client.listDevices();
      if (devices.isEmpty) {
        appendLog('Aucun périphérique trouvé');
        return;
      }

      selectedDevice = devices.first;
      session = await client.open(selectedDevice!);

      appendLog(
        'Connecté: ${selectedDevice!.productName ?? selectedDevice!.id}',
      );
    } catch (e) {
      appendLog('Erreur connexion: $e');
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

  Future<void> download() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    try {
      appendLog('Téléchargement en cours...');
      appendLog('Lecture RAW en cours...');

      final watch = Stopwatch()..start();

      // ✅ PAS DE TIMEOUT
      final Uint8List data = await client.downloadData(session!);

      watch.stop();
      appendLog('Lecture RAW terminée en ${watch.elapsed.inSeconds}s');

      appendLog('Téléchargé: ${data.length} octets');

      if (data.isEmpty) {
        appendLog('Pas de données');
        return;
      }

      appendLog('Hash OK');

      // UUID
      if (deviceId == null || deviceId!.trim().isEmpty) {
        try {
          final uuid = await readDeviceIdInFreshSession();
          if (uuid != null && uuid.trim().isNotEmpty) {
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

      final previewLines = rawLines.take(20).toList();
      for (final line in previewLines) {
        print('CSV_PREVIEW: [$line]');
      }

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId!,
        periods: widget.periods
      );

      appendLog('${rows.length} point(s) brut(s) parsé(s)');

      if (rows.isEmpty) {
        appendLog('Aucune donnée exploitable trouvée dans le CSV');
        return;
      }


      appendLog('Sauvegarde locale en cours...');
      if (kIsWeb) {
        saveRowsLocallyWeb(rows,deviceId: deviceId!);
      } else {
        final path = await saveRowsLocally(rows);
        appendLog('Fichier sauvegardé: $path');
      }
      appendLog('Sauvegarde locale terminée');

      final uniqueIds = rows.map((e) => e.id).toSet();
      appendLog('DocId uniques: ${uniqueIds.length}');

      final start = rows.first.timestamp.toDate();
      final end = rows.last.timestamp.toDate();
      final duration = end.difference(start);

      appendLog('Début: ${start.toIso8601String()}');
      appendLog('Fin: ${end.toIso8601String()}');
      appendLog(
        'Durée: ${duration.inMinutes} min ${duration.inSeconds % 60} s',
      );

      if (duration.inMilliseconds > 0 && rows.length > 1) {
        final hz =
        ((rows.length - 1) / (duration.inMilliseconds / 1000))
            .toStringAsFixed(2);
        appendLog('Fréquence estimée: $hz Hz');
      }

      for (final row in rows.take(20)) {
        print(
          '${row.id} | '
              '${row.timestamp.toDate().toIso8601String()} | '
              '${row.latitude} | ${row.longitude} | ${row.altitude} | ${row.speed} | ${row.hr}',
        );
      }
    } catch (e, st) {
      appendLog('Erreur download: $e');
      print('DOWNLOAD_ERROR: $e');
      print(st);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<String> saveRowsLocally(List<TrackerDeviceRaw> rows) async {
    final dir = await getApplicationDocumentsDirectory();

    final fileName =
        'tracker_${deviceId ?? "unknown"}_${DateTime.now().millisecondsSinceEpoch}.json';

    final file = File('${dir.path}/$fileName');

    final jsonList = rows.map((row) {
      return {
        'id': row.id,
        'deviceId': row.deviceId,
        'timestamp': row.timestamp.toDate().toIso8601String(),
        'latitude': row.latitude,
        'longitude': row.longitude,
        'altitude': row.altitude,
        'speed': row.speed,
        'hr': row.hr,
      };
    }).toList();

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );

    return file.path;
  }

  Future<void> eraseData() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    try {
      appendLog('Effacement en cours...');
      await client.eraseData(session!);
      appendLog('Effacement terminé ou aucune donnée à effacer');
    } catch (e, st) {
      appendLog('Erreur erase data: $e');
      debugPrint('ERASE_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => loading = false);
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

  Future<void> disconnect() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);
    try {
      await client.close(session!);
      appendLog('Déconnecté');
      session = null;
    } catch (e) {
      appendLog('Erreur déconnexion: $e');
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
                onPressed: loading ? null : connectDevice,
                icon: const Icon(Icons.usb_rounded),
                label: const Text('Connecter'),
              ),
              ElevatedButton.icon(
                onPressed: loading ? null : download,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Télécharger'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : eraseData,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Erase data'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : disconnect,
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

  Future<void> openAsiConverterDialog({
    required BuildContext context,
    required String deviceId,
    required List<TimeRange> periods,
    required bool isMatch,
    required String eventId,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 1000,
            height: 700,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Import fichier ASI',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // CONTENU
                Expanded(
                  child: AsiConverterScreen(
                    deviceId: deviceId,
                    periods: periods,
                    isMatch: isMatch,
                    eventId: eventId,
                  ),
                ),

                const Divider(height: 1),

                // FOOTER
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
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
}