#!/usr/bin/env bash
# Configure Strava OAuth secrets for Firebase Cloud Functions.
#
# IMPORTANT:
#   - Do NOT put STRAVA_CLIENT_SECRET in dart_defines.json (client-side).
#   - These secrets are read only by Cloud Functions (stravaOAuthStart / Callback).
#
# Usage (recommended — paste values when prompted):
#   ./scripts/set_strava_firebase_secrets.sh
#
# Or from environment variables:
#   export STRAVA_CLIENT_ID=50642
#   export STRAVA_CLIENT_SECRET=your_secret
#   ./scripts/set_strava_firebase_secrets.sh
#
# Then deploy:
#   firebase deploy --only functions:stravaOAuthStart,functions:stravaOAuthCallback,functions:stravaDisconnect

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install it, then retry." >&2
  exit 1
fi

read_secret() {
  local var_name="$1"
  local prompt="$2"
  local current="${!var_name:-}"
  if [[ -n "$current" ]]; then
    echo "$var_name already set in environment — reusing it."
    return 0
  fi
  # -s hides input (important for client secret)
  read -r -s -p "$prompt" value
  echo
  if [[ -z "$value" ]]; then
    echo "Empty value for $var_name — aborting." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$value"
}

read_secret STRAVA_CLIENT_ID "STRAVA_CLIENT_ID: "
read_secret STRAVA_CLIENT_SECRET "STRAVA_CLIENT_SECRET: "

echo "Setting Firebase secret STRAVA_CLIENT_ID..."
printf '%s' "$STRAVA_CLIENT_ID" | firebase functions:secrets:set STRAVA_CLIENT_ID

echo "Setting Firebase secret STRAVA_CLIENT_SECRET..."
printf '%s' "$STRAVA_CLIENT_SECRET" | firebase functions:secrets:set STRAVA_CLIENT_SECRET

echo
echo "Secrets configured."
echo "Next:"
echo "  firebase deploy --only functions:stravaOAuthStart,functions:stravaOAuthCallback,functions:stravaDisconnect"
echo
echo "Also remove STRAVA_CLIENT_SECRET from dart_defines.json if present (client must not embed it)."
