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
   - **iOS / Android:** **Scanner les capteurs Polar** (liste BLE → Connecter → Ajouter au kit → owner + customName).
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

### Mobile BLE (iOS / Android)

- Package Flutter `polar` (Polar BLE SDK).
- Écran admin : scan → liste des Polar → **Connecter** → **Ajouter au kit** → owner + `customName`.
- Permissions : Bluetooth (Android 12+ `BLUETOOTH_SCAN` / `CONNECT`, iOS `NSBluetoothAlwaysUsageDescription`).
- `minSdk` Android = 24.

## End-of-session import (no live)

Polar kits use `withSyncing: true` like Inspirit: coach imports **after** the
session over BLE (Chrome or mobile). Data is **cardio**, not pitch GPS.

### Collections

| GPS kit | Polar kit |
|---------|-----------|
| `TRACKER_Analysis/{eventId}_{trackerId}` | `TRACKER_PolarAnalysis/{eventId}_{trackerId}` |
| GNSS distance / speed / heatmap | HR / duration / calories (Loop) |
| `TRACKER_Sync.devices.*.withAsiFile` | `TRACKER_Sync.devices.*.polarImported` |

`trackerId` = `TRACKER_DeviceOwner` doc id (same as `PlayerTraining.deviceId`).

### `TRACKER_PolarAnalysis` fields

```
eventId, playerId, trackerId, polarDeviceId, deviceType
provider: "polar"
kind: "cardio"
durationMs, startedAt?, endedAt?
avgHrBpm?, maxHrBpm?, minHrBpm?, hrSamplesCount
hrZoneSeconds: { z1…z5 → seconds }
caloriesKcal?, distanceMeters?, steps?   // Loop extras; usually null on Verity
importChannel: "ble_mobile" | "ble_chrome" | "manual"
importedAt, importedUid?, sourceFirmware?
createdAt, updatedAt
```

Code: `lib/model/tracker/polar_session_analysis.dart` +
`PolarSessionAnalysisService`.

### Device coverage (phase 1)

| Field | Verity Sense | Loop |
|-------|--------------|------|
| duration / FC avg-max-min | Oui | Oui |
| hrZoneSeconds | Oui (dérivé) | Oui (dérivé) |
| calories / steps / distance lifestyle | Rare | Oui si dispo |
| GPS pitch / sprints / heatmap | Non | Non |

### Sync state

On `TRACKER_Sync/{eventId}.devices.{deviceId}`:

- `polarImported`, `polarImportedAt`, `polarImportedUid`
- `DeviceSync.isSynced` is true when `polarImported` (or USB/ASI paths)

## End-of-session import UI

After **Finish training** on a Polar kit session, Grinta opens
`PolarImportHubPage` immediately (required on mobile — Sync tab is web-only).

Also available:
- Agenda → **Importer les données Polar** while `isTrackerDataUploaded == false`
- Web Sync tab → **Upload** on a Polar-owned training/match

`trackerId` keys = `TRACKER_DeviceOwner` doc ids (not jersey customName).

| Channel | Behaviour |
|---------|-----------|
| **iOS / Android** | Connect (listen before connect) → wait connected / `fileTransfer` (or settle if iOS Verity omits it) → `listExercises` → pick nearest to event time → `fetchExercise` → HR stats → `TRACKER_PolarAnalysis`. Verity Sense must be in **sensor mode** (blue LED); quit Polar Flow first. |
| **Web / Chrome** | Manual cardio entry (duration + HR; Loop extras optional). Full offline pull needs Polar SDK (mobile). |
| **Fallback** | Manual entry on all platforms |

Orchestration: `PolarSessionImportService` → `PolarSessionAnalysisService.saveAnalysis`
+ `EventSyncService.markPolarImported`.

HR zones (absolute BPM when no HRmax): z1&lt;120 · z2 120–139 · z3 140–159 ·
z4 160–179 · z5 ≥180. Optional % of HRmax (60/70/80/90).

## What is not in this phase

- Live multi-sensor HR during the session
- Chrome Web Bluetooth offline exercise pull (proprietary Polar file transfer)
- Polar Team Pro API / Polar Pro GPS sensors
- Writing org/teams into Polar
- Cardio charts beside GPS analysis UI (next)

## Analysis UI (cardio replaces GPS)

When the event owner is Polar (`typeTracker == polar`), analysis entry points
use cardio UI instead of GPS:

| Host | Polar | GPS |
|------|-------|-----|
| `SessionTrackerStatsView` | `MatchPolarStatsTable` | `MatchTrackerStatsTable` |
| `SessionPlayerAnalysisView` | `PolarPlayerAnalysisWidget` | `TrackerPlayerAnalysisWidget` |

Wired from match stats tab, agenda tracker sheets, and metrics panel.

Polar player view: synthesis (duration, avg/max/min HR, samples, Loop extras)
+ HR zones (z1–z5). No heatmap / pitch GPS tabs.

## Next phase

1. Agenda activity rings for Polar (today rings still depend on GPS `TRACKER_TeamAnalysis`; agenda already exposes **Voir l'analyse Polar** once `TRACKER_PolarAnalysis` exists).
2. Optional: Chrome HR stream snapshot if product needs a web-native path.
