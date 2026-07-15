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

After OAuth, the Cloud Function stores tokens server-side and redirects the user back to the mobile app:

```
grinta://whoop/callback
```

Ensure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) already declare the `grinta` URL scheme (added in Phase 1).

## 3. Webhook URL (Phase 2 placeholder)

Whoop webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/whoopWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets

From the project root:

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
2. Open **Settings** → **Appareils/Applications** (Devices/Applications).
3. Select **Whoop** in the dropdown and tap **Sync**.
4. Complete Whoop OAuth in the browser.
5. App returns via `grinta://whoop/callback` — you should see a success snackbar.
6. Toggle **Coach visibility** per data type (recovery, cycles, sleep, workout, profile, body measurements).
7. Tap **Disconnect** on the Whoop row to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Select **Whoop** and complete OAuth with the player’s Whoop account.

## Firestore layout

**Server-only tokens**

```
whoop_integrations/{uid}_{playerId}
  uid, playerId, whoopUserId, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/whoopSync/{playerId}
  connected, connectedAt, lastSyncedAt?, whoopUserId?, initiatedBy, coachVisibility
```

Tokens are never written to client-readable documents.

## Phase 2 TODO

- Whoop webhooks (`whoopWebhook` HTTP function)
- Scheduled token refresh (rotating refresh tokens)
- Workout / recovery / sleep data sync into Grinta
- Coach roster badges when a player shares metrics
