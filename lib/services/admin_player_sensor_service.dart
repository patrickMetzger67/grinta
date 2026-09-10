import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/wearable_sync_owner.dart';

/// Resolves team-kit / wearable indicators for admin player lists.
class AdminPlayerSensorService {
  AdminPlayerSensorService({
    TeamService? teamService,
    WearableDevicesRepository? wearableRepository,
  })  : _teamService = teamService,
        _wearableRepository = wearableRepository;

  TeamService? _teamService;
  WearableDevicesRepository? _wearableRepository;

  TeamService get _effectiveTeamService => _teamService ??= TeamService();

  WearableDevicesRepository get _effectiveWearableRepository =>
      _wearableRepository ??= WearableDevicesRepository();

  Future<AdminPlayerSensorFlags> loadFlags(Player player) async {
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    final hasTeamKit = await _hasTeamKitSensor(player);
    final hasDevices = memberId.isEmpty
        ? false
        : await _hasConnectedDevices(player, memberId);
    return AdminPlayerSensorFlags(
      hasTeamKitSensor: hasTeamKit,
      hasConnectedDevices: hasDevices,
    );
  }

  Future<bool> _hasTeamKitSensor(Player player) async {
    try {
      final teams = await _effectiveTeamService
          .getTeamsForPlayerGrintaMembership(player);
      if (teams.isEmpty) return false;

      final lookupIds = playerMemberLookupIds(player);
      if (lookupIds.isEmpty) return false;

      for (final team in teams) {
        for (final entry in team.grintaPlayers ?? const []) {
          final id = entry.playerId.trim();
          if (id.isEmpty || !lookupIds.contains(id)) continue;
          if (entry.trackers.any((t) => t.trim().isNotEmpty)) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasConnectedDevices(Player player, String memberId) async {
    // Empty callerUid avoids treating the admin account as the sync owner.
    final ownerUid = resolveWearableSyncOwnerUid(
      callerUid: '',
      player: player,
    ).trim();
    if (ownerUid.isEmpty) return false;
    try {
      return await _effectiveWearableRepository.hasAnyConnected(
        ownerUid,
        memberId,
      );
    } catch (_) {
      return false;
    }
  }
}
