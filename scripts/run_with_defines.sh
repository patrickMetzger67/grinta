#!/usr/bin/env bash
# Run Flutter with dart-defines from a local JSON file (not committed).
#
# Usage:
#   cp dart_defines.example.json dart_defines.json
#   # Edit dart_defines.json with your keys
#   ./scripts/run_with_defines.sh [flutter run args...]
#
# Android Studio: Run → Edit Configurations → Additional run args:
#   --dart-define-from-file=dart_defines.json
# (Create dart_defines.json locally from dart_defines.example.json)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES_FILE="${DART_DEFINES_FILE:-$ROOT/dart_defines.json}"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "Missing $DEFINES_FILE — copy dart_defines.example.json and fill in values." >&2
  exit 1
fi

cd "$ROOT"
exec flutter run --dart-define-from-file="$DEFINES_FILE" "$@"
