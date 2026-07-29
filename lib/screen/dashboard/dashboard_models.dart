part of 'dashboard_screen.dart';

enum DashboardPeriod {
  week,
  month,
  custom,
}
enum DashboardStatsType {
  matches,
  trainings,
  personalSports,
}

enum DashboardWhereType {
  player,
  team,
}

enum _MatchOutcome {
  won,
  lost,
  draw,
}

class _ActivityStats {
  const _ActivityStats({
    required this.done,
    required this.planned,
    required this.presentPecent,
    this.matchOutcomes = const <_MatchOutcome, int>{},
    this.trainingMetrics = const <ActivityMetrics>[],
    this.personalActivities = const <PersonalSportActivity>[],
  });

  final int done;
  final int planned;
  final double presentPecent;
  final Map<_MatchOutcome, int> matchOutcomes;

  /// Utilisé uniquement pour les entraînements.
  final List<ActivityMetrics> trainingMetrics;

  /// Utilisé uniquement pour les activités sportives personnelles.
  final List<PersonalSportActivity> personalActivities;

  int get total => done + planned;

  int get won => matchOutcomes[_MatchOutcome.won] ?? 0;
  int get lost => matchOutcomes[_MatchOutcome.lost] ?? 0;
  int get draw => matchOutcomes[_MatchOutcome.draw] ?? 0;

  int get totalOutcomes => won + lost + draw;

  bool get hasMatchOutcomes => totalOutcomes > 0;

  bool get hasTrainingMetrics => trainingMetrics.isNotEmpty;

  bool get hasPersonalActivities => personalActivities.isNotEmpty;
}
