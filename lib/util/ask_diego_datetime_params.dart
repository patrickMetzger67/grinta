import 'package:flutter/material.dart';

/// Resolved date/time for Ask Diego create_training / create_match navigation.
class AskDiegoCreateEventDateTime {
  const AskDiegoCreateEventDateTime({this.date, this.time});

  final DateTime? date;
  final TimeOfDay? time;
}

/// Parses navigate params from Diego, with optional French fallback from [userMessage].
AskDiegoCreateEventDateTime resolveCreateEventDateTime({
  required Map<String, dynamic> params,
  String? userMessage,
  DateTime? referenceDate,
}) {
  final DateTime ref = referenceDate ?? DateTime.now();
  DateTime? date = parseIsoDateParam(params['date']?.toString());
  TimeOfDay? time = parseTimeParam(params['time']?.toString());

  final String message = userMessage?.trim() ?? '';
  if (message.isNotEmpty) {
    date ??= parseFrenchRelativeDate(message, ref);
    time ??= parseFrenchTime(message);
  }

  return AskDiegoCreateEventDateTime(date: date, time: time);
}

/// Parses `yyyy-MM-dd` (or ISO datetime — date part only).
DateTime? parseIsoDateParam(String? raw) {
  final String value = raw?.trim() ?? '';
  if (value.isEmpty) return null;

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Parses `HH:mm` (24h).
TimeOfDay? parseTimeParam(String? raw) {
  final String value = raw?.trim() ?? '';
  if (value.isEmpty) return null;

  final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;

  final int? hour = int.tryParse(match.group(1)!);
  final int? minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// Best-effort French relative date from natural language (fallback when Diego omits params).
DateTime? parseFrenchRelativeDate(String message, DateTime reference) {
  final String normalized = _normalizeFrench(message);
  if (normalized.isEmpty) return null;

  final DateTime today = DateTime(reference.year, reference.month, reference.day);

  if (RegExp(r'\bdemain\b').hasMatch(normalized)) {
    return today.add(const Duration(days: 1));
  }
  if (RegExp(r'\bapres-demain\b').hasMatch(normalized)) {
    return today.add(const Duration(days: 2));
  }
  if (RegExp(r"\baujourd'?hui\b").hasMatch(normalized)) {
    return today;
  }

  const Map<String, int> weekdays = <String, int>{
    'lundi': DateTime.monday,
    'mardi': DateTime.tuesday,
    'mercredi': DateTime.wednesday,
    'jeudi': DateTime.thursday,
    'vendredi': DateTime.friday,
    'samedi': DateTime.saturday,
    'dimanche': DateTime.sunday,
  };

  for (final MapEntry<String, int> entry in weekdays.entries) {
    final String day = entry.key;
    final int weekday = entry.value;
    final bool isProchain = RegExp('$day\\s+prochain(e)?\\b').hasMatch(normalized);
    final bool isCe = RegExp('ce\\s+$day\\b').hasMatch(normalized);
    final bool isBare = RegExp('\\b$day\\b').hasMatch(normalized);
    if (!isProchain && !isCe && !isBare) continue;

    if (isCe) {
      return _dateOnWeekday(reference: today, weekday: weekday, sameWeek: true);
    }
    return _nextWeekdayDate(
      reference: today,
      weekday: weekday,
      forceNextWeek: isProchain,
    );
  }

  return null;
}

/// Best-effort French time from natural language (fallback when Diego omits params).
TimeOfDay? parseFrenchTime(String message) {
  final String normalized = _normalizeFrench(message);
  if (normalized.isEmpty) return null;

  final Iterable<RegExpMatch> colonMatches =
      RegExp(r'(?:\ba\s*)?(\d{1,2}):(\d{2})\b').allMatches(normalized);
  for (final RegExpMatch match in colonMatches) {
    final TimeOfDay? parsed = _timeFromParts(match.group(1), match.group(2));
    if (parsed != null) return parsed;
  }

  final Iterable<RegExpMatch> hMatches =
      RegExp(r'(?:\ba\s*)?(\d{1,2})\s*h(?:\s*(\d{2}))?\b').allMatches(normalized);
  for (final RegExpMatch match in hMatches) {
    final TimeOfDay? parsed = _timeFromParts(match.group(1), match.group(2) ?? '0');
    if (parsed != null) return parsed;
  }

  final RegExpMatch? heuresMatch =
      RegExp(r'(?:\ba\s*)?(\d{1,2})\s*heures?\b').firstMatch(normalized);
  if (heuresMatch != null) {
    return _timeFromParts(heuresMatch.group(1), '0');
  }

  return null;
}

String _normalizeFrench(String input) {
  return input
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ô', 'o')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

TimeOfDay? _timeFromParts(String? hourRaw, String? minuteRaw) {
  final int? hour = int.tryParse(hourRaw ?? '');
  final int? minute = int.tryParse(minuteRaw ?? '');
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

DateTime _nextWeekdayDate({
  required DateTime reference,
  required int weekday,
  required bool forceNextWeek,
}) {
  int delta = (weekday - reference.weekday + 7) % 7;
  if (delta == 0) delta = 7;

  DateTime candidate = reference.add(Duration(days: delta));
  if (forceNextWeek) {
    final DateTime refWeekStart = _mondayOfWeek(reference);
    final DateTime candidateWeekStart = _mondayOfWeek(candidate);
    if (!candidateWeekStart.isAfter(refWeekStart)) {
      candidate = candidate.add(const Duration(days: 7));
    }
  }
  return DateTime(candidate.year, candidate.month, candidate.day);
}

DateTime _dateOnWeekday({
  required DateTime reference,
  required int weekday,
  required bool sameWeek,
}) {
  if (!sameWeek) {
    return _nextWeekdayDate(
      reference: reference,
      weekday: weekday,
      forceNextWeek: false,
    );
  }

  final DateTime weekStart = _mondayOfWeek(reference);
  final DateTime target = weekStart.add(Duration(days: weekday - 1));
  if (target.isBefore(reference)) {
    return _nextWeekdayDate(
      reference: reference,
      weekday: weekday,
      forceNextWeek: false,
    );
  }
  return DateTime(target.year, target.month, target.day);
}

DateTime _mondayOfWeek(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}
