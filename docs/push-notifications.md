# Push notifications (FCM)

Grinta sends phone/web pushes via the callable Cloud Function
`sendPushFCMNotification` (`europe-west1`).

## Contract (Grinta)

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
- **`recipientUserIds`**: Auth uids of recipients. The CF loads each user's
  `users/{uid}/app_state/notification_preferences` and **skips** push when:
  - `remindersEnabled === false`, or
  - current local time is in quiet days / quiet hours (timezone-aware).
- Tokens live in `users/{uid}/fcmTokens/{token}` with `app: "grinta"`.

In-app cloche notifications are still created by the app even when push is skipped.

## Deploy

```bash
firebase deploy --only functions:sendPushFCMNotification,firestore:rules
```

Source: [`functions/send_push_fcm.js`](../functions/send_push_fcm.js).

## Client checklist

| Platform | Requirement |
|----------|-------------|
| **iOS** | Push capability (`aps-environment`), `UIBackgroundModes` → `remote-notification`, APNs key in Firebase Console |
| **Android** | `POST_NOTIFICATIONS`, `google-services.json` for `io.grinta.app` |
| **Web** | Build with `--dart-define=FCM_WEB_VAPID_KEY=…` (Firebase → Cloud Messaging → Web Push certificates) |

## Triggers (app)

Convocations, feeling post-sync, member added to team, non-sport events — all go through
`NotificationFCMService.postNotification` → CF above.
