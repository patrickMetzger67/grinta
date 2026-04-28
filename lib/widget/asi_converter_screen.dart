import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/eventSync.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/widget/proPitchView.dart';

import '../model/timeRange.dart';
import '../model/tracker/device.dart';
import '../model/tracker/trackerData.dart';
import '../model/trackerDeviceRaw.dart';
import '../services/event_sync_service.dart';
import '../services/pitch_heatmap_builder.dart';
import '../services/sensorAnalysisService.dart';
import '../services/trackerDataAnalysisService.dart';
import '../util/app_theme.dart';
import '../util/heatmap_svg_generator.dart';


enum HeatmapDisplayPeriod {
  firstHalf,
  secondHalf,
  fullMatch,
}

class AsiConverterScreen extends StatefulWidget {
  final String deviceId;
  final List<TimeRange> periods;
  final bool showAppBar;
  final bool isMatch;
  final String eventId;
  final FieldGpsCorners? fieldGpsCorners;
  final String playerId;
  final EventSync eventSync;
  final String? ownerId;

  const AsiConverterScreen({
    super.key,
    required this.deviceId,
    required this.isMatch,
    required this.eventId,
    this.periods = const [],
    this.showAppBar = true,
    required this.fieldGpsCorners,
    required this.playerId,
    required this.eventSync,
    required this.ownerId,
  });

  @override
  State<AsiConverterScreen> createState() => _AsiConverterScreenState();
}

class _AsiConverterScreenState extends State<AsiConverterScreen> {
  late final TextEditingController _deviceIdCtrl;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _csvResult;
  int _rowsCount = 0;
  bool _isLoading = false;

  FootballFieldGps? footballFieldGps;
  List<Offset> cornersM = [];

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  TrackerAnalysisResult? _analysisResult;
  TrackerAnalysisResult? _displayAnalysisResult;

  List<TrackerRaw> _allTrackerSamples = [];

  HeatmapDisplayPeriod _selectedPeriod = HeatmapDisplayPeriod.fullMatch;
  bool _showSprintTrajectoriesOnly = false;
  List<PitchPolyline> _sprintPolylines = const [];

  static const double _sprintThresholdKmh = 20.0;
  static const int _minSprintPoints = 4;


  String? svgFullMatch;
  String? svgFullMatchWithSprints;

  String? svgFirstHalf;
  String? svgFirstHalfWithSprints;
  String? svgSecondHalf;
  String? svgSecondHalfWithSprints;
  String? svgToDisplay;
  EventSync? eventSync;

  @override
  void initState() {
    super.initState();
    _deviceIdCtrl = TextEditingController(text: widget.deviceId);
    eventSync = widget.eventSync;
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickAsiFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['asi'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null) {
        if (!mounted) return;
        _showSnackBar('Impossible de lire le fichier sélectionné');
        return;
      }


      DeviceOwner? deviceOwner = await DeviceOwnerService().getByOwnerIdAndCustomName(widget.ownerId!, widget.deviceId);

      if(deviceOwner != null) {
        Device? device = await DeviceService().getDeviceById(deviceOwner.deviceId);
        if(device != null && device.deviceName!.isNotEmpty) {
          if(file.name.contains(device.deviceName!) == false) {
            _showSnackBar('Le fichier ne correspond pas au tracker sélectionné');
            return;
          }
        } else {
          _showSnackBar('Tracker non reconnu');
          return;
        }
      } else {
        _showSnackBar('Tracker non reconnu');
        return;
      }

      setState(() {
        _selectedFileBytes = file.bytes!;
        _selectedFileName = file.name;
      });
    } catch (e) {
      debugPrint('Erreur file picker: $e');
      if (!mounted) return;
      _showSnackBar('Erreur lors de la sélection du fichier : $e');
    }
  }

  Future<String> convertAsiToCsv(Uint8List asiBytes) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('insidersConvertAsiToCsv');

    final result = await callable.call({
      'asiBase64': base64Encode(asiBytes),
      'filename': _selectedFileName ?? 'inspirit_data.ASI',
    });

    final data = Map<String, dynamic>.from(result.data['data'] as Map);
    return data['csv'] as String;
  }

  String _buildCsvFromRows(List<TrackerDeviceRaw> rows) {
    const header = 'timestamp,latitude,longitude,altitude,speed,hr';

    if (rows.isEmpty) return header;

    final buffer = StringBuffer();
    buffer.writeln(header);

    for (final row in rows) {
      final timestampSeconds = row.timestamp.millisecondsSinceEpoch ~/ 1000;

      buffer.writeln([
        timestampSeconds,
        row.latitude,
        row.longitude,
        row.altitude ?? '',
        row.speed ?? '',
        row.hr ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  List<TimeRange> get _sortedPeriods {
    final list = [...widget.periods];
    list.sort((a, b) => a.start.compareTo(b.start));
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

  List<TrackerRaw> _getSamplesForSelectedPeriod() {
    if (_allTrackerSamples.isEmpty) return const [];

    TimeRange? period;

    switch (_selectedPeriod) {
      case HeatmapDisplayPeriod.fullMatch:
        return List<TrackerRaw>.from(_allTrackerSamples);

      case HeatmapDisplayPeriod.firstHalf:
        period = _firstHalfPeriod;
        break;

      case HeatmapDisplayPeriod.secondHalf:
        period = _secondHalfPeriod;
        break;
    }

    if (period == null) return const [];

    final startMs = period.start.toDate().millisecondsSinceEpoch;
    final endMs = period.end.toDate().millisecondsSinceEpoch;

    return _allTrackerSamples.where((sample) {
      return sample.timeMs >= startMs && sample.timeMs <= endMs;
    }).toList(growable: false);
  }

  List<TrackerRaw> _getSamplesForPeriod(TimeRange? period) {
    if (period == null || _allTrackerSamples.isEmpty) return const [];

    final startMs = period.start.toDate().millisecondsSinceEpoch;
    final endMs = period.end.toDate().millisecondsSinceEpoch;

    return _allTrackerSamples.where((sample) {
      return sample.timeMs >= startMs && sample.timeMs <= endMs;
    }).toList(growable: false);
  }

  String _selectedPeriodInfo() {
    switch (_selectedPeriod) {
      case HeatmapDisplayPeriod.firstHalf:
        return _firstHalfPeriod == null
            ? '1ère mi-temps indisponible'
            : '1ère mi-temps';

      case HeatmapDisplayPeriod.secondHalf:
        return _secondHalfPeriod == null
            ? '2ème mi-temps indisponible'
            : '2ème mi-temps';

      case HeatmapDisplayPeriod.fullMatch:
        return 'Match entier';
    }
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
        trackerId: _deviceIdCtrl.text.trim(),
        allSamples: segment,
        isMatch: widget.isMatch,
        playerId: _deviceIdCtrl.text.trim(),
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

  Offset _centroidOfHeatmap(List<HeatmapPoint> points) {
    if (points.isEmpty) return Offset.zero;

    double sumX = 0;
    double sumY = 0;
    double sumW = 0;

    for (final p in points) {
      final w = p.intensity <= 0 ? 1.0 : p.intensity;
      sumX += p.xMeters * w;
      sumY += p.yMeters * w;
      sumW += w;
    }

    if (sumW <= 0) return Offset.zero;
    return Offset(sumX / sumW, sumY / sumW);
  }

  double _distanceSq(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return dx * dx + dy * dy;
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


  Future<void> _convertFile() async {
    FocusScope.of(context).unfocus();

    final deviceId = _deviceIdCtrl.text.trim();

    if (_selectedFileBytes == null) {
      _showSnackBar('Veuillez sélectionner un fichier .asi');
      return;
    }

    if (deviceId.isEmpty) {
      _showSnackBar('Veuillez renseigner le deviceId');
      return;
    }

    setState(() {
      _isLoading = true;
      _csvResult = null;
      _rowsCount = 0;
      _analysisResult = null;
      _displayAnalysisResult = null;
      _allTrackerSamples = [];
      _sprintPolylines = const [];
      svgFullMatch = null;
      svgFullMatchWithSprints = null;
      svgFirstHalf = null;
      svgFirstHalfWithSprints = null;
      svgSecondHalf = null;
      svgSecondHalfWithSprints = null;
      svgToDisplay = null;
    });

    try {
      final String csv = await convertAsiToCsv(_selectedFileBytes!);

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId,
        periods: widget.periods,
      );

      final filteredCsv = _buildCsvFromRows(rows);

      final trackerSamples = rows.map((row) {
        return TrackerRaw(
          trackerId: row.deviceId,
          timeMs: row.timestamp.millisecondsSinceEpoch,
          latitude: row.latitude!,
          longitude: row.longitude!,
          speedMps: row.speed ?? 0,
        );
      }).toList(growable: false);

      _allTrackerSamples = trackerSamples;

      if (widget.fieldGpsCorners != null) {
        footballFieldGps = FootballFieldGps.fromFieldGpsCorners(
          widget.fieldGpsCorners!,
        );
        cornersM = footballFieldGps!.cornersToPitchMeters();
      } else {
        footballFieldGps = null;
        cornersM = [];
      }

      _analysisResult = SensorAnalysisService.analyzeSensorData(
        trackerId: deviceId,
        allSamples: trackerSamples,
        isMatch: widget.isMatch,
        playerId: widget.playerId,
        fieldGps: footballFieldGps,
        eventId: widget.eventId,
      );

      if (_analysisResult == null) {
        throw Exception('Analyse impossible');
      }

      await TrackerAnalysisService.saveAnalysis(
        docId: '${widget.eventId}_${widget.deviceId}',
        _analysisResult!,
        eventId: widget.eventId,
      );


      if(widget.isMatch) {

        // MATCH COMPLET = DONNÉES BRUTES
        svgFullMatch = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: _analysisResult!.heatmapPoints,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.deviceId}-${widget.eventId}_fullMatch',
          svg: svgFullMatch!,
        );

        final fullMatchSprintPolylines = _buildSprintPolylines(trackerSamples);

        svgFullMatchWithSprints = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: _analysisResult!.heatmapPoints,
          sprintPolylines: fullMatchSprintPolylines,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.deviceId}-${widget.eventId}_fullMatchWithSprints',
          svg: svgFullMatchWithSprints!,
        );

        // MI-TEMPS
        final firstHalfSamples = _getSamplesForPeriod(_firstHalfPeriod);
        final secondHalfSamples = _getSamplesForPeriod(_secondHalfPeriod);

        TrackerAnalysisResult? firstHalfAnalysis;
        TrackerAnalysisResult? secondHalfAnalysis;

        if (firstHalfSamples.isNotEmpty) {
          firstHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: deviceId,
            allSamples: firstHalfSamples,
            isMatch: widget.isMatch,
            playerId: deviceId,
            fieldGps: footballFieldGps,
            eventId: widget.eventId,
          );
        }

        if (secondHalfSamples.isNotEmpty) {
          secondHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: deviceId,
            allSamples: secondHalfSamples,
            isMatch: widget.isMatch,
            playerId: deviceId,
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

          svgFirstHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );
          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_firstHalf',
            svg: svgFirstHalf!,
          );

          svgFirstHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: firstHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_firstHalfWithSprints',
            svg: svgFirstHalfWithSprints!,
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

          svgSecondHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_secondHalf',
            svg: svgSecondHalf!,
          );

          svgSecondHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: secondHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_secondHalfWithSprints',
            svg: svgSecondHalfWithSprints!,
          );
        }

      }


      _displayAnalysisResult = _analysisResult;
      _selectedPeriod = HeatmapDisplayPeriod.fullMatch;
      svgToDisplay = svgFullMatchWithSprints ?? svgFullMatch;

      if (!mounted) return;

      setState(() {
        _csvResult = filteredCsv;
        _rowsCount = rows.length;
      });

      if(eventSync != null) {
        Map<String, DeviceSync> devices = eventSync!.devices;
        DeviceSync? deviceSync = devices[widget.deviceId];
        if(deviceSync != null) {
          deviceSync.withAsiFile = true;
          deviceSync.withAsiFileAt= Timestamp.now();
          deviceSync.withAsiFileUid = FirebaseAuth.instance.currentUser?.uid;
          devices[widget.deviceId] = deviceSync;
          await EventSyncService().createOrUpdateEventSync(eventSync!);
        }
      }
      _showSnackBar('Conversion terminée - $_rowsCount ligne(s) retenue(s)');

    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur pendant la conversion : $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _csvResult = null;
      _rowsCount = 0;
      _analysisResult = null;
      _displayAnalysisResult = null;
      _allTrackerSamples = [];
      _sprintPolylines = const [];
      svgFullMatch = null;
      svgFullMatchWithSprints = null;
      svgFirstHalf = null;
      svgFirstHalfWithSprints = null;
      svgSecondHalf = null;
      svgSecondHalfWithSprints = null;
      svgToDisplay = null;
    });
  }

  String _formatPeriodsSummary() {
    if (widget.periods.isEmpty) {
      return 'Aucune période définie';
    }

    if (widget.periods.length == 1) {
      return '1 période transmise';
    }

    return '${widget.periods.length} période(s) transmise(s) - les 2 premières seront utilisées pour les mi-temps';
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importer un fichier .asi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sélectionne un fichier, vérifie le deviceId, puis lance la conversion.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paramètres',
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _deviceIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Device ID',
                            hintText: 'Exemple : tracker_001',
                            prefixIcon: Icon(Icons.memory_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Périodes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _formatPeriodsSummary(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fichier sélectionné',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedFileName ??
                                          'Aucun fichier sélectionné',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                        color: _selectedFileName == null
                                            ? colors.textSecondary
                                            : colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _pickAsiFile,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Choisir un fichier .asi'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading ||
                                        _selectedFileName == null
                                        ? null
                                        : _clearSelection,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Réinitialiser'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _convertFile,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.sync_alt_rounded),
                            label: Text(
                              _isLoading
                                  ? 'Conversion en cours...'
                                  : 'Convertir en CSV',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_displayAnalysisResult != null &&
                    _displayAnalysisResult!.heatmapPoints.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heatmap',
                            style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_displayAnalysisResult!.heatmapPoints.length} point(s) - ${_selectedPeriodInfo()}',
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DropdownButton<HeatmapDisplayPeriod>(
                                value: _selectedPeriod,
                                items: [
                                  const DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.fullMatch,
                                    child: Text('Match entier'),
                                  ),
                                  DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.firstHalf,
                                    enabled: _firstHalfPeriod != null,
                                    child: Text(
                                      _firstHalfPeriod != null
                                          ? '1ère mi-temps'
                                          : '1ère mi-temps indisponible',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.secondHalf,
                                    enabled: _secondHalfPeriod != null,
                                    child: Text(
                                      _secondHalfPeriod != null
                                          ? '2ème mi-temps'
                                          : '2ème mi-temps indisponible',
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    _selectedPeriod = value;

                                    switch (value) {
                                      case HeatmapDisplayPeriod.firstHalf:
                                        svgToDisplay =
                                            svgFirstHalfWithSprints ??
                                                svgFirstHalf;
                                        break;
                                      case HeatmapDisplayPeriod.secondHalf:
                                        svgToDisplay =
                                            svgSecondHalfWithSprints ??
                                                svgSecondHalf;
                                        break;
                                      case HeatmapDisplayPeriod.fullMatch:
                                        svgToDisplay =
                                            svgFullMatchWithSprints ??
                                                svgFullMatch;
                                        break;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (svgToDisplay != null && svgToDisplay!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 320,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: SvgPicture.string(
                                svgToDisplay!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (svgFirstHalf != null && svgFirstHalf!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 320,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: SvgPicture.string(
                                svgFirstHalf!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (svgSecondHalf != null && svgSecondHalf!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 320,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: SvgPicture.string(
                                svgSecondHalf!,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
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

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.showAppBar ? null : Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
        title: const Text('Conversion ASI vers CSV'),
      )
          : null,
      body: _buildContent(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Builder(
        builder: (innerContext) {
          return _buildBody(innerContext);
        },
      ),
    );
  }
}

Future<void> showAsiConverterDialog({
  required BuildContext context,
  required String deviceId,
  required String playerId,
  required List<TimeRange> periods,
  required bool isMatch,
  required String eventId,
  required FieldGpsCorners? fieldGpsCorners,
  required EventSync eventSync,
  required String? ownerId,
}) async {
  final colors = context.appColors;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 1000,
          height: 720,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Import fichier ASI',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              Expanded(
                child: AsiConverterScreen(
                  deviceId: deviceId,
                  periods: periods,
                  showAppBar: false,
                  isMatch: isMatch,
                  eventId: eventId,
                  fieldGpsCorners: fieldGpsCorners,
                  playerId: playerId,
                  eventSync: eventSync,
                  ownerId: ownerId,
                ),
              ),
              Divider(height: 1, color: colors.border),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
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