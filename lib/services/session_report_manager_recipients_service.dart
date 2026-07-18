import 'package:flutter/foundation.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:grinta/util/training_creation_helper.dart';

/// A team manager that can receive a session PDF report email.
class SessionReportManagerRecipient {
  const SessionReportManagerRecipient({
    required this.player,
    required this.displayName,
    required this.email,
    required this.selectionKey,
  });

  final Player player;
  final String displayName;
  final String email;

  /// Stable key for checkbox selection (player doc id or user id).
  final String selectionKey;
}

/// Loads team managers with a usable email for the report send dialog.
class SessionReportManagerRecipientsService {
  SessionReportManagerRecipientsService({
    TeamService? teamService,
    PlayerService? playerService,
  })  : _teamService = teamService ?? TeamService(),
        _playerService = playerService ?? PlayerService();

  final TeamService _teamService;
  final PlayerService _playerService;

  Future<List<SessionReportManagerRecipient>> loadManagers({
    required String? teamId,
  }) async {
    final String trimmedTeamId = teamId?.trim() ?? '';
    if (trimmedTeamId.isEmpty) {
      return const <SessionReportManagerRecipient>[];
    }

    try {
      final Team? team = await _teamService.getTeamById(trimmedTeamId);
      if (team == null) {
        return const <SessionReportManagerRecipient>[];
      }

      final Set<String> managerIds = managerIdsFromTeam(team);
      if (managerIds.isEmpty) {
        return const <SessionReportManagerRecipient>[];
      }

      final Map<String, String> grintaEmailByPlayerId = <String, String>{};
      for (final gp in team.grintaPlayers ?? const <GrintaPlayer>[]) {
        final String playerId = gp.playerId.trim();
        final String email = (gp.email ?? '').trim();
        if (playerId.isNotEmpty &&
            email.isNotEmpty &&
            isValidEmailFormat(email)) {
          grintaEmailByPlayerId[playerId] = email;
        }
      }

      final Map<String, SessionReportManagerRecipient> byEmail =
          <String, SessionReportManagerRecipient>{};

      for (final String managerId in managerIds) {
        try {
          Player? player = await _playerService.getPlayerById(managerId);
          player ??= await _playerService.getPlayerByUserId(managerId);
          if (player == null) {
            continue;
          }

          final String email = _resolveEmail(
            player: player,
            grintaEmailByPlayerId: grintaEmailByPlayerId,
          );
          if (email.isEmpty) {
            continue;
          }

          final String key = effectiveMemberId(player) ??
              (player.userID?.trim().isNotEmpty == true
                  ? player.userID!.trim()
                  : managerId);

          // Deduplicate by email (same person may appear under multiple ids).
          byEmail.putIfAbsent(
            email.toLowerCase(),
            () => SessionReportManagerRecipient(
              player: player!,
              displayName: playerDisplayName(player),
              email: email,
              selectionKey: key,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'SessionReportManagerRecipientsService: skip $managerId: $e',
            );
          }
        }
      }

      final List<SessionReportManagerRecipient> recipients =
          byEmail.values.toList(growable: false);
      recipients.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
      );
      return recipients;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'SessionReportManagerRecipientsService.loadManagers failed: $e\n$st',
        );
      }
      return const <SessionReportManagerRecipient>[];
    }
  }

  String _resolveEmail({
    required Player player,
    required Map<String, String> grintaEmailByPlayerId,
  }) {
    for (final String id in playerMemberLookupIds(player)) {
      final String? fromGrinta = grintaEmailByPlayerId[id];
      if (fromGrinta != null && fromGrinta.isNotEmpty) {
        return fromGrinta;
      }
    }

    final String fromPlayer = (player.email ?? '').trim();
    if (fromPlayer.isNotEmpty && isValidEmailFormat(fromPlayer)) {
      return fromPlayer;
    }
    return '';
  }
}
