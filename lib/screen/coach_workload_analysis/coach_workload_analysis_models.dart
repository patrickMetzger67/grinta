import 'package:grinta/model/match.dart' as match_model;
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';

enum CoachWorkloadPeriod {
  week,
  month,
  custom,
}

/// Compact per-player row for the coach comparison list.
class CoachPlayerWorkloadSummary {
  const CoachPlayerWorkloadSummary({
    required this.player,
    required this.memberId,
    required this.trainingPresent,
    required this.trainingAbsent,
    required this.matchCount,
    required this.personalSportCount,
    required this.volumeMinutes,
    this.avgWorkloadScore,
    this.avgDistanceKm,
  });

  final Player player;
  final String memberId;
  final int trainingPresent;
  final int trainingAbsent;
  final int matchCount;
  final int personalSportCount;
  final int volumeMinutes;
  final double? avgWorkloadScore;
  final double? avgDistanceKm;

  int get sessionCount =>
      trainingPresent + matchCount + personalSportCount;

  int get trainingMarked => trainingPresent + trainingAbsent;

  double? get presencePercent {
    if (trainingMarked <= 0) return null;
    return (trainingPresent / trainingMarked) * 100;
  }
}

enum CoachWorkloadActivityKind {
  training,
  match,
  personalSport,
}

/// Unified activity row for the player detail list.
class CoachWorkloadActivityItem {
  const CoachWorkloadActivityItem({
    required this.kind,
    required this.startAt,
    this.training,
    this.match,
    this.personalSport,
    this.workloadScore,
    this.distanceKm,
    this.durationMinutes,
    this.wasPresent,
  });

  final CoachWorkloadActivityKind kind;
  final DateTime startAt;
  final Training? training;
  final match_model.Match? match;
  final PersonalSportActivity? personalSport;
  final double? workloadScore;
  final double? distanceKm;
  final int? durationMinutes;
  final bool? wasPresent;
}

class CoachPlayerWorkloadDetail {
  const CoachPlayerWorkloadDetail({
    required this.summary,
    required this.activities,
  });

  final CoachPlayerWorkloadSummary summary;
  final List<CoachWorkloadActivityItem> activities;
}
