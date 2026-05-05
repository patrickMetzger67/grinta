import 'package:grinta/model/activityMetrics.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/training.dart';

enum AgendaItemType {
  match,
  entrainement,
  preparationPhysique,
}

class AgendaItem {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? subtitle;
  final AgendaItemType type;
  final bool isDone;
  final Training? training;
  final grinta_match.Match? match;
  final ActivityMetrics? activityMetrics;
  final bool withTracker;
  final bool areTrackersSynchronized;
  final TeamWorkloadSummary? teamWorkloadSummary;


  const AgendaItem({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.subtitle,
    required this.type,
    this.isDone = false,
    this.match,
    this.training,
    this.activityMetrics,
    this.withTracker = false,
    this.areTrackersSynchronized = false,
    this.teamWorkloadSummary,
  });
}

typedef AgendaItemsLoader = Future<List<AgendaItem>> Function({
required DateTime start,
required DateTime end,
});