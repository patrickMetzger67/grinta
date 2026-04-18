import 'package:cloud_firestore/cloud_firestore.dart';

Timestamp buildTimestampFromDateAndTime({
  required String date,
  required String time,
}) {
  final dateParts = date.split('/');
  final timeParts = time.split(':');

  if (dateParts.length != 3) {
    throw FormatException('Date invalide: $date');
  }

  if (timeParts.length != 2) {
    throw FormatException('Heure invalide: $time');
  }

  final int day = int.parse(dateParts[0]);
  final int month = int.parse(dateParts[1]);
  final int year = int.parse(dateParts[2]);

  final int hour = int.parse(timeParts[0]);
  final int minute = int.parse(timeParts[1]);

  final dateTime = DateTime(year, month, day, hour, minute);

  return Timestamp.fromDate(dateTime);
}