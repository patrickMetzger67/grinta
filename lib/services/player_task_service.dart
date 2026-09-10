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
import 'package:intl/intl.dart';

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

  Stream<List<PlayerTask>> watchTasksForMemberBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    final String trimmed = memberId.trim();
    if (trimmed.isEmpty) {
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

    return _collection
        .where(keyPlayerTaskAccessMemberIds, arrayContains: trimmed)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<PlayerTask> tasks = snapshot.docs
          .map(PlayerTask.fromSnapshot)
          .where(
            (PlayerTask task) =>
                !task.endAt.isBefore(rangeStart) &&
                !task.startAt.isAfter(rangeEnd),
          )
          .toList()
        ..sort((PlayerTask a, PlayerTask b) {
          final int startCmp = a.startAt.compareTo(b.startAt);
          if (startCmp != 0) {
            return startCmp;
          }
          return a.barLabel.toLowerCase().compareTo(b.barLabel.toLowerCase());
        });
      return tasks;
    }).handleError((Object error, StackTrace stackTrace) {
      debugPrint(
        'PlayerTaskService.watchTasksForMemberBetweenDates failed: $error',
      );
      Error.throwWithStackTrace(error, stackTrace);
    });
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

    final Set<String> accessMemberIds = <String>{
      ...assigneeMemberIds,
      if ((createdByMemberId ?? '').trim().isNotEmpty)
        createdByMemberId!.trim(),
    };

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

    final Set<String> accessMemberIds = <String>{
      ...assigneeMemberIds,
      if ((existing.createdByMemberId ?? '').trim().isNotEmpty)
        existing.createdByMemberId!.trim(),
    };

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
    return updated.copyWith(id: target.id, ref: target);
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

    final String period = _periodLabel(task);
    final String pushTitle = l10n.createPlayerTaskNotificationTitle;
    final String pushBody = l10n.createPlayerTaskNotificationBody(
      task.barLabel,
      period,
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
              type: NotifType.event,
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
          type: 'event',
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

  String _periodLabel(PlayerTask task) {
    final DateTime start = task.startDay;
    final DateTime end = task.endDay;
    if (start == end) {
      return DateFormat('dd/MM/yyyy').format(start);
    }
    return '${DateFormat('dd/MM/yyyy').format(start)} → ${DateFormat('dd/MM/yyyy').format(end)}';
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
