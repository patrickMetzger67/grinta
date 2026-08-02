#!/usr/bin/env bash
# Fails if an AAB/APK still declares Google Play–restricted media permissions.
set -euo pipefail

ARTIFACT="${1:-}"
if [[ -z "$ARTIFACT" ]]; then
  if [[ -f build/app/outputs/bundle/release/app-release.aab ]]; then
    ARTIFACT="build/app/outputs/bundle/release/app-release.aab"
  elif [[ -f build/app/outputs/flutter-apk/app-release.apk ]]; then
    ARTIFACT="build/app/outputs/flutter-apk/app-release.apk"
  else
    echo "Usage: $0 <path-to-app-release.aab|apk>"
    echo "Build first: flutter build appbundle --release"
    exit 2
  fi
fi

if [[ ! -f "$ARTIFACT" ]]; then
  echo "Fichier introuvable: $ARTIFACT"
  exit 2
fi

echo "Analyse des permissions: $ARTIFACT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PERMS_FILE="$TMP/perms.txt"

if [[ "$ARTIFACT" == *.aab ]]; then
  unzip -p "$ARTIFACT" "base/manifest/AndroidManifest.xml" >"$TMP/AndroidManifest.xml" 2>/dev/null || true
  if [[ ! -s "$TMP/AndroidManifest.xml" ]]; then
    echo "Impossible d'extraire le manifeste du AAB."
    exit 1
  fi
  # Binary XML — use aapt/aapt2 if available on a temp APK from bundletool,
  # otherwise strings-scan the binary (permission names are UTF-8 literals).
  strings "$TMP/AndroidManifest.xml" >"$PERMS_FILE"
else
  if command -v aapt >/dev/null 2>&1; then
    aapt dump permissions "$ARTIFACT" >"$PERMS_FILE"
  elif command -v aapt2 >/dev/null 2>&1; then
    aapt2 dump permissions "$ARTIFACT" >"$PERMS_FILE"
  else
    unzip -p "$ARTIFACT" "AndroidManifest.xml" >"$TMP/AndroidManifest.xml"
    strings "$TMP/AndroidManifest.xml" >"$PERMS_FILE"
  fi
fi

FORBIDDEN=(
  "android.permission.READ_MEDIA_IMAGES"
  "android.permission.READ_MEDIA_VIDEO"
  "android.permission.READ_MEDIA_AUDIO"
  "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"
  "android.permission.MANAGE_EXTERNAL_STORAGE"
)

FOUND=0
for p in "${FORBIDDEN[@]}"; do
  if grep -Fq "$p" "$PERMS_FILE"; then
    echo "INTERDIT trouvé: $p"
    FOUND=1
  fi
done

if [[ "$FOUND" -ne 0 ]]; then
  echo ""
  echo "ÉCHEC: cet artefact déclare encore des permissions médias restreintes."
  echo "Ne l'uploade PAS sur Play Console."
  exit 1
fi

echo "OK: aucune permission READ_MEDIA_* / MANAGE_EXTERNAL_STORAGE trouvée."
echo ""
echo "Sur Play Console: dans la publication, retire TOUS les anciens AAB"
echo "(versionCode 1/2/3/4) — Google refuse si un seul artefact du lot"
echo "déclare encore READ_MEDIA_IMAGES / READ_MEDIA_VIDEO."
