import 'package:cloud_functions/cloud_functions.dart';
import 'package:grinta/services/stream_channel_service.dart';
import 'package:grinta/services/user_root_service.dart';

const String kAdminListTeamStreamChannelsFunctionName =
    'adminListTeamStreamChannels';
const String kAdminDeleteTeamStreamChannelFunctionName =
    'adminDeleteTeamStreamChannel';

/// A GetStream team channel row for the platform admin panel.
class AdminStreamChannel {
  const AdminStreamChannel({
    required this.teamId,
    required this.cid,
    required this.channelType,
    required this.name,
    this.teamName,
    required this.memberCount,
    this.lastMessageAt,
  });

  final String teamId;
  final String cid;
  final String channelType;
  final String name;
  final String? teamName;
  final int memberCount;
  final DateTime? lastMessageAt;

  factory AdminStreamChannel.fromMap(Map<String, dynamic> map) {
    final lastMessageRaw = map['lastMessageAt']?.toString().trim();
    DateTime? lastMessageAt;
    if (lastMessageRaw != null && lastMessageRaw.isNotEmpty) {
      lastMessageAt = DateTime.tryParse(lastMessageRaw);
    }

    return AdminStreamChannel(
      teamId: (map['teamId'] ?? '').toString(),
      cid: (map['cid'] ?? '').toString(),
      channelType: (map['channelType'] ?? 'team').toString(),
      name: (map['name'] ?? '').toString(),
      teamName: (map['teamName'] as String?)?.trim().isEmpty == true
          ? null
          : map['teamName']?.toString(),
      memberCount: _parseInt(map['memberCount']),
      lastMessageAt: lastMessageAt,
    );
  }
}

int _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Root-only admin operations on GetStream team channels.
class StreamChannelAdminService {
  StreamChannelAdminService._();

  static final StreamChannelAdminService instance =
      StreamChannelAdminService._();

  Future<void> _ensureRoot() async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
  }

  Future<List<AdminStreamChannel>> listTeamStreamChannels() async {
    await _ensureRoot();

    final functions = FirebaseFunctions.instanceFor(
      region: kStreamFunctionsRegion,
    );
    final callable =
        functions.httpsCallable(kAdminListTeamStreamChannelsFunctionName);

    final result = await callable.call<Map<String, dynamic>>({});
    final data = Map<String, dynamic>.from(result.data);
    final rawChannels = data['channels'];
    if (rawChannels is! List) {
      return const <AdminStreamChannel>[];
    }

    return rawChannels
        .whereType<Map>()
        .map((entry) => AdminStreamChannel.fromMap(
              Map<String, dynamic>.from(entry),
            ))
        .toList();
  }

  Future<void> deleteTeamStreamChannel({required String teamId}) async {
    await _ensureRoot();

    final trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      throw StateError('invalid-team-id');
    }

    final functions = FirebaseFunctions.instanceFor(
      region: kStreamFunctionsRegion,
    );
    final callable =
        functions.httpsCallable(kAdminDeleteTeamStreamChannelFunctionName);

    await callable.call<Map<String, dynamic>>({
      'teamId': trimmedTeamId,
    });
  }
}
