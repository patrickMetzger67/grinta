# Whoop integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect scaffolding. Data sync, webhooks, and coach roster badges are planned for Phase 2.

> **Related:** Strava, Polar, and Fitbit use the same **Appareils/Applications** settings UI. See [Strava integration](./strava-integration.md), [Polar integration](./polar-integration.md), and [Fitbit integration](./fitbit-integration.md).

## 1. Create a Whoop developer app

1. Open [Whoop Developer Dashboard](https://developer-dashboard.whoop.com/apps/create).
2. Create an app for Grinta (production API: `api.prod.whoop.com`).
3. Enable these scopes:
   - `offline`
   - `read:recovery`
   - `read:cycles`
   - `read:sleep`
   - `read:workout`
   - `read:profile`
   - `read:body_measurement`

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Whoop app settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/whoopOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side and redirects:

- **Mobile:** `grinta://whoop/callback`
- **Web:** back to the app origin with `?whoopOAuth=1&success=1&playerId=...`

Ensure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) already declare the `grinta` URL scheme (added in Phase 1).

## 3. Webhook URL (Phase 2 placeholder)

Whoop webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/whoopWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets (required — not `dart_defines.json`)

Whoop OAuth runs in **Cloud Functions**. Credentials must be stored as
Firebase secrets, **not** in `dart_defines.json`.

From the project root, either:

```bash
./scripts/set_whoop_firebase_secrets.sh
```

or manually:

```bash
firebase functions:secrets:set WHOOP_CLIENT_ID
firebase functions:secrets:set WHOOP_CLIENT_SECRET
```

Use the Client ID and Client Secret from the Whoop developer dashboard.

## 5. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only functions:whoopOAuthStart,functions:whoopOAuthCallback,functions:whoopDisconnect
firebase deploy --only firestore:rules
```

## 6. Test connect / disconnect

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Appareils/Applications** (Devices/Applications) — badge shows the connected count.
3. Tap **+**, select **Whoop** in the type dropdown.
4. Enter the **Whoop account** (email) — it may differ from the Grinta email — then tap **Continue to Whoop**.
5. Complete Whoop OAuth in the browser with that Whoop account.
6. App returns via `grinta://whoop/callback` — you should see a success snackbar; the dialog returns to the connections list.
7. Toggle **Coach visibility** per data type (recovery, cycles, sleep, workout, profile, body measurements).
8. Tap **Disconnect** on the Whoop row to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Tap **+**, select **Whoop**, enter the player's Whoop account, then complete OAuth with that account.

## Firestore layout

**Server-only tokens**

```
whoop_integrations/{uid}_{playerId}
  uid, playerId, whoopUserId, whoopAccountHint?, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/whoopSync/{playerId}
  connected, connectedAt, lastSyncedAt?, whoopUserId?, whoopAccountHint?, initiatedBy, coachVisibility
```

Tokens are never written to client-readable documents.

## Phase 2 TODO

- Whoop webhooks (`whoopWebhook` HTTP function)
- Scheduled token refresh (rotating refresh tokens)
- Workout / recovery / sleep data sync into Grinta
- Coach roster badges when a player shares metrics
