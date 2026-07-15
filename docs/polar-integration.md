# Polar integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect scaffolding for Polar Loop and Verity Sense via Polar AccessLink (Polar Flow cloud sync). Data sync, webhooks, and coach roster badges are planned for Phase 2.

> **Related:** Whoop, Strava, and Fitbit use the same **Appareils/Applications** settings UI. See [Whoop integration](./whoop-integration.md), [Strava integration](./strava-integration.md), and [Fitbit integration](./fitbit-integration.md).

## Devices supported (Phase 1)

Polar Loop and Verity Sense do not connect directly to Grinta in Phase 1. The athlete pairs the device with **Polar Flow**, and Grinta reads data through the **Polar AccessLink API** after OAuth.

## 1. Create a Polar AccessLink application

1. Open the [Polar AccessLink admin portal](https://admin.polaraccesslink.com/).
2. Create an application for Grinta.
3. Request the `accesslink.read_all` scope (training, sleep, heart rate, physical info).

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Polar app settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/polarOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side, registers the user with AccessLink, and redirects back to the mobile app:

```
grinta://polar/callback
```

Ensure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) declare the `grinta` URL scheme with host `polar` (added in Phase 1).

## 3. Webhook URL (Phase 2 placeholder)

Polar AccessLink webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/polarWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets

From the project root:

```bash
firebase functions:secrets:set POLAR_CLIENT_ID
firebase functions:secrets:set POLAR_CLIENT_SECRET
```

Use the Client ID and Client Secret from the Polar AccessLink admin portal.

## 5. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only functions:polarOAuthStart,functions:polarOAuthCallback,functions:polarDisconnect
firebase deploy --only firestore:rules
```

## 6. Test connect / disconnect

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Appareils/Applications** (Devices/Applications).
3. Select **Polar** in the dropdown and tap **Sync**.
4. Complete Polar OAuth in the browser (Polar Flow account).
5. App returns via `grinta://polar/callback` — you should see a success snackbar.
6. Toggle **Coach visibility** per data type (training, sleep, recovery/HR, profile, body).
7. Tap **Disconnect** on the Polar row to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Select **Polar** and complete OAuth with the player’s Polar Flow account.

## Firestore layout

**Server-only tokens**

```
polar_integrations/{uid}_{playerId}
  uid, playerId, polarUserId, memberId, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/polarSync/{playerId}
  connected, connectedAt, lastSyncedAt?, polarUserId?, memberId?, initiatedBy, coachVisibility
```

**Coach visibility fields** (`coachVisibility` map):

| Key | Description |
|-----|-------------|
| `training` | Workouts / exercises (Loop, Verity Sense via Polar Flow) |
| `sleep` | Sleep / nightly recharge |
| `recovery_hr` | Recovery and continuous heart rate |
| `profile` | User profile |
| `body` | Body measurements / physical info |

Tokens are never written to client-readable documents.

## Phase 2 TODO

- Polar AccessLink webhooks (`polarWebhook` HTTP function)
- Token refresh and user deregistration at disconnect
- Exercise, sleep, and HR data sync into Grinta
- Coach roster badges when a player shares metrics
