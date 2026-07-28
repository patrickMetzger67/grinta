#!/usr/bin/env bash
# Upload country flag PNGs to Firebase Storage under flags/{CODE}.png
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FLAGS_DIR="${ROOT}/flags"
PROJECT="${FIREBASE_PROJECT:-aserstein-2453e}"
BUCKET="${FIREBASE_STORAGE_BUCKET:-aserstein-2453e.appspot.com}"

if [[ ! -d "${FLAGS_DIR}" ]]; then
  echo "Missing flags directory: ${FLAGS_DIR}" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required" >&2
  exit 1
fi

echo "Uploading flags from ${FLAGS_DIR} to gs://${BUCKET}/flags/ (project ${PROJECT})"

shopt -s nullglob
for file in "${FLAGS_DIR}"/*.png; do
  name="$(basename "${file}")"
  echo "→ flags/${name}"
  npx --yes firebase-tools@13 storage:upload "${file}" \
    --project "${PROJECT}" \
    --bucket "${BUCKET}" \
    --destination "flags/${name}" \
    || {
      # Fallback: gsutil if available
      if command -v gsutil >/dev/null 2>&1; then
        gsutil -h "Cache-Control:public,max-age=86400" \
          -h "Content-Type:image/png" \
          cp "${file}" "gs://${BUCKET}/flags/${name}"
      else
        echo "Upload failed for ${name}. Install gsutil or use the Firebase console." >&2
        exit 1
      fi
    }
done

echo "Done. Public URLs look like:"
echo "https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/flags%2FFR.png?alt=media"
