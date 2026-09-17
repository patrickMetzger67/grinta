import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/wearable_sync_owner.dart';

/// Resolves team-kit / wearable indicators for admin player lists.
///
/// Never uses [TeamService.getTeamsForPlayerGrintaMembership] (that path
/// downloads every visible team per player). Indicators are best-effort and
/// must not block association lists or hub navigation.
class AdminPlayerSensorService {
  AdminPlayerSensorService({
    TeamService? teamService,
    WearableDevicesRepository? wearableRepository,
    Future<List<Team>> Function(Player player)? loadGrintaTeams,
    Future<bool> Function(Player player, String memberId)? hasConnectedDevices,
    this.timeout = const Duration(seconds: 4),
  })  : _teamService = teamService,
        _wearableRepository = wearableRepository,
        _loadGrintaTeams = loadGrintaTeams,
        _hasConnectedDevicesOverride = hasConnectedDevices;

  TeamService? _teamService;
  WearableDevicesRepository? _wearableRepository;
  final Future<List<Team>> Function(Player player)? _loadGrintaTeams;
  final Future<bool> Function(Player player, String memberId)?
      _hasConnectedDevicesOverride;

  /// Caps each indicator lookup so a hung Firestore read cannot freeze Admin.
  final Duration timeout;

  TeamService get _effectiveTeamService => _teamService ??= TeamService();

  WearableDevicesRepository get _effectiveWearableRepository =>
      _wearableRepository ??= WearableDevicesRepository();

  Future<AdminPlayerSensorFlags> loadFlags(Player player) async {
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    final teamKitFuture = _hasTeamKitSensor(player);
    final devicesFuture = memberId.isEmpty
        ? Future<bool>.value(false)
        : _hasConnectedDevices(player, memberId);

    final results = await Future.wait<bool>([
      teamKitFuture.timeout(timeout, onTimeout: () => false),
      devicesFuture.timeout(timeout, onTimeout: () => false),
    ]);

    return AdminPlayerSensorFlags(
      hasTeamKitSensor: results[0],
      hasConnectedDevices: results[1],
    );
  }

  Future<bool> _hasTeamKitSensor(Player player) async {
    try {
      final loader = _loadGrintaTeams ??
          _effectiveTeamService.getIndexedGrintaTeamsForPlayer;
      final teams = await loader(player);
      return playerHasAssignedTeamKit(player: player, teams: teams);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasConnectedDevices(Player player, String memberId) async {
    if (_hasConnectedDevicesOverride != null) {
      return _hasConnectedDevicesOverride(player, memberId);
    }
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

/// True when [player] has a non-empty tracker id on a Grinta roster row.
bool playerHasAssignedTeamKit({
  required Player player,
  required List<Team> teams,
}) {
  final lookupIds = playerMemberLookupIds(player);
  if (lookupIds.isEmpty) return false;

  for (final team in teams) {
    for (final entry in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      final id = entry.playerId.trim();
      if (id.isEmpty || !lookupIds.contains(id)) continue;
      if (entry.trackers.any((t) => t.trim().isNotEmpty)) {
        return true;
      }
    }
  }
  return false;
}
