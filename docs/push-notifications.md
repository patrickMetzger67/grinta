# Push notifications (FCM)

Grinta delivers phone/web pushes in two ways (`europe-west1`):

1. **Firestore trigger** `sendGrintaPushOnNotificationCreated` — fires when a
   document is created in `grinta_notification` (not the shared `notification`
   collection used by AS Erstein). If the user can receive push now, FCM is sent
   immediately (with the Grinta logo). If not, the same document is kept with
   `pushDispatch.sendAfter`.
2. **Callable** `sendGrintaPushFCMNotification` (fallback
   `sendPushFCMNotification`) — chat / member-added. Quiet recipients go to
   `pending_push`. Both callables always send brand `grinta`.

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

Never to untagged iOS/web leftovers. Those tokens often belong to the **AS Erstein
app**; FCM then displays AS Erstein's name **and launcher icon** (not a title
string in our payload). `app: "aserstein"` and Aserstein package names are
never targeted by a Grinta send.

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

- **`clubId`**: the Flutter client always sends `"0"` (Grinta platform). A
  real club id such as AS Erstein (`500554`) is stored on the in-app
  `notification` document only — never on the FCM callable.
- **`brand`**: always `"grinta"` from the Flutter client.
- **`recipientUserIds`**: Auth uids. The CF loads `users/{uid}/fcmTokens` when
  `fcmTokens` is empty.
- Tokens live in `users/{uid}/fcmTokens/{token}` with `app: "grinta"` and
  `packageName: "io.grinta.app"` (current builds).

`pushDispatch` on the `notification` document:
`sending` / `sent` / `skipped` / `deferred` / `failed`, plus `sendAfter` when deferred.

Grinta **does not** register FCM devices with Stream (`addDevice`). The shared
Stream app already has AS Erstein devices for the same uid; Stream Firebase
push would show those banners as AS Erstein (app name + icon). On login Grinta
removes **all** Stream devices and sets Stream chat push to `none`. Chat
lock-screen delivery uses `sendGrintaPushFCMNotification` only.

Disable or split the default Stream Firebase provider in the Stream dashboard
if AS Erstein still fans out chat to the shared project.

## Deploy (required for prod)

Code on `main` does nothing until Cloud Functions are redeployed. Prefer the
push-only script (avoids WhatsApp / OAuth secret blockers that blocked earlier
deploys — leaving production on the old dual-app FCM code):

```bash
./scripts/deploy_push_functions.sh
```

Equivalent:

```bash
firebase deploy --only functions:sendPushFCMNotification,functions:sendGrintaPushFCMNotification,functions:drainPendingPushNotifications,functions:sendPushOnNotificationCreated,functions:sendGrintaPushOnNotificationCreated,firestore:indexes
```

Then install a Grinta build that writes `grinta_notification` and open the app
once on each affected device.

Source: [`functions/send_push_fcm.js`](../functions/send_push_fcm.js),
[`functions/pending_push.js`](../functions/pending_push.js),
[`functions/notify_on_create.js`](../functions/notify_on_create.js).
