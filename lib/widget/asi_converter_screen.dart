import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/widget/proPitchView.dart';


import '../model/timeRange.dart';
import '../model/tracker/trackerData.dart';
import '../model/trackerDeviceRaw.dart';
import '../services/pitch_heatmap_builder.dart';
import '../services/sensorAnalysisService.dart';
import '../services/trackerDataAnalysisService.dart';
import '../util/app_theme.dart';
import '../util/heatmap_svg_generator.dart';
import 'gps_field.dart';

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

  const AsiConverterScreen({
    super.key,
    required this.deviceId,
    required this.isMatch,
    required this.eventId,
    this.periods = const [],
    this.showAppBar = true,
    required this.fieldGpsCorners,
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
  bool _invertSides = false;


  FootballFieldGps? footballFieldGps;
  List<Offset> cornersM = [];

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  /// Analyse complète existante
  TrackerAnalysisResult? _analysisResult;

  /// Analyse recalculée uniquement pour l’affichage
  TrackerAnalysisResult? _displayAnalysisResult;

  /// Samples convertis depuis le CSV
  List<TrackerRaw> _allTrackerSamples = [];

  HeatmapDisplayPeriod _selectedPeriod = HeatmapDisplayPeriod.fullMatch;
  bool _showSprintTrajectoriesOnly = false;

  List<PitchPolyline> _sprintPolylines = const [];

  static const double _sprintThresholdKmh = 20.0;
  static const int _minSprintPoints = 4;


  String? svgFullMatch;
  String? svgFirstHalf;
  String? svgSecondHalf;

  @override
  void initState() {
    debugPrint('dans AsiConverterScreen isMatch=${widget.isMatch}');
    super.initState();
    _deviceIdCtrl = TextEditingController(text: widget.deviceId);
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

    if (rows.isEmpty) {
      return header;
    }

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

  // ---------------------------------------------------------------------------
  // PÉRIODES / MI-TEMPS
  // ---------------------------------------------------------------------------

  DateTime? _extractDateTimeFromDynamic(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    try {
      // ex: Timestamp Firestore
      final dynamic dt = value.toDate?.call();
      if (dt is DateTime) return dt;
    } catch (_) {}

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  DateTime? _tryReadTimeRangeField(TimeRange range, List<String> fieldNames) {
    for (final field in fieldNames) {
      try {
        final dynamic raw = (range as dynamic)
            .toJson?.call()[field];
        final date = _extractDateTimeFromDynamic(raw);
        if (date != null) return date;
      } catch (_) {}

      try {
        final dynamic raw = (range as dynamic)
            .toMap?.call()[field];
        final date = _extractDateTimeFromDynamic(raw);
        if (date != null) return date;
      } catch (_) {}

      try {
        final dynamic raw = (range as dynamic)
            .toFirestore?.call()[field];
        final date = _extractDateTimeFromDynamic(raw);
        if (date != null) return date;
      } catch (_) {}

      try {
        final dynamic raw = (range as dynamic).__getattribute__(field);
        final date = _extractDateTimeFromDynamic(raw);
        if (date != null) return date;
      } catch (_) {}

      try {
        final dynamic raw = (range as dynamic).toString();
        if (raw != null) {
          // aucun traitement utile ici, on laisse
        }
      } catch (_) {}
    }

    // fallback reflection-like manuel par champs usuels
    for (final field in fieldNames) {
      try {
        final dynamic raw = switch (field) {
          'start' => (range as dynamic).start,
          'end' => (range as dynamic).end,
          'startAt' => (range as dynamic).startAt,
          'endAt' => (range as dynamic).endAt,
          'from' => (range as dynamic).from,
          'to' => (range as dynamic).to,
          'begin' => (range as dynamic).begin,
          'finish' => (range as dynamic).finish,
          'dateStart' => (range as dynamic).dateStart,
          'dateEnd' => (range as dynamic).dateEnd,
          _ => null,
        };

        final date = _extractDateTimeFromDynamic(raw);
        if (date != null) return date;
      } catch (_) {}
    }

    return null;
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

  bool _isSampleInsidePeriod(TrackerRaw sample, TimeRange period) {
    final startMs = period.start.toDate().millisecondsSinceEpoch;
    final endMs = period.end.toDate().millisecondsSinceEpoch;

    return sample.timeMs >= startMs && sample.timeMs <= endMs;
  }

  String _orientationInfo() {
    if (_selectedPeriod == HeatmapDisplayPeriod.fullMatch) {
      return 'Orientation terrain complet';
    }

    if (!_invertSides) {
      return 'Orientation normale';
    }

    return 'Camps inversés';
  }

  PitchViewMode get _selectedPitchMode {
    switch (_selectedPeriod) {
      case HeatmapDisplayPeriod.firstHalf:
        return _invertSides
            ? PitchViewMode.bottomHalfPortrait
            : PitchViewMode.topHalfPortrait;

      case HeatmapDisplayPeriod.secondHalf:
        return _invertSides
            ? PitchViewMode.topHalfPortrait
            : PitchViewMode.bottomHalfPortrait;

      case HeatmapDisplayPeriod.fullMatch:
        return PitchViewMode.fullLandscape;
    }
  }

  List<TrackerRaw> _getSamplesForSelectedPeriod() {
    if (_allTrackerSamples.isEmpty) return const [];

    switch (_selectedPeriod) {
      case HeatmapDisplayPeriod.fullMatch:
        return List<TrackerRaw>.from(_allTrackerSamples);

      case HeatmapDisplayPeriod.firstHalf:
        final first = _firstHalfPeriod;
        if (first == null) return const [];
        return _allTrackerSamples
            .where((s) => _isSampleInsidePeriod(s, first))
            .toList(growable: false);

      case HeatmapDisplayPeriod.secondHalf:
        final second = _secondHalfPeriod;
        if (second == null) return const [];
        return _allTrackerSamples
            .where((s) => _isSampleInsidePeriod(s, second))
            .toList(growable: false);
    }
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

  // ---------------------------------------------------------------------------
  // SPRINTS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // REBUILD DISPLAY
  // ---------------------------------------------------------------------------

  void _rebuildDisplayAnalysis() {
    if (_allTrackerSamples.isEmpty) {
      _displayAnalysisResult = null;
      _sprintPolylines = const [];
      return;
    }

    final samplesForDisplay = _getSamplesForSelectedPeriod();

    if (samplesForDisplay.isEmpty) {
      _displayAnalysisResult = null;
      _sprintPolylines = const [];
      return;
    }
    _displayAnalysisResult = SensorAnalysisService.analyzeSensorData(
      trackerId: _deviceIdCtrl.text.trim(),
      allSamples: samplesForDisplay,
      isMatch: widget.isMatch,
      playerId: _deviceIdCtrl.text.trim(),
    );

    _sprintPolylines = _showSprintTrajectoriesOnly
        ? _buildSprintPolylines(samplesForDisplay)
        : const [];
  }

  // ---------------------------------------------------------------------------
  // CONVERSION
  // ---------------------------------------------------------------------------

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
          speedMps: (row.speed ?? 0) / 3.6,
        );
      }).toList();

      _allTrackerSamples = trackerSamples;

      if(widget.fieldGpsCorners != null) {
        setState(() {
          footballFieldGps= FootballFieldGps.fromFieldGpsCorners(widget.fieldGpsCorners!);
        });
        if(footballFieldGps != null) {
          setState(() {
            cornersM = footballFieldGps!.cornersToPitchMeters();
          });
        }
      }

      _analysisResult = SensorAnalysisService.analyzeSensorData(
        trackerId: deviceId,
        allSamples: trackerSamples,
        isMatch: widget.isMatch,
        playerId: deviceId,
        fieldGps: footballFieldGps,
      );

      _rebuildDisplayAnalysis();

      if (_analysisResult != null) {
        debugPrint('deviceId: ${_analysisResult!.trackerId}');
        debugPrint('distanceKm: ${_analysisResult!.distanceKm}');
        debugPrint('duration: ${_analysisResult!.duration}');
        debugPrint('averageSpeedKmh: ${_analysisResult!.averageSpeedKmh}');
        debugPrint('maxSpeedKmh: ${_analysisResult!.maxSpeedKmh}');
        debugPrint('samplesCount: ${_analysisResult!.samplesCount}');
        debugPrint('sprintCount: ${_analysisResult!.sprintCount}');
        debugPrint('timeAbove20Kmh: ${_analysisResult!.timeAbove20Kmh}');
        debugPrint(
          'maxAccelerationMps2: ${_analysisResult!.maxAccelerationMps2}',
        );
        debugPrint('heatmapPoint=${_analysisResult!.heatmapPoints.length}');
        debugPrint('workloadScore: ${_analysisResult!.workloadScore}');

        print('maxValidatedSpeedKmh: ${_analysisResult!.maxValidatedSpeedKmh}');
        print(
          'highAccelerationCount: ${_analysisResult!.highAccelerationCount}',
        );
        print('playerProfile: ${_analysisResult!.playerProfile}');
        print('fatigueIndex: ${_analysisResult!.fatigueIndex}');
        print('firstHalfDistanceKm: ${_analysisResult!.firstHalfDistanceKm}');
        print('secondHalfDistanceKm: ${_analysisResult!.secondHalfDistanceKm}');

        final firstHalf =
        _analysisResult!.halfStats.firstWhere((e) => e.halfIndex == 1);
        final secondHalf =
        _analysisResult!.halfStats.firstWhere((e) => e.halfIndex == 2);

        print('Diff distance: ${secondHalf.distanceKm - firstHalf.distanceKm}');
        print(
          'Diff vitesse: ${secondHalf.averageSpeedKmh - firstHalf.averageSpeedKmh}',
        );
        print(
          'RESULT distanceTimeline length = ${_analysisResult!.distanceTimeline.length}',
        );
        print(
          'RESULT toMap distanceTimeline = ${_analysisResult!.toMap()['distanceTimeline']}',
        );

        for (final z in _analysisResult!.speedZones) {
          print(
            '${z.zoneId} -> ${z.duration} (${z.percentOfSession.toStringAsFixed(1)}%)',
          );
        }

        print('heatmap=${_analysisResult!.heatmapPoints.length}');

        /*
        await SensorAnalysisService.heatmapToCsv(
          deviceId: widget.deviceId,
          eventId: widget.eventId,
          heatmapPoints: _analysisResult!.heatmapPoints,
        );
        */
        print('avant TrackerAnalysisService.saveAnalysis ${DateTime.now().toString()}');
        await TrackerAnalysisService.saveAnalysis(
          docId: '${widget.eventId}_${widget.deviceId}',
          _analysisResult!,
          eventId: widget.eventId,
        );

        print('avant HeatmapSvgGenerator.generateSvg ${DateTime.now().toString()}');
        setState(() {
          _selectedPeriod = HeatmapDisplayPeriod.fullMatch;
        });
        svgFullMatch = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: _analysisResult!.heatmapPoints,
          invertSides: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );
        print('après HeatmapSvgGenerator.generateSvg ${DateTime.now().toString()}');
        await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_fullMatch',
            svg: svgFullMatch!);

        setState(() {
          _selectedPeriod = HeatmapDisplayPeriod.firstHalf;
        });
        print('avant _rebuildDisplayAnalysis() ${DateTime.now().toString()}');
        _rebuildDisplayAnalysis();
        print('après _rebuildDisplayAnalysis() ${DateTime.now().toString()}');

        svgFirstHalf = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: _analysisResult!.heatmapPoints,
          invertSides: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );
        await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_firstHalf',
            svg: svgFullMatch!);
        setState(() {
          _selectedPeriod = HeatmapDisplayPeriod.secondHalf;
        });
        svgSecondHalf = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: _analysisResult!.heatmapPoints,
          invertSides: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );
        await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.deviceId}-${widget.eventId}_secondHalf',
            svg: svgSecondHalf!);
        print('apres TrackerAnalysisService.saveAnalysis ${DateTime.now().toString()}');
      }

      if (!mounted) return;

      setState(() {
        _csvResult = filteredCsv;
        _rowsCount = rows.length;
      });


      _showSnackBar('Conversion terminée - $_rowsCount ligne(s) retenue(s)');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur pendant la conversion : $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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


  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

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
                                    label:
                                    const Text('Choisir un fichier .asi'),
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

                                  if (value == HeatmapDisplayPeriod.firstHalf &&
                                      _firstHalfPeriod == null) {
                                    return;
                                  }

                                  if (value == HeatmapDisplayPeriod.secondHalf &&
                                      _secondHalfPeriod == null) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedPeriod = value;
                                    _rebuildDisplayAnalysis();
                                  });
                                },
                              ),
                              FilterChip(
                                selected: _showSprintTrajectoriesOnly,
                                label: const Text('Trajectoires des sprints'),
                                onSelected: (value) {
                                  setState(() {
                                    _showSprintTrajectoriesOnly = value;
                                    _rebuildDisplayAnalysis();
                                  });
                                },
                              ),
                              FilterChip(
                                selected: _invertSides,
                                label: const Text('Inverser les camps'),
                                onSelected: (value) {
                                  setState(() {
                                    _invertSides = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (svgFullMatch != null && svgFullMatch!.isNotEmpty) ...[
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
                                svgFullMatch!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ]
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
  required List<TimeRange> periods,
  required bool isMatch,
  required String eventId,
  required FieldGpsCorners? fieldGpsCorners,
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