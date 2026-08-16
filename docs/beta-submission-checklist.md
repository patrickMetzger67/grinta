> **Pour importer dans Notion :** Nouvelle page → Import → Markdown → sélectionner ce fichier

# Checklist bêta — Grinta

**App :** Grinta · **Bundle / package :** `io.grinta.app` · **Version actuelle :** `1.0.0+1`

**Références projet :**

- **Version actuelle :** `1.0.0+1` (`pubspec.yaml`)
- **Bundle ID iOS / package Android :** `io.grinta.app`
- **Fichier de secrets local :** copier `dart_defines.example.json` → `dart_defines.json` (jamais commité)
- **Script de lancement :** `./scripts/run_with_defines.sh`
- **Codes promo (anti-régression démo) :** [`docs/promo-codes.md`](./promo-codes.md) — déployer `redeemPromoCode` avant toute démo

---

## Informations communes

### Identifiants produits (App Store Connect + Google Play)

| Produit | ID exact |
|---------|----------|
| Coach Basic — mensuel | `io.grinta.app.coach.basic.monthly` |
| Coach Elite — mensuel | `io.grinta.app.coach.elite.monthly` |
| Coach Pro — mensuel | `io.grinta.app.coach.pro.monthly` |
| Player — mensuel | `io.grinta.app.player.monthly` |
| Coach Basic — annuel | `io.grinta.app.coach.basic.yearly` |
| Coach Elite — annuel | `io.grinta.app.coach.elite.yearly` |
| Coach Pro — annuel | `io.grinta.app.coach.pro.yearly` |
| Player — annuel | `io.grinta.app.player.yearly` |

### Entitlements RevenueCat (dashboard)

| Entitlement | ID exact |
|-------------|----------|
| Coach Basic | `coach_basic` |
| Coach Elite | `coach_elite` |
| Coach Pro | `coach_pro` |
| Player | `player` |

### Prix indicatifs (référence marketing dans le code)

| Offre | Mensuel | Annuel |
|-------|---------|--------|
| Coach Basic | 9,99 € | 99,99 € |
| Coach Elite | 14,99 € | 149,99 € |
| Coach Pro | 24,99 € | 249,99 € |
| Player | 2,49 € | 24,99 € |

### Clés à renseigner dans `dart_defines.json`

| Clé | Préfixe attendu | Usage |
|-----|-----------------|-------|
| `REVENUECAT_IOS_API_KEY_SANDBOX` | `appl_…` | Debug / profile |
| `REVENUECAT_IOS_API_KEY_PROD` | `appl_…` | Builds release (TestFlight, App Store) |
| `REVENUECAT_ANDROID_API_KEY_SANDBOX` | `goog_…` | Debug / profile |
| `REVENUECAT_ANDROID_API_KEY_PROD` | `goog_…` | Builds release (Play Console) |
| `REVENUECAT_WEB_API_KEY_SANDBOX` | `rcb_sb_…` | Web billing sandbox |
| `REVENUECAT_WEB_API_KEY_PROD` | `rcb_…` | Web billing prod |

> **Important :** les builds bêta uploadés sur TestFlight / Play Console sont des builds **release** → RevenueCat utilisera les clés `*_PROD`. Le sandbox Apple/Google est géré par les **comptes testeurs**, pas par une seconde clé RevenueCat.

---

## Partie C — RevenueCat (à faire en premier, commun iOS + Android)

### Phase 1 — Projet et apps

- [ ] Créer / ouvrir le projet sur [app.revenuecat.com](https://app.revenuecat.com)
- [ ] Ajouter l'app **iOS** : bundle ID `io.grinta.app`
- [ ] Ajouter l'app **Android** : package `io.grinta.app`
- [ ] (Optionnel web) Configurer **Web Billing** avec Stripe pour les abonnements cross-platform — checklist détaillée Apple Pay / Google Pay : [`docs/web-billing-apple-google-pay.md`](./web-billing-apple-google-pay.md)

### Phase 2 — Lier les stores

- [ ] **App Store Connect** : clé API ASC (Users and Access → Integrations → App Store Connect API) → RevenueCat Project Settings
- [ ] **Google Play** : Service Account JSON (Google Cloud + Play Console → Users and permissions) → RevenueCat Project Settings
- [ ] Attendre la synchronisation des produits (peut prendre quelques minutes)

### Phase 3 — Entitlements

- [ ] Créer **4 entitlements** (IDs exacts) :

| Entitlement ID | Produits associés |
|----------------|-------------------|
| `coach_basic` | `io.grinta.app.coach.basic.monthly` + `.yearly` |
| `coach_elite` | `io.grinta.app.coach.elite.monthly` + `.yearly` |
| `coach_pro` | `io.grinta.app.coach.pro.monthly` + `.yearly` |
| `player` | `io.grinta.app.player.monthly` + `.yearly` |

- [ ] Chaque produit store (iOS + Android) rattaché au bon entitlement

### Phase 4 — Products (catalogue)

- [ ] Vérifier que les **8 product IDs** apparaissent dans RevenueCat (importés depuis ASC / Play)
- [ ] Si un produit manque : le créer d'abord dans ASC/Play, puis **Refresh** dans RevenueCat ou attendre la sync automatique

### Phase 5 — Offerings et packages

- [ ] Créer ou vérifier l'offering **`default`** (l'app cherche `offerings.current`, qui correspond à l'offering marquée « Current »)
- [ ] Ajouter des **packages** dans `default` — un par produit ou regroupés par tier :
  - Packages coach : basic / elite / pro (monthly + yearly)
  - Package player (monthly + yearly)
- [ ] Marquer **`default`** comme offering **Current** dans le dashboard
- [ ] Vérifier dans l'app (logs debug) : `SubscriptionService: offering "default"` avec packages non vides

### Phase 6 — Clés API dans les builds

- [ ] Récupérer les clés **publiques** (pas les secret keys) :
  - iOS : `appl_…` → `REVENUECAT_IOS_API_KEY_PROD`
  - Android : `goog_…` → `REVENUECAT_ANDROID_API_KEY_PROD`
  - Web : `rcb_…` / `rcb_sb_…` → clés web correspondantes
- [ ] Les placer dans `dart_defines.json` (copie locale de `dart_defines.example.json`)
- [ ] **Toujours** builder avec `--dart-define-from-file=dart_defines.json` ou utiliser `./scripts/run_with_defines.sh` pour le dev

### Phase 7 — Cross-platform et Firebase

- [ ] L'app appelle `Purchases.logIn(firebaseUid)` — le même UID Firebase unifie web (Stripe via RC Web Billing) et mobile
- [ ] Vérifier qu'un achat sandbox iOS/Android débloque le bon entitlement (`coach_pro`, etc.) dans le dashboard RC → Customers
- [ ] Tester la **restauration des achats** (bouton dans l'app) après réinstallation

### Phase 8 — Validation finale avant envoi aux testeurs

- [ ] 8 produits créés et actifs dans ASC **et** Play Console
- [ ] 4 entitlements configurés dans RevenueCat avec bons mappings
- [ ] Offering `default` = Current, avec packages
- [ ] Clés `appl_` et `goog_` dans `dart_defines.json`
- [ ] Build release iOS uploadée sur TestFlight
- [ ] Build release Android uploadée sur test interne
- [ ] Comptes sandbox Apple + licence testers Google configurés
- [ ] Achat test réussi sur iOS sandbox
- [ ] Achat test réussi sur Android licence test
- [ ] Entitlement visible dans RevenueCat dashboard pour l'utilisateur test

---

## Partie A — App Store Connect + TestFlight (Apple)

### Phase 0 — Prérequis

- [ ] **Compte Apple Developer actif** (99 €/an) avec accès à [developer.apple.com](https://developer.apple.com) et [App Store Connect](https://appstoreconnect.apple.com)
- [ ] **Mac avec Xcode installé** (dernière version stable recommandée) et **Flutter** configuré (`flutter doctor` sans erreur bloquante iOS)
- [ ] **Certificat de distribution** et **profil de provisioning App Store** pour le bundle ID `io.grinta.app` (Xcode peut les générer automatiquement : Xcode → Signing & Capabilities)
- [ ] **Fichier `dart_defines.json`** créé localement :

```bash
cp dart_defines.example.json dart_defines.json
```

Renseigner au minimum `REVENUECAT_IOS_API_KEY_PROD` (clé publique `appl_…` depuis le dashboard RevenueCat).

- [ ] **Pages légales accessibles :**
  - Politique de confidentialité : https://www.grinta.io/politiquedeconfidentialite
  - Conditions d'utilisation : https://www.grinta.io/conditionsutilisation
  - En cas de refus **3.1.2** (lien EULA manquant dans les métadonnées) : [app-store-rejection-3-1-2-eula.md](./app-store-rejection-3-1-2-eula.md)
  - En cas de refus Play Health Connect / privacy : [`docs/play-health-connect-rejection.md`](./play-health-connect-rejection.md)
- [ ] **Biométrie (Face ID)** : `NSFaceIDUsageDescription` est présent dans `ios/Runner/Info.plist`. Guide store : [`docs/biometric-unlock-store.md`](./biometric-unlock-store.md)
- [ ] **App Privacy** : ne pas déclarer Face ID / empreinte comme données *collectées* (restent sur l’appareil / Secure Enclave)

### Phase 1 — Enregistrer l'app et le bundle ID

- [ ] Aller sur [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → **App IDs** → type **App**
- [ ] Créer (ou vérifier) l'identifiant **`io.grinta.app`** — doit correspondre exactement à `ios/Runner.xcodeproj/project.pbxproj`
- [ ] Activer les capabilities nécessaires (Push Notifications, Sign in with Apple si utilisé, etc.)
- [ ] Sur **App Store Connect** → **Apps** → **+** → **Nouvelle app** :
  - Plateforme : iOS
  - Nom : Grinta
  - Langue principale : Français (ou autre)
  - Bundle ID : `io.grinta.app`
  - SKU : identifiant interne libre (ex. `grinta-ios-001`)

### Phase 2 — Créer les abonnements (IAP)

- [ ] Dans App Store Connect → votre app → **Fonctionnalités** → **Abonnements**
- [ ] Créer un **groupe d'abonnements** (ex. « Grinta Premium »)
- [ ] Créer **8 abonnements auto-renouvelables** avec les IDs **exactement** comme ci-dessous :

| # | Product ID | Période | Prix suggéré |
|---|-----------|---------|--------------|
| 1 | `io.grinta.app.coach.basic.monthly` | 1 mois | 9,99 € |
| 2 | `io.grinta.app.coach.elite.monthly` | 1 mois | 14,99 € |
| 3 | `io.grinta.app.coach.pro.monthly` | 1 mois | 24,99 € |
| 4 | `io.grinta.app.player.monthly` | 1 mois | 2,49 € |
| 5 | `io.grinta.app.coach.basic.yearly` | 1 an | 99,99 € |
| 6 | `io.grinta.app.coach.elite.yearly` | 1 an | 149,99 € |
| 7 | `io.grinta.app.coach.pro.yearly` | 1 an | 249,99 € |
| 8 | `io.grinta.app.player.yearly` | 1 an | 24,99 € |

- [ ] Pour chaque abonnement, remplir :
  - Nom d'affichage et description (localisés FR/EN minimum)
  - Prix par territoire
  - **Capture d'écran de révision** (obligatoire pour les abonnements — montrer l'écran paywall de l'app)
- [ ] Soumettre le groupe d'abonnements pour **révision** (peut bloquer TestFlight externe si non validé)

### Phase 3 — Comptes sandbox Apple (test achats)

- [ ] App Store Connect → **Utilisateurs et accès** → **Sandbox** → **Testeurs**
- [ ] Créer des comptes sandbox (email fictif, ex. `testeur1+grinta@example.com`)
- [ ] **Ne pas** utiliser votre Apple ID personnel sur l'appareil de test pour les achats sandbox
- [ ] Sur l'iPhone/iPad de test : **Réglages → App Store → Compte Sandbox** → se connecter avec le compte sandbox
- [ ] Installer la build TestFlight, ouvrir le paywall, acheter — l'App Store sandbox ne facture pas réellement

### Phase 4 — RevenueCat iOS

- [ ] Se connecter à [app.revenuecat.com](https://app.revenuecat.com) → votre projet Grinta
- [ ] Vérifier l'app iOS avec bundle ID `io.grinta.app`
- [ ] **Project Settings → App Store Connect** : lier le compte ASC (clé API `.p8` ou connexion OAuth)
- [ ] Importer / associer les 8 product IDs listés ci-dessus
- [ ] Vérifier les 4 entitlements : `coach_basic`, `coach_elite`, `coach_pro`, `player`
- [ ] Vérifier l'offering **`default`** (utilisée par l'app) contient des packages pour chaque produit
- [ ] Copier la **clé publique iOS** (`appl_…`) dans `dart_defines.json` → `REVENUECAT_IOS_API_KEY_PROD`

### Phase 5 — Construire l'IPA

- [ ] Incrémenter la version si nécessaire dans `pubspec.yaml` (format `X.Y.Z+build`, ex. `1.0.0+2`)
- [ ] Depuis la racine du projet :

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa \
  --release \
  --dart-define-from-file=dart_defines.json
```

- [ ] L'IPA est générée dans `build/ios/ipa/` (fichier `.ipa`)

### Phase 6 — Upload vers App Store Connect

**Option A — Transporter (recommandé pour non-experts)**

- [ ] Télécharger **Transporter** depuis le Mac App Store
- [ ] Ouvrir Transporter → glisser-déposer le fichier `.ipa`
- [ ] Cliquer **Livrer** → attendre le traitement (5–30 min)

**Option B — Xcode**

- [ ] Xcode → **Window → Organizer** → onglet **Archives** → **Distribute App** → App Store Connect

- [ ] Attendre l'email « Processing Complete » ou vérifier dans App Store Connect → **TestFlight** que la build apparaît (statut « En traitement » puis « Prête à soumettre »)

### Phase 7 — TestFlight : interne vs externe

**Test interne (équipe ASC, jusqu'à 100 personnes)**

- [ ] App Store Connect → TestFlight → **Testeurs internes** → ajouter des membres de votre équipe (rôle Admin, Developer, etc.)
- [ ] La build est disponible **immédiatement** après traitement, sans révision Apple
- [ ] Idéal pour la première validation technique (crash, login, paywall)

**Test externe (beta publique limitée, jusqu'à 10 000 testeurs)**

- [ ] TestFlight → **Testeurs externes** → créer un **groupe** (ex. « Beta Grinta FR »)
- [ ] Ajouter la build au groupe → remplir **Informations de test** :
  - Description des nouveautés
  - Email de contact
  - URL de feedback
- [ ] Soumettre pour **révision bêta Apple** (24–48 h en général)
- [ ] Une fois approuvé, partager le **lien public TestFlight** ou inviter par email

### Phase 8 — Notes pour les testeurs bêta

- [ ] Envoyer aux testeurs :
  - Le lien TestFlight ou l'invitation email
  - Version testée (`1.0.0+1` ou supérieure)
  - Compte Firebase / Grinta à utiliser pour se connecter
  - **Pour tester les abonnements :** créer un compte sandbox Apple (voir phase 3) — les achats ne sont pas facturés
  - Liste des fonctionnalités à tester (login, création d'équipe, paywall, achat sandbox, restauration achats)
  - Canal de feedback (email, Slack, formulaire)
- [ ] Rappeler : l'abonnement se renouvelle automatiquement ; annulation dans Réglages → Apple ID → Abonnements

### Phase 9 — Pièges courants et rejets

| Piège | Détail |
|-------|--------|
| Bundle ID mismatch | `io.grinta.app` doit être identique partout (Xcode, ASC, RevenueCat) |
| Product IDs incorrects | La moindre typo casse le paywall (offering vide) |
| Clé RevenueCat absente au build | Sans `--dart-define-from-file=dart_defines.json`, RevenueCat ne s'initialise pas |
| Abonnements non soumis pour révision | Bloque les tests d'achat en externe |
| Capture d'écran paywall manquante | Rejet systématique pour les IAP |
| Politique de confidentialité inaccessible | Rejet App Review |
| Guideline 2.1 (App Completeness) | L'app doit être fonctionnelle sans crash au lancement ; login testable |
| Guideline 3.1.2 (Subscriptions) | Lien vers CGU et politique de confidentialité visibles dans l'app **et** dans la Description App Store (EULA). Voir [refus 3.1.2 EULA](./app-store-rejection-3-1-2-eula.md) |
| Build « Missing Compliance » | Répondre à la question export compliance dans ASC (souvent « Non » si pas de chiffrement custom) |
| Sandbox vs production | En TestFlight, les achats passent par le sandbox Apple si le testeur utilise un compte sandbox ; pas besoin de build debug |
| Face ID sans usage string | Rejet si `NSFaceIDUsageDescription` manquant — déjà présent dans `Info.plist` |
| Biométrie déclarée à tort comme collectée | Les templates Face ID / empreinte ne quittent pas l’appareil ; ne pas les cocher comme données collectées |

---

## Partie B — Google Play Console (test interne / fermé)

### Phase 0 — Prérequis

- [ ] **Compte Google Play Developer** actif (25 $ unique) sur [play.google.com/console](https://play.google.com/console)
- [ ] **Keystore de release Android** configuré :

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- [ ] Créer `android/key.properties` (non commité) :

```
storePassword=<mot de passe>
keyPassword=<mot de passe>
keyAlias=upload
storeFile=<chemin absolu vers upload-keystore.jks>
```

- [ ] **Fichier `dart_defines.json`** avec `REVENUECAT_ANDROID_API_KEY_PROD` (`goog_…`)
- [ ] **Sauvegarder le keystore** en lieu sûr — perte = impossibilité de mettre à jour l'app

### Phase 1 — Créer l'application

- [ ] Play Console → **Créer une application**
- [ ] Nom : **Grinta**
- [ ] Langue par défaut : Français
- [ ] Type : Application / Gratuit (avec achats intégrés)
- [ ] **Nom de package** : `io.grinta.app` (identique à `android/app/build.gradle.kts` → `applicationId`)
- [ ] Accepter les déclarations (politique, US export, etc.)

### Phase 2 — Fiche Play Store (minimum pour testing)

- [ ] Remplir les sections obligatoires avant publication en test :
  - **Fiche Play Store** : titre, description courte/longue, icône 512×512, feature graphic
  - **Classification du contenu** (questionnaire)
  - **Public cible** et **Sécurité des données**
  - **Politique de confidentialité** : https://www.grinta.io/politiquedeconfidentialite
  - Health Connect : déclarer uniquement Exercise / Distance / Total calories / Heart rate (+ history) — voir [`docs/play-health-connect-rejection.md`](./play-health-connect-rejection.md)
- [ ] **Biométrie** : permission `USE_BIOMETRIC` déclarée ; dans Data safety, indiquer usage local uniquement (pas de collecte / partage). Détails : [`docs/biometric-unlock-store.md`](./biometric-unlock-store.md)
- [ ] Ces éléments sont requis même pour le track **test interne** sur un compte Play Developer récent

### Phase 3 — Créer les abonnements

- [ ] Play Console → votre app → **Monétisation** → **Produits** → **Abonnements**
- [ ] Créer **8 abonnements** avec les IDs **exactement** identiques à iOS :

| # | Product ID | Période | Prix suggéré |
|---|-----------|---------|--------------|
| 1 | `io.grinta.app.coach.basic.monthly` | Mensuel | 9,99 € |
| 2 | `io.grinta.app.coach.elite.monthly` | Mensuel | 14,99 € |
| 3 | `io.grinta.app.coach.pro.monthly` | Mensuel | 24,99 € |
| 4 | `io.grinta.app.player.monthly` | Mensuel | 2,49 € |
| 5 | `io.grinta.app.coach.basic.yearly` | Annuel | 99,99 € |
| 6 | `io.grinta.app.coach.elite.yearly` | Annuel | 149,99 € |
| 7 | `io.grinta.app.coach.pro.yearly` | Annuel | 249,99 € |
| 8 | `io.grinta.app.player.yearly` | Annuel | 24,99 € |

- [ ] Pour chaque abonnement : titre, description, prix, période d'essai gratuite (optionnel), grace period
- [ ] **Activer** chaque abonnement (statut « Actif »)

### Phase 4 — Testeurs licence (achats sandbox Google)

- [ ] Play Console → **Configuration** → **Test de licence**
- [ ] Ajouter les adresses Gmail des testeurs (comptes Google qui pourront acheter sans être facturés)
- [ ] Les testeurs doivent accepter l'invitation et utiliser le **même compte Google** sur l'appareil

### Phase 5 — RevenueCat Android

- [ ] Dashboard RevenueCat → app Android, package `io.grinta.app`
- [ ] **Project Settings → Google Play** : lier le compte (Service Account JSON depuis Google Cloud Console, rôle dans Play Console)
- [ ] Importer les 8 product IDs
- [ ] Vérifier entitlements (`coach_basic`, `coach_elite`, `coach_pro`, `player`) et offering **`default`**
- [ ] Copier la clé publique Android (`goog_…`) → `REVENUECAT_ANDROID_API_KEY_PROD` dans `dart_defines.json`

### Phase 6 — Construire l'App Bundle

- [ ] Incrémenter `version` dans `pubspec.yaml` si nouvelle build (ex. `1.0.0+2` — le `+2` devient `versionCode` Android)
- [ ] Vérifier que `android/key.properties` existe (sinon la build sera signée en debug et rejetée par Play)
- [ ] Depuis la racine :

```bash
flutter clean
flutter pub get
flutter build appbundle \
  --release \
  --dart-define-from-file=dart_defines.json
```

- [ ] Le fichier `.aab` est dans `build/app/outputs/bundle/release/app-release.aab`

### Phase 7 — Upload sur le track test interne

- [ ] Play Console → **Tests** → **Test interne** → **Créer une version**
- [ ] Uploader `app-release.aab`
- [ ] Renseigner les **notes de version** (ex. « Première bêta — paywall et abonnements »)
- [ ] **Examiner et déployer** → la build est disponible en quelques minutes pour les testeurs internes
- [ ] **Tests → Test interne → Testeurs** → créer une liste d'emails → ajouter les testeurs → copier le **lien d'opt-in**

### Phase 8 — Test fermé (closed testing)

- [ ] Pour un groupe plus large (jusqu'à des milliers de testeurs) : **Tests → Test fermé**
- [ ] Créer une **piste** (ex. « Beta fermée FR »)
- [ ] Uploader la même `.aab` ou une version plus récente
- [ ] Créer une **liste de testeurs** (emails Google ou Google Group)
- [ ] Partager le **lien d'inscription** au test fermé
- [ ] Optionnel : activer **Test ouvert** plus tard pour une beta publique sans liste d'emails

### Phase 9 — Notes pour les testeurs Android

- [ ] Envoyer aux testeurs :
  - Lien d'opt-in test interne/fermé
  - Leur compte Google doit être dans la liste de testeurs **et** dans les testeurs de licence (pour achats sandbox)
  - Version testée et changelog
  - Instructions : installer via le lien Play (pas sideload APK)
  - Scénarios à tester : login, paywall, achat sandbox, restauration, annulation via Play Store → Abonnements
- [ ] Délai : les nouveaux testeurs peuvent mettre **quelques heures** à voir l'app dans le Play Store

### Phase 10 — Pièges courants Android

| Piège | Détail |
|-------|--------|
| Package name mismatch | Doit être `io.grinta.app` partout |
| Build signée debug | Play rejette ; vérifier `key.properties` |
| Clé RevenueCat `goog_xxx` placeholder | Désactive RevenueCat sur Android |
| Abonnements inactifs | Le paywall affiche « produit introuvable » |
| Compte testeur pas dans licence testers | Achats réels ou erreurs |
| versionCode non incrémenté | Play refuse l'upload d'un `.aab` avec le même `+build` |
| Service Account RevenueCat mal configuré | Les achats ne se synchronisent pas avec RC |

---

## Commandes de référence rapide

```bash
# Préparer les secrets
cp dart_defines.example.json dart_defines.json
# Éditer dart_defines.json avec vos clés RevenueCat

# Dev local
./scripts/run_with_defines.sh

# Build iOS TestFlight
flutter build ipa --release --dart-define-from-file=dart_defines.json

# Build Android Play Console
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

> **Note :** le dépôt ne contient pas de documentation de build dédiée (`README.md` est le template Flutter par défaut). Les instructions ci-dessus sont dérivées de `subscription_config.dart`, `dart_defines.example.json`, `scripts/run_with_defines.sh` et des fichiers natifs iOS/Android.
