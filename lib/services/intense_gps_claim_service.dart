import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/intense_gps_sync_config.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/intense_gps_sync_repository.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/wearable_sync_owner.dart';

enum IntenseGpsClaimResult {
  success,
  missingSerial,
  notFound,
  alreadyAssigned,
  alreadyConnected,
  unauthenticated,
  missingEmail,
  failed,
}

/// Claims an Intense GPS tracker by serial for an individual player profile.
///
/// Creates `TRACKER_Owner` (`isIndividual: true`, `typeTracker: intense`) and
/// associates `TRACKER_Device` + `TRACKER_DeviceOwner`. Disconnect reverses it.
class IntenseGpsClaimService {
  IntenseGpsClaimService({
    DeviceService? deviceService,
    OwnerService? ownerService,
    DeviceOwnerService? deviceOwnerService,
    IntenseGpsSyncRepository? syncRepository,
    PlayerService? playerService,
    FirebaseFirestore? firestore,
  })  : _devices = deviceService ?? DeviceService(),
        _owners = ownerService ?? OwnerService(),
        _deviceOwners = deviceOwnerService ?? DeviceOwnerService(),
        _syncRepository = syncRepository ?? IntenseGpsSyncRepository(),
        _players = playerService ?? PlayerService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  static final IntenseGpsClaimService instance = IntenseGpsClaimService();

  final DeviceService _devices;
  final OwnerService _owners;
  final DeviceOwnerService _deviceOwners;
  final IntenseGpsSyncRepository _syncRepository;
  final PlayerService _players;
  final FirebaseFirestore _firestore;

  /// Hydrates `users/{uid}/intenseGpsSync/{playerId}` from an existing
  /// individual Intense `TRACKER_Owner` linked by the player email.
  ///
  /// Needed so Appareils/Applications badge + list count pre-existing claims.
  Future<bool> repairPlayerSync({
    required String playerId,
    String initiatedBy = 'player',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final trimmedPlayerId = playerId.trim();
    if (trimmedPlayerId.isEmpty) return false;

    try {
      final player = await _players.getPlayerById(trimmedPlayerId);
      if (player == null) return false;

      final syncOwnerUid = resolveWearableSyncOwnerUid(
        callerUid: uid,
        player: player,
      );

      final existing =
          await _syncRepository.getConfig(syncOwnerUid, trimmedPlayerId);
      if (existing?.connected == true) return false;

      final email = (player.email ?? '').trim();
      if (email.isEmpty) return false;

      final resolved = await _resolveExistingIndividualIntense(
        email: email,
      );
      if (resolved == null) return false;

      await _syncRepository.saveConfig(
        uid: syncOwnerUid,
        playerId: trimmedPlayerId,
        config: IntenseGpsSyncConfig(
          connected: true,
          connectedAt: DateTime.now(),
          serialNumber: resolved.serialNumber,
          deviceId: resolved.deviceId,
          ownerId: resolved.ownerId,
          deviceOwnerId: resolved.deviceOwnerId,
          initiatedBy: initiatedBy,
          coachUid: initiatedBy == 'coach' ? uid : null,
        ),
      );
      return true;
    } catch (e, st) {
      debugPrint('[IntenseGpsClaim] repair failed: $e\n$st');
      return false;
    }
  }

  Future<IntenseGpsClaimResult> claimBySerial({
    required String playerId,
    required String serialNumber,
    required String initiatedBy,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return IntenseGpsClaimResult.unauthenticated;
    }

    final serial = serialNumber.trim();
    if (serial.isEmpty) {
      return IntenseGpsClaimResult.missingSerial;
    }

    final player = await _players.getPlayerById(playerId.trim());
    if (player == null) {
      return IntenseGpsClaimResult.failed;
    }

    final syncOwnerUid = resolveWearableSyncOwnerUid(
      callerUid: uid,
      player: player,
    );

    final existing = await _syncRepository.getConfig(syncOwnerUid, playerId);
    if (existing?.connected == true) {
      return IntenseGpsClaimResult.alreadyConnected;
    }

    final email = (player.email ?? '').trim();
    if (email.isEmpty) {
      return IntenseGpsClaimResult.missingEmail;
    }

    try {
      final device = await _devices.getDeviceBySerialNumber(serial);
      if (device == null) {
        return IntenseGpsClaimResult.notFound;
      }

      final currentOwnerId = device.ownerId?.trim() ?? '';
      if (currentOwnerId.isNotEmpty) {
        final currentOwner = await _owners.getOwnerById(currentOwnerId);
        if (currentOwner != null &&
            _isIndividualIntenseOwner(currentOwner) &&
            currentOwner.email.trim().toLowerCase() == email.toLowerCase()) {
          await _hydrateSyncFromOwnerDevice(
            syncOwnerUid: syncOwnerUid,
            playerId: playerId.trim(),
            owner: currentOwner,
            deviceId: device.id,
            serialNumber: device.serialNumber?.trim().isNotEmpty == true
                ? device.serialNumber!.trim()
                : serial,
            initiatedBy: initiatedBy,
            coachUid: initiatedBy == 'coach' ? uid : null,
          );
          return IntenseGpsClaimResult.success;
        }
        return IntenseGpsClaimResult.alreadyAssigned;
      }

      final now = Timestamp.now();
      final firstName = (player.firstName ?? '').trim();
      final lastName = (player.lastName ?? '').trim();
      final displayName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');

      final owner = Owner(
        name: displayName.isEmpty ? email : displayName,
        typeTracker: TrackerOwner.typeIntense,
        isActive: true,
        withSyncing: false,
        isIndividual: true,
        email: email,
        firstname: firstName,
        lastname: lastName,
        createdAt: now,
        uidCreate: uid,
        updatedAt: now,
        uidUpdate: uid,
      );
      await _owners.upsertOwner(owner);

      await _firestore
          .collection(DeviceService.collectionName)
          .doc(device.id)
          .update(<String, dynamic>{
        'ownerId': owner.id,
        'updatedAt': now,
      });

      final deviceOwnerDocId = await _deviceOwners.create(
        DeviceOwner(
          id: '',
          ownerId: owner.id,
          deviceId: device.id,
          customName: device.customName ?? device.deviceName,
          affectedAt: now,
          affectedUid: uid,
        ),
      );

      await _syncRepository.saveConfig(
        uid: syncOwnerUid,
        playerId: playerId.trim(),
        config: IntenseGpsSyncConfig(
          connected: true,
          connectedAt: DateTime.now(),
          serialNumber: serial,
          deviceId: device.id,
          ownerId: owner.id,
          deviceOwnerId: deviceOwnerDocId,
          initiatedBy: initiatedBy,
          coachUid: initiatedBy == 'coach' ? uid : null,
        ),
      );

      return IntenseGpsClaimResult.success;
    } catch (e, st) {
      debugPrint('[IntenseGpsClaim] claim failed: $e\n$st');
      return IntenseGpsClaimResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final player = await _players.getPlayerById(playerId.trim());
    final syncOwnerUid = resolveWearableSyncOwnerUid(
      callerUid: uid,
      player: player,
    );

    try {
      final config =
          await _syncRepository.getConfig(syncOwnerUid, playerId.trim());
      if (config == null || config.connected != true) {
        await _syncRepository.clearConfig(
          uid: syncOwnerUid,
          playerId: playerId.trim(),
        );
        return true;
      }

      final deviceId = config.deviceId?.trim() ?? '';
      final ownerId = config.ownerId?.trim() ?? '';
      final deviceOwnerId = config.deviceOwnerId?.trim() ?? '';

      if (deviceOwnerId.isNotEmpty) {
        try {
          await _deviceOwners.delete(deviceOwnerId);
        } catch (_) {
          if (deviceId.isNotEmpty) {
            await _deviceOwners.deleteLatestByDeviceId(deviceId);
          }
        }
      } else if (deviceId.isNotEmpty) {
        await _deviceOwners.deleteLatestByDeviceId(deviceId);
      }

      if (deviceId.isNotEmpty) {
        await _firestore
            .collection(DeviceService.collectionName)
            .doc(deviceId)
            .update(<String, dynamic>{
          'ownerId': '',
          'updatedAt': Timestamp.now(),
        });
      }

      if (ownerId.isNotEmpty) {
        final owner = await _owners.getOwnerById(ownerId);
        if (owner != null && _isIndividualIntenseOwner(owner)) {
          await _owners.deleteOwner(ownerId);
        }
      }

      await _syncRepository.clearConfig(
        uid: syncOwnerUid,
        playerId: playerId.trim(),
      );
      return true;
    } catch (e, st) {
      debugPrint('[IntenseGpsClaim] disconnect failed: $e\n$st');
      return false;
    }
  }

  bool _isIndividualIntenseOwner(Owner owner) {
    if (!owner.isActive || owner.withSyncing) return false;
    final type = owner.typeTracker.trim().toLowerCase();
    if (type == TrackerOwner.typePolar) return false;
    final intenseLike = type.isEmpty ||
        type == TrackerOwner.typeIntense ||
        type == 'insiders' ||
        type == 'gps';
    if (!intenseLike) return false;
    // Prefer isIndividual; also accept legacy Intense owners missing the flag.
    return owner.isIndividual || type == TrackerOwner.typeIntense;
  }

  Future<_ResolvedIntenseClaim?> _resolveExistingIndividualIntense({
    required String email,
  }) async {
    // Email match in TRACKER_Owner is case-sensitive in Firestore queries.
    final owners = <Owner>[];
    final seen = <String>{};
    for (final candidate in <String>{email, email.toLowerCase()}) {
      for (final owner in await _owners.getOwnersByEmail(candidate)) {
        if (seen.add(owner.id)) owners.add(owner);
      }
    }
    final candidates = owners.where(_isIndividualIntenseOwner).toList();
    candidates.sort((a, b) {
      final aIntense =
          a.typeTracker.trim().toLowerCase() == TrackerOwner.typeIntense
              ? 0
              : 1;
      final bIntense =
          b.typeTracker.trim().toLowerCase() == TrackerOwner.typeIntense
              ? 0
              : 1;
      return aIntense.compareTo(bIntense);
    });

    for (final owner in candidates) {
      final deviceOwners = await _deviceOwners.listByOwnerId(owner.id);
      if (deviceOwners.isEmpty) continue;

      deviceOwners.sort(
        (a, b) => b.affectedAt.compareTo(a.affectedAt),
      );
      final deviceOwner = deviceOwners.first;
      final deviceId = deviceOwner.deviceId.trim();
      if (deviceId.isEmpty) continue;

      final device = await _devices.getDeviceById(deviceId);
      final serial = device?.serialNumber?.trim() ?? '';

      return _ResolvedIntenseClaim(
        ownerId: owner.id,
        deviceId: deviceId,
        deviceOwnerId: deviceOwner.id,
        serialNumber: serial.isEmpty ? null : serial,
      );
    }
    return null;
  }

  Future<void> _hydrateSyncFromOwnerDevice({
    required String syncOwnerUid,
    required String playerId,
    required Owner owner,
    required String deviceId,
    required String serialNumber,
    required String initiatedBy,
    String? coachUid,
  }) async {
    final deviceOwners = await _deviceOwners.listByOwnerId(owner.id);
    String? deviceOwnerId;
    for (final row in deviceOwners) {
      if (row.deviceId.trim() == deviceId.trim()) {
        deviceOwnerId = row.id;
        break;
      }
    }
    deviceOwnerId ??= deviceOwners.isNotEmpty ? deviceOwners.first.id : null;

    await _syncRepository.saveConfig(
      uid: syncOwnerUid,
      playerId: playerId,
      config: IntenseGpsSyncConfig(
        connected: true,
        connectedAt: DateTime.now(),
        serialNumber: serialNumber,
        deviceId: deviceId,
        ownerId: owner.id,
        deviceOwnerId: deviceOwnerId,
        initiatedBy: initiatedBy,
        coachUid: coachUid,
      ),
    );
  }
}

class _ResolvedIntenseClaim {
  const _ResolvedIntenseClaim({
    required this.ownerId,
    required this.deviceId,
    required this.deviceOwnerId,
    this.serialNumber,
  });

  final String ownerId;
  final String deviceId;
  final String deviceOwnerId;
  final String? serialNumber;
}
