import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Inclusive calendar bounds for a player activity report period.
class AskDiegoActivityPeriod {
  const AskDiegoActivityPeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  int get dayCount => end.difference(start).inDays + 1;

  /// Previous period for trend comparison.
  ///
  /// Full calendar months compare to the previous calendar month; other ranges
  /// use a rolling window of the same [dayCount] immediately before [start].
  AskDiegoActivityPeriod previousPeriod(String localeCode) {
    if (_isFullCalendarMonth(start, end)) {
      final previousMonthStart = DateTime(start.year, start.month - 1);
      final previousMonthEnd = DateTime(start.year, start.month, 0);
      return AskDiegoActivityPeriod(
        start: previousMonthStart,
        end: previousMonthEnd,
        label: _formatMonthLabel(previousMonthStart, localeCode),
      );
    }

    final durationDays = dayCount;
    final previousEnd = DateUtils.dateOnly(start.subtract(const Duration(days: 1)));
    final previousStart =
        previousEnd.subtract(Duration(days: durationDays - 1));
    return AskDiegoActivityPeriod(
      start: previousStart,
      end: previousEnd,
      label: _formatRangeLabel(previousStart, previousEnd, localeCode),
    );
  }

  static bool _isFullCalendarMonth(DateTime start, DateTime end) {
    if (start.day != 1) {
      return false;
    }
    final lastDayOfMonth = DateTime(start.year, start.month + 1, 0).day;
    return end.year == start.year &&
        end.month == start.month &&
        end.day == lastDayOfMonth;
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return <String, dynamic>{
      'start': dateFormat.format(start),
      'end': dateFormat.format(end),
      'label': label,
      'dayCount': dayCount,
    };
  }
}

/// Parses a natural-language activity period from [message].
///
/// Returns null when no supported period expression is found.
AskDiegoActivityPeriod? parseActivityPeriodFromMessage({
  required String message,
  required DateTime referenceDate,
  String localeCode = 'fr',
}) {
  final normalized = _normalizeText(message);
  if (normalized.isEmpty) {
    return null;
  }

  final today = DateUtils.dateOnly(referenceDate);

  final singleDay = _parseSingleDay(normalized, today, localeCode);
  if (singleDay != null) {
    return singleDay;
  }

  final lastWeek = _parseLastWeek(normalized, today, localeCode);
  if (lastWeek != null) {
    return lastWeek;
  }

  final thisWeek = _parseThisWeek(normalized, today, localeCode);
  if (thisWeek != null) {
    return thisWeek;
  }

  final month = _parseMonthPeriod(normalized, today, localeCode);
  if (month != null) {
    return month;
  }

  final lastMonth = _parseLastMonth(normalized, today, localeCode);
  if (lastMonth != null) {
    return lastMonth;
  }

  final lastNDays = _parseLastNDays(normalized, today, localeCode);
  if (lastNDays != null) {
    return lastNDays;
  }

  return null;
}

AskDiegoActivityPeriod? _parseSingleDay(
  String normalized,
  DateTime today,
  String localeCode,
) {
  const yesterdayPatterns = <String>[
    r'\bhier\b',
    r'\byesterday\b',
    r'\bieri\b',
    r'\bgestern\b',
    r'\bayer\b',
  ];
  if (_matchesAny(normalized, yesterdayPatterns)) {
    final day = today.subtract(const Duration(days: 1));
    return AskDiegoActivityPeriod(
      start: day,
      end: day,
      label: _formatRangeLabel(day, day, localeCode),
    );
  }

  const todayPatterns = <String>[
    r"\baujourd[\s']?hui\b",
    r'\baujourd\s*hui\b',
    r'\btoday\b',
    r'\boggi\b',
    r'\bheute\b',
    r'\bhoy\b',
  ];
  if (_matchesAny(normalized, todayPatterns)) {
    return AskDiegoActivityPeriod(
      start: today,
      end: today,
      label: _formatRangeLabel(today, today, localeCode),
    );
  }

  const dayBeforeYesterdayPatterns = <String>[
    r'\bavant[\s-]hier\b',
    r'\bday\s+before\s+yesterday\b',
    r'\bavantieri\b',
    r'\bvorgestern\b',
    r'\banteayer\b',
  ];
  if (_matchesAny(normalized, dayBeforeYesterdayPatterns)) {
    final day = today.subtract(const Duration(days: 2));
    return AskDiegoActivityPeriod(
      start: day,
      end: day,
      label: _formatRangeLabel(day, day, localeCode),
    );
  }

  return null;
}

AskDiegoActivityPeriod? _parseLastWeek(
  String normalized,
  DateTime today,
  String localeCode,
) {
  const patterns = <String>[
    r'\b(?:la\s+)?semaine\s+(?:derniere|passee|precedente)\b',
    r'\b(?:last|previous)\s+week\b',
    r'\bscorsa\s+settimana\b',
    r'\bletzte\s+woche\b',
    r'\bsemana\s+(?:pasada|anterior)\b',
  ];

  if (!_matchesAny(normalized, patterns)) {
    return null;
  }

  final weekStart = _mondayOfWeek(today).subtract(const Duration(days: 7));
  final weekEnd = weekStart.add(const Duration(days: 6));
  return AskDiegoActivityPeriod(
    start: weekStart,
    end: weekEnd,
    label: _formatRangeLabel(weekStart, weekEnd, localeCode),
  );
}

AskDiegoActivityPeriod? _parseThisWeek(
  String normalized,
  DateTime today,
  String localeCode,
) {
  const patterns = <String>[
    r'\b(?:cette|cette-ci|la)\s+semaine\b',
    r'\bthis\s+week\b',
    r'\bquesta\s+settimana\b',
    r'\bdiese\s+woche\b',
    r'\besta\s+semana\b',
  ];

  if (!_matchesAny(normalized, patterns)) {
    return null;
  }

  final weekStart = _mondayOfWeek(today);
  final weekEnd = weekStart.add(const Duration(days: 6));
  return AskDiegoActivityPeriod(
    start: weekStart,
    end: weekEnd,
    label: _formatRangeLabel(weekStart, weekEnd, localeCode),
  );
}

AskDiegoActivityPeriod? _parseLastMonth(
  String normalized,
  DateTime today,
  String localeCode,
) {
  const patterns = <String>[
    r'\b(?:le\s+)?mois\s+(?:dernier|passee|precedent)\b',
    r'\blast\s+month\b',
    r'\bscorso\s+mese\b',
    r'\bletzten\s+monat\b',
    r'\bel\s+mes\s+(?:pasado|anterior)\b',
  ];

  if (!_matchesAny(normalized, patterns)) {
    return null;
  }

  final firstOfThisMonth = DateTime(today.year, today.month);
  final lastMonthEnd = firstOfThisMonth.subtract(const Duration(days: 1));
  final lastMonthStart = DateTime(lastMonthEnd.year, lastMonthEnd.month);
  return AskDiegoActivityPeriod(
    start: lastMonthStart,
    end: lastMonthEnd,
    label: _formatMonthLabel(lastMonthStart, localeCode),
  );
}

AskDiegoActivityPeriod? _parseLastNDays(
  String normalized,
  DateTime today,
  String localeCode,
) {
  final match = RegExp(
    r'\b(?:last|derniers?|ultimi|letzten?)\s+(\d{1,3})\s+(?:days?|jours?|giorni|tage)\b',
  ).firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final days = int.tryParse(match.group(1) ?? '');
  if (days == null || days <= 0 || days > 366) {
    return null;
  }

  final end = today;
  final start = end.subtract(Duration(days: days - 1));
  return AskDiegoActivityPeriod(
    start: start,
    end: end,
    label: _formatRangeLabel(start, end, localeCode),
  );
}

AskDiegoActivityPeriod? _parseMonthPeriod(
  String normalized,
  DateTime today,
  String localeCode,
) {
  final explicitYearMonth = RegExp(
    r'\b(\d{4})[-/](\d{1,2})\b',
  ).firstMatch(normalized);
  if (explicitYearMonth != null) {
    final year = int.tryParse(explicitYearMonth.group(1)!);
    final month = int.tryParse(explicitYearMonth.group(2)!);
    if (year != null && month != null && month >= 1 && month <= 12) {
      return _monthPeriod(year, month, localeCode);
    }
  }

  for (final MapEntry<String, int> entry in _monthNames.entries) {
    final name = entry.key;
    final month = entry.value;

    final withYear = RegExp(
      '$name\\s+(\\d{4})',
    ).firstMatch(normalized);
    if (withYear != null) {
      final year = int.tryParse(withYear.group(1)!);
      if (year != null) {
        return _monthPeriod(year, month, localeCode);
      }
    }

    if (RegExp('\\b$name\\b').hasMatch(normalized)) {
      var year = today.year;
      final candidate = DateTime(year, month);
      if (candidate.isAfter(DateTime(today.year, today.month, today.day))) {
        year -= 1;
      }
      return _monthPeriod(year, month, localeCode);
    }
  }

  return null;
}

AskDiegoActivityPeriod _monthPeriod(int year, int month, String localeCode) {
  final start = DateTime(year, month);
  final end = DateTime(year, month + 1, 0);
  return AskDiegoActivityPeriod(
    start: start,
    end: end,
    label: _formatMonthLabel(start, localeCode),
  );
}

String _formatMonthLabel(DateTime date, String localeCode) {
  final formatted = DateFormat.yMMMM(localeCode).format(date);
  if (formatted.isEmpty) {
    return DateFormat('yyyy-MM').format(date);
  }
  return formatted[0].toUpperCase() + formatted.substring(1);
}

String _formatRangeLabel(DateTime start, DateTime end, String localeCode) {
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return DateFormat.yMMMMd(localeCode).format(start);
  }
  if (start.year == end.year && start.month == end.month) {
    return '${DateFormat.d(localeCode).format(start)}–${DateFormat.yMMMMd(localeCode).format(end)}';
  }
  return '${DateFormat.yMMMd(localeCode).format(start)} – ${DateFormat.yMMMd(localeCode).format(end)}';
}

DateTime _mondayOfWeek(DateTime date) {
  return DateUtils.dateOnly(date)
      .subtract(Duration(days: date.weekday - DateTime.monday));
}

bool _matchesAny(String normalized, List<String> patterns) {
  for (final pattern in patterns) {
    if (RegExp(pattern).hasMatch(normalized)) {
      return true;
    }
  }
  return false;
}

String _normalizeText(String input) {
  return input
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ç', 'c')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Month names in fr / en / de / es / it (normalized, no accents).
const Map<String, int> _monthNames = <String, int>{
  'janvier': 1,
  'january': 1,
  'januar': 1,
  'enero': 1,
  'gennaio': 1,
  'fevrier': 2,
  'february': 2,
  'februar': 2,
  'febrero': 2,
  'febbraio': 2,
  'mars': 3,
  'march': 3,
  'marz': 3,
  'marzo': 3,
  'avril': 4,
  'april': 4,
  'abril': 4,
  'aprile': 4,
  'mai': 5,
  'may': 5,
  'maggio': 5,
  'mayo': 5,
  'juin': 6,
  'june': 6,
  'juni': 6,
  'junio': 6,
  'giugno': 6,
  'juillet': 7,
  'july': 7,
  'juli': 7,
  'julio': 7,
  'luglio': 7,
  'aout': 8,
  'august': 8,
  'augustus': 8,
  'agosto': 8,
  'septembre': 9,
  'september': 9,
  'septiembre': 9,
  'settembre': 9,
  'octobre': 10,
  'october': 10,
  'oktober': 10,
  'octubre': 10,
  'ottobre': 10,
  'novembre': 11,
  'november': 11,
  'noviembre': 11,
  'decembre': 12,
  'december': 12,
  'dezember': 12,
  'diciembre': 12,
  'dicembre': 12,
};
