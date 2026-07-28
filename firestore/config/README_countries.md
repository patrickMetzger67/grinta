# Config `countries`

Document Firestore : `config/countries`

## Import Firestore

1. Console Firebase → Firestore → collection `config` → document `countries`
2. Importer le contenu de `countries.json` (champ racine `countries` = tableau)
   - ou via CLI (compte root / service account) :
     ```bash
     npx firebase-tools firestore:delete config/countries --force
     # Puis coller / set le JSON dans la console, ou utiliser un script Admin SDK.
     ```

## Drapeaux (Firebase Storage)

Fichiers locaux : `firestore/config/flags/{CODE}.png`  
Chemin Storage cible : `flags/{CODE}.png`  
Règles : lecture publique (`storage.rules` → `match /flags/{fileName}`).

Upload (après `firebase login`) :

```bash
./firestore/config/upload_flags.sh
```

Ou manuellement dans la console Storage → dossier `flags/`.

## Schéma d’un pays

| Champ       | Type   | Description                                      |
|-------------|--------|--------------------------------------------------|
| `code`      | string | Code ISO 3166-1 alpha-2 (`FR`, `DE`, …)          |
| `available` | bool   | Visible dans la liste déroulante équipe          |
| `flagUrl`   | string | URL publique Firebase Storage du drapeau         |
| `names`     | map    | Libellés `fr`, `en`, `de`, `es`, `it`            |

Seul `FR` est `available: true` au démarrage.
