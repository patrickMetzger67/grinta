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

After OAuth, the Cloud Function stores tokens server-side, registers the user with AccessLink, and redirects:

- **Mobile:** `grinta://polar/callback`
- **Web:** back to the app origin with `?polarOAuth=1&success=1&playerId=...`

Ensure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) declare the `grinta` URL scheme with host `polar` (added in Phase 1).

## 3. Webhook URL (Phase 2 placeholder)

Polar AccessLink webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/polarWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets (required — not `dart_defines.json`)

Polar OAuth runs in **Cloud Functions**. Credentials must be stored as
Firebase secrets, **not** in `dart_defines.json`.

From the project root, either:

```bash
./scripts/set_polar_firebase_secrets.sh
```

or manually:

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
2. Open **Settings** → **Appareils/Applications** (Devices/Applications) — badge shows the connected count.
3. Tap **+**, select **Polar** in the type dropdown.
4. Enter the **Polar Flow account** (email) — it may differ from the Grinta email — then tap **Continue to Polar**.
5. Complete Polar OAuth in the browser with that Polar Flow account.
6. App returns via `grinta://polar/callback` (mobile) or the same web tab — you should see a success snackbar; the dialog returns to the connections list.
7. Toggle **Coach visibility** per data type (training, sleep, recovery/HR, profile, body).
8. Tap **Disconnect** on the Polar row (or via the type dropdown) to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Tap **+**, select **Polar**, enter the player's Polar Flow account, then complete OAuth with that account.

> **Web:** OAuth opens in the **same browser tab** and returns to the app origin.
> **Player profiles:** Polar sync metadata is stored under the **signed-in**
> Firebase uid (`users/{authUid}/polarSync/{playerId}`) so the settings badge
> updates immediately.

## Firestore layout

**Server-only tokens**

```
polar_integrations/{uid}_{playerId}
  uid, playerId, polarUserId, memberId, polarAccountHint?, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/polarSync/{playerId}
  connected, connectedAt, lastSyncedAt?, polarUserId?, memberId?, polarAccountHint?, initiatedBy, coachVisibility
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
