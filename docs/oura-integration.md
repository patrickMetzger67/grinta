# Oura integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect plus **manual import of Oura workouts** into personal sport activities, with **duration** and **heart-rate zones** (same UX as Whoop / Polar / Strava).

> **Related:** Whoop, Strava, Polar, and Fitbit use the same **Appareils/Applications** settings UI. See [Whoop integration](./whoop-integration.md), [Strava integration](./strava-integration.md), [Polar integration](./polar-integration.md), and [Fitbit integration](./fitbit-integration.md).

## 1. Create an Oura API application

1. Open [Oura Cloud → My Applications](https://cloud.ouraring.com/oauth/applications).
2. Create an app for Grinta (display name, website, privacy policy, terms).
3. Enable at least these scopes:
   - `email`
   - `personal`
   - `daily`
   - `heartrate`
   - `workout`

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Oura app settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/ouraOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side and redirects:

- **Mobile:** `grinta://oura/callback`
- **Web:** back to the app origin with `?ouraOAuth=1&success=1&playerId=...`

Do **not** register the mobile deep link as the Oura redirect URI.

## 3. Firebase secrets (required — not `dart_defines.json`)

```bash
./scripts/set_oura_firebase_secrets.sh
```

or:

```bash
firebase functions:secrets:set OURA_CLIENT_ID
firebase functions:secrets:set OURA_CLIENT_SECRET
```

## 4. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only functions:ouraOAuthStart,functions:ouraOAuthCallback,functions:ouraDisconnect,functions:ouraRepairPlayerSync,functions:ouraListActivities,functions:ouraImportActivity
firebase deploy --only firestore:rules
```

## 5. Test connect / import

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Appareils/Applications**.
3. Tap **+**, select **Oura**, enter the Oura account email, then **Continue to Oura**.
4. Complete Oura OAuth in the browser.
5. App returns via `grinta://oura/callback` (or web query) with a success snackbar.
6. **Créer** → activité personnelle → import → choose an Oura workout → import.
7. Open the activity: duration, avg/max HR, and zone chart (`hrZoneSeconds` z0…z5).

## Firestore layout

**Server-only tokens**

```
oura_integrations/{uid}_{playerId}
oura_oauth_pending/{state}
```

**Client-readable sync (no tokens)**

```
users/{uid}/ouraSync/{playerId}
```

**Imported activities**

```
personalSportActivities/{id}
  externalSource: 'oura'
  externalId: <Oura workout id>
  durationSeconds, averageHeartRateBpm, maxHeartRateBpm
  hrZoneSeconds: { z0…z5 → seconds }
  hrMaxUsedBpm?
```

## How HR zones are computed

Oura workout documents expose duration (or start/end). Detailed zone breakdown is derived on import:

1. `GET /v2/usercollection/workout/{id}`
2. `GET /v2/usercollection/heart_rate?start_datetime&end_datetime` (prefer `source=workout` samples)
3. Bucket BPM samples into Grinta zones (same %-of-HRmax bands as Whoop; HRmax ≈ `220 − age` from `personal_info` when available)

## What is not in this phase

- Continuous sleep / readiness sync
- Webhooks
- Coach roster badges driven by Oura recovery
