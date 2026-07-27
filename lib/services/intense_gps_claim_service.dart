import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/intense_gps_sync_config.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/deviceService.dart';
import 'package:grinta/services/intense_gps_sync_repository.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
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
    PersonalGpsSyncService? personalGpsSyncService,
    FirebaseFirestore? firestore,
  })  : _devices = deviceService ?? DeviceService(),
        _owners = ownerService ?? OwnerService(),
        _deviceOwners = deviceOwnerService ?? DeviceOwnerService(),
        _syncRepository = syncRepository ?? IntenseGpsSyncRepository(),
        _players = playerService ?? PlayerService(),
        _personalGps = personalGpsSyncService ?? PersonalGpsSyncService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  static final IntenseGpsClaimService instance = IntenseGpsClaimService();

  final DeviceService _devices;
  final OwnerService _owners;
  final DeviceOwnerService _deviceOwners;
  final IntenseGpsSyncRepository _syncRepository;
  final PlayerService _players;
  final PersonalGpsSyncService _personalGps;
  final FirebaseFirestore _firestore;

  /// Same uid convention as [WearableDevicesDialogContent] / settings badge:
  /// player → auth uid; coach → member owner uid.
  String _syncOwnerUid({
    required String callerUid,
    required Player? player,
    required String initiatedBy,
  }) {
    if (initiatedBy == 'coach') {
      return resolveWearableSyncOwnerUid(callerUid: callerUid, player: player);
    }
    return callerUid;
  }

  /// Hydrates `users/{uid}/intenseGpsSync/{playerId}` from an existing
  /// individual GPS `TRACKER_Owner` (same resolution as personal GPS sync).
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

      final syncOwnerUid = _syncOwnerUid(
        callerUid: uid,
        player: player,
        initiatedBy: initiatedBy,
      );

      final existing =
          await _syncRepository.getConfig(syncOwnerUid, trimmedPlayerId);
      if (existing?.connected == true) return false;

      final resolved = await _resolveExistingIndividualIntense(
        player: player,
        authEmail: FirebaseAuth.instance.currentUser?.email,
      );
      if (resolved == null) {
        debugPrint(
          '[IntenseGpsClaim] repair: no individual GPS owner for '
          'player=$trimmedPlayerId email=${player.email}',
        );
        return false;
      }

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
      debugPrint(
        '[IntenseGpsClaim] repair hydrated → uid=$syncOwnerUid '
        'owner=${resolved.ownerId} device=${resolved.deviceId} '
        'serial=${resolved.serialNumber}',
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

    final syncOwnerUid = _syncOwnerUid(
      callerUid: uid,
      player: player,
      initiatedBy: initiatedBy,
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
        final ownerEmail = currentOwner?.email.trim().toLowerCase() ?? '';
        if (currentOwner != null &&
            _isClaimableIndividualOwner(currentOwner) &&
            ownerEmail == email.toLowerCase()) {
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
    // Prefer player path (auth uid). Also clear coach-path doc if present.
    final playerSyncUid = _syncOwnerUid(
      callerUid: uid,
      player: player,
      initiatedBy: 'player',
    );
    final coachSyncUid = _syncOwnerUid(
      callerUid: uid,
      player: player,
      initiatedBy: 'coach',
    );

    try {
      var config =
          await _syncRepository.getConfig(playerSyncUid, playerId.trim());
      var syncUid = playerSyncUid;
      if (config?.connected != true && coachSyncUid != playerSyncUid) {
        config = await _syncRepository.getConfig(coachSyncUid, playerId.trim());
        syncUid = coachSyncUid;
      }

      if (config == null || config.connected != true) {
        await _syncRepository.clearConfig(
          uid: playerSyncUid,
          playerId: playerId.trim(),
        );
        if (coachSyncUid != playerSyncUid) {
          await _syncRepository.clearConfig(
            uid: coachSyncUid,
            playerId: playerId.trim(),
          );
        }
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
        try {
          await _firestore
              .collection(DeviceService.collectionName)
              .doc(deviceId)
              .update(<String, dynamic>{
            'ownerId': '',
            'updatedAt': Timestamp.now(),
          });
        } catch (e) {
          // Legacy DeviceOwner.deviceId may be an Insiders numeric id, not a
          // TRACKER_Device doc id — ignore missing docs.
          debugPrint('[IntenseGpsClaim] clear device ownerId skipped: $e');
        }
      }

      if (ownerId.isNotEmpty) {
        final owner = await _owners.getOwnerById(ownerId);
        if (owner != null && _isClaimableIndividualOwner(owner)) {
          await _owners.deleteOwner(ownerId);
        }
      }

      await _syncRepository.clearConfig(
        uid: syncUid,
        playerId: playerId.trim(),
      );
      if (syncUid != playerSyncUid) {
        await _syncRepository.clearConfig(
          uid: playerSyncUid,
          playerId: playerId.trim(),
        );
      }
      if (syncUid != coachSyncUid && coachSyncUid != playerSyncUid) {
        await _syncRepository.clearConfig(
          uid: coachSyncUid,
          playerId: playerId.trim(),
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('[IntenseGpsClaim] disconnect failed: $e\n$st');
      return false;
    }
  }

  /// Same rules as [PersonalGpsSyncService]: active individual, cloud GPS.
  bool _isClaimableIndividualOwner(Owner owner) {
    if (!owner.isActive || !owner.isIndividual) return false;
    final type = owner.typeTracker.trim().toLowerCase();
    if (type == TrackerOwner.typePolar) return false;
    return !owner.withSyncing;
  }

  List<String> _emailsForPlayer(Player player, String? authEmail) {
    final emails = <String>[];
    final seen = <String>{};
    void add(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      if (seen.add(trimmed.toLowerCase())) emails.add(trimmed);
    }

    add(player.email);
    add(authEmail);
    add(player.email?.toLowerCase());
    add(authEmail?.toLowerCase());
    return emails;
  }

  Future<_ResolvedIntenseClaim?> _resolveExistingIndividualIntense({
    required Player player,
    String? authEmail,
  }) async {
    // 1) Same path as activité personnelle / session GPS.
    for (final email in _emailsForPlayer(player, authEmail)) {
      final availability = await _personalGps.resolveForEmail(email);
      if (availability == null || availability.devices.isEmpty) continue;

      final option = availability.devices.first;
      final owner = availability.owner;
      final deviceOwner = option.deviceOwner;

      // Prefer TRACKER_Device rows for serial display.
      final ownedDevices = await _devices.getDevicesByOwnerId(owner.id);
      final matchingDevice = ownedDevices.where((d) {
        final serial = d.serialNumber?.trim() ?? '';
        return d.id == deviceOwner.deviceId ||
            (serial.isNotEmpty && serial == deviceOwner.deviceId.trim());
      }).firstOrNull ??
          (ownedDevices.isNotEmpty ? ownedDevices.first : null);

      final serial = matchingDevice?.serialNumber?.trim();
      final label = option.label.trim();

      return _ResolvedIntenseClaim(
        ownerId: owner.id,
        deviceId: matchingDevice?.id ?? deviceOwner.deviceId,
        deviceOwnerId: deviceOwner.id,
        serialNumber: (serial != null && serial.isNotEmpty)
            ? serial
            : (label.isEmpty ? null : label),
      );
    }

    // 2) Fallback: individual owner without resolvable Insiders id, but with
    // DeviceOwner / Device rows (admin-linked sensors).
    for (final email in _emailsForPlayer(player, authEmail)) {
      final owners = await _personalGps.resolveIndividualOwnersForEmail(email);
      for (final owner in owners.where(_isClaimableIndividualOwner)) {
        final deviceOwners = await _deviceOwners.listByOwnerId(owner.id);
        final ownedDevices = await _devices.getDevicesByOwnerId(owner.id);

        if (deviceOwners.isEmpty && ownedDevices.isEmpty) continue;

        deviceOwners.sort((a, b) => b.affectedAt.compareTo(a.affectedAt));
        final deviceOwner = deviceOwners.isNotEmpty ? deviceOwners.first : null;
        final device = ownedDevices.isNotEmpty
            ? ownedDevices.first
            : (deviceOwner != null
                ? await _devices.getDeviceById(deviceOwner.deviceId)
                : null);

        final serial = device?.serialNumber?.trim();
        final label = deviceOwner?.customName?.trim() ??
            device?.customName?.trim() ??
            device?.deviceName?.trim() ??
            '';

        return _ResolvedIntenseClaim(
          ownerId: owner.id,
          deviceId: device?.id ?? deviceOwner?.deviceId ?? '',
          deviceOwnerId: deviceOwner?.id ?? '',
          serialNumber: (serial != null && serial.isNotEmpty)
              ? serial
              : (label.isEmpty ? null : label),
        );
      }
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
