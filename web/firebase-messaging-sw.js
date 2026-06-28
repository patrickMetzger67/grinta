// Firebase Cloud Messaging service worker for Grinta web push.
//
// Required for background notifications when the tab is in the background or closed.
// Foreground messages are handled in Dart via FirebaseMessaging.onMessage.
//
// Manual setup: Firebase Console → Cloud Messaging → Web Push certificates (VAPID).
// Dart app must pass the same public key via --dart-define=FCM_WEB_VAPID_KEY=…
//
// SDK version should stay aligned with firebase_core_web (see supportedFirebaseJsSdkVersion).

importScripts('https://www.gstatic.com/firebasejs/12.9.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.9.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB2b2jmuizBpCXtE5lNfV-YoXmq4Ec2WRk',
  appId: '1:626293600533:web:cd2bb4abec1eeef2a8791c',
  messagingSenderId: '626293600533',
  projectId: 'aserstein-2453e',
  authDomain: 'auth.grinta.io',
  storageBucket: 'aserstein-2453e.appspot.com',
  measurementId: 'G-DWZBSPWQH8',
});

const messaging = firebase.messaging();

/** Grinta PWA icon — do not use /favicon.png (legacy Aserstein asset). */
const GRINTA_DEFAULT_ICON = '/icons/Icon-192.png';

/**
 * Small notification icon. Prefer explicit `data.icon` from the Cloud Function
 * (dual-brand: grinta | aserstein). Do not fall back to notification.image,
 * which is the large banner and may point at the wrong brand.
 */
function resolveNotificationIcon(payload) {
  const data = payload.data || {};
  if (data.icon) return data.icon;
  const n = payload.notification;
  if (n && n.icon) return n.icon;
  return GRINTA_DEFAULT_ICON;
}

// Background data/notification payloads (tab not focused).
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw] background message', payload);

  const notification = payload.notification;
  if (!notification?.title) return;

  const data = payload.data || {};
  const options = {
    body: notification.body || '',
    icon: resolveNotificationIcon(payload),
    data: data,
  };

  const largeImage = data.image || notification.image;
  if (largeImage) {
    options.image = largeImage;
  }

  return self.registration.showNotification(notification.title, options);
});

// Focus an open tab when the user clicks a notification.
// Deep-link navigation is handled in Dart via onMessageOpenedApp when the app
// is already running; cold-start deep links from web push are not supported by
// firebase_messaging_web (getInitialMessage is always null on web).
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      }),
  );
});
