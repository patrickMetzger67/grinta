import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/util/calendar_event_formatter.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:intl/intl.dart';

/// Match day used for unavailability checks (kick-off when known, else date only).
DateTime? matchEventDateTime(models.Match match) {
  return matchKickoffDateTime(match) ?? parseMatchDateCh(match.dateCh);
}

/// Default gathering address for a match convocation sheet.
String defaultMatchConvocationAddress(models.Match match) {
  final saved = match.addressConvo?.trim() ?? '';
  if (saved.isNotEmpty) {
    return saved;
  }

  final location = CalendarEventFormatter.matchLocation(match)?.trim() ?? '';
  if (location.isNotEmpty) {
    return location;
  }

  final parts = <String>[
    match.nomDuTerrain?.trim() ?? '',
    match.terrainAdresse1?.trim() ?? '',
    match.terrainAddress2?.trim() ?? '',
  ].where((part) => part.isNotEmpty);

  return parts.join(' — ');
}

/// Default gathering time for a match convocation sheet.
DateTime defaultMatchConvocationDateTime(models.Match match) {
  final saved = match.dateTimeConvo?.toDate();
  if (saved != null) {
    return saved;
  }

  final matchDate = parseMatchDateCh(match.dateCh);
  final matchTime = parseMatchTimeCh(match.timeCh);
  if (matchDate != null && matchTime != null) {
    final kickoff = DateTime(
      matchDate.year,
      matchDate.month,
      matchDate.day,
      matchTime.hour,
      matchTime.minute,
    );
    return kickoff.subtract(const Duration(hours: 1));
  }

  if (matchDate != null) {
    return DateTime(matchDate.year, matchDate.month, matchDate.day, 17, 0);
  }

  return DateTime.now().add(const Duration(hours: 1));
}

String _clean(String? value) => value?.trim() ?? '';

String matchConvocationOpponentLabel(models.Match match) {
  final team1 = _clean(match.team1);
  final team2 = _clean(match.team2);
  if (team1.isNotEmpty && team2.isNotEmpty) {
    return '$team1 - $team2';
  }
  return team1.isNotEmpty ? team1 : team2;
}

String formatConvocationDateTime(AppLocalizations l10n, DateTime dateTime) {
  final locale = l10n.localeName;
  final date = DateFormat.yMMMd(locale).format(dateTime);
  final time = DateFormat.Hm(locale).format(dateTime);
  return l10n.matchConvocationsSendDateTimeValue(date, time);
}

/// Full in-app / Firestore notification body for a convocation.
String buildConvocationNotificationBody({
  required AppLocalizations l10n,
  required String message,
  required DateTime convocationDateTime,
  required String address,
  required models.Match match,
}) {
  final buffer = StringBuffer();

  final trimmedMessage = message.trim();
  if (trimmedMessage.isNotEmpty) {
    buffer.writeln(trimmedMessage);
    buffer.writeln();
  }

  final opponent = matchConvocationOpponentLabel(match);
  if (opponent.isNotEmpty) {
    buffer.writeln(l10n.matchConvocationsSendMatchLine(opponent));
  }

  buffer.writeln(
    l10n.matchConvocationsSendTimeLine(
      formatConvocationDateTime(l10n, convocationDateTime),
    ),
  );

  final trimmedAddress = address.trim();
  if (trimmedAddress.isNotEmpty) {
    buffer.writeln(l10n.matchConvocationsSendAddressLine(trimmedAddress));
  }

  return buffer.toString().trim();
}

/// Short push body shown in the system tray.
String buildConvocationPushBody({
  required AppLocalizations l10n,
  required String message,
  required DateTime convocationDateTime,
  required models.Match match,
}) {
  final opponent = matchConvocationOpponentLabel(match);
  final timeLabel = formatConvocationDateTime(l10n, convocationDateTime);
  final trimmedMessage = message.trim();

  if (trimmedMessage.isNotEmpty) {
    return l10n.matchConvocationNotificationBodyWithMessage(
      opponent,
      timeLabel,
      trimmedMessage,
    );
  }

  return l10n.matchConvocationNotificationBody(opponent, timeLabel);
}

String? resolveMatchClubId(models.Match match) {
  for (final dynamic raw in match.clubs ?? const <dynamic>[]) {
    final clubId = raw?.toString().trim() ?? '';
    if (clubId.isNotEmpty) {
      return clubId;
    }
  }
  return null;
}
