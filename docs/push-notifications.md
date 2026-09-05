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
  when the app was killed. APNs topic is always `io.grinta.app` (shared Firebase
  project with Aserstein).

## Dual-app tokens (Grinta + Aserstein)

Both apps share Firebase project `aserstein-2453e` and `users/{uid}/fcmTokens`.
The same person can have both apps installed (two FCM tokens on one uid).
A Grinta event must never surface in the **AS Erstein** tray.

Typical dual-app failures:

1. First event: Grinta token **and** an unbranded leftover (AS Erstein) → two banners.
2. Next event: Grinta token missing/invalid, leftover still targeted → **only** AS Erstein.

If the uid has any Aserstein-tagged token and **no** explicit Grinta token, Grinta
sends **nothing** rather than falling back to that leftover.

Grinta sends only to:

- docs with `app: "grinta"` (and `packageName: "io.grinta.app"` on current builds)
- docs whose `packageName` is `io.grinta.app`
- legacy iOS/web docs without `app` **only if that uid has no Aserstein token**

If the uid also has `app: "aserstein"` (or an Aserstein `packageName`), unbranded
iOS/web leftovers are skipped — they are often the Aserstein device.

Naked unbranded **Android** docs are always skipped. `app: "aserstein"` and
Aserstein package names are never targeted by a Grinta send.

FCM delivery is also pinned to the Grinta apps:

- Android `restrictedPackageName`: `io.grinta.app`
- APNs `apns-topic`: `io.grinta.app`

In-app `notification/{id}` documents written by Grinta always include
`brand: "grinta"`. `sendPushOnNotificationCreated` uses that field (missing
brand = Grinta). A club id such as AS Erstein’s FFF id must **not** switch the
push to Aserstein.

An Aserstein Cloud Function or client that also listens to `notification` must
ignore `brand == "grinta"`. Aserstein-only users still receive Aserstein
pushes when the document (or callable) sets `brand: "aserstein"` — those sends
target only Aserstein tokens / `com.tome4.asersteinv2`.

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
- Tokens live in `users/{uid}/fcmTokens/{token}` with `app: "grinta"` and
  `packageName: "io.grinta.app"` (current builds).

`pushDispatch` on the `notification` document:
`sending` / `sent` / `skipped` / `deferred` / `failed`, plus `sendAfter` when deferred.

## Deploy

```bash
firebase deploy --only functions:sendPushFCMNotification,functions:drainPendingPushNotifications,functions:sendPushOnNotificationCreated,firestore:indexes
```

Stream Chat registers the FCM token with `pushProviderName: "grinta"` so a
Stream dashboard Firebase config named `grinta` can target only `io.grinta.app`.
Disable or split the default Stream Firebase provider if it still fans out to
Aserstein devices on the same Stream user.

Source: [`functions/send_push_fcm.js`](../functions/send_push_fcm.js),
[`functions/pending_push.js`](../functions/pending_push.js),
[`functions/notify_on_create.js`](../functions/notify_on_create.js).
