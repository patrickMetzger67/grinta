import 'package:grinta/model/season.dart';

/// Inclusive calendar bounds for filtering match dates.
class SeasonPeriodRange {
  const SeasonPeriodRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !normalized.isBefore(startDay) && !normalized.isAfter(endDay);
  }
}

/// Full season plus first/second half splits for football season stats.
class SeasonPeriodRanges {
  const SeasonPeriodRanges({
    required this.fullSeason,
    required this.firstHalf,
    required this.secondHalf,
  });

  final SeasonPeriodRange fullSeason;
  final SeasonPeriodRange firstHalf;
  final SeasonPeriodRange secondHalf;
}

/// Derives football season period boundaries.
///
/// Prefers [season] Firestore dates when present, otherwise parses
/// [seasonId] as `YYYY-YYYY` (e.g. `2025-2026`).
///
/// Halves follow the French season convention:
/// - first half: 01/07 → 31/12 of the start year
/// - second half: 01/01 → 30/06 of the end year
SeasonPeriodRanges resolveSeasonPeriodRanges({
  required String seasonId,
  Season? season,
}) {
  final parsedYears = _parseSeasonYears(seasonId, season);
  final int startYear = parsedYears.$1;
  final int endYear = parsedYears.$2;

  final DateTime defaultFullStart = DateTime(startYear, 7, 1);
  final DateTime defaultFullEnd = DateTime(endYear, 6, 30);

  final DateTime? seasonStart = season?.startDate?.toDate();
  final DateTime? seasonEnd = season?.endDate?.toDate();

  final DateTime fullStart = seasonStart ?? defaultFullStart;
  final DateTime fullEnd = seasonEnd ?? defaultFullEnd;

  return SeasonPeriodRanges(
    fullSeason: SeasonPeriodRange(start: fullStart, end: fullEnd),
    firstHalf: SeasonPeriodRange(
      start: DateTime(startYear, 7, 1),
      end: DateTime(startYear, 12, 31),
    ),
    secondHalf: SeasonPeriodRange(
      start: DateTime(endYear, 1, 1),
      end: DateTime(endYear, 6, 30),
    ),
  );
}

(int, int) _parseSeasonYears(String seasonId, Season? season) {
  final fromId = _parseYearPair(seasonId);
  if (fromId != null) {
    return fromId;
  }

  final seasonName = season?.name?.trim() ?? '';
  final fromName = _parseYearPair(seasonName);
  if (fromName != null) {
    return fromName;
  }

  final start = season?.startDate?.toDate();
  final end = season?.endDate?.toDate();
  if (start != null && end != null) {
    return (start.year, end.year);
  }

  final now = DateTime.now();
  final startYear = now.month >= 7 ? now.year : now.year - 1;
  return (startYear, startYear + 1);
}

(int, int)? _parseYearPair(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(r'^(\d{4})\s*[-/]\s*(\d{4})$').firstMatch(trimmed);
  if (match == null) return null;

  final startYear = int.tryParse(match.group(1) ?? '');
  final endYear = int.tryParse(match.group(2) ?? '');
  if (startYear == null || endYear == null) return null;

  return (startYear, endYear);
}
