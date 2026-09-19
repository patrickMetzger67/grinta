import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/model/tracker/trackerData.dart';

/// How many previous sessions of the same type Gio compares against.
const int kGioSessionOpinionRecentLimit = 5;

const String kGioSessionTypeTraining = 'training';
const String kGioSessionTypeMatch = 'match';

enum GioSessionOpinionSource { gps, polar }

/// One training or match performance snapshot sent to Gio.
class GioOpinionSessionRecord {
  const GioOpinionSessionRecord({
    required this.eventId,
    required this.sessionType,
    required this.metrics,
    this.date,
    this.label,
  });

  final String eventId;
  final String sessionType;
  final Map<String, num> metrics;
  final DateTime? date;
  final String? label;
}

String gioSessionType({required bool isMatch}) {
  return isMatch ? kGioSessionTypeMatch : kGioSessionTypeTraining;
}

String gioSessionOpinionSourceValue(GioSessionOpinionSource source) {
  return source == GioSessionOpinionSource.polar ? 'polar' : 'gps';
}

/// Fixed instruction sent with [buildGioSessionOpinionContext].
String gioSessionOpinionUserMessage({required bool isMatch}) {
  final kind = isMatch ? 'match' : 'entraînement';
  final sameType = isMatch ? 'matchs' : 'entraînements';
  return "Le joueur vient d'ouvrir sa fiche performance ($kind). "
      "Donne l'avis de Gio : commente les résultats de cette séance et "
      "analyse-les par rapport aux derniers résultats du même type "
      '(uniquement des $sameType). '
      'Utilise uniquement context.sessionPerformanceOpinion. '
      'Réponds dans la langue de context.locale. Pas de navigation.';
}

String? formatGioOpinionDate(DateTime? date) {
  if (date == null) return null;
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// GPS synthesis metrics Gio is allowed to comment on.
Map<String, num> gioMetricsFromTrackerAnalysis(TrackerAnalysisResult analysis) {
  return <String, num>{
    'distanceKm': _round(analysis.distanceKm, 2),
    'durationMinutes': _round(analysis.duration.inMilliseconds / 60000, 1),
    'averageSpeedKmh': _round(analysis.averageSpeedKmh, 1),
    'maxValidatedSpeedKmh': _round(analysis.maxValidatedSpeedKmh, 1),
    'sprintCount': analysis.sprintCount,
    'highAccelerationCount': analysis.highAccelerationCount,
    'highSpeedDurationSeconds': _round(
      analysis.highSpeedDuration.inMilliseconds / 1000,
      1,
    ),
    'maxAccelerationMps2': _round(analysis.maxAccelerationMps2, 2),
    'workloadScore': _round(analysis.workloadScore, 0),
    'fatigueIndex': _round(analysis.fatigueIndex, 2),
  };
}

/// Polar cardio metrics Gio is allowed to comment on.
Map<String, num> gioMetricsFromPolarAnalysis(PolarSessionAnalysis analysis) {
  final metrics = <String, num>{
    'durationMinutes': _round(analysis.duration.inMilliseconds / 60000, 1),
  };
  _put(metrics, 'avgHrBpm', analysis.avgHrBpm, 0);
  _put(metrics, 'maxHrBpm', analysis.maxHrBpm, 0);
  _put(metrics, 'minHrBpm', analysis.minHrBpm, 0);
  _put(metrics, 'caloriesKcal', analysis.caloriesKcal, 0);
  _put(metrics, 'steps', analysis.steps, 0);
  if (analysis.distanceMeters != null) {
    _put(metrics, 'distanceKm', analysis.distanceMeters! / 1000, 2);
  }
  for (final zone in const <String>['z1', 'z2', 'z3', 'z4', 'z5']) {
    final seconds = analysis.hrZoneSeconds[zone];
    if (seconds == null) continue;
    metrics['hrZone${zone.toUpperCase()}Seconds'] = seconds;
  }
  return metrics;
}

/// Context block `sessionPerformanceOpinion` for Ask Gio.
///
/// [history] may include other session types and the current event: only the
/// [recentLimit] newest records of [sessionType], excluding [current], are kept.
Map<String, dynamic> buildGioSessionOpinionContext({
  required String sessionType,
  required GioSessionOpinionSource source,
  required GioOpinionSessionRecord current,
  required List<GioOpinionSessionRecord> history,
  String? playerName,
  int recentLimit = kGioSessionOpinionRecentLimit,
}) {
  final recent = selectRecentSameTypeSessions(
    currentEventId: current.eventId,
    sessionType: sessionType,
    history: history,
    limit: recentLimit,
  );
  final averages = _averages(recent);
  final comparison = _comparison(current: current.metrics, averages: averages);
  final name = playerName?.trim() ?? '';

  return <String, dynamic>{
    'sessionType': sessionType,
    'source': gioSessionOpinionSourceValue(source),
    if (name.isNotEmpty) 'playerName': name,
    'current': _sessionJson(current),
    'recentSameType': recent.map(_sessionJson).toList(growable: false),
    'recentCount': recent.length,
    'recentAverages': averages,
    'currentVsRecentAverage': comparison,
  };
}

/// Newest [limit] sessions of [sessionType], excluding [currentEventId].
List<GioOpinionSessionRecord> selectRecentSameTypeSessions({
  required String currentEventId,
  required String sessionType,
  required List<GioOpinionSessionRecord> history,
  int limit = kGioSessionOpinionRecentLimit,
}) {
  final currentId = currentEventId.trim();
  final wantedType = sessionType.trim();
  final byEvent = <String, GioOpinionSessionRecord>{};

  for (final record in history) {
    if (record.sessionType.trim() != wantedType) continue;
    final eventId = record.eventId.trim();
    if (eventId.isEmpty || eventId == currentId) continue;
    final existing = byEvent[eventId];
    if (existing == null || _isNewer(record, existing)) {
      byEvent[eventId] = record;
    }
  }

  final sorted = byEvent.values.toList()
    ..sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

  if (limit < 0) return const <GioOpinionSessionRecord>[];
  if (sorted.length <= limit) return sorted;
  return sorted.sublist(0, limit);
}

Map<String, dynamic> _sessionJson(GioOpinionSessionRecord record) {
  final label = record.label?.trim() ?? '';
  final date = formatGioOpinionDate(record.date);
  return <String, dynamic>{
    'eventId': record.eventId.trim(),
    if (date != null) 'date': date,
    if (label.isNotEmpty) 'label': label,
    'metrics': record.metrics,
  };
}

Map<String, num> _averages(List<GioOpinionSessionRecord> sessions) {
  final sums = <String, double>{};
  final counts = <String, int>{};
  for (final session in sessions) {
    session.metrics.forEach((key, value) {
      final number = value.toDouble();
      if (!number.isFinite) return;
      sums[key] = (sums[key] ?? 0) + number;
      counts[key] = (counts[key] ?? 0) + 1;
    });
  }

  final averages = <String, num>{};
  for (final entry in sums.entries) {
    final count = counts[entry.key] ?? 0;
    if (count <= 0) continue;
    averages[entry.key] = _round(entry.value / count, 2);
  }
  return averages;
}

Map<String, dynamic> _comparison({
  required Map<String, num> current,
  required Map<String, num> averages,
}) {
  final keys = <String>{...current.keys, ...averages.keys};
  final comparison = <String, dynamic>{};
  for (final key in keys) {
    final currentValue = current[key];
    final average = averages[key];
    if (currentValue == null && average == null) continue;
    final change = _changePercent(currentValue, average);
    comparison[key] = <String, dynamic>{
      if (currentValue != null) 'current': currentValue,
      if (average != null) 'recentAverage': average,
      if (change != null) 'changePercent': change,
    };
  }
  return comparison;
}

double? _changePercent(num? current, num? previous) {
  if (current == null || previous == null) return null;
  final currentValue = current.toDouble();
  final previousValue = previous.toDouble();
  if (!currentValue.isFinite || !previousValue.isFinite) return null;
  if (previousValue == 0) {
    return currentValue == 0 ? 0 : null;
  }
  final change = ((currentValue - previousValue) / previousValue.abs()) * 100;
  if (!change.isFinite) return null;
  return double.parse(change.toStringAsFixed(1));
}

bool _isNewer(
  GioOpinionSessionRecord candidate,
  GioOpinionSessionRecord existing,
) {
  final candidateDate = candidate.date;
  final existingDate = existing.date;
  if (candidateDate == null) return false;
  if (existingDate == null) return true;
  return candidateDate.isAfter(existingDate);
}

num _round(num value, int decimals) {
  final number = value.toDouble();
  if (!number.isFinite) return 0;
  return double.parse(number.toStringAsFixed(decimals));
}

void _put(Map<String, num> metrics, String key, num? value, int decimals) {
  if (value == null) return;
  final number = value.toDouble();
  if (!number.isFinite) return;
  metrics[key] = _round(number, decimals);
}
