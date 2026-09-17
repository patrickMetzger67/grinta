import 'package:flutter/material.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/services/notification_preferences_service.dart';
import 'package:intl/intl.dart';

/// `jj/mm/aa` as specified for player-task notification copy.
String formatPlayerTaskNotificationDate(DateTime day) {
  return DateFormat('dd/MM/yy').format(DateUtils.dateOnly(day));
}

bool agendaItemIsTeamSportEvent(AgendaItem item) {
  return item.type == AgendaItemType.match ||
      item.type == AgendaItemType.entrainement ||
      item.type == AgendaItemType.preparationPhysique;
}

bool agendaItemConcernsTeam(AgendaItem item, String teamId) {
  final String trimmed = teamId.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  for (final String id in item.teamIds) {
    if (id.trim() == trimmed) {
      return true;
    }
  }
  return false;
}

/// Next local time a reminder may fire, respecting quiet days/hours.
///
/// Quiet hours shift to [NotificationPreferences.morningReminderHour] on the
/// next non-quiet morning instead of firing at 22h+.
DateTime? nextAllowedReminderTime(
  NotificationPreferences preferences,
  DateTime preferred,
) {
  if (!preferences.remindersEnabled) {
    return null;
  }
  if (!preferences.isQuietAt(preferred)) {
    return preferred;
  }

  DateTime cursor = DateTime(
    preferred.year,
    preferred.month,
    preferred.day,
    preferences.morningReminderHour,
  );
  if (!cursor.isAfter(preferred)) {
    final DateTime nextDay = preferred.add(const Duration(days: 1));
    cursor = DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      preferences.morningReminderHour,
    );
  }

  for (int i = 0; i < 8; i++) {
    if (!preferences.isQuietAt(cursor)) {
      return cursor;
    }
    final DateTime nextDay = cursor.add(const Duration(days: 1));
    cursor = DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      preferences.morningReminderHour,
    );
  }
  return null;
}

class PlayerTaskReminderOccurrence {
  const PlayerTaskReminderOccurrence({
    required this.reminderKey,
    required this.scheduledAt,
    required this.task,
    required this.event,
  });

  final String reminderKey;
  final DateTime scheduledAt;
  final PlayerTask task;
  final AgendaItem event;
}

/// One local reminder per assigned task per day that has a team event.
///
/// Prefers 2 hours before the first training/match that day. Quiet hours
/// shift to the morning reminder; quiet days skip that weekday entirely.
List<PlayerTaskReminderOccurrence> planPlayerTaskReminders({
  required Iterable<PlayerTask> assignedTasks,
  required Iterable<AgendaItem> agendaItems,
  required NotificationPreferences preferences,
  required DateTime now,
}) {
  if (!preferences.remindersEnabled) {
    return const <PlayerTaskReminderOccurrence>[];
  }

  final List<AgendaItem> sportEvents = <AgendaItem>[
    for (final AgendaItem item in agendaItems)
      if (agendaItemIsTeamSportEvent(item)) item,
  ]..sort((AgendaItem a, AgendaItem b) => a.startAt.compareTo(b.startAt));

  final List<PlayerTaskReminderOccurrence> plans =
      <PlayerTaskReminderOccurrence>[];

  for (final PlayerTask task in assignedTasks) {
    final String taskId = task.id?.trim() ?? '';
    if (taskId.isEmpty) {
      continue;
    }

    final Map<DateTime, AgendaItem> firstEventByDay = <DateTime, AgendaItem>{};
    for (final AgendaItem item in sportEvents) {
      if (!agendaItemConcernsTeam(item, task.teamId)) {
        continue;
      }
      final DateTime day = DateUtils.dateOnly(item.startAt);
      if (!task.occursOnDay(day)) {
        continue;
      }
      firstEventByDay.putIfAbsent(day, () => item);
    }

    for (final MapEntry<DateTime, AgendaItem> entry
        in firstEventByDay.entries) {
      final AgendaItem event = entry.value;
      if (preferences.quietDays.contains(entry.key.weekday)) {
        continue;
      }

      final DateTime preferred =
          event.startAt.subtract(const Duration(hours: 2));
      final DateTime? scheduled = nextAllowedReminderTime(
        preferences,
        preferred,
      );
      if (scheduled == null) {
        continue;
      }
      if (scheduled.isAfter(event.startAt)) {
        continue;
      }
      if (!scheduled.isAfter(now)) {
        continue;
      }

      final String dayKey = DateFormat('yyyyMMdd').format(entry.key);
      plans.add(
        PlayerTaskReminderOccurrence(
          reminderKey: 'player_task_${taskId}_$dayKey',
          scheduledAt: scheduled,
          task: task,
          event: event,
        ),
      );
    }
  }

  return plans;
}
