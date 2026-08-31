import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

/// Month key `yyyy-MM` for paint-cache buckets.
String agendaMonthPaintKey(DateTime month) {
  final DateTime m = DateTime(month.year, month.month, 1);
  return '${m.year}-${m.month.toString().padLeft(2, '0')}';
}

/// In-memory LRU of agenda items sliced by calendar month.
///
/// Used for stale-while-revalidate: when the user swipes to a month that was
/// visited recently, paint the cached slice immediately while Firestore
/// re-hydrates in the background.
class AgendaMonthPaintCache {
  AgendaMonthPaintCache({this.maxMonths = 8});

  final int maxMonths;
  final LinkedHashMap<String, List<AgendaItem>> _byMonth =
      LinkedHashMap<String, List<AgendaItem>>();

  int get monthCount => _byMonth.length;

  bool coversMonth(DateTime month) =>
      _byMonth.containsKey(agendaMonthPaintKey(month));

  /// Stores [items] into every month bucket they touch between [rangeStart]
  /// and [rangeEnd] (inclusive calendar days).
  void storeRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<AgendaItem> items,
  }) {
    final DateTime start = DateUtils.dateOnly(rangeStart);
    final DateTime end = DateUtils.dateOnly(rangeEnd);
    if (end.isBefore(start)) return;

    final Map<String, List<AgendaItem>> buckets = <String, List<AgendaItem>>{};
    DateTime cursor = DateTime(start.year, start.month, 1);
    final DateTime lastMonth = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(lastMonth)) {
      buckets[agendaMonthPaintKey(cursor)] = <AgendaItem>[];
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    for (final AgendaItem item in items) {
      DateTime day = DateUtils.dateOnly(item.startAt);
      final DateTime last = DateUtils.dateOnly(item.endAt);
      final Set<String> seenMonths = <String>{};
      while (!day.isAfter(last)) {
        if (!day.isBefore(start) && !day.isAfter(end)) {
          final String key = agendaMonthPaintKey(day);
          if (buckets.containsKey(key) && seenMonths.add(key)) {
            buckets[key]!.add(item);
          }
        }
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }

    for (final MapEntry<String, List<AgendaItem>> entry in buckets.entries) {
      _put(entry.key, List<AgendaItem>.unmodifiable(entry.value));
    }
  }

  void _put(String key, List<AgendaItem> items) {
    _byMonth.remove(key);
    _byMonth[key] = items;
    while (_byMonth.length > maxMonths) {
      _byMonth.remove(_byMonth.keys.first);
    }
  }

  /// Merged paint for [rangeStart]→[rangeEnd] when every month in the span is
  /// cached; otherwise `null` (caller keeps previous paint / shows skeleton).
  List<AgendaItem>? tryPaintRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final DateTime start = DateUtils.dateOnly(rangeStart);
    final DateTime end = DateUtils.dateOnly(rangeEnd);
    if (end.isBefore(start)) return null;

    final List<AgendaItem> merged = <AgendaItem>[];
    final Set<String> seenIds = <String>{};
    DateTime cursor = DateTime(start.year, start.month, 1);
    final DateTime lastMonth = DateTime(end.year, end.month, 1);

    while (!cursor.isAfter(lastMonth)) {
      final String key = agendaMonthPaintKey(cursor);
      final List<AgendaItem>? slice = _byMonth[key];
      if (slice == null) return null;
      // Touch LRU order.
      _byMonth.remove(key);
      _byMonth[key] = slice;
      for (final AgendaItem item in slice) {
        final String id = '${item.type.name}:${item.id}';
        if (seenIds.add(id)) {
          merged.add(item);
        }
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return merged;
  }

  void clear() => _byMonth.clear();
}

/// Months to warm silently after the UI settles (beyond the live M±radius).
///
/// Returns nearer months first so a single prefetch tick prioritizes the next
/// swipe target.
List<DateTime> planAgendaPrefetchMonths({
  required DateTime focusMonth,
  required bool Function(DateTime month) isCached,
  int windowRadiusMonths = 1,
  int prefetchRadiusMonths = 2,
}) {
  assert(prefetchRadiusMonths >= windowRadiusMonths);
  final DateTime focus = DateTime(focusMonth.year, focusMonth.month, 1);
  final List<DateTime> targets = <DateTime>[];

  for (int radius = windowRadiusMonths + 1;
      radius <= prefetchRadiusMonths;
      radius++) {
    final DateTime prev = DateTime(focus.year, focus.month - radius, 1);
    final DateTime next = DateTime(focus.year, focus.month + radius, 1);
    if (!isCached(prev)) targets.add(prev);
    if (!isCached(next)) targets.add(next);
  }

  return targets;
}

/// Debounces load-side work while [LatestWinsGate] keeps UI clicks instant.
///
/// Only the latest scheduled token runs; older timers are cancelled.
class DebouncedLatestAction {
  DebouncedLatestAction({
    this.delay = const Duration(milliseconds: 90),
  });

  final Duration delay;
  Timer? _timer;

  void schedule(
    LatestWinsToken token,
    void Function(LatestWinsToken token) action,
  ) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!token.isCurrent) return;
      action(token);
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}

/// Collapses rapid stream emissions into a single paint callback per frame.
class AgendaPaintCoalescer<T> {
  AgendaPaintCoalescer(this.onPaint);

  final void Function(T value) onPaint;
  T? _pending;
  bool _scheduled = false;

  void submit(T value) {
    _pending = value;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _scheduled = false;
      final T? next = _pending;
      _pending = null;
      if (next != null) {
        onPaint(next);
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void dispose() {
    _pending = null;
    _scheduled = false;
  }
}

/// Cheap fingerprint so identical progressive emits skip a full list rebuild.
String agendaItemsPaintFingerprint(List<AgendaItem> items) {
  if (items.isEmpty) return '0';
  final StringBuffer buffer = StringBuffer(items.length)
    ..write(':')
    ..write(items.first.id)
    ..write(':')
    ..write(items.last.id);
  var hash = items.length;
  for (final AgendaItem item in items) {
    hash = 0x1fffffff & (hash + item.id.hashCode);
    hash = 0x1fffffff & (hash + item.type.index * 31);
    hash = 0x1fffffff & (hash + item.startAt.millisecondsSinceEpoch);
  }
  buffer.write(':$hash');
  return buffer.toString();
}
