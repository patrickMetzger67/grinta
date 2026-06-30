import 'package:grinta/model/agendaItem.dart';

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
    final buffer = StringBuffer()
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${_eventUid(item)}')
      ..writeln('DTSTAMP:${_formatDateTime(DateTime.now().toUtc())}')
      ..writeln('DTSTART:${_formatDateTime(item.startAt.toUtc())}')
      ..writeln('DTEND:${_formatDateTime(item.endAt.toUtc())}')
      ..writeln('SUMMARY:${_escapeText(item.title)}')
      ..writeln('DESCRIPTION:${_escapeText(url)}')
      ..writeln('URL:$url')
      ..writeln('END:VEVENT');
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
