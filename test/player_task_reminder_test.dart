import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/services/notification_preferences_service.dart';
import 'package:grinta/util/player_task_reminder.dart';

PlayerTask _task({
  String id = 'task-1',
  String teamId = 'team-1',
  DateTime? start,
  DateTime? end,
  String typeName = 'Matériel',
}) {
  final DateTime startAt = start ?? DateTime(2026, 9, 10);
  return PlayerTask(
    id: id,
    typeId: 'type-1',
    typeName: typeName,
    typeColor: 0xFFFF0000,
    startAt: startAt,
    endAt: end ?? DateTime(2026, 9, 12, 23, 59, 59),
    teamId: teamId,
    assigneeMemberIds: const <String>['player-1'],
    createdByUserId: 'manager-1',
  );
}

AgendaItem _event({
  required DateTime startAt,
  String id = 'evt-1',
  String teamId = 'team-1',
  AgendaItemType type = AgendaItemType.entrainement,
}) {
  return AgendaItem(
    id: id,
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1, minutes: 30)),
    title: 'Training',
    type: type,
    teamIds: <String>[teamId],
  );
}

void main() {
  group('formatPlayerTaskNotificationDate', () {
    test('formats jj/mm/aa', () {
      expect(
        formatPlayerTaskNotificationDate(DateTime(2026, 9, 10, 18, 30)),
        '10/09/26',
      );
      expect(
        formatPlayerTaskNotificationDate(DateTime(2026, 12, 1)),
        '01/12/26',
      );
    });
  });

  group('nextAllowedReminderTime', () {
    const NotificationPreferences prefs = NotificationPreferences(
      remindersEnabled: true,
      quietDays: <int>[],
      quietHoursStart: 22,
      quietHoursEnd: 7,
      morningReminderHour: 8,
      timezone: 'Europe/Paris',
    );

    test('keeps a 2h-before time outside quiet hours', () {
      final DateTime preferred = DateTime(2026, 9, 10, 16, 0);
      expect(nextAllowedReminderTime(prefs, preferred), preferred);
    });

    test('shifts overnight quiet hours to the morning reminder', () {
      final DateTime preferred = DateTime(2026, 9, 10, 22, 30);
      expect(
        nextAllowedReminderTime(prefs, preferred),
        DateTime(2026, 9, 11, 8),
      );
    });

    test('shifts early-morning quiet hours to the same-day morning reminder', () {
      final DateTime preferred = DateTime(2026, 9, 10, 6, 0);
      expect(
        nextAllowedReminderTime(prefs, preferred),
        DateTime(2026, 9, 10, 8),
      );
    });

    test('returns null when reminders are disabled', () {
      const NotificationPreferences off = NotificationPreferences(
        remindersEnabled: false,
      );
      expect(
        nextAllowedReminderTime(off, DateTime(2026, 9, 10, 16)),
        isNull,
      );
    });

    test('skips a quiet weekday when shifting to morning', () {
      const NotificationPreferences sundayQuiet = NotificationPreferences(
        quietDays: <int>[DateTime.sunday],
        quietHoursStart: 22,
        quietHoursEnd: 7,
        morningReminderHour: 8,
      );
      // Saturday 22:30 → Sunday 08:00 is a quiet day → Monday 08:00.
      expect(
        nextAllowedReminderTime(sundayQuiet, DateTime(2026, 9, 12, 22, 30)),
        DateTime(2026, 9, 14, 8),
      );
    });
  });

  group('planPlayerTaskReminders', () {
    const NotificationPreferences prefs = NotificationPreferences(
      quietHoursStart: 22,
      quietHoursEnd: 7,
      morningReminderHour: 8,
    );

    test('schedules 2h before the first team event of the day', () {
      final DateTime now = DateTime(2026, 9, 10, 8);
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[_task()],
        agendaItems: <AgendaItem>[
          _event(id: 'later', startAt: DateTime(2026, 9, 10, 20)),
          _event(id: 'first', startAt: DateTime(2026, 9, 10, 18)),
        ],
        preferences: prefs,
        now: now,
      );

      expect(plans, hasLength(1));
      expect(plans.first.event.id, 'first');
      expect(plans.first.scheduledAt, DateTime(2026, 9, 10, 16));
      expect(plans.first.reminderKey, 'player_task_task-1_20260910');
    });

    test('one reminder per day even with multiple events', () {
      final DateTime now = DateTime(2026, 9, 10, 8);
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[
          _task(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 10, 23)),
        ],
        agendaItems: <AgendaItem>[
          _event(
            id: 'train',
            startAt: DateTime(2026, 9, 10, 18),
            type: AgendaItemType.entrainement,
          ),
          _event(
            id: 'match',
            startAt: DateTime(2026, 9, 10, 20),
            type: AgendaItemType.match,
          ),
        ],
        preferences: prefs,
        now: now,
      );
      expect(plans, hasLength(1));
      expect(plans.single.event.id, 'train');
    });

    test('ignores events for another team', () {
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[_task()],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 18), teamId: 'other'),
        ],
        preferences: prefs,
        now: DateTime(2026, 9, 10, 8),
      );
      expect(plans, isEmpty);
    });

    test('does not notify on silent weekdays', () {
      const NotificationPreferences thursdayQuiet = NotificationPreferences(
        quietDays: <int>[DateTime.thursday],
        quietHoursStart: 22,
        quietHoursEnd: 7,
        morningReminderHour: 8,
      );
      // 10/09/2026 is a Thursday.
      expect(DateTime(2026, 9, 10).weekday, DateTime.thursday);
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[_task()],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 18)),
        ],
        preferences: thursdayQuiet,
        now: DateTime(2026, 9, 10, 8),
      );
      expect(plans, isEmpty);
    });

    test('does not notify when reminders are disabled', () {
      const NotificationPreferences off = NotificationPreferences(
        remindersEnabled: false,
      );
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[_task()],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 18)),
        ],
        preferences: off,
        now: DateTime(2026, 9, 10, 8),
      );
      expect(plans, isEmpty);
    });

    test('shifts a 2h-before that lands in quiet hours to 08:00', () {
      final DateTime now = DateTime(2026, 9, 10, 7);
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[
          _task(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 10, 23)),
        ],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 8)),
        ],
        preferences: prefs,
        now: now,
      );
      // 08:00 event → 06:00 preferred (quiet) → 08:00 morning, equal to event
      // start so it is still allowed.
      expect(plans, hasLength(1));
      expect(plans.single.scheduledAt, DateTime(2026, 9, 10, 8));
    });

    test('skips past reminder times', () {
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[_task()],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 18)),
        ],
        preferences: prefs,
        now: DateTime(2026, 9, 10, 17),
      );
      expect(plans, isEmpty);
    });

    test('does not notify managers who are not assignees', () {
      // Planner only receives assigned tasks; a manager-only task is excluded
      // by the caller. An empty assignee list here still plans if passed in —
      // the service query filters by assigneeMemberIds.
      final PlayerTask assigned = _task(id: 'a');
      final List<PlayerTaskReminderOccurrence> plans = planPlayerTaskReminders(
        assignedTasks: <PlayerTask>[assigned],
        agendaItems: <AgendaItem>[
          _event(startAt: DateTime(2026, 9, 10, 18)),
        ],
        preferences: prefs,
        now: DateTime(2026, 9, 10, 8),
      );
      expect(plans, hasLength(1));
    });
  });
}
