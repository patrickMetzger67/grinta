# Refus Google Play — Health Connect & politique de confidentialité

Checklist pour corriger les trois motifs de refus Play Console du type :

1. **Politique relative aux autorisations de Connexion santé** — *Renseignements insuffisants pour déterminer le fonctionnement de l'appli pour Connexion santé*
2. **Politique relative aux données de l'utilisateur** — *Politique de confidentialité incorrecte*
3. **Politique relative aux autorisations de Connexion santé** — *Accès excessif aux données pour la fonctionnalité déclarée*

## Ce qui a été corrigé dans le code

### Accès excessif (motif 3)

Le manifeste et le client ne demandent plus que le **minimum** aligné sur les fonctionnalités livrées :

| Permission Health Connect | Usage produit |
|---------------------------|---------------|
| `READ_EXERCISE` | Importer les séances Google Fit / Health Connect |
| `READ_DISTANCE` | Distance sur les séances importées |
| `READ_TOTAL_CALORIES_BURNED` | Calories sur les séances importées |
| `READ_HEART_RATE` | FC moyenne optionnelle à l’import |
| `WRITE_EXERCISE` / `WRITE_DISTANCE` | Export distance+durée après bilan de séance |
| `READ_HEALTH_DATA_HISTORY` | Lookback d’import au-delà de ~30 jours |

**Retiré** (non utilisé par une feature user-facing) : `READ_SLEEP`, `READ_STEPS`, `READ_ACTIVE_CALORIES_BURNED`, `WRITE_TOTAL_CALORIES_BURNED`.

Fichiers : `android/app/src/main/AndroidManifest.xml`, `lib/services/google_health_platform_io.dart`.

### Politique de confidentialité (motif 2)

`LegalConfig` pointe vers les pages Squarespace live :

- Privacy : https://www.grinta.io/politiquedeconfidentialite
- Terms : https://www.grinta.io/conditionsutilisation

Utiliser **exactement** cette URL privacy dans la fiche Play Store.

> Recommandation : dans la section appareils / services connectés de la politique, nommer explicitement **Android Health Connect / Google Fit** (lecture Exercise, Distance, Calories, FC ; écriture Exercise / Distance pour l’export de séance). Play vérifie souvent que la politique cite Health Connect.

Des copies HTML de secours restent dans `web/privacy/` et `web/terms/` (déployables via Firebase si besoin).

## Actions obligatoires avant resoumission (Play Console)

### A. URL privacy dans Play Console

Play Console → **Présence sur Google Play** → **Préparation de la fiche** → **Politique de confidentialité** :

`https://www.grinta.io/politiquedeconfidentialite`

Vérifier que la page charge (pas 404) et décrit les données santé / appareils connectés.

### B. Déclaration Health apps / Health Connect (motif 1 + 3)

Play Console → **Contenu de l’appli** → **Applications de santé** (Health apps) / déclaration Health Connect.

**Cas d’usage :** fitness & sports performance (football) — import d’entraînements et export de séances tracker.

**Fonctionnalités à décrire (FR, à coller / adapter) :**

> Grinta Performance aide les joueurs et coaches de football à suivre la charge d’entraînement. Sur Android, l’utilisateur peut connecter Google Fit via Health Connect pour :
> 1) importer ses séances d’exercice dans l’agenda Grinta (activité sportive personnelle) avec distance, durée, calories et fréquence cardiaque moyenne si disponible ;
> 2) exporter vers Health Connect la distance et la durée d’une séance d’entraînement ou de match mesurée par les trackers Grinta (après le bilan de séance).
> L’accès est demandé uniquement lorsque l’utilisateur lance la connexion dans Appareils/Applications ou accepte l’export. Les données ne sont pas utilisées pour la publicité. L’utilisateur contrôle la visibilité coach par type de métrique et peut révoquer Health Connect à tout moment.

**Justification par type de donnée (EN recommandé pour le formulaire) :**

| Data type | Read/Write | Justification |
|-----------|------------|---------------|
| Exercise | Read | List and import user workouts from Health Connect into personal sport activities |
| Exercise | Write | Write training/match sessions (duration) from Grinta tracker recap into Health Connect |
| Distance | Read | Attach distance to imported exercise sessions |
| Distance | Write | Write session distance from Grinta tracker recap |
| Total calories | Read | Attach energy burned to imported exercise sessions |
| Heart rate | Read | Compute average heart rate during an imported workout window |
| Health data history | Read | Allow importing workouts older than the default ~30-day window (up to ~90 days in-app) |

Ne **pas** déclarer Sleep, Steps, Active calories, etc.

### C. Vidéo / preuves pour « renseignements insuffisants »

Joindre une **courte vidéo** (ou captures) montrant :

1. Réglages → Appareils/Applications → + → Google Health → Sync → feuille d’autorisations Health Connect (Exercise, Distance, Calories, Heart rate).
2. Agenda → Créer → activité sportive personnelle → import d’une séance depuis Google Fit / Health Connect.
3. (Optionnel) Bilan de séance → export vers Google Fit.
4. Lien politique de confidentialité ouvert depuis Réglages → Infos.

### D. Data safety

Aligner le formulaire **Sécurité des données** avec la politique :

- Données de santé / fitness collectées : oui (exercices, FC, etc. si l’utilisateur connecte une source)
- Finalité : fonctionnalités de l’app (pas pub)
- Partage : selon club/coach / prestataires techniques (Firebase), pas de vente
- Lien politique = `https://www.grinta.io/politiquedeconfidentialite`

### E. Nouveau build Android

Publier un **nouvel AAB** (`1.0.0+6`) qui contient le manifeste réduit. Sans nouveau binaire, Play continue d’évaluer l’ancien paquet avec Sleep/Steps/etc.

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

## Vérifications rapides

- [ ] `aapt dump permissions` / APK Analyzer : plus de `READ_SLEEP`, `READ_STEPS`, `READ_ACTIVE_CALORIES_BURNED`, `WRITE_TOTAL_CALORIES_BURNED`
- [ ] https://www.grinta.io/politiquedeconfidentialite charge et couvre santé / appareils connectés
- [ ] URL privacy dans la fiche Play = URL ci-dessus
- [ ] Déclaration Health Connect = mêmes types que le manifeste
- [ ] Vidéo / description du parcours utilisateur jointe
- [ ] Data safety à jour

## Références

- [Publish your health app on Google Play](https://developer.android.com/health-and-fitness/health-connect/publish)
- [Android Health Permissions guidance](https://support.google.com/googleplay/android-developer/answer/12991134)
- Intégration technique : [`docs/google-health-connect-integration.md`](./google-health-connect-integration.md)
