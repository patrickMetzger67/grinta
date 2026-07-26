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
2. **Admin → Tracker devices** → **Add Polar**:
   - **Web / Chrome:** **Ajouter via Chrome Bluetooth** (picker → 1 capteur à la fois).
   - **Manuel:** saisir l’ID Polar.
3. Assign device → owner (optional custom name / jersey).
4. Coach (Pro) links the owner on the team via the existing tracker-owners sheet.
5. Coach assigns devices to players (`GrintaPlayer.trackers`) like other kits.

One Polar kit owner can be linked to **several Grinta teams** (shared inventory).

### Device id — où le trouver ?

`TRACKER_Device.id` = **Polar BLE device id** (pas l’id opaque de Chrome).

| Source | Exemple |
|--------|---------|
| Nom BLE annoncé | `Polar H10 1C709B20` → id = **`1C709B20`** |
| Verity Sense | `Polar Sense 8C4CAD2D` → id = **`8C4CAD2D`** |
| Imprimé sur le capteur | Même code hex au dos / sous le boîtier |
| Chrome `BluetoothDevice.id` | **Ne pas utiliser** (id navigateur, par origine) |

Sur le web, Grinta lit l’id dans le **nom BLE** après le picker Chrome. Si le nom n’a pas de suffixe hex, saisie manuelle de l’id imprimé.

Supported types: H10, H9, Verity Sense, OH1, Other.

### Web Bluetooth (Chrome)

- HTTPS ou `localhost`, navigateur Chrome.
- Pas de liste libre de tous les BLE : le **sélecteur Chrome** s’ouvre à chaque ajout.
- Répéter pour chaque capteur du kit.

## What is not in this phase

- Live multi-sensor HR streaming during a session
- Native iOS/Android Polar BLE SDK scan list
- Polar Team Pro API / Polar Pro GPS sensors
- Writing org/teams into Polar

## Next phase (mobile BLE live)

1. Polar BLE SDK (Flutter `polar` or native).
2. Coach session UI: connect assigned devices → stream HR → `TRACKER_Analysis`.
3. Reuse `isPolarTrackerOwner` / `ownerUsesPolarTeamKit`.
