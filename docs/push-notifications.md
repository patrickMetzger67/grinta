# Push notifications (FCM)

Grinta delivers phone/web pushes in two ways (`europe-west1`):

1. **Firestore trigger** `sendPushOnNotificationCreated` — fires when a document
   is created in `notification`. If the user can receive push now, FCM is sent
   immediately (with the Grinta logo). If not, the same document is kept with
   `pushDispatch.sendAfter`.
2. **Callable** `sendPushFCMNotification` — fallback for chat / member-added
   (no `notification` doc). Quiet recipients go to `pending_push`.

## User preferences

Document: `users/{uid}/app_state/notification_preferences`

| Setting | Effect on OS/web push |
|---|---|
| `remindersEnabled === false` | **Skip** (no queue) |
| Quiet day / quiet hours | **Store** the notification with `sendAfter` = next allowed instant (from those settings, timezone included) |
| Allowed window | Send immediately |

`sendAfter` is written on `notification.pushDispatch.sendAfter` (and on
`pending_push.sendAfter` for callable-only sends).

`drainPendingPushNotifications` runs **every hour** (`0 * * * *`,
`Europe/Paris`) and sends every due item.

Local agenda reminders (`trainingReminder`, `matchOpponentStatsReminder`,
`RPEBefore`) stay on `InternalReminderService` + the OS scheduler — the trigger
does not FCM them.

## Logo

Every FCM payload includes the Grinta icons:

- Small / web: `https://grinta.web.app/icons/Icon-192.png`
- Large / Android + web image: `https://grinta.web.app/icons/Icon-512.png`
- Android status-bar: `@drawable/ic_notification` (white silhouette required by the OS)
- iOS lock-screen: text alert only (no `mutable-content` / image). Grinta has no
  Notification Service Extension; attaching an image on APNs dropped banners
  when the app was killed.

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
- **`brand`**: always `"grinta"` from the Flutter client.
- **`recipientUserIds`**: Auth uids. The CF loads `users/{uid}/fcmTokens` when
  `fcmTokens` is empty.
- Tokens live in `users/{uid}/fcmTokens/{token}` with `app: "grinta"`.

`pushDispatch` on the `notification` document:
`sending` / `sent` / `skipped` / `deferred` / `failed`, plus `sendAfter` when deferred.

## Deploy

```bash
firebase deploy --only functions:sendPushFCMNotification,functions:drainPendingPushNotifications,functions:sendPushOnNotificationCreated,firestore:indexes
```

Source: [`functions/send_push_fcm.js`](../functions/send_push_fcm.js),
[`functions/pending_push.js`](../functions/pending_push.js),
[`functions/notify_on_create.js`](../functions/notify_on_create.js).
