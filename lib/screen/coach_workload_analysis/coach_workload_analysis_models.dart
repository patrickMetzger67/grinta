import 'package:grinta/model/match.dart' as match_model;
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';

enum CoachWorkloadPeriod {
  week,
  month,
  custom,
}

enum CoachMetricTone {
  neutral,
  success,
  warning,
}

/// Team-wide averages used to color player metric chips.
class CoachTeamWorkloadAverages {
  const CoachTeamWorkloadAverages({
    this.avgWorkloadScore,
    this.totalDistanceKm,
    this.sessionCount,
    this.trainingCount,
    this.matchCount,
    this.presencePercent,
    this.volumeMinutes,
  });

  final double? avgWorkloadScore;
  final double? totalDistanceKm;
  final double? sessionCount;
  final double? trainingCount;
  final double? matchCount;
  final double? presencePercent;
  final double? volumeMinutes;

  CoachMetricTone toneFor({
    required double? value,
    required double? teamAverage,
  }) {
    if (value == null || teamAverage == null) {
      return CoachMetricTone.neutral;
    }
    return value + 1e-9 >= teamAverage
        ? CoachMetricTone.success
        : CoachMetricTone.warning;
  }
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
    this.totalDistanceKm,
  });

  final Player player;
  final String memberId;
  final int trainingPresent;
  final int trainingAbsent;
  final int matchCount;
  final int personalSportCount;
  final int volumeMinutes;
  final double? avgWorkloadScore;

  /// Tracker distance + personal sport distance over the period.
  final double? totalDistanceKm;

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
    this.maxValidatedSpeedKmh,
    this.highAccelerationCount,
    this.highSpeedDurationSec,
    this.maxAccelerationMps2,
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

  /// Tracker metrics (training/match with GPS), same set as session stats table.
  final double? maxValidatedSpeedKmh;
  final double? highAccelerationCount;
  final double? highSpeedDurationSec;
  final double? maxAccelerationMps2;

  final int? durationMinutes;
  final bool? wasPresent;
}

class CoachPlayerWorkloadDetail {
  const CoachPlayerWorkloadDetail({
    required this.summary,
    required this.activities,
    this.teamAverages = const CoachTeamWorkloadAverages(),
  });

  final CoachPlayerWorkloadSummary summary;
  final List<CoachWorkloadActivityItem> activities;
  final CoachTeamWorkloadAverages teamAverages;
}

class CoachTeamWorkloadReport {
  const CoachTeamWorkloadReport({
    required this.summaries,
    required this.teamAverages,
  });

  final List<CoachPlayerWorkloadSummary> summaries;
  final CoachTeamWorkloadAverages teamAverages;
}
