import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/util/calendar_event_formatter.dart';

/// Builds RFC 5545 ICS calendar files from agenda items.
class CalendarIcsBuilder {
  const CalendarIcsBuilder._();

  static String buildCalendar({
    required String calendarName,
    required List<AgendaItem> items,
    required String Function(AgendaItem item) eventUrlBuilder,
  }) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Grinta//Calendar//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:${_escapeText(calendarName)}');

    for (final item in items) {
      buffer.writeln(_buildEvent(item, eventUrlBuilder: eventUrlBuilder));
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _buildEvent(
    AgendaItem item, {
    required String Function(AgendaItem item) eventUrlBuilder,
  }) {
    final url = eventUrlBuilder(item);
    final title = CalendarEventFormatter.eventTitle(item);
    final description = CalendarEventFormatter.eventDescription(
      deepLink: url,
      item: item,
    );
    final location = CalendarEventFormatter.eventLocation(item);
    final geo = item.type == AgendaItemType.match
        ? CalendarEventFormatter.icsGeoValue(item.match)
        : null;

    final buffer = StringBuffer()
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${_eventUid(item)}')
      ..writeln('DTSTAMP:${_formatDateTime(DateTime.now().toUtc())}')
      ..writeln('DTSTART:${_formatDateTime(item.startAt.toUtc())}')
      ..writeln('DTEND:${_formatDateTime(item.endAt.toUtc())}')
      ..writeln('SUMMARY:${_escapeText(title)}')
      ..writeln('DESCRIPTION:${_escapeText(description)}')
      ..writeln('URL:$url');

    if (location != null && location.isNotEmpty) {
      buffer.writeln('LOCATION:${_escapeText(location)}');
    }
    if (geo != null) {
      buffer.writeln('GEO:$geo');
    }

    buffer.writeln('END:VEVENT');
    return buffer.toString();
  }

  static String _eventUid(AgendaItem item) {
    return '${item.type.name}-${item.id}@grinta.io';
  }

  static String _formatDateTime(DateTime utc) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
  }
}
