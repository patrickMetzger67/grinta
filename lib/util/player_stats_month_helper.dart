import 'package:intl/intl.dart';

/// Calendar month key (`yyyy-MM`) for grouping player stats.
String calendarMonthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

/// Localized month label (e.g. "juin 2026").
String calendarMonthLabel(DateTime date, String localeCode) {
  final formatted = DateFormat.yMMMM(localeCode).format(
    DateTime(date.year, date.month),
  );
  if (formatted.isEmpty) {
    return calendarMonthKey(date);
  }
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// Aggregates playing time for one calendar month.
class MonthPlayingTimeBucket {
  MonthPlayingTimeBucket({
    required this.year,
    required this.month,
  });

  final int year;
  final int month;
  int minutes = 0;
  int matchesPlayed = 0;

  String get key => calendarMonthKey(DateTime(year, month));

  void addMatch({required int matchMinutes}) {
    if (matchMinutes > 0) {
      minutes += matchMinutes;
    }
    matchesPlayed++;
  }

  Map<String, dynamic> toJson(String localeCode) {
    return <String, dynamic>{
      'month': key,
      'monthLabel': calendarMonthLabel(DateTime(year, month), localeCode),
      'minutes': minutes,
      'matchesPlayed': matchesPlayed,
    };
  }
}

/// Aggregates training attendance for one calendar month.
class MonthTrainingAttendanceBucket {
  MonthTrainingAttendanceBucket({
    required this.year,
    required this.month,
  });

  final int year;
  final int month;
  int present = 0;
  int absent = 0;

  String get key => calendarMonthKey(DateTime(year, month));

  int get totalTrainings => present + absent;

  double? get ratePercent {
    if (totalTrainings <= 0) {
      return null;
    }
    return (present / totalTrainings) * 100;
  }

  Map<String, dynamic> toJson(String localeCode) {
    return <String, dynamic>{
      'month': key,
      'monthLabel': calendarMonthLabel(DateTime(year, month), localeCode),
      'present': present,
      'absent': absent,
      'ratePercent': ratePercent,
      'totalTrainings': totalTrainings,
    };
  }
}

MonthPlayingTimeBucket playingTimeBucketForDate(
  Map<String, MonthPlayingTimeBucket> buckets,
  DateTime date,
) {
  return buckets.putIfAbsent(
    calendarMonthKey(date),
    () => MonthPlayingTimeBucket(year: date.year, month: date.month),
  );
}

MonthTrainingAttendanceBucket trainingAttendanceBucketForDate(
  Map<String, MonthTrainingAttendanceBucket> buckets,
  DateTime date,
) {
  return buckets.putIfAbsent(
    calendarMonthKey(date),
    () => MonthTrainingAttendanceBucket(year: date.year, month: date.month),
  );
}

List<Map<String, dynamic>> sortedPlayingTimeByMonth(
  Map<String, MonthPlayingTimeBucket> buckets,
  String localeCode,
) {
  final sorted = buckets.values.toList()
    ..sort((MonthPlayingTimeBucket a, MonthPlayingTimeBucket b) {
      if (a.year != b.year) {
        return a.year.compareTo(b.year);
      }
      return a.month.compareTo(b.month);
    });
  return sorted.map((bucket) => bucket.toJson(localeCode)).toList();
}

List<Map<String, dynamic>> sortedTrainingAttendanceByMonth(
  Map<String, MonthTrainingAttendanceBucket> buckets,
  String localeCode,
) {
  final sorted = buckets.values.toList()
    ..sort((MonthTrainingAttendanceBucket a, MonthTrainingAttendanceBucket b) {
      if (a.year != b.year) {
        return a.year.compareTo(b.year);
      }
      return a.month.compareTo(b.month);
    });
  return sorted.map((bucket) => bucket.toJson(localeCode)).toList();
}
