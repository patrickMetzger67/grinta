# Oura Ring integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect plus **manual import of Oura workouts** into personal sport activities (same UX as Whoop / Strava / Polar). Continuous readiness/sleep/activity sync, webhooks, and coach roster badges remain Phase 2.

> **Related:** Whoop, Strava, Polar, and Fitbit use the same **Appareils/Applications** settings UI. See [Whoop integration](./whoop-integration.md), [Strava integration](./strava-integration.md), [Polar integration](./polar-integration.md), and [Fitbit integration](./fitbit-integration.md).
>
> **API docs:** [Oura Cloud API v2](https://cloud.ouraring.com/v2/docs#section/Overview) · [Authentication](https://cloud.ouraring.com/docs/authentication)

## 1. Create an Oura developer app

1. Open [Oura Cloud — My Applications](https://cloud.ouraring.com/oauth/applications).
2. Create an app for Grinta.
3. Enable these scopes:
   - `email`
   - `personal`
   - `daily` (sleep / activity / readiness summaries — Phase 2 sync)
   - `heartrate`
   - `workout`
   - `spo2`

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Oura app settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/ouraOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side and redirects:

- **Mobile:** `grinta://oura/callback`
- **Web:** back to the app origin with `?ouraOAuth=1&success=1&playerId=...`

Ensure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) already declare the `grinta` URL scheme (Android host `oura` is registered in Phase 1).

## 3. Webhook URL (Phase 2 placeholder)

Oura webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/ouraWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets (required — not `dart_defines.json`)

Oura OAuth runs in **Cloud Functions**. Credentials must be stored as
Firebase secrets, **not** in `dart_defines.json`.

From the project root, either:

```bash
./scripts/set_oura_firebase_secrets.sh
```

or manually:

```bash
firebase functions:secrets:set OURA_CLIENT_ID
firebase functions:secrets:set OURA_CLIENT_SECRET
```

Use the Client ID and Client Secret from the Oura developer dashboard.

## 5. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only \
  functions:ouraOAuthStart,functions:ouraOAuthCallback,functions:ouraDisconnect,functions:ouraRepairPlayerSync,functions:ouraListActivities,functions:ouraImportActivity
firebase deploy --only firestore:rules
```

> **Web:** OAuth opens in the **same browser tab** and returns to the app origin.
> **Player profiles:** Oura sync metadata is stored under the **signed-in**
> Firebase uid (`users/{authUid}/ouraSync/{playerId}`) so the settings badge
> updates immediately. Opening Appareils/Applications also runs
> `ouraRepairPlayerSync` to migrate any legacy doc left under `member.userID`.

## 6. Test connect / disconnect

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Appareils/Applications** (Devices/Applications) — badge shows the connected count.
3. Tap **+**, select **Oura** in the type dropdown.
4. Enter the **Oura account** (email) — it may differ from the Grinta email — then tap **Continue to Oura**.
5. Complete Oura OAuth in the browser with that Oura account.
6. App returns via `grinta://oura/callback` — you should see a success snackbar; the dialog returns to the connections list.
7. Toggle **Coach visibility** per data type (readiness, sleep, activity, workout, personal, heartrate, SpO2).
8. Tap **Disconnect** on the Oura row to disconnect (also revokes the token at Oura when possible).

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Tap **+**, select **Oura**, enter the player's Oura account, then complete OAuth with that account.

## Firestore layout

**Server-only tokens**

```
oura_integrations/{uid}_{playerId}
  uid, playerId, ouraUserId, ouraAccountHint?, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/ouraSync/{playerId}
  connected, connectedAt, lastSyncedAt?, ouraUserId?, ouraAccountHint?, initiatedBy, coachVisibility
```

Tokens are never written to client-readable documents.

## Workout import (personal sport activities)

After Oura is connected, **Créer → Une activité sportive personnelle → import** lists Oura workouts not yet imported (`externalSource: oura`).

Oura returns historical workouts via paginated `GET /v2/usercollection/workout` (Phase 1 uses a ~90-day window).

Cloud Functions:

- `ouraListActivities` — list workouts; refresh token if needed (Oura refresh tokens are **single-use** and rotate)
- `ouraImportActivity` — fetch workout detail and write `personalSportActivities`

**Required deploy:**

```bash
firebase deploy --only \
  functions:ouraListActivities,functions:ouraImportActivity
```

Mapped fields: duration (`start_datetime` / `end_datetime`), activity → Grinta `typeId`,
calories (kcal), distance when present, optional average/max HR when provided by the API,
and intensity label.

> Oura’s public workout document does **not** always expose a continuous HR series
> or zone breakdown (unlike Polar AccessLink samples / Whoop zones).

## Phase 2 TODO

- Oura webhooks (`ouraWebhook` HTTP function)
- Scheduled background sync (beyond on-demand import)
- Readiness / sleep / daily activity sync into Grinta
- Coach roster badges when a player shares metrics
