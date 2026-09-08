#!/usr/bin/env bash
# Deploy ONLY the Grinta push Cloud Functions + Firestore indexes.
#
# Why this script exists:
#   A full `firebase deploy --only functions` also touches WhatsApp / OAuth
#   functions that require secrets. Those secrets have blocked past deploys,
#   leaving production on the old dual-app FCM code — so banners still open
#   AS Erstein. Deploying the push functions alone avoids that trap.
#
# Prerequisites:
#   firebase login
#   firebase use aserstein-2453e
#
# Usage:
#   ./scripts/deploy_push_functions.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install: npm i -g firebase-tools" >&2
  exit 1
fi

echo "Project: $(firebase use 2>/dev/null || true)"
echo "Deploying Grinta push functions + firestore indexes…"

firebase deploy --only \
  functions:sendPushFCMNotification,\
functions:sendGrintaPushFCMNotification,\
functions:drainPendingPushNotifications,\
functions:sendPushOnNotificationCreated,\
functions:sendGrintaPushOnNotificationCreated,\
firestore:indexes

echo
echo "Done. Next:"
echo "  1. Ship / install a Grinta build that includes this branch."
echo "  2. Open Grinta once on each affected device (retags FCM + clears Stream devices)."
echo "  3. Trigger a test notification — the tray must say Grinta, not AS Erstein."
