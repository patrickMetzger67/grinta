import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/timeRange.dart';
import '../model/tracker/trackerData.dart';
import '../model/trackerDeviceRaw.dart';
import '../services/sensorAnalysisService.dart';
import '../services/trackerDataAnalysisService.dart';
import '../util/app_theme.dart';

class AsiConverterScreen extends StatefulWidget {
  final String deviceId;
  final List<TimeRange> periods;
  final bool showAppBar;
  final bool isMatch;
  final String eventId;

  const AsiConverterScreen({
    super.key,
    required this.deviceId,
    required this.isMatch,
    required this.eventId,
    this.periods = const [],
    this.showAppBar = true,

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

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

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

      final analysis = SensorAnalysisService.analyzeSensorData(
        trackerId: deviceId,
        allSamples: trackerSamples,
        isMatch: widget.isMatch,
        playerId: deviceId,
      );

      debugPrint('deviceId: ${analysis.trackerId}');
      debugPrint('distanceKm: ${analysis.distanceKm}');
      debugPrint('duration: ${analysis.duration}');
      debugPrint('averageSpeedKmh: ${analysis.averageSpeedKmh}');
      debugPrint('maxSpeedKmh: ${analysis.maxSpeedKmh}');
      debugPrint('samplesCount: ${analysis.samplesCount}');
      debugPrint('sprintCount: ${analysis.sprintCount}');
      debugPrint('timeAbove20Kmh: ${analysis.timeAbove20Kmh}');
      debugPrint('maxAccelerationMps2: ${analysis.maxAccelerationMps2}');
      debugPrint('heatmapPoint=${analysis.heatmapPoints.length}');
      debugPrint('workloadScore: ${analysis.workloadScore}');

      print('maxValidatedSpeedKmh: ${analysis.maxValidatedSpeedKmh}');
      print('highAccelerationCount: ${analysis.highAccelerationCount}');
      print('playerProfile: ${analysis.playerProfile}');
      print('fatigueIndex: ${analysis.fatigueIndex}');
      print('firstHalfDistanceKm: ${analysis.firstHalfDistanceKm}');
      print('secondHalfDistanceKm: ${analysis.secondHalfDistanceKm}');

      final firstHalf = analysis.halfStats.firstWhere((e) => e.halfIndex == 1);
      final secondHalf = analysis.halfStats.firstWhere((e) => e.halfIndex == 2);

      print('Diff distance: ${secondHalf.distanceKm - firstHalf.distanceKm}');
      print('Diff vitesse: ${secondHalf.averageSpeedKmh - firstHalf.averageSpeedKmh}');
      print('RESULT distanceTimeline length = ${analysis.distanceTimeline.length}');
      print('RESULT toMap distanceTimeline = ${analysis.toMap()['distanceTimeline']}');

      for (final z in analysis.speedZones) {
        print('${z.zoneId} -> ${z.duration} (${z.percentOfSession.toStringAsFixed(1)}%)');
      }

      print('heatmap=${analysis.heatmapPoints.length}');

      final url = await SensorAnalysisService.heatmapToCsv(
        deviceId: widget.deviceId,
        eventId: widget.eventId,
        heatmapPoints: analysis.heatmapPoints,
      );
      final docId = await TrackerAnalysisService.saveAnalysis(
        docId: '${widget.eventId}_${widget.deviceId}',
        analysis,
        eventId: widget.eventId,
      );


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
    });
  }

  String _formatPeriodsSummary() {
    if (widget.periods.isEmpty) {
      return 'Aucune période définie';
    }

    return '${widget.periods.length} période(s) transmise(s)';
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
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                                    onPressed:
                                    _isLoading ? null : _pickAsiFile,
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
                if (_csvResult != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Résultat CSV',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (_rowsCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text(
                                    '$_rowsCount ligne(s)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: _csvResult!),
                                  );

                                  if (!mounted) return;

                                  _showSnackBar(
                                    'CSV copié dans le presse-papiers',
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copier'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              minHeight: 220,
                              maxHeight: 420,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _csvResult!,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: colors.textPrimary,
                                  height: 1.45,
                                ),
                              ),
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
  required List<TimeRange> periods,
  required bool isMatch,
  required String eventId,
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