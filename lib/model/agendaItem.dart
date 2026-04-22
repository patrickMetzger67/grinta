import 'package:grinta/model/match.dart' as grinta_match;
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
  final bool withTracker;
  final bool areTrackersSynchronized;


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
    this.withTracker = false,
    this.areTrackersSynchronized = false
  });
}

typedef AgendaItemsLoader = Future<List<AgendaItem>> Function({
required DateTime start,
required DateTime end,
});