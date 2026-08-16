#!/usr/bin/env bash
# Configure Oura OAuth secrets for Firebase Cloud Functions.
#
# IMPORTANT:
#   - Do NOT put OURA_CLIENT_SECRET in dart_defines.json (client-side).
#   - These secrets are read only by Cloud Functions (ouraOAuthStart / Callback).
#
# Usage:
#   ./scripts/set_oura_firebase_secrets.sh
#
# Or from environment variables:
#   export OURA_CLIENT_ID=...
#   export OURA_CLIENT_SECRET=...
#   ./scripts/set_oura_firebase_secrets.sh
#
# Then deploy:
#   firebase deploy --only functions:ouraOAuthStart,functions:ouraOAuthCallback,functions:ouraDisconnect

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
  read -r -s -p "$prompt" value
  echo
  if [[ -z "$value" ]]; then
    echo "Empty value for $var_name — aborting." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$value"
}

read_secret OURA_CLIENT_ID "OURA_CLIENT_ID: "
read_secret OURA_CLIENT_SECRET "OURA_CLIENT_SECRET: "

echo "Setting Firebase secret OURA_CLIENT_ID..."
printf '%s' "$OURA_CLIENT_ID" | firebase functions:secrets:set OURA_CLIENT_ID

echo "Setting Firebase secret OURA_CLIENT_SECRET..."
printf '%s' "$OURA_CLIENT_SECRET" | firebase functions:secrets:set OURA_CLIENT_SECRET

echo
echo "Secrets configured."
echo "Next:"
echo "  firebase deploy --only functions:ouraOAuthStart,functions:ouraOAuthCallback,functions:ouraDisconnect"
echo
echo "Also remove OURA_CLIENT_SECRET from dart_defines.json if present (client must not embed it)."
