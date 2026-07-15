# Fitbit integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect scaffolding for Fitbit bracelets (Charge, Versa, Sense, Pixel Watch with Fitbit, etc.) via the **Fitbit Web API** (Fitbit cloud sync). Data sync, webhooks, and coach roster badges are planned for Phase 2.

> **Related:** Whoop, Strava, and Polar use the same **Appareils/Applications** settings UI. Apple Health / Apple Forme is **iOS-only** (HealthKit, no OAuth). See [Whoop integration](./whoop-integration.md), [Strava integration](./strava-integration.md), [Polar integration](./polar-integration.md), and [Apple Health integration](./apple-health-integration.md).

## Fitbit cloud vs Google Health Connect

| Approach | What it is | Phase 1? |
|----------|------------|----------|
| **Fitbit Web API** (`dev.fitbit.com`) | OAuth 2.0 + PKCE; devices sync to Fitbit cloud; cross-platform (iOS, Android, web) | **Yes** — this doc |
| **Google Health Connect** | Android-only on-device API; reads local health data; no OAuth cloud sync | **No** — future Android-only option |

Fitbit/Google bracelets (Pixel Watch, Charge, Versa, etc.) pair with the **Fitbit app** and upload data to **Fitbit cloud**. Grinta reads that data through the Fitbit Web API after OAuth — the same pattern as Whoop, Strava, and Polar.

**Google Health Connect** is a separate Android API for reading on-device health records. It does **not** replace the Fitbit Web API for a cross-platform Grinta integration. Health Connect may be explored later as an Android-only supplement for users who store Fitbit-exported data locally, but Phase 1 uses Fitbit OAuth only.

## Devices supported (Phase 1)

Fitbit bracelets do not connect directly to Grinta in Phase 1. The athlete pairs the device with the **Fitbit app**, and Grinta reads data through the **Fitbit Web API** after OAuth.

Supported scopes (Phase 1): `activity`, `heartrate`, `sleep`, `profile`, `weight`.

## 1. Create a Fitbit developer application

1. Sign in at [dev.fitbit.com](https://dev.fitbit.com/) and open [Register an app](https://dev.fitbit.com/apps/new).
2. Create an application for Grinta (OAuth 2.0 Application Type).
3. Enable PKCE (recommended/required for server-side callback flow).
4. Request scopes: **Activity**, **Heart Rate**, **Sleep**, **Profile**, **Weight**.

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Fitbit app settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/fitbitOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side and redirects back to the mobile app:

```
grinta://fitbit/callback
```

Ensure Android (`AndroidManifest.xml`) declares the `grinta` URL scheme with host `fitbit` (added in Phase 1). iOS uses the generic `grinta` URL scheme in `Info.plist`.

## 3. Firebase secrets

From the project root:

```bash
firebase functions:secrets:set FITBIT_CLIENT_ID
firebase functions:secrets:set FITBIT_CLIENT_SECRET
```

Use the OAuth 2.0 Client ID and Client Secret from the Fitbit developer portal.

## 4. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only functions:fitbitOAuthStart,functions:fitbitOAuthCallback,functions:fitbitDisconnect
firebase deploy --only firestore:rules
```

## 5. Test connect / disconnect

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Appareils/Applications** (Devices/Applications).
3. Select **Fitbit** in the dropdown and tap **Sync**.
4. Complete Fitbit OAuth in the browser (Fitbit account).
5. App returns via `grinta://fitbit/callback` — you should see a success snackbar.
6. Toggle **Coach visibility** per data type (activity, heart rate, sleep, profile, body/weight).
7. Tap **Disconnect** on the Fitbit row to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Appareils/Applications** for a player.
4. Select **Fitbit** and complete OAuth with the player’s Fitbit account.

## Firestore layout

**Server-only tokens**

```
fitbit_integrations/{uid}_{playerId}
  uid, playerId, fitbitUserId, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/fitbitSync/{playerId}
  connected, connectedAt, lastSyncedAt?, fitbitUserId?, initiatedBy, coachVisibility
```

**Coach visibility fields** (`coachVisibility` map):

| Key | Description |
|-----|-------------|
| `activity` | Workouts, steps, and daily activity |
| `heartrate` | Resting and intraday heart rate |
| `sleep` | Sleep logs and stages |
| `profile` | User profile |
| `body` | Weight and body measurements |

Tokens are never written to client-readable documents.

## Phase 2 TODO

- Fitbit subscription webhooks for activity/sleep/HR updates
- Token refresh (Fitbit access tokens expire after ~8 hours)
- Activity, sleep, and HR data sync into Grinta
- Coach roster badges when a player shares metrics
- Optional: Android **Health Connect** read path (separate from Fitbit OAuth)
