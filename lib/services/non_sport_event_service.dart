import 'dart:async' show StreamSubscription, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/non_sport_event.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:intl/intl.dart';

class NonSportEventCreateResult {
  const NonSportEventCreateResult({
    required this.event,
    required this.notificationsCreated,
    required this.pushNotificationsSent,
    required this.skippedNoLinkedAccount,
  });

  final NonSportEvent event;
  final int notificationsCreated;
  final int pushNotificationsSent;
  final int skippedNoLinkedAccount;
}

class NonSportEventService {
  static const String collectionName = 'agendaActivity';

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final PlayerService _playerService;
  final TeamService _teamService;

  NonSportEventService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    PlayerService? playerService,
    TeamService? teamService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        _playerService = playerService ?? PlayerService(),
        _teamService = teamService ?? TeamService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Loads all roster members (players + staff) for a team.
  Future<List<Player>> loadAllTeamMembers(Team team) async {
    final Set<String> memberIds = <String>{};

    for (final dynamic rawId in team.players ?? const <dynamic>[]) {
      final String id = rawId?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        memberIds.add(id);
      }
    }

    for (final dynamic rawId in team.managers ?? const <dynamic>[]) {
      final String id = rawId?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        memberIds.add(id);
      }
    }

    for (final entry in team.grintaPlayers ?? const []) {
      final String id = entry.playerId.trim();
      if (id.isNotEmpty) {
        memberIds.add(id);
      }
    }

    for (final String id in team.grintaPlayerMemberIds ?? const <String>[]) {
      final String trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        memberIds.add(trimmed);
      }
    }

    final List<Player> players = <Player>[];
    for (final String id in memberIds) {
      final Player? player = await _playerService.getPlayerById(id);
      if (player != null) {
        players.add(player);
      }
    }

    players.sort((Player a, Player b) {
      final int last = (a.lastName ?? '')
          .toLowerCase()
          .compareTo((b.lastName ?? '').toLowerCase());
      if (last != 0) {
        return last;
      }
      return (a.firstName ?? '')
          .toLowerCase()
          .compareTo((b.firstName ?? '').toLowerCase());
    });

    return _dedupePlayers(players);
  }

  Future<NonSportEventCreateResult> createEvent({
    required AppLocalizations l10n,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required bool allDay,
    required String? location,
    required List<String> teamIds,
    required List<Player> invitees,
    required String createdByUserId,
    required String? createdByMemberId,
    required String? seasonId,
    String? clubId,
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw StateError('missingTitle');
    }

    final String trimmedUserId = createdByUserId.trim();
    if (trimmedUserId.isEmpty) {
      throw StateError('missingAuth');
    }

    final List<Player> uniqueInvitees = _dedupePlayers(invitees);
    final List<NonSportInvitee> inviteeRows = uniqueInvitees
        .map((Player player) {
          final String? memberId = effectiveMemberId(player);
          if (memberId == null) {
            return null;
          }
          return NonSportInvitee(
            memberId: memberId,
            displayName: playerDisplayName(player),
            teamIds: const <String>[],
            status: NonSportInviteStatus.pending,
          );
        })
        .whereType<NonSportInvitee>()
        .toList();

    // Attach originating team ids when the invitee belongs to selected teams.
    final Map<String, Set<String>> memberTeamIds = <String, Set<String>>{};
    for (final String teamId in teamIds) {
      final String trimmedTeamId = teamId.trim();
      if (trimmedTeamId.isEmpty) {
        continue;
      }
      final Team? team = await _teamService.getTeamById(trimmedTeamId);
      if (team == null) {
        continue;
      }
      final List<Player> members = await loadAllTeamMembers(team);
      for (final Player member in members) {
        final String? memberId = effectiveMemberId(member);
        if (memberId == null) {
          continue;
        }
        memberTeamIds
            .putIfAbsent(memberId, () => <String>{})
            .add(trimmedTeamId);
      }
    }

    final List<NonSportInvitee> inviteesWithTeams = inviteeRows.map((row) {
      final Set<String>? teams = memberTeamIds[row.memberId];
      if (teams == null || teams.isEmpty) {
        return row;
      }
      return row.copyWith(teamIds: teams.toList()..sort());
    }).toList();

    final List<String> inviteeMemberIds = inviteesWithTeams
        .map((NonSportInvitee e) => e.memberId)
        .toList();

    final Set<String> accessMemberIds = <String>{
      ...inviteeMemberIds,
      if ((createdByMemberId ?? '').trim().isNotEmpty)
        createdByMemberId!.trim(),
    };

    final String resolvedClubId = (clubId ?? '').trim().isNotEmpty
        ? clubId!.trim()
        : InvitationConfig.grintaInvitationClubId;

    final DocumentReference<Map<String, dynamic>> docRef = _collection.doc();
    NonSportEvent event = NonSportEvent(
      id: docRef.id,
      title: trimmedTitle,
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      location: location?.trim().isEmpty == true ? null : location?.trim(),
      teamIds: teamIds
          .map((String id) => id.trim())
          .where((String id) => id.isNotEmpty)
          .toList(),
      inviteeMemberIds: inviteeMemberIds,
      accessMemberIds: accessMemberIds.toList()..sort(),
      invitees: inviteesWithTeams,
      createdByUserId: trimmedUserId,
      createdByMemberId: createdByMemberId?.trim(),
      seasonId: seasonId?.trim(),
      clubId: resolvedClubId,
      createdAt: Timestamp.now(),
      ref: docRef,
    );

    await docRef.set(event.toMap());

    final _NotifyOutcome notifyOutcome = await _notifyInvitees(
      l10n: l10n,
      event: event,
      invitees: uniqueInvitees,
      managerUserId: trimmedUserId,
    );

    event = event.copyWith(invitees: notifyOutcome.invitees);
    await docRef.set(
      <String, dynamic>{
        keyNonSportEventInvitees:
            event.invitees.map((NonSportInvitee e) => e.toMap()).toList(),
        keyNonSportEventUpdatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return NonSportEventCreateResult(
      event: event,
      notificationsCreated: notifyOutcome.notificationsCreated,
      pushNotificationsSent: notifyOutcome.pushNotificationsSent,
      skippedNoLinkedAccount: notifyOutcome.skippedNoLinkedAccount,
    );
  }

  /// Updates an existing event, replaces invite notifications, and re-notifies.
  Future<NonSportEventCreateResult> updateEvent({
    required AppLocalizations l10n,
    required NonSportEvent existing,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    required bool allDay,
    required String? location,
    required List<String> teamIds,
    required List<Player> invitees,
    required String editorUserId,
  }) async {
    final String eventId = existing.id?.trim() ?? '';
    if (eventId.isEmpty) {
      throw StateError('missingEventId');
    }

    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw StateError('missingTitle');
    }

    final String trimmedUserId = editorUserId.trim();
    if (trimmedUserId.isEmpty) {
      throw StateError('missingAuth');
    }

    final List<Player> uniqueInvitees = _dedupePlayers(invitees);
    final List<NonSportInvitee> inviteesWithTeams =
        await _buildInviteeRows(uniqueInvitees, teamIds);

    final List<String> inviteeMemberIds = inviteesWithTeams
        .map((NonSportInvitee e) => e.memberId)
        .toList();

    final Set<String> accessMemberIds = <String>{
      ...inviteeMemberIds,
      if ((existing.createdByMemberId ?? '').trim().isNotEmpty)
        existing.createdByMemberId!.trim(),
    };

    NonSportEvent event = existing.copyWith(
      title: trimmedTitle,
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      location: location?.trim().isEmpty == true ? null : location?.trim(),
      teamIds: teamIds
          .map((String id) => id.trim())
          .where((String id) => id.isNotEmpty)
          .toList(),
      inviteeMemberIds: inviteeMemberIds,
      accessMemberIds: accessMemberIds.toList()..sort(),
      invitees: inviteesWithTeams,
      updatedAt: Timestamp.now(),
    );

    final DocumentReference<Map<String, dynamic>> docRef =
        existing.ref as DocumentReference<Map<String, dynamic>>? ??
            _collection.doc(eventId);

    // Remove previous invite notifications before sending fresh ones.
    await _notificationService.deleteNotificationsByObjectId(eventId);

    await docRef.set(event.toMap(includeTimestamps: false), SetOptions(merge: true));
    await docRef.set(
      <String, dynamic>{
        keyNonSportEventUpdatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final _NotifyOutcome notifyOutcome = await _notifyInvitees(
      l10n: l10n,
      event: event,
      invitees: uniqueInvitees,
      managerUserId: trimmedUserId,
    );

    event = event.copyWith(invitees: notifyOutcome.invitees, ref: docRef);
    await docRef.set(
      <String, dynamic>{
        keyNonSportEventInvitees:
            event.invitees.map((NonSportInvitee e) => e.toMap()).toList(),
        keyNonSportEventUpdatedAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return NonSportEventCreateResult(
      event: event,
      notificationsCreated: notifyOutcome.notificationsCreated,
      pushNotificationsSent: notifyOutcome.pushNotificationsSent,
      skippedNoLinkedAccount: notifyOutcome.skippedNoLinkedAccount,
    );
  }

  /// Deletes the event document and all related notifications.
  Future<void> deleteEvent(NonSportEvent event) async {
    final String eventId = event.id?.trim() ?? '';
    if (eventId.isEmpty) {
      throw StateError('missingEventId');
    }

    await _notificationService.deleteNotificationsByObjectId(eventId);

    final DocumentReference<Map<String, dynamic>> docRef =
        event.ref as DocumentReference<Map<String, dynamic>>? ??
            _collection.doc(eventId);
    await docRef.delete();
  }

  Future<List<NonSportInvitee>> _buildInviteeRows(
    List<Player> invitees,
    List<String> teamIds,
  ) async {
    final List<NonSportInvitee> inviteeRows = invitees
        .map((Player player) {
          final String? memberId = effectiveMemberId(player);
          if (memberId == null) {
            return null;
          }
          return NonSportInvitee(
            memberId: memberId,
            displayName: playerDisplayName(player),
            teamIds: const <String>[],
            status: NonSportInviteStatus.pending,
          );
        })
        .whereType<NonSportInvitee>()
        .toList();

    final Map<String, Set<String>> memberTeamIds = <String, Set<String>>{};
    for (final String teamId in teamIds) {
      final String trimmedTeamId = teamId.trim();
      if (trimmedTeamId.isEmpty) {
        continue;
      }
      final Team? team = await _teamService.getTeamById(trimmedTeamId);
      if (team == null) {
        continue;
      }
      final List<Player> members = await loadAllTeamMembers(team);
      for (final Player member in members) {
        final String? memberId = effectiveMemberId(member);
        if (memberId == null) {
          continue;
        }
        memberTeamIds
            .putIfAbsent(memberId, () => <String>{})
            .add(trimmedTeamId);
      }
    }

    return inviteeRows.map((NonSportInvitee row) {
      final Set<String>? teams = memberTeamIds[row.memberId];
      if (teams == null || teams.isEmpty) {
        return row;
      }
      return row.copyWith(teamIds: teams.toList()..sort());
    }).toList();
  }

  Stream<List<NonSportEvent>> watchEventsForMemberBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    final String trimmedMemberId = memberId.trim();
    if (trimmedMemberId.isEmpty) {
      return Stream<List<NonSportEvent>>.value(const <NonSportEvent>[]);
    }

    final DateTime rangeStart = DateTime(
      start.year,
      start.month,
      start.day,
    );
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
        .where(keyNonSportEventAccessMemberIds, arrayContains: trimmedMemberId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<NonSportEvent> events = snapshot.docs
          .map(NonSportEvent.fromSnapshot)
          .where((NonSportEvent event) {
            // Keep events that overlap the visible agenda window (multi-day).
            return !event.endAt.isBefore(rangeStart) &&
                !event.startAt.isAfter(rangeEnd);
          })
          .toList()
        ..sort((NonSportEvent a, NonSportEvent b) {
          if (a.allDay != b.allDay) {
            return a.allDay ? -1 : 1;
          }
          return a.startAt.compareTo(b.startAt);
        });
      return events;
    }).handleError((Object error, StackTrace stackTrace) {
      debugPrint(
        'NonSportEventService.watchEventsForMemberBetweenDates failed: $error',
      );
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  /// Combines member-access streams when several member profiles may apply.
  Stream<List<NonSportEvent>> watchEventsForMembersBetweenDates({
    required List<String> memberIds,
    required DateTime start,
    required DateTime end,
  }) {
    final List<String> uniqueMemberIds = memberIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueMemberIds.isEmpty) {
      return Stream<List<NonSportEvent>>.value(const <NonSportEvent>[]);
    }

    if (uniqueMemberIds.length == 1) {
      return watchEventsForMemberBetweenDates(
        memberId: uniqueMemberIds.first,
        start: start,
        end: end,
      );
    }

    return Stream<List<NonSportEvent>>.multi((controller) {
      final Map<String, List<NonSportEvent>> partial =
          <String, List<NonSportEvent>>{};
      final List<StreamSubscription<List<NonSportEvent>>> subscriptions =
          <StreamSubscription<List<NonSportEvent>>>[];

      void emitMerged() {
        final Map<String, NonSportEvent> unique = <String, NonSportEvent>{};
        for (final List<NonSportEvent> events in partial.values) {
          for (final NonSportEvent event in events) {
            final String? id = event.id;
            if (id == null || id.isEmpty) {
              continue;
            }
            unique[id] = event;
          }
        }

        final List<NonSportEvent> merged = unique.values.toList()
          ..sort((NonSportEvent a, NonSportEvent b) {
            if (a.allDay != b.allDay) {
              return a.allDay ? -1 : 1;
            }
            return a.startAt.compareTo(b.startAt);
          });
        controller.add(merged);
      }

      for (final String memberId in uniqueMemberIds) {
        subscriptions.add(
          watchEventsForMemberBetweenDates(
            memberId: memberId,
            start: start,
            end: end,
          ).listen(
            (List<NonSportEvent> events) {
              partial[memberId] = events;
              emitMerged();
            },
            onError: controller.addError,
          ),
        );
      }

      controller.onCancel = () {
        for (final StreamSubscription<List<NonSportEvent>> subscription
            in subscriptions) {
          unawaited(subscription.cancel());
        }
      };
    });
  }

  Future<_NotifyOutcome> _notifyInvitees({
    required AppLocalizations l10n,
    required NonSportEvent event,
    required List<Player> invitees,
    required String managerUserId,
  }) async {
    final String eventId = event.id?.trim() ?? '';
    if (eventId.isEmpty) {
      return const _NotifyOutcome(
        invitees: <NonSportInvitee>[],
        notificationsCreated: 0,
        pushNotificationsSent: 0,
        skippedNoLinkedAccount: 0,
      );
    }

    final String pushTitle = l10n.createNonSportEventNotificationTitle;
    final bool multiDay = DateUtils.dateOnly(event.startAt) !=
        DateUtils.dateOnly(event.endAt);
    final String whenLabel;
    if (event.allDay) {
      whenLabel = multiDay
          ? '${DateFormat('dd/MM/yyyy').format(event.startAt)} → ${DateFormat('dd/MM/yyyy').format(event.endAt)}'
          : l10n.createNonSportEventAllDay;
    } else if (multiDay) {
      whenLabel =
          '${DateFormat('dd/MM/yyyy HH:mm').format(event.startAt)} → ${DateFormat('dd/MM/yyyy HH:mm').format(event.endAt)}';
    } else {
      whenLabel = DateFormat('dd/MM/yyyy HH:mm').format(event.startAt);
    }
    final String location = (event.location ?? '').trim();
    final String pushBody = location.isEmpty
        ? l10n.createNonSportEventNotificationBody(
            event.title,
            whenLabel,
          )
        : l10n.createNonSportEventNotificationBodyWithLocation(
            event.title,
            whenLabel,
            location,
          );

    var notificationsCreated = 0;
    var pushNotificationsSent = 0;
    var skippedNoLinkedAccount = 0;
    final List<NonSportInvitee> updatedInvitees = <NonSportInvitee>[];

    for (final Player player in invitees) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        continue;
      }

      final NonSportInvitee existing = event.invitees.firstWhere(
        (NonSportInvitee e) => e.memberId == memberId,
        orElse: () => NonSportInvitee(
          memberId: memberId,
          displayName: playerDisplayName(player),
        ),
      );

      try {
        final Player playerForSend =
            await _playerService.getPlayerById(memberId) ?? player;
        final List<String> linkedUids =
            collectMemberLinkedUserIds(playerForSend).toList();

        if (linkedUids.isEmpty) {
          skippedNoLinkedAccount++;
          updatedInvitees.add(
            existing.copyWith(status: NonSportInviteStatus.noAccount),
          );
          continue;
        }

        for (final String uid in linkedUids) {
          final NotificationApp notification = NotificationApp(
            userId: uid,
            type: NotifType.event,
            sendBy: SendBy.notification,
            title: pushTitle,
            body: pushBody,
            objectId: eventId,
            createdUserId: managerUserId,
            clubId: event.clubId,
            playerId: memberId,
            dateTimeCreated: Timestamp.now(),
          );
          await _notificationService.createNotification(notification);
          notificationsCreated++;
        }

        final List<String> tokens =
            await NotificationFCMService.fetchFcmTokensForUsers(linkedUids);
        if (tokens.isNotEmpty) {
          final bool pushSent =
              await NotificationFCMService.instance.postNotification(
            tokens: tokens,
            title: pushTitle,
            body: pushBody,
            type: 'event',
            payload: <String, dynamic>{
              'id': eventId,
              'type': 'event',
              'body': pushBody,
            },
            clubId: event.clubId,
          );
          if (pushSent) {
            pushNotificationsSent++;
          }
        }

        updatedInvitees.add(
          existing.copyWith(
            status: NonSportInviteStatus.sent,
            notifiedUserIds: linkedUids,
          ),
        );
      } catch (error, stackTrace) {
        debugPrint(
          'NonSportEventService._notifyInvitees failed for $memberId: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        updatedInvitees.add(
          existing.copyWith(status: NonSportInviteStatus.error),
        );
      }
    }

    return _NotifyOutcome(
      invitees: updatedInvitees,
      notificationsCreated: notificationsCreated,
      pushNotificationsSent: pushNotificationsSent,
      skippedNoLinkedAccount: skippedNoLinkedAccount,
    );
  }

  static List<Player> _dedupePlayers(List<Player> players) {
    final Set<String> seen = <String>{};
    final List<Player> result = <Player>[];
    for (final Player player in players) {
      final String? memberId = effectiveMemberId(player);
      if (memberId == null) {
        result.add(player);
        continue;
      }
      if (seen.add(memberId)) {
        result.add(player);
      }
    }
    return result;
  }
}

class _NotifyOutcome {
  const _NotifyOutcome({
    required this.invitees,
    required this.notificationsCreated,
    required this.pushNotificationsSent,
    required this.skippedNoLinkedAccount,
  });

  final List<NonSportInvitee> invitees;
  final int notificationsCreated;
  final int pushNotificationsSent;
  final int skippedNoLinkedAccount;
}

/// Lightweight date/time formatting without depending on a BuildContext.