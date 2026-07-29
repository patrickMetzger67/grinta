import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
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
import '../util/match_heatmap_service.dart';


enum HeatmapDisplayPeriod {
  firstHalf,
  secondHalf,
  fullMatch,
}

/// ---------------------------------------------------------------------------
/// Feature flag — CLOUD vs LOCAL capteur analysis
/// ---------------------------------------------------------------------------
/// Bascule l'analyse des données capteur (ASI / inspirit USB) entre :
///   - `true`  : fonction cloud `analyzeInsidersSensorData`
///               (region europe-west1). Le cloud calcule l'analyse ET
///               persiste lui-même (TRACKER_Analysis + TRACKER_Svg + PNG).
///   - `false` : ancien chemin 100% local `SensorAnalysisService`
///               + `TrackerAnalysisService.saveAnalysis`
///               + `HeatmapSvgGenerator.saveSvgToFirestore`.
///
/// On garde volontairement le chemin LOCAL intact pour pouvoir vérifier le
/// cloud sans rien casser : il suffit de repasser ce booléen à `false`.
const bool kUseCloudSensorAnalysis = true;

/// Debug : quand `true` ET que le cloud est actif, on relance aussi l'analyse
/// LOCALE (full match) et on logue une comparaison des métriques clés.
/// Laisser à `false` en production (double le calcul).
const bool kCompareCloudAndLocalSensorAnalysis = false;

/// Regroupe l'analyse cloud (match complet + mi-temps) renvoyée en un seul appel.
class _CloudSensorAnalysisBundle {
  final TrackerAnalysisResult full;
  final TrackerAnalysisResult? firstHalf;
  final TrackerAnalysisResult? secondHalf;

  const _CloudSensorAnalysisBundle({
    required this.full,
    this.firstHalf,
    this.secondHalf,
  });
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

  /// Seuil minimal d'échantillons exploitables après parsing du CSV en dessous
  /// duquel on considère le fichier .asi comme vide / sans donnée.
  static const int _minRequiredSamples = 1;


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
        _showSnackBar(context.l10n.asiCannotReadFile);
        return;
      }


      DeviceOwner? deviceOwner = await DeviceOwnerService().getByOwnerIdAndCustomName(widget.ownerId!, widget.deviceId);

      if(deviceOwner != null) {
        Device? device = await DeviceService().getDeviceById(deviceOwner.deviceId);
        if(device != null && device.deviceName!.isNotEmpty) {
          if(file.name.contains(device.deviceName!) == false) {
            _showSnackBar(context.l10n.asiFileMismatch);
            return;
          }
        } else {
          _showSnackBar(context.l10n.asiTrackerUnknown);
          return;
        }
      } else {
        _showSnackBar(context.l10n.asiTrackerUnknown);
        return;
      }

      setState(() {
        _selectedFileBytes = file.bytes!;
        _selectedFileName = file.name;
      });
    } catch (e) {
      debugPrint('Erreur file picker: $e');
      if (!mounted) return;
      _showSnackBar(context.l10n.asiFilePickError(e.toString()));
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

  /// Appelle la fonction cloud `analyzeInsidersSensorData` (europe-west1).
  ///
  /// On envoie directement les `samples` déjà parsés localement (mode "raw" de
  /// la cloud function, cf. `resolveSamplesFromRequest` -> `data.samples`), donc
  /// AUCUN appel à l'API Insiders n'est déclenché ici.
  ///
  /// Le cloud persiste lui-même l'analyse (TRACKER_Analysis) et les heatmaps
  /// (TRACKER_Svg + PNG Storage). On demande `includeHeatmapPoints: true` pour
  /// pouvoir reconstruire le même `TrackerAnalysisResult` côté app et afficher
  /// les heatmaps localement (à l'identique du chemin local).
  Future<_CloudSensorAnalysisBundle> _analyzeSensorDataViaCloud({
    required String deviceId,
    required List<TrackerRaw> samples,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('analyzeInsidersSensorData');

    // Garde-fou : la cloud function `analyzeInsidersSensorData`
    // (resolveSamplesFromRequest) exige un tableau `samples[]` NON vide, sinon
    // elle lève `invalid-argument: Provide samples[] OR insidersDeviceId ...`.
    // On échoue ici avec un message clair plutôt que de subir l'erreur cloud.
    debugPrint(
      '[ASI][CLOUD] preparing analyzeInsidersSensorData '
      'trackerId=$deviceId samples=${samples.length}',
    );
    if (samples.length < _minRequiredSamples) {
      throw Exception(
        'Aucun échantillon exploitable à envoyer au cloud '
        '(samples=${samples.length}). Vérifiez le fichier .asi et le deviceId.',
      );
    }

    final payload = <String, dynamic>{
      'trackerId': deviceId,
      'playerId': widget.playerId,
      'eventId': widget.eventId,
      'isMatch': widget.isMatch,
      'docId': '${widget.eventId}_${widget.deviceId}',
      'teamId': '0',
      'generateHeatmaps': true,
      'generatePng': true,
      'includeHeatmapPoints': true,
      // On force `trackerId` = `deviceId` (paramètre de la requête) pour CHAQUE
      // échantillon : la cloud (`sensorAnalysisCore.analyzeSensorData`) filtre
      // `allSamples` sur `s.trackerId === trackerId`. Si un échantillon portait
      // un trackerId différent/vide, il serait silencieusement écarté -> analyse
      // vide. Ici on garantit la correspondance (le parsing local utilise déjà
      // ce même deviceId, donc aucun changement de comportement).
      'samples': samples
          .map((s) => {
                'trackerId': deviceId,
                'timeMs': s.timeMs,
                'latitude': s.latitude,
                'longitude': s.longitude,
                'speedMps': s.speedMps,
              })
          .toList(growable: false),
      if (footballFieldGps != null) 'fieldGps': footballFieldGps!.toMap(),
    };

    final result = await callable.call(payload);
    final data = Map<String, dynamic>.from(result.data as Map);

    final full = _trackerAnalysisResultFromCloudMap(
      Map<String, dynamic>.from(data['fullAnalysis'] as Map),
      fieldGps: footballFieldGps,
    );

    TrackerAnalysisResult? firstHalf;
    if (data['firstHalfAnalysis'] != null) {
      firstHalf = _trackerAnalysisResultFromCloudMap(
        Map<String, dynamic>.from(data['firstHalfAnalysis'] as Map),
        fieldGps: footballFieldGps,
      );
    }

    TrackerAnalysisResult? secondHalf;
    if (data['secondHalfAnalysis'] != null) {
      secondHalf = _trackerAnalysisResultFromCloudMap(
        Map<String, dynamic>.from(data['secondHalfAnalysis'] as Map),
        fieldGps: footballFieldGps,
      );
    }

    debugPrint(
      '[ASI][CLOUD] analyzeInsidersSensorData '
      'docId=${data['docId']} source=${data['analysisSource']} '
      'distanceKm=${full.distanceKm.toStringAsFixed(3)} '
      'avgKmh=${full.averageSpeedKmh.toStringAsFixed(2)} '
      'maxKmh=${full.maxSpeedKmh.toStringAsFixed(2)} '
      'sprints=${full.sprintCount} '
      'points=${full.heatmapPoints.length}',
    );

    return _CloudSensorAnalysisBundle(
      full: full,
      firstHalf: firstHalf,
      secondHalf: secondHalf,
    );
  }

  /// Reconstruit un [TrackerAnalysisResult] à partir de l'objet d'analyse
  /// renvoyé par la cloud function (structure de `sensorAnalysisCore.js`).
  ///
  /// Le `fieldGps` n'est pas re-parsé depuis la réponse : on réutilise
  /// directement l'instance locale déjà construite.
  TrackerAnalysisResult _trackerAnalysisResultFromCloudMap(
    Map<String, dynamic> m, {
    required FootballFieldGps? fieldGps,
  }) {
    final heatmapPoints = (m['heatmapPoints'] as List?)
            ?.map((e) {
              final p = Map<String, dynamic>.from(e as Map);
              return HeatmapPoint(
                xMeters: _cloudDouble(p['xMeters']),
                yMeters: _cloudDouble(p['yMeters']),
                timeMs: _cloudInt(p['timeMs']),
                intensity: _cloudDouble(p['intensity']),
              );
            })
            .toList(growable: false) ??
        const <HeatmapPoint>[];

    return TrackerAnalysisResult(
      trackerId: (m['trackerId'] ?? '').toString(),
      playerId: (m['playerId'] ?? '').toString(),
      eventId: (m['eventId'] ?? '').toString(),
      distanceKm: _cloudDouble(m['distanceKm']),
      duration: Duration(milliseconds: _cloudInt(m['durationMs'])),
      averageSpeedKmh: _cloudDouble(m['averageSpeedKmh']),
      maxSpeedKmh: _cloudDouble(m['maxSpeedKmh']),
      maxValidatedSpeedKmh: _cloudDouble(m['maxValidatedSpeedKmh']),
      samplesCount: _cloudInt(m['samplesCount']),
      heatmapPoints: heatmapPoints,
      fieldGps: fieldGps,
      sprintCount: _cloudInt(m['sprintCount']),
      highAccelerationCount: _cloudInt(m['highAccelerationCount']),
      highSpeedDuration:
          Duration(milliseconds: _cloudInt(m['highSpeedDurationMs'])),
      maxAccelerationMps2: _cloudDouble(m['maxAccelerationMps2']),
      distanceByZones: (m['distanceByZones'] as List?)
              ?.map((e) =>
                  FieldZoneStats.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      speedZones: (m['speedZones'] as List?)
              ?.map((e) =>
                  SpeedZoneStat.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      halfStats: (m['halfStats'] as List?)
              ?.map((e) =>
                  HalfStats.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      workloadScore: _cloudDouble(m['workloadScore']),
      workloadScorePerMinute: _cloudDouble(m['workloadScorePerMinute']),
      playerProfile: (m['playerProfile'] ?? '').toString(),
      fatigueIndex: _cloudDouble(m['fatigueIndex']),
      firstHalfDistanceKm: _cloudDouble(m['firstHalfDistanceKm']),
      secondHalfDistanceKm: _cloudDouble(m['secondHalfDistanceKm']),
      distanceTimeline: (m['distanceTimeline'] as List?)
              ?.map((e) => DistanceTimelineStat.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  static double _cloudDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static int _cloudInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
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

  String _selectedPeriodInfo(BuildContext context) {
    final l10n = context.l10n;
    switch (_selectedPeriod) {
      case HeatmapDisplayPeriod.firstHalf:
        return _firstHalfPeriod == null
            ? l10n.halfFirstUnavailable
            : l10n.halfFirst;

      case HeatmapDisplayPeriod.secondHalf:
        return _secondHalfPeriod == null
            ? l10n.halfSecondUnavailable
            : l10n.halfSecond;

      case HeatmapDisplayPeriod.fullMatch:
        return l10n.entityFullMatch;
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
      _showSnackBar(context.l10n.asiSelectFile);
      return;
    }

    if (deviceId.isEmpty) {
      _showSnackBar(context.l10n.asiEnterDeviceId);
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

      // Fichier .asi vide / aucune donnée exploitable après parsing CSV :
      // on affiche un message clair et on stoppe AVANT toute analyse
      // (cloud OU local), pour éviter l'erreur cryptique renvoyée par le cloud
      // ("Provide samples[] OR insidersDeviceId with start/end query").
      if (trackerSamples.length < _minRequiredSamples) {
        if (!mounted) return;
        _showSnackBar(context.l10n.asiFileEmptyOrNoData);
        return;
      }

      if (widget.fieldGpsCorners != null) {
        footballFieldGps = FootballFieldGps.fromFieldGpsCorners(
          widget.fieldGpsCorners!,
        );
        cornersM = footballFieldGps!.cornersToPitchMeters();
      } else {
        footballFieldGps = null;
        cornersM = [];
      }

      // Analyse capteur : CLOUD (analyzeInsidersSensorData) ou LOCAL selon le flag.
      // cf. kUseCloudSensorAnalysis en tête de fichier.
      _CloudSensorAnalysisBundle? cloudBundle;

      if (kUseCloudSensorAnalysis) {
        cloudBundle = await _analyzeSensorDataViaCloud(
          deviceId: deviceId,
          samples: trackerSamples,
        );
        _analysisResult = cloudBundle.full;
      } else {
        _analysisResult = SensorAnalysisService.analyzeSensorData(
          trackerId: deviceId,
          allSamples: trackerSamples,
          isMatch: widget.isMatch,
          playerId: widget.playerId,
          fieldGps: footballFieldGps,
          eventId: widget.eventId,
        );
      }

      if (_analysisResult == null) {
        throw Exception('Analyse impossible');
      }

      // Debug optionnel : compare les métriques clés cloud vs local.
      if (kUseCloudSensorAnalysis && kCompareCloudAndLocalSensorAnalysis) {
        final local = SensorAnalysisService.analyzeSensorData(
          trackerId: deviceId,
          allSamples: trackerSamples,
          isMatch: widget.isMatch,
          playerId: widget.playerId,
          fieldGps: footballFieldGps,
          eventId: widget.eventId,
        );
        debugPrint(
          '[ASI][COMPARE] '
          'distanceKm cloud=${_analysisResult!.distanceKm.toStringAsFixed(3)} '
          'local=${local.distanceKm.toStringAsFixed(3)} | '
          'maxKmh cloud=${_analysisResult!.maxSpeedKmh.toStringAsFixed(2)} '
          'local=${local.maxSpeedKmh.toStringAsFixed(2)} | '
          'sprints cloud=${_analysisResult!.sprintCount} '
          'local=${local.sprintCount} | '
          'points cloud=${_analysisResult!.heatmapPoints.length} '
          'local=${local.heatmapPoints.length}',
        );
      }

      // Persistance de l'analyse (TRACKER_Analysis) :
      // - LOCAL : l'app écrit via TrackerAnalysisService.saveAnalysis.
      // - CLOUD : la cloud function a déjà persisté -> on n'écrit PAS ici
      //   (évite les doubles écritures).
      if (!kUseCloudSensorAnalysis) {
        await TrackerAnalysisService.saveAnalysis(
          docId: '${widget.eventId}_${widget.deviceId}',
          _analysisResult!,
          eventId: widget.eventId,
        );
      }


      if (widget.isMatch) {
        final firstHalfSamples = _getSamplesForPeriod(_firstHalfPeriod);
        final secondHalfSamples = _getSamplesForPeriod(_secondHalfPeriod);

        TrackerAnalysisResult? firstHalfAnalysis;
        TrackerAnalysisResult? secondHalfAnalysis;

        if (kUseCloudSensorAnalysis) {
          // CLOUD : les analyses des deux mi-temps sont renvoyées par l'appel
          // cloud (découpage par temps médian côté serveur).
          firstHalfAnalysis = cloudBundle?.firstHalf;
          secondHalfAnalysis = cloudBundle?.secondHalf;
        } else {
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
        }

        final fullMatchSprintPolylines =
            footballFieldGps != null
                ? _buildSprintPolylines(trackerSamples)
                : const <PitchPolyline>[];
        final firstHalfSprintPolylines =
            footballFieldGps != null
                ? _buildSprintPolylines(firstHalfSamples)
                : const <PitchPolyline>[];
        final secondHalfSprintPolylines =
            footballFieldGps != null
                ? _buildSprintPolylines(secondHalfSamples)
                : const <PitchPolyline>[];

        final fullSprintSegments = _extractSprintSegments(trackerSamples);
        final firstHalfSprintSegments =
            _extractSprintSegments(firstHalfSamples);
        final secondHalfSprintSegments =
            _extractSprintSegments(secondHalfSamples);

        // Terrain géolocalisé → heatmap schématique actuelle.
        // Sinon → fond satellite Google calé sur les GPS collectés.
        // Cloud : les SVG schématiques sont déjà persistés ; on re-persiste
        // uniquement le fallback satellite (pas de coins terrain).
        final bundle = await MatchHeatmapService.generateAndSaveMatchHeatmaps(
          trackerId: widget.deviceId,
          eventId: widget.eventId,
          fieldGps: footballFieldGps,
          fullSamples: trackerSamples,
          fullHeatmapPoints: _analysisResult!.heatmapPoints,
          fullSprintPolylines: fullMatchSprintPolylines,
          fullSprintSegments: fullSprintSegments,
          firstHalfSamples: firstHalfSamples,
          firstHalfHeatmapPoints:
              firstHalfAnalysis?.heatmapPoints ?? const [],
          firstHalfSprintPolylines: firstHalfSprintPolylines,
          firstHalfSprintSegments: firstHalfSprintSegments,
          secondHalfSamples: secondHalfSamples,
          secondHalfHeatmapPoints:
              secondHalfAnalysis?.heatmapPoints ?? const [],
          secondHalfSprintPolylines: secondHalfSprintPolylines,
          secondHalfSprintSegments: secondHalfSprintSegments,
          persist: true,
          skipSchematicPersist: kUseCloudSensorAnalysis,
        );

        svgFullMatch = bundle.fullMatch;
        svgFullMatchWithSprints = bundle.fullMatchWithSprints;
        svgFirstHalf = bundle.firstHalf;
        svgFirstHalfWithSprints = bundle.firstHalfWithSprints;
        svgSecondHalf = bundle.secondHalf;
        svgSecondHalfWithSprints = bundle.secondHalfWithSprints;
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
      _showSnackBar(context.l10n.successConversionDone(_rowsCount));

    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context.l10n.asiConversionError(e.toString()));
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

  String _formatPeriodsSummary(BuildContext context) {
    final l10n = context.l10n;
    if (widget.periods.isEmpty) {
      return l10n.periodUndefined;
    }

    if (widget.periods.length == 1) {
      return l10n.asiPeriodsOne;
    }

    return l10n.asiPeriodsMany(widget.periods.length);
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
                  context.l10n.asiImportTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.asiImportSubtitle,
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
                          context.l10n.infoParameters,
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _deviceIdCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.entityDeviceId,
                            hintText: context.l10n.hintDeviceIdExample,
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
                                context.l10n.entityPeriods,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _formatPeriodsSummary(context),
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
                                context.l10n.asiFileSelectedLabel,
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
                                          context.l10n.emptyNoFileSelected,
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
                                    label: Text(context.l10n.actionChooseAsiFile),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading ||
                                        _selectedFileName == null
                                        ? null
                                        : _clearSelection,
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(context.l10n.actionReset),
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
                                  ? context.l10n.asiConverting
                                  : context.l10n.actionConvertToCsv,
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
                            context.l10n.entityHeatmap,
                            style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.asiHeatmapPointCount(
                              _displayAnalysisResult!.heatmapPoints.length,
                              _selectedPeriodInfo(context),
                            ),
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
                                  DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.fullMatch,
                                    child: Text(context.l10n.entityFullMatch),
                                  ),
                                  DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.firstHalf,
                                    enabled: _firstHalfPeriod != null,
                                    child: Text(
                                      _firstHalfPeriod != null
                                          ? context.l10n.halfFirst
                                          : context.l10n.halfFirstUnavailable,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: HeatmapDisplayPeriod.secondHalf,
                                    enabled: _secondHalfPeriod != null,
                                    child: Text(
                                      _secondHalfPeriod != null
                                          ? context.l10n.halfSecond
                                          : context.l10n.halfSecondUnavailable,
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
        title: Text(context.l10n.dialogAsiConversionTitle),
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
                        dialogContext.l10n.asiImportFileHeader,
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
                      child: Text(dialogContext.l10n.actionCancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(dialogContext.l10n.actionClose),
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