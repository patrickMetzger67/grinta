import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/model/player_task_type.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_task_access.dart';
import 'package:grinta/util/player_task_reminder.dart';

class PlayerTaskService {
  static const String collectionName = 'playerTasks';

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final PlayerService _playerService;

  PlayerTaskService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    PlayerService? playerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        _playerService = playerService ?? PlayerService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Agenda visibility for player tasks.
  ///
  /// Dual query (preferred over stuffing manager ids into [accessMemberIds]):
  /// 1. `accessMemberIds` arrayContains [memberId] — assignees and creator
  /// 2. `teamId` whereIn the caller's currently managed teams
  ///
  /// (2) covers existing documents that never listed co-managers, and a
  /// manager added to the team later, without going stale when staff changes.
  Stream<List<PlayerTask>> watchTasksForMemberBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
    Iterable<String> managedTeamIds = const <String>[],
  }) {
    final String trimmed = memberId.trim();
    final List<String> teamIds = normalizedPlayerTaskTeamIds(managedTeamIds);
    if (trimmed.isEmpty && teamIds.isEmpty) {
      return Stream<List<PlayerTask>>.value(const <PlayerTask>[]);
    }

    final DateTime rangeStart = DateUtils.dateOnly(start);
    final DateTime rangeEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );

    return Stream<List<PlayerTask>>.multi((
      MultiStreamController<List<PlayerTask>> controller,
    ) {
      final Map<String, List<PlayerTask>> buckets = <String, List<PlayerTask>>{};
      final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
          subscriptions =
          <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

      void emitMerged() {
        final List<PlayerTask> merged = mergePlayerTasksById(buckets.values);
        final List<PlayerTask> inRange = <PlayerTask>[
          for (final PlayerTask task in merged)
            if (!task.endAt.isBefore(rangeStart) &&
                !task.startAt.isAfter(rangeEnd))
              task,
        ];
        controller.add(
          playerTasksVisibleToMember(
            inRange,
            trimmed,
            managedTeamIds: teamIds,
          ),
        );
      }

      void listenQuery(String key, Query<Map<String, dynamic>> query) {
        subscriptions.add(
          query.snapshots().listen(
            (QuerySnapshot<Map<String, dynamic>> snapshot) {
              buckets[key] = <PlayerTask>[
                for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                    in snapshot.docs)
                  PlayerTask.fromSnapshot(doc),
              ];
              emitMerged();
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint(
                'PlayerTaskService.watchTasksForMemberBetweenDates failed: $error',
              );
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
          ),
        );
      }

      if (trimmed.isNotEmpty) {
        listenQuery(
          'access',
          _collection.where(
            keyPlayerTaskAccessMemberIds,
            arrayContains: trimmed,
          ),
        );
      }

      const int whereInLimit = 30;
      for (int offset = 0; offset < teamIds.length; offset += whereInLimit) {
        final int endIndex = offset + whereInLimit > teamIds.length
            ? teamIds.length
            : offset + whereInLimit;
        final List<String> batch = teamIds.sublist(offset, endIndex);
        listenQuery(
          'team_$offset',
          batch.length == 1
              ? _collection.where(
                  keyPlayerTaskTeamId,
                  isEqualTo: batch.single,
                )
              : _collection.where(keyPlayerTaskTeamId, whereIn: batch),
        );
      }

      controller.onCancel = () {
        for (final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
            subscription in subscriptions) {
          unawaited(subscription.cancel());
        }
      };
    });
  }

  /// Tasks where [memberId] is an assignee (managers who are not assigned
  /// are excluded — used for player-task reminders).
  Future<List<PlayerTask>> loadAssignedTasksBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) async {
    final String trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return const <PlayerTask>[];
    }

    final DateTime rangeStart = DateUtils.dateOnly(start);
    final DateTime rangeEnd = DateUtils.dateOnly(end);

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
          .where(keyPlayerTaskAssigneeMemberIds, arrayContains: trimmed)
          .get();
      final List<PlayerTask> tasks = <PlayerTask>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final PlayerTask task = PlayerTask.fromSnapshot(doc);
        if (task.overlapsRange(rangeStart, rangeEnd)) {
          tasks.add(task);
        }
      }
      return tasks;
    } catch (error, stackTrace) {
      debugPrint(
        'PlayerTaskService.loadAssignedTasksBetweenDates failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return const <PlayerTask>[];
    }
  }

  Future<PlayerTask> createTask({
    required AppLocalizations l10n,
    required String title,
    required PlayerTaskType type,
    required DateTime startAt,
    required DateTime endAt,
    required String teamId,
    required List<Player> assignees,
    required String createdByUserId,
    required String? createdByMemberId,
    required String? seasonId,
    String? clubId,
  }) async {
    final String trimmedUserId = createdByUserId.trim();
    if (trimmedUserId.isEmpty) {
      throw StateError('missingAuth');
    }
    final String trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      throw StateError('missingTeam');
    }
    final String? typeId = type.id?.trim();
    if (typeId == null || typeId.isEmpty) {
      throw StateError('missingType');
    }

    final List<Player> uniqueAssignees = _dedupePlayers(assignees);
    if (uniqueAssignees.isEmpty) {
      throw StateError('missingAssignees');
    }

    final List<String> assigneeMemberIds = <String>[];
    final List<String> assigneeNames = <String>[];
    for (final Player player in uniqueAssignees) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        continue;
      }
      assigneeMemberIds.add(memberId);
      assigneeNames.add(playerDisplayName(player));
    }
    if (assigneeMemberIds.isEmpty) {
      throw StateError('missingAssignees');
    }

    final Set<String> accessMemberIds = playerTaskAccessMemberIds(
      assigneeMemberIds: assigneeMemberIds,
      createdByMemberId: createdByMemberId,
    );

    final DateTime start = DateUtils.dateOnly(startAt);
    final DateTime endDay = DateUtils.dateOnly(endAt);
    final DateTime end = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
    );

    final PlayerTask task = PlayerTask(
      title: title.trim(),
      typeId: typeId,
      typeName: type.name,
      typeColor: type.color,
      startAt: start,
      endAt: end,
      teamId: trimmedTeamId,
      assigneeMemberIds: assigneeMemberIds,
      assigneeNames: assigneeNames,
      accessMemberIds: accessMemberIds.toList()..sort(),
      createdByUserId: trimmedUserId,
      createdByMemberId: createdByMemberId?.trim(),
      seasonId: seasonId?.trim(),
      clubId: clubId?.trim(),
    );

    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(task.toMap());
    final PlayerTask saved = task.copyWith(id: ref.id, ref: ref);

    await _notifyAssignees(
      l10n: l10n,
      task: saved,
      assignees: uniqueAssignees,
      managerUserId: trimmedUserId,
    );

    return saved;
  }

  Future<PlayerTask> updateTask({
    required AppLocalizations l10n,
    required PlayerTask existing,
    required String title,
    required PlayerTaskType type,
    required DateTime startAt,
    required DateTime endAt,
    required String teamId,
    required List<Player> assignees,
  }) async {
    final DocumentReference? existingRef = existing.ref;
    final String? existingId = existing.id?.trim();
    if (existingRef == null && (existingId == null || existingId.isEmpty)) {
      throw StateError('missingId');
    }

    final String? typeId = type.id?.trim();
    if (typeId == null || typeId.isEmpty) {
      throw StateError('missingType');
    }

    final List<Player> uniqueAssignees = _dedupePlayers(assignees);
    if (uniqueAssignees.isEmpty) {
      throw StateError('missingAssignees');
    }

    final List<String> assigneeMemberIds = <String>[];
    final List<String> assigneeNames = <String>[];
    for (final Player player in uniqueAssignees) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        continue;
      }
      assigneeMemberIds.add(memberId);
      assigneeNames.add(playerDisplayName(player));
    }

    final Set<String> accessMemberIds = playerTaskAccessMemberIds(
      assigneeMemberIds: assigneeMemberIds,
      createdByMemberId: existing.createdByMemberId,
    );

    final DateTime start = DateUtils.dateOnly(startAt);
    final DateTime endDay = DateUtils.dateOnly(endAt);
    final DateTime end = DateTime(
      endDay.year,
      endDay.month,
      endDay.day,
      23,
      59,
      59,
    );

    final PlayerTask updated = existing.copyWith(
      title: title.trim(),
      typeId: typeId,
      typeName: type.name,
      typeColor: type.color,
      startAt: start,
      endAt: end,
      teamId: teamId.trim(),
      assigneeMemberIds: assigneeMemberIds,
      assigneeNames: assigneeNames,
      accessMemberIds: accessMemberIds.toList()..sort(),
    );

    final DocumentReference target = existingRef ?? _collection.doc(existingId);
    await target.set(updated.toMap(), SetOptions(merge: true));
    final PlayerTask saved = updated.copyWith(id: target.id, ref: target);

    final Set<String> previousAssigneeIds = existing.assigneeMemberIds.toSet();
    final List<Player> newlyAdded = <Player>[];
    for (final Player player in uniqueAssignees) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null || previousAssigneeIds.contains(memberId)) {
        continue;
      }
      newlyAdded.add(player);
    }
    if (newlyAdded.isNotEmpty) {
      await _notifyAssignees(
        l10n: l10n,
        task: saved,
        assignees: newlyAdded,
        managerUserId: existing.createdByUserId,
      );
    }

    return saved;
  }

  Future<void> deleteTask(PlayerTask task) async {
    final DocumentReference? ref = task.ref;
    if (ref != null) {
      await ref.delete();
      return;
    }
    final String? id = task.id?.trim();
    if (id == null || id.isEmpty) {
      throw StateError('missingId');
    }
    await _collection.doc(id).delete();
  }

  Future<void> _notifyAssignees({
    required AppLocalizations l10n,
    required PlayerTask task,
    required List<Player> assignees,
    required String managerUserId,
  }) async {
    final String taskId = task.id?.trim() ?? '';
    if (taskId.isEmpty) {
      return;
    }

    final String startLabel = formatPlayerTaskNotificationDate(task.startDay);
    final String endLabel = formatPlayerTaskNotificationDate(task.endDay);
    final String pushTitle = l10n.createPlayerTaskNotificationTitle;
    final String pushBody = l10n.createPlayerTaskNotificationBody(
      task.typeName,
      startLabel,
      endLabel,
    );

    for (final Player player in assignees) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        continue;
      }
      try {
        final Player playerForSend =
            await _playerService.getPlayerById(memberId) ?? player;
        final List<String> linkedUids =
            collectMemberLinkedUserIds(playerForSend).toList();
        if (linkedUids.isEmpty) {
          continue;
        }

        for (final String uid in linkedUids) {
          await _notificationService.createNotification(
            NotificationApp(
              userId: uid,
              type: NotifType.playerTask,
              sendBy: SendBy.notification,
              title: pushTitle,
              body: pushBody,
              objectId: taskId,
              createdUserId: managerUserId,
              clubId: task.clubId,
              playerId: memberId,
              dateTimeCreated: Timestamp.now(),
            ),
          );
        }

        await NotificationFCMService.instance.postNotification(
          tokens: await NotificationFCMService.fetchFcmTokensForUsers(
            linkedUids,
          ),
          title: pushTitle,
          body: pushBody,
          type: 'playerTask',
          payload: <String, dynamic>{
            'id': taskId,
            'type': 'playerTask',
            'body': pushBody,
          },
          clubId: task.clubId,
          recipientUserIds: linkedUids,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'PlayerTaskService._notifyAssignees failed for $memberId: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  List<Player> _dedupePlayers(List<Player> players) {
    final Set<String> seen = <String>{};
    final List<Player> unique = <Player>[];
    for (final Player player in players) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null || !seen.add(memberId)) {
        continue;
      }
      unique.add(player);
    }
    return unique;
  }
}
