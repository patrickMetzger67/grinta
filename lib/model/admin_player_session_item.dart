import 'package:grinta/model/personal_sport_activity.dart';

/// Kind of player session shown in the admin sessions list.
enum AdminPlayerSessionKind {
  /// GPS team-kit analysis (`TRACKER_Analysis`).
  gps,

  /// Polar team-kit cardio analysis (`TRACKER_PolarAnalysis`).
  polar,

  /// Personal sport activity (wearable / app import).
  personalSport,
}

/// One row in the admin player sessions list.
class AdminPlayerSessionItem {
  const AdminPlayerSessionItem({
    required this.kind,
    required this.sessionDate,
    required this.eventId,
    this.analysisDocId,
    this.trackerId,
    this.ownerId,
    this.teamId,
    this.isMatch = false,
    this.personalSport,
  });

  final AdminPlayerSessionKind kind;
  final DateTime sessionDate;
  final String eventId;
  final String? analysisDocId;
  final String? trackerId;
  final String? ownerId;
  final String? teamId;
  final bool isMatch;
  final PersonalSportActivity? personalSport;
}
