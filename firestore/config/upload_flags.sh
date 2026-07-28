#!/usr/bin/env bash
# Upload country flag PNGs to Firebase Storage under flags/{CODE}.png
#
# Prefers: gcloud storage cp
# Fallback: gsutil cp
#
# Prerequisites:
#   gcloud auth login
#   gcloud config set project aserstein-2453e
#   (optional) firebase deploy --only storage   # so flags/ is publicly readable
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FLAGS_DIR="${ROOT}/flags"
PROJECT="${FIREBASE_PROJECT:-aserstein-2453e}"
BUCKET="${FIREBASE_STORAGE_BUCKET:-aserstein-2453e.appspot.com}"

if [[ ! -d "${FLAGS_DIR}" ]]; then
  echo "Missing flags directory: ${FLAGS_DIR}" >&2
  exit 1
fi

shopt -s nullglob
files=("${FLAGS_DIR}"/*.png)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No PNG files in ${FLAGS_DIR}" >&2
  exit 1
fi

echo "Uploading ${#files[@]} flags from ${FLAGS_DIR} to gs://${BUCKET}/flags/ (project ${PROJECT})"

upload_one() {
  local file="$1"
  local name
  name="$(basename "${file}")"
  local dest="gs://${BUCKET}/flags/${name}"
  echo "→ ${dest}"

  if command -v gcloud >/dev/null 2>&1; then
    gcloud storage cp "${file}" "${dest}" \
      --project="${PROJECT}" \
      --content-type=image/png \
      --cache-control="public,max-age=86400"
    return 0
  fi

  if command -v gsutil >/dev/null 2>&1; then
    gsutil -h "Cache-Control:public,max-age=86400" \
      -h "Content-Type:image/png" \
      cp "${file}" "${dest}"
    return 0
  fi

  echo "Neither gcloud nor gsutil found." >&2
  echo "Install Google Cloud SDK, or upload manually in Firebase Console → Storage → flags/" >&2
  exit 1
}

for file in "${files[@]}"; do
  upload_one "${file}"
done

echo
echo "Done. Check e.g.:"
echo "https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/flags%2FFR.png?alt=media"
echo
echo "If you get Reauthentication / quota errors, run first:"
echo "  gcloud auth login"
echo "  gcloud config set project ${PROJECT}"
