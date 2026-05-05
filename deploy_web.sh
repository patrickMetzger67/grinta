#!/bin/bash

set -e

VERSION=$(date +%Y%m%d%H%M%S)
INDEX_FILE="build/web/index.html"
SITE="${1:-}"

if [ -z "$SITE" ]; then
  echo "Erreur : tu dois préciser le site Firebase Hosting à déployer."
  echo ""
  echo "Exemples :"
  echo "  ./deploy_web.sh grinta"
  echo "  ./deploy_web.sh lucarne-e66a3"
  exit 1
fi

echo "Site Firebase Hosting ciblé : $SITE"

echo "Nettoyage du projet Flutter..."
flutter clean

echo "Récupération des dépendances..."
flutter pub get

echo "Build Flutter Web sans service worker..."
flutter build web --release --pwa-strategy=none

if [ ! -f "$INDEX_FILE" ]; then
  echo "Erreur : fichier $INDEX_FILE introuvable."
  exit 1
fi

echo "Mise à jour de la version dans index.html..."
echo "Version utilisée : $VERSION"

perl -0pi -e "s#flutter_bootstrap\.js(\?v=[0-9A-Za-z._-]+)?#flutter_bootstrap.js?v=$VERSION#g" "$INDEX_FILE"

echo "Suppression du manifest dans index.html pour enlever l'icône d'installation Chrome..."

perl -0pi -e 's#\s*<link\s+rel=["'"'"']manifest["'"'"']\s+href=["'"'"']manifest\.json["'"'"']\s*/?>\s*##gi' "$INDEX_FILE"

echo "Suppression des fichiers PWA éventuels..."

rm -f build/web/manifest.json
rm -f build/web/flutter_service_worker.js

echo "Vérification flutter_bootstrap.js :"
grep "flutter_bootstrap.js" "$INDEX_FILE" || true

echo "Vérification manifest.json dans index.html :"
if grep -q "manifest.json" "$INDEX_FILE"; then
  echo "Attention : manifest.json est encore présent dans index.html"
else
  echo "OK : manifest.json supprimé de index.html"
fi

echo "Déploiement Firebase Hosting sur le site : $SITE"
firebase deploy --only hosting:$SITE

echo "Déploiement terminé avec succès."