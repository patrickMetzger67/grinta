import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/calendar_sync_config.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/calendar_sync_repository.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';
import 'package:grinta/util/calendar_event_formatter.dart';
import 'package:grinta/util/calendar_ics_builder.dart';
import 'package:grinta/util/download_ics.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class CalendarSyncService {
  CalendarSyncService._();

  static final CalendarSyncService instance = CalendarSyncService._();

  static const Duration syncDebounce = Duration(minutes: 15);
  static const Color brandColor = Color(0xFFF95C1B);

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  final CalendarSyncRepository _repository = CalendarSyncRepository();

  bool _syncInProgress = false;
  bool _timeZonesInitialized = false;

  void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  TZDateTime _toTzDateTime(DateTime value) {
    _ensureTimeZonesInitialized();
    return TZDateTime.from(value, local);
  }

  String calendarDisplayNameForPlayer(Player player) {
    final name = playerDisplayName(player);
    return 'Grinta — $name';
  }

  String buildDeepLink({
    required String eventType,
    required String eventId,
    required String playerId,
  }) {
    return 'grinta://event?type=$eventType&id=$eventId&playerId=$playerId';
  }

  String computeContentHash(AgendaItem item, {required String deepLink}) {
    final buffer = StringBuffer()
      ..write(item.id)
      ..write('|')
      ..write(item.type.name)
      ..write('|')
      ..write(CalendarEventFormatter.eventTitle(item))
      ..write('|')
      ..write(CalendarEventFormatter.eventLocation(item) ?? '')
      ..write('|')
      ..write(item.startAt.toUtc().millisecondsSinceEpoch)
      ..write('|')
      ..write(item.endAt.toUtc().millisecondsSinceEpoch)
      ..write('|')
      ..write(deepLink);
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  String _eventTypeForAgendaItem(AgendaItem item) {
    switch (item.type) {
      case AgendaItemType.match:
        return 'match';
      case AgendaItemType.entrainement:
        return 'training';
      case AgendaItemType.preparationPhysique:
        return 'training';
      case AgendaItemType.nonSport:
        return 'event';
    }
  }

  Future<bool> requestCalendarPermissions() async {
    if (kIsWeb) return false;

    final hasPermissions = await _plugin.hasPermissions();
    if (hasPermissions.isSuccess && hasPermissions.data == true) {
      return true;
    }

    final result = await _plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<String?> ensureCalendar(String displayName) async {
    if (kIsWeb) return null;

    if (!await requestCalendarPermissions()) return null;

    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess) return null;

    final calendars = calendarsResult.data ?? const <Calendar>[];
    for (final calendar in calendars) {
      if (calendar.name == displayName && calendar.isReadOnly != true) {
        return calendar.id;
      }
    }

    final createResult = await _plugin.createCalendar(
      displayName,
      calendarColor: brandColor,
    );
    if (createResult.isSuccess && createResult.data != null) {
      return createResult.data;
    }

    return null;
  }

  /// Returns a valid local calendar id, recreating the calendar and clearing
  /// stale Firestore event maps when the stored id no longer exists (e.g. after
  /// a phone reset).
  Future<String?> _resolveCalendarId({
    required String uid,
    required String playerId,
    required CalendarSyncConfig config,
    required String displayName,
  }) async {
    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess) {
      return config.calendarExternalId;
    }

    final calendars = calendarsResult.data ?? const <Calendar>[];
    final storedId = config.calendarExternalId;
    if (storedId != null &&
        storedId.isNotEmpty &&
        calendars.any((calendar) => calendar.id == storedId)) {
      return storedId;
    }

    await _repository.deleteAllEventMaps(uid, playerId);

    final calendarId = await ensureCalendar(displayName);
    if (calendarId == null) return null;

    await _repository.saveConfig(
      uid: uid,
      playerId: playerId,
      config: CalendarSyncConfig(
        enabled: true,
        calendarExternalId: calendarId,
        calendarDisplayName: displayName,
        platform: config.platform,
      ),
    );

    return calendarId;
  }

  Future<CalendarSyncResult> enableSync({
    required String uid,
    required String playerId,
    required Player player,
    required AppSession appSession,
  }) async {
    if (kIsWeb) {
      return _enableWebSync(
        uid: uid,
        playerId: playerId,
        player: player,
        appSession: appSession,
      );
    }

    if (!await requestCalendarPermissions()) {
      return CalendarSyncResult.permissionDenied;
    }

    final calendarName = calendarDisplayNameForPlayer(player);
    final calendarId = await ensureCalendar(calendarName);
    if (calendarId == null) {
      return CalendarSyncResult.calendarCreationFailed;
    }

    final platform = defaultTargetPlatform.name;
    await _repository.saveConfig(
      uid: uid,
      playerId: playerId,
      config: CalendarSyncConfig(
        enabled: true,
        calendarExternalId: calendarId,
        calendarDisplayName: calendarName,
        platform: platform,
      ),
    );

    final syncResult = await syncForPlayer(
      uid: uid,
      playerId: playerId,
      appSession: appSession,
      force: true,
    );

    if (!syncResult.success) {
      return syncResult;
    }

    return CalendarSyncResult.success;
  }

  Future<CalendarSyncResult> disableSync({
    required String uid,
    required String playerId,
  }) async {
    if (kIsWeb) {
      await _repository.setEnabled(uid: uid, playerId: playerId, enabled: false);
      return CalendarSyncResult.success;
    }

    final config = await _repository.getConfig(uid, playerId);
    final calendarId = config?.calendarExternalId;
    final eventMaps = await _repository.getAllEventMaps(uid, playerId);

    if (calendarId != null) {
      for (final entry in eventMaps) {
        if (entry.externalEventId.isEmpty) continue;
        await _plugin.deleteEvent(calendarId, entry.externalEventId);
        await _repository.deleteEventMap(
          uid: uid,
          playerId: playerId,
          grintaEventId: entry.grintaEventId,
        );
      }
    } else {
      await _repository.deleteAllEventMaps(uid, playerId);
    }

    await _repository.setEnabled(uid: uid, playerId: playerId, enabled: false);
    return CalendarSyncResult.success;
  }

  Future<void> maybeSyncAfterAgendaLoad({
    required AppSession appSession,
  }) async {
    // Web uses manual ICS download; native syncs after each agenda load (debounced).
    if (kIsWeb) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = appSession.selectedPlayerId;
    if (uid == null || playerId == null) return;

    final config = await _repository.getConfig(uid, playerId);
    if (config == null || !config.enabled) return;

    final lastSyncedAt = config.lastSyncedAt;
    if (lastSyncedAt != null &&
        DateTime.now().difference(lastSyncedAt) < syncDebounce) {
      return;
    }

    await syncForPlayer(
      uid: uid,
      playerId: playerId,
      appSession: appSession,
    );
  }

  Future<CalendarSyncResult> syncForPlayer({
    required String uid,
    required String playerId,
    required AppSession appSession,
    bool force = false,
  }) async {
    if (kIsWeb) {
      return _syncForPlayerWeb(
        uid: uid,
        playerId: playerId,
        appSession: appSession,
        force: force,
      );
    }
    if (_syncInProgress) return CalendarSyncResult.alreadyInProgress;

    final config = await _repository.getConfig(uid, playerId);
    if (config == null || !config.enabled) {
      return CalendarSyncResult.notEnabled;
    }

    if (!force &&
        config.lastSyncedAt != null &&
        DateTime.now().difference(config.lastSyncedAt!) < syncDebounce) {
      return CalendarSyncResult.skippedDebounce;
    }

    _syncInProgress = true;
    try {
      final player = appSession.selectedPlayer;
      if (player == null) {
        return CalendarSyncResult.playerNotFound;
      }

      final displayName =
          config.calendarDisplayName ?? calendarDisplayNameForPlayer(player);
      final calendarId = await _resolveCalendarId(
        uid: uid,
        playerId: playerId,
        config: config,
        displayName: displayName,
      );
      if (calendarId == null) {
        return CalendarSyncResult.calendarCreationFailed;
      }

      final items = await _loadSeasonAgendaItems(appSession);
      final syncableItems = items
          .where(
            (item) =>
                item.type == AgendaItemType.match ||
                item.type == AgendaItemType.entrainement,
          )
          .toList();

      final existingMaps = await _repository.getAllEventMaps(uid, playerId);
      final existingById = {
        for (final entry in existingMaps) entry.grintaEventId: entry,
      };
      final currentIds = syncableItems.map((item) => item.id).toSet();

      for (final item in syncableItems) {
        final eventType = _eventTypeForAgendaItem(item);
        final deepLink = buildDeepLink(
          eventType: eventType,
          eventId: item.id,
          playerId: playerId,
        );
        final contentHash = computeContentHash(item, deepLink: deepLink);
        final existing = existingById[item.id];

        if (existing != null && existing.contentHash == contentHash) {
          continue;
        }

        final event = Event(
          calendarId,
          eventId: existing?.externalEventId,
          title: CalendarEventFormatter.eventTitle(item),
          description: CalendarEventFormatter.eventDescription(
            deepLink: deepLink,
            item: item,
          ),
          start: _toTzDateTime(item.startAt),
          end: _toTzDateTime(item.endAt),
        )
          ..location = CalendarEventFormatter.eventLocation(item)
          ..url = Uri.parse(deepLink);

        var result = await _plugin.createOrUpdateEvent(event);
        if ((result == null || !result.isSuccess || result.data == null) &&
            existing?.externalEventId.isNotEmpty == true) {
          final freshEvent = Event(
            calendarId,
            title: event.title,
            description: event.description,
            start: event.start,
            end: event.end,
          )
            ..location = event.location
            ..url = event.url;
          result = await _plugin.createOrUpdateEvent(freshEvent);
        }
        if (result == null || !result.isSuccess || result.data == null) {
          debugPrint(
            'CalendarSyncService: failed to sync event ${item.id}: '
            '${result?.errors}',
          );
          continue;
        }

        await _repository.upsertEventMap(
          uid: uid,
          playerId: playerId,
          grintaEventId: item.id,
          entry: CalendarSyncEventMapEntry(
            grintaEventId: item.id,
            externalEventId: result.data!,
            eventType: eventType,
            contentHash: contentHash,
          ),
        );
      }

      for (final entry in existingMaps) {
        if (currentIds.contains(entry.grintaEventId)) continue;
        if (entry.externalEventId.isNotEmpty) {
          await _plugin.deleteEvent(calendarId, entry.externalEventId);
        }
        await _repository.deleteEventMap(
          uid: uid,
          playerId: playerId,
          grintaEventId: entry.grintaEventId,
        );
      }

      await _repository.updateLastSyncedAt(uid: uid, playerId: playerId);
      return CalendarSyncResult.success;
    } catch (e, st) {
      debugPrint('CalendarSyncService.syncForPlayer error: $e\n$st');
      return CalendarSyncResult.failed;
    } finally {
      _syncInProgress = false;
    }
  }

  Future<List<AgendaItem>> _loadSeasonAgendaItems(AppSession appSession) async {
    final season = appSession.selectedSeason;
    final teams = appSession.teamsForAgendaSelectedSeason;
    final seasonId = season?.ref?.id;

    DateTime rangeStart;
    DateTime rangeEnd;
    if (season?.startDate != null && season?.endDate != null) {
      rangeStart = season!.startDate!.toDate();
      rangeEnd = season.endDate!.toDate();
    } else {
      final now = DateTime.now();
      rangeStart = DateTime(now.year, now.month - 1, 1);
      rangeEnd = DateTime(now.year, now.month + 3, 0);
    }

    final allItems = <AgendaItem>[];
    final timestampNow = Timestamp.now();

    for (final team in teams) {
      if (team.keyTeam == null) continue;

      final matches =
          await MatchService().getMatchesForTeamEngagementsBetweenDates(
        teamId: team.keyTeam!,
        clubId: team.clubId ?? '',
        seasonId: seasonId,
        start: Timestamp.fromDate(rangeStart),
        end: Timestamp.fromDate(rangeEnd),
      );

      final trainings = await TrainingService().getTrainingsByTeamIdBetweenDates(
        teamId: team.keyTeam!,
        start: Timestamp.fromDate(rangeStart),
        end: Timestamp.fromDate(rangeEnd),
      );

      for (final match in matches) {
        DateTime? startAt;
        if (match.timestamp != null) {
          startAt = match.timestamp!.toDate();
        } else if (match.dateCh != null && match.timeCh != null) {
          startAt = buildTimestampFromDateAndTime(
            date: match.dateCh!,
            time: match.timeCh!,
          ).toDate();
        }
        if (startAt == null || match.id == null) continue;

        final endAt = startAt.add(const Duration(minutes: 90));
        allItems.add(
          AgendaItem(
            id: match.id!,
            startAt: startAt,
            endAt: endAt,
            title: team.name ?? 'Match',
            type: AgendaItemType.match,
            match: match,
            isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
                timestampNow.millisecondsSinceEpoch,
          ),
        );
      }

      for (final training in trainings) {
        if (training.dateTime == null || training.ref == null) continue;

        final endAt = training.dateTime!.toDate().add(const Duration(minutes: 90));
        allItems.add(
          AgendaItem(
            id: training.ref!.id,
            startAt: training.dateTime!.toDate(),
            endAt: endAt,
            title: '${team.name}: Entraînement',
            type: AgendaItemType.entrainement,
            training: training,
            isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
                timestampNow.millisecondsSinceEpoch,
          ),
        );
      }
    }

    final unique = <String, AgendaItem>{};
    for (final item in allItems) {
      unique['${item.type.name}_${item.id}'] = item;
    }

    return unique.values.toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  Future<CalendarSyncResult> _enableWebSync({
    required String uid,
    required String playerId,
    required Player player,
    required AppSession appSession,
  }) async {
    final calendarName = calendarDisplayNameForPlayer(player);
    await _repository.saveConfig(
      uid: uid,
      playerId: playerId,
      config: CalendarSyncConfig(
        enabled: true,
        calendarDisplayName: calendarName,
        platform: 'web',
      ),
    );

    return _syncForPlayerWeb(
      uid: uid,
      playerId: playerId,
      appSession: appSession,
      force: true,
    );
  }

  Future<CalendarSyncResult> _syncForPlayerWeb({
    required String uid,
    required String playerId,
    required AppSession appSession,
    bool force = false,
  }) async {
    if (_syncInProgress) return CalendarSyncResult.alreadyInProgress;

    final config = await _repository.getConfig(uid, playerId);
    if (config == null || !config.enabled) {
      return CalendarSyncResult.notEnabled;
    }

    if (!force &&
        config.lastSyncedAt != null &&
        DateTime.now().difference(config.lastSyncedAt!) < syncDebounce) {
      return CalendarSyncResult.skippedDebounce;
    }

    _syncInProgress = true;
    try {
      final player = appSession.selectedPlayer;
      if (player == null) {
        return CalendarSyncResult.playerNotFound;
      }

      final items = await _loadSeasonAgendaItems(appSession);
      final syncableItems = items
          .where(
            (item) =>
                item.type == AgendaItemType.match ||
                item.type == AgendaItemType.entrainement,
          )
          .toList();

      final calendarName =
          config.calendarDisplayName ?? calendarDisplayNameForPlayer(player);
      final icsContent = CalendarIcsBuilder.buildCalendar(
        calendarName: calendarName,
        items: syncableItems,
        eventUrlBuilder: (item) => buildDeepLink(
          eventType: _eventTypeForAgendaItem(item),
          eventId: item.id,
          playerId: playerId,
        ),
      );

      final safeName = calendarName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      downloadIcsFile(
        fileName: '${safeName.isEmpty ? 'grinta' : safeName}.ics',
        icsContent: icsContent,
      );

      await _repository.updateLastSyncedAt(uid: uid, playerId: playerId);
      return CalendarSyncResult.success;
    } catch (e, st) {
      debugPrint('CalendarSyncService._syncForPlayerWeb error: $e\n$st');
      return CalendarSyncResult.failed;
    } finally {
      _syncInProgress = false;
    }
  }

  Future<CalendarSyncResult> redownloadWebCalendar({
    required String uid,
    required String playerId,
    required AppSession appSession,
  }) {
    return _syncForPlayerWeb(
      uid: uid,
      playerId: playerId,
      appSession: appSession,
      force: true,
    );
  }
}

enum CalendarSyncResult {
  success,
  permissionDenied,
  calendarCreationFailed,
  unavailableOnWeb,
  notEnabled,
  skippedDebounce,
  alreadyInProgress,
  playerNotFound,
  failed,
}

extension CalendarSyncResultX on CalendarSyncResult {
  bool get success => this == CalendarSyncResult.success;
}
