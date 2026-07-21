# Strava integration (Phase 1)

Phase 1 delivers OAuth connect/disconnect scaffolding alongside Whoop. Activity sync, webhooks, and polling are planned for Phase 2.

See also: [Whoop integration](./whoop-integration.md), [Polar integration](./polar-integration.md), and [Fitbit integration](./fitbit-integration.md) for the shared wearable devices UI (`Appareils/Applications` / `Devices/Applications`).

## 1. Create a Strava API application

1. Open [Strava API settings](https://www.strava.com/settings/api).
2. Create an application for Grinta.
3. Request these scopes (Phase 1):
   - `read`
   - `activity:read_all`

Optional later: `profile:read_all` for richer profile data.

## 2. Redirect URI (required)

Register this **HTTPS** redirect URI in the Strava application settings:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/stravaOAuthCallback
```

After OAuth, the Cloud Function stores tokens server-side and redirects the user back to the mobile app:

```
grinta://strava/callback
```

Ensure Android (`AndroidManifest.xml`) declares the `grinta://strava/callback` intent filter (added in Phase 1). iOS uses the existing `grinta` URL scheme.

## 3. Webhook URL (Phase 2 placeholder)

Strava activity webhooks are not consumed yet. Reserve this URL for Phase 2:

```
https://europe-west1-aserstein-2453e.cloudfunctions.net/stravaWebhook
```

(Not deployed in Phase 1.)

## 4. Firebase secrets

From the project root:

```bash
firebase functions:secrets:set STRAVA_CLIENT_ID
firebase functions:secrets:set STRAVA_CLIENT_SECRET
```

Use the Client ID and Client Secret from the Strava API application page.

## 5. Deploy Cloud Functions & Firestore rules

```bash
cd functions && npm install && cd ..
firebase deploy --only functions:stravaOAuthStart,functions:stravaOAuthCallback,functions:stravaDisconnect
firebase deploy --only firestore:rules
```

To deploy Whoop and Strava together:

```bash
firebase deploy --only functions:whoopOAuthStart,functions:whoopOAuthCallback,functions:whoopDisconnect,functions:stravaOAuthStart,functions:stravaOAuthCallback,functions:stravaDisconnect
```

## 6. Test connect / disconnect

### Player flow

1. Sign in to Grinta and select a player profile.
2. Open **Settings** → **Devices/Applications** (badge shows the connected count).
3. The dialog lists existing connections. Tap the **+** FAB to add one.
4. Select **Strava** in the **Device/application type** dropdown.
5. Enter the **Strava account** (email or username) — it may differ from the Grinta email — then tap **Continue to Strava**.
6. Complete Strava OAuth in the browser with that Strava account.
7. App returns via `grinta://strava/callback` — you should see a success snackbar; the dialog returns to the connections list.
8. Toggle **Coach visibility** for activities and profile under the Strava row.
9. Tap **Disconnect** on the Strava row to disconnect.

### Coach flow

1. Sign in as a coach with roster management rights.
2. Open a team → player **Trackers** sheet.
3. Tap **Devices/Applications** for a player.
4. Tap **+**, select **Strava**, enter the player's Strava account, then complete OAuth with that account.

## Firestore layout

**Server-only tokens**

```
strava_integrations/{uid}_{playerId}
  uid, playerId, stravaAthleteId, status, scopes, tokens, initiatedBy, coachUid?
```

**Client-readable connection**

```
users/{uid}/stravaSync/{playerId}
  connected, connectedAt, lastSyncedAt?, stravaAthleteId?, initiatedBy, coachVisibility
    coachVisibility.activities  (default: false)
    coachVisibility.profile     (default: false)
```

Tokens are never written to client-readable documents.

## Phase 2 TODO

- Strava webhooks (`stravaWebhook` HTTP function)
- Scheduled token refresh
- Activity sync into Grinta training/workout data
- Coach roster badges when a player shares activities
