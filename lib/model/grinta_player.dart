import 'package:cloud_firestore/cloud_firestore.dart';

import 'grinta_player_hw.dart';

String keyGrintaPlayerId = 'playerId';
String keyGrintaPlayerPositions = 'positions';
String keyGrintaPlayerTrackers = 'trackers';
String keyGrintaPlayerEmail = 'email';
String keyGrintaPlayerPhoneE164 = 'phoneE164';
String keyGrintaPlayerBirthday = 'birthday';
String keyGrintaPlayerHwHistory = 'hwHistory';
String keyGrintaPlayerInvitationId = 'invitationId';

class GrintaPlayer {
  String playerId;
  List<int> positions;
  List<String> trackers;
  String? email;
  String? phoneE164;
  DateTime? birthday;
  List<GrintaPlayerHW> hwHistory;
  String? invitationId;

  GrintaPlayer({
    this.playerId = '',
    List<int>? positions,
    List<String>? trackers,
    this.email,
    this.phoneE164,
    this.birthday,
    List<GrintaPlayerHW>? hwHistory,
    this.invitationId,
  })  : positions = positions ?? <int>[],
        trackers = trackers ?? <String>[],
        hwHistory = hwHistory ?? <GrintaPlayerHW>[];

  GrintaPlayerHW? get latestHw {
    if (hwHistory.isEmpty) return null;

    GrintaPlayerHW latest = hwHistory.first;
    for (final GrintaPlayerHW entry in hwHistory.skip(1)) {
      if (entry.dateTime.isAfter(latest.dateTime)) {
        latest = entry;
      }
    }
    return latest;
  }

  factory GrintaPlayer.fromMap(Map<String, dynamic>? map) {
    final String playerId = (map?[keyGrintaPlayerId] ?? '').toString().trim();

    final List<int> positions = <int>[];
    final dynamic rawPositions = map?[keyGrintaPlayerPositions];
    if (rawPositions is List) {
      for (final dynamic entry in rawPositions) {
        final int? code = _parsePositionCode(entry);
        if (code != null) {
          positions.add(code);
        }
      }
    }

    final List<String> trackers = <String>[];
    final dynamic rawTrackers = map?[keyGrintaPlayerTrackers];
    if (rawTrackers is List) {
      for (final dynamic entry in rawTrackers) {
        final String id = entry?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          trackers.add(id);
        }
      }
    }

    final List<GrintaPlayerHW> hwHistory = <GrintaPlayerHW>[];
    final dynamic rawHwHistory = map?[keyGrintaPlayerHwHistory];
    if (rawHwHistory is List) {
      for (final dynamic entry in rawHwHistory) {
        if (entry is Map) {
          hwHistory.add(
            GrintaPlayerHW.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final String? email = _optionalTrimmedString(map?[keyGrintaPlayerEmail]);
    final String? phoneE164 =
        _optionalTrimmedString(map?[keyGrintaPlayerPhoneE164]);
    final DateTime? birthday = _parseBirthday(map?[keyGrintaPlayerBirthday]);
    final String? invitationId =
        _optionalTrimmedString(map?[keyGrintaPlayerInvitationId]);

    return GrintaPlayer(
      playerId: playerId,
      positions: positions,
      trackers: trackers,
      email: email,
      phoneE164: phoneE164,
      birthday: birthday,
      hwHistory: hwHistory,
      invitationId: invitationId,
    );
  }

  static String? _optionalTrimmedString(Object? value) {
    if (value == null) return null;
    final String trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _parseBirthday(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int? _parsePositionCode(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return _parsePositionCode(map['code'] ?? map['id'] ?? map['position']);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      keyGrintaPlayerId: playerId,
      keyGrintaPlayerPositions: positions,
      keyGrintaPlayerTrackers: trackers,
      if (email != null && email!.trim().isNotEmpty)
        keyGrintaPlayerEmail: email!.trim(),
      if (phoneE164 != null && phoneE164!.trim().isNotEmpty)
        keyGrintaPlayerPhoneE164: phoneE164!.trim(),
      if (birthday != null)
        keyGrintaPlayerBirthday: Timestamp.fromDate(birthday!),
      if (hwHistory.isNotEmpty)
        keyGrintaPlayerHwHistory:
            hwHistory.map((GrintaPlayerHW entry) => entry.toMap()).toList(),
      if (invitationId != null && invitationId!.trim().isNotEmpty)
        keyGrintaPlayerInvitationId: invitationId!.trim(),
    };
  }

  @override
  String toString() {
    return 'GrintaPlayer(playerId=$playerId, positions=$positions, '
        'trackers=$trackers, email=$email, phoneE164=$phoneE164, '
        'birthday=$birthday, hwHistory=$hwHistory, invitationId=$invitationId)';
  }
}
