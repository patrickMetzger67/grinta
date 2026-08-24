# Push notifications (FCM)

Grinta delivers phone/web pushes in two ways (`europe-west1`):

1. **Firestore trigger** `sendPushOnNotificationCreated` — fires when a document
   is created in `notification`. This is the reliable path: if the cloche
   document exists, the OS/web push is sent (sensor sync, convocations, events).
2. **Callable** `sendPushFCMNotification` — used by the Flutter client as a
   fallback (chat, member added to team, and older app builds).

## Why a notification doc is not enough by itself

The in-app cloche writes `notification/{id}`. Until the trigger is deployed,
push is a *separate* client call. That call was skipped when:

- the coach device could not read `users/{playerUid}/fcmTokens`
- quiet hours (default 22:00–07:00) deferred **all** types, including
  post-sync « Comment te sens-tu ? »
- `remindersEnabled === false` (the settings toggle is for *local* agenda
  reminders only)

The trigger + transactional-type exception fix that.

## Contract (callable)

```json
{
  "fcmTokens": ["…"],
  "recipientUserIds": ["firebaseAuthUid…"],
  "clubId": "0",
  "brand": "grinta",
  "icon": "https://grinta.web.app/icons/Icon-192.png",
  "image": "https://grinta.web.app/icons/Icon-512.png",
  "title": "…",
  "body": "…",
  "type": "convocation",
  "payload": { "id": "…", "type": "convocation" }
}
```

- **`clubId`**: always `"0"` for the Grinta platform club (required by the CF).
- **`brand`**: always `"grinta"` from the Flutter client — forces Grinta icons
  (never Aserstein `/favicon.png`).
- **`recipientUserIds`**: Auth uids. The CF loads `users/{uid}/fcmTokens` when
  `fcmTokens` is empty.
- **Reminder prefs** (`users/{uid}/app_state/notification_preferences`) apply
  only to `trainingReminder`, `matchOpponentStatsReminder`, `RPEBefore`:
  - `remindersEnabled === false` → **skip** (no queue)
  - quiet days / quiet hours → **enqueue** `pending_push` until `sendAfter`
    (drained by `drainPendingPushNotifications` every 5 minutes; max defer 48h)
- Transactional types (`RPEAfter`, `convocation`, `event`, `chat`, `teamDetail`,
  …) are sent immediately.
- Tokens live in `users/{uid}/fcmTokens/{token}` with `app: "grinta"`.

The trigger writes `pushDispatch` on the `notification` document
(`sending` / `sent` / `skipped` / `deferred` / `failed`). Local agenda
reminders (`trainingReminder`, `matchOpponentStatsReminder`, `RPEBefore`)
are skipped — they stay on `InternalReminderService` + the OS scheduler.

## Deploy

```bash
firebase deploy --only functions:sendPushFCMNotification,functions:drainPendingPushNotifications,functions:sendPushOnNotificationCreated,firestore:rules,firestore:indexes
```

Source: [`functions/send_push_fcm.js`](../functions/send_push_fcm.js),
[`functions/pending_push.js`](../functions/pending_push.js),
[`functions/notify_on_create.js`](../functions/notify_on_create.js).

## Client checklist

| Platform | Requirement |
|----------|-------------|
| **iOS** | Push capability (`aps-environment`), `UIBackgroundModes` → `remote-notification`, APNs key in Firebase Console |
| **Android** | `POST_NOTIFICATIONS`, `google-services.json` for `io.grinta.app` |
| **Web** | Build with `--dart-define=FCM_WEB_VAPID_KEY=…` (Firebase → Cloud Messaging → Web Push certificates) |

## Triggers (app)

- Feeling post-sync, convocations, non-sport events → write `notification`
  then (fallback) `NotificationFCMService.postNotification`.
- Chat / member added to team → callable only (no `notification` doc).
