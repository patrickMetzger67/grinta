# Polar team kit (GPS tracker model)

Grinta supports **two Polar modes**. They must not share storage.

| Mode | Product | Storage | Master data |
|------|---------|---------|-------------|
| **Individual** | Polar Flow + AccessLink | `users/{uid}/polarSync/{playerId}` + `polar_integrations` | Player Polar account (OAuth) |
| **Team kit** | Polar BLE sensors (H10, Verity Sense, …) | `TRACKER_*` (same as Inspirit / Intense / Footbar) | **Grinta** org / teams / roster |

See also [Polar AccessLink (individual)](./polar-integration.md).

## Team kit data model

Same graph as other GPS kits:

```
TRACKER_Owner          typeTracker: "polar", withSyncing: true
        │
TRACKER_DeviceOwner    customName = jersey / label
        │              deviceId = Polar BLE device id
TRACKER_Device         provider: "polar", id = Polar device id
        │
Team.owners[]          kit linked to one or more teams
GrintaPlayer.trackers  DeviceOwner doc ids
Training / Match       withTracker + ownerId
PlayerTraining.deviceId / PlayerCompo.deviceOwnerId
```

### Admin setup

1. **Admin → Tracker owners** → create owner with type **Polar (BLE team kit)**.
2. **Admin → Tracker devices** → **Add Polar** (device id printed on the sensor).
3. Assign device → owner (optional custom name / jersey).
4. Coach (Pro) links the owner on the team via the existing tracker-owners sheet.
5. Coach assigns devices to players (`GrintaPlayer.trackers`) like other kits.

One Polar kit owner can be linked to **several Grinta teams** (shared inventory).

### Device id

`TRACKER_Device.id` = Polar BLE device id (same string used later by Polar BLE SDK `connectToDevice`).

Supported types in the admin UI: H10, H9, Verity Sense, OH1, Other.

## What is not in this phase

- Live BLE scan / multi-sensor HR streaming (`PolarBleSessionService` stub only)
- Polar Team Pro API / Polar Pro GPS sensors (different product, read-only API)
- Writing org/teams into Polar (AccessLink & Team Pro APIs do not support Grinta→Polar writes)

## Next phase (BLE live)

1. Add Polar BLE SDK (Flutter `polar` package or native wrappers).
2. Permissions: Android Bluetooth + iOS `NSBluetoothAlwaysUsageDescription`.
3. Coach session UI: connect assigned devices → stream HR → write `TRACKER_Analysis`.
4. Reuse `isPolarTrackerOwner` / `ownerUsesPolarTeamKit` for agenda eligibility.
