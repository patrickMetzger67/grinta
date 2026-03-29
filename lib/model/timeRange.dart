import 'package:cloud_firestore/cloud_firestore.dart';

class TimeRange {
  Timestamp start;
  Timestamp end;

  TimeRange({
    Timestamp? start,
    Timestamp? end,
  })  : start = start ?? Timestamp.now(),
        end = end ?? Timestamp.now();

  Duration get duration =>
      end.toDate().difference(start.toDate());

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      start: map['start'] as Timestamp,
      end: map['end'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'TimeRange('
        'start: ${start.toDate()}, '
        'end: ${end.toDate()}, '
        'duration: ${duration.inSeconds}s'
        ')';
  }
}