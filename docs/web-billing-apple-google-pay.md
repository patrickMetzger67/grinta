> **Pour importer dans Notion :** Nouvelle page → Import → Markdown → sélectionner ce fichier

# Checklist — Web Billing + Apple Pay / Google Pay (Grinta)

**Objectif :** reproduire un checkout web type Strava (essai gratuit, abonnement annuel/mensuel, boutons Apple Pay / Google Pay / carte) pour **Grinta Performance**, en restant aligné avec le code actuel.

**Stack déjà en place dans l’app :**

- Mobile : RevenueCat → App Store / Play Billing (`purchases_flutter`)
- Web : RevenueCat **Web Billing** (checkout hébergé RC / Stripe) — pas de SDK Stripe Flutter
- Identité unique : `Purchases.logIn(firebaseUid)` → mêmes entitlements web + mobile

**Références code :**

- `lib/config/subscription_config.dart`
- `lib/services/subscription_service.dart`
- `lib/widget/subscription_paywall.dart`
- `dart_defines.example.json`
- Checklist stores mobile : [`docs/beta-submission-checklist.md`](./beta-submission-checklist.md)

**Docs RevenueCat utiles :**

- [Payment methods (Apple Pay / Google Pay)](https://www.revenuecat.com/docs/web/web-billing/payment-methods)
- [Configuring RevenueCat Billing](https://www.revenuecat.com/docs/web/web-billing/configuring-overview)
- [Stripe Billing integration](https://www.revenuecat.com/docs/web/integrations/stripe) (si vous choisissez Stripe Billing plutôt que RC Billing)

---

## Avant de commencer — choisir le moteur web

| Option | Quand l’utiliser | Produits / prix | Apple Pay / G Pay |
|--------|------------------|-----------------|-------------------|
| **A. RevenueCat Billing** (recommandé pour démarrer) | Catalogue et cycle de vie gérés dans RC ; Stripe = processeur de paiement | Créés dans le dashboard RC | Activés via domaines Stripe (souvent auto sur `pay.rev.cat`) |
| **B. Stripe Billing** connecté à RC | Vous voulez gérer abonnements / essais / tax dans Stripe | Produits Stripe importés dans RC | Idem + config Stripe Billing |

L’app Flutter n’a **pas** besoin de connaître cette différence : elle appelle `Purchases.purchase` / packages de l’offering ; le checkout web s’ouvre côté RC.

---

## Partie 1 — Prérequis communs

- [ ] Compte [RevenueCat](https://app.revenuecat.com) avec le projet Grinta
- [ ] Apps **iOS** (`io.grinta.app`) et **Android** (`io.grinta.app`) déjà créées (même si le focus est web — pour l’accès cross-platform)
- [ ] **4 entitlements** créés avec les IDs exacts :

| Entitlement | ID |
|-------------|-----|
| Coach Basic | `coach_basic` |
| Coach Elite | `coach_elite` |
| Coach Pro | `coach_pro` |
| Player | `player` |

- [ ] Compte **Stripe** (mode Test + mode Live)
- [ ] Compte **Apple Developer** (pour Apple Pay en live ; le Merchant ID est géré via Stripe / RC)
- [ ] Domaine web de prod connu (ex. `grinta.io` ou le host Firebase : `*.web.app` / custom domain)
- [ ] Fichier local `dart_defines.json` (copie de `dart_defines.example.json`, **jamais commité**)

---

## Partie 2 — Connecter Stripe à RevenueCat

### Phase 1 — Lien Stripe

- [ ] RevenueCat → **Project Settings** → **Integrations** / **Stripe** (ou section Web)
- [ ] Connecter le compte Stripe en **Test** (sandbox)
- [ ] Connecter le compte Stripe en **Live** (production)
- [ ] Si Stripe affiche l’app RevenueCat avec des **permissions en attente** → les **approuver** (notamment écriture sur Payment Method Domains)

### Phase 2 — Config Web Billing

- [ ] Dans le projet RC → créer / ouvrir la config **Web** (RevenueCat Billing ou Stripe Billing selon le choix Partie 1)
- [ ] Noter les clés publiques :
  - Sandbox : `rcb_sb_…` → `REVENUECAT_WEB_API_KEY_SANDBOX`
  - Prod : `rcb_…` → `REVENUECAT_WEB_API_KEY_PROD`
- [ ] Les coller dans `dart_defines.json`
- [ ] Laisser `STRIPE_PUBLISHABLE_KEY_*` **vides** si le checkout est 100 % RC (recommandé ; voir commentaire dans `subscription_config.dart`)

---

## Partie 3 — Catalogue web (produits, essai, offering)

Les product IDs **web / Stripe** peuvent différer des IDs App Store / Play. L’app matche aussi par **tier + période** (`SubscriptionProductLookup.semanticKey`) — gardez des noms explicites contenant `coach_basic|elite|pro`, `player`, `monthly|yearly`.

### Phase 1 — Créer les 8 plans web

Créer (RC Billing **ou** Stripe puis import RC) :

| Plan | Sémantique attendue | Prix indicatif | Essai (optionnel) |
|------|---------------------|----------------|-------------------|
| Coach Basic mensuel | `coach` + `basic` + `month` | 9,99 € | ex. 30 jours |
| Coach Elite mensuel | `coach` + `elite` + `month` | 14,99 € | idem |
| Coach Pro mensuel | `coach` + `pro` + `month` | 24,99 € | idem |
| Player mensuel | `player` + `month` | 2,49 € | idem |
| Coach Basic annuel | `coach` + `basic` + `year` | 99,99 € | idem |
| Coach Elite annuel | `coach` + `elite` + `year` | 149,99 € | idem |
| Coach Pro annuel | `coach` + `pro` + `year` | 249,99 € | idem |
| Player annuel | `player` + `year` | 24,99 € | idem |

- [ ] Pour chaque plan : titre FR, description, devise EUR, période, **essai gratuit** si voulu (comme Strava 30 jours)
- [ ] Rattacher chaque produit au bon **entitlement** (`coach_basic`, etc.)

### Phase 2 — Offering

- [ ] Offering **`default`** (ou celle marquée **Current**) contient les packages web
- [ ] Même offering (ou mapping entitlements) que mobile pour un accès unifié
- [ ] Vérifier dans l’app web (logs debug) : `SubscriptionService: offering "default"` avec packages non vides

---

## Partie 4 — Apple Pay (côté Apple / Stripe)

Apple Pay sur le web **n’est pas** StoreKit. C’est le wallet via Stripe dans le checkout RC.

### Phase 1 — Stripe / domaines

**Cas A — checkout hébergé RevenueCat** (`pay.rev.cat`, funnels `signup.cat`)

- [ ] Rien à enregistrer manuellement : RC enregistre ces domaines auprès de Stripe
- [ ] Si les boutons n’apparaissent pas : Stripe Dashboard → **Apps** → app RevenueCat → **approuver** les permissions Payment Method Domains

**Cas B — achat initié sur votre propre domaine** (Flutter web / SDK sur `grinta.io`, Firebase Hosting, etc.)

- [ ] Stripe Dashboard → [Payment method domains](https://dashboard.stripe.com/settings/payment_method_domains)
- [ ] **Test mode** : ajouter le domaine exact du checkout (sous-domaine inclus), statut **Enabled**
- [ ] **Live mode** : ajouter le domaine de prod (ex. `app.grinta.io` ou `grinta.io`), statut **Enabled**
- [ ] Si staging ≠ prod (ex. `preview.web.app`), ajouter **chaque** host séparément

### Phase 2 — Apple Developer (live)

- [ ] Compte Apple Developer actif (organisation Grinta)
- [ ] Stripe guide la création / association du **Merchant ID** et des certificats — suivre les prompts Stripe si demandés en Live
- [ ] Domaine en **HTTPS** valide (obligatoire)

### Phase 3 — Comportement attendu (comme les captures Strava)

| Contexte | Ce que voit l’utilisateur |
|----------|---------------------------|
| Safari / appareil Apple avec carte Wallet | Bouton **Apple Pay** + sheet native |
| Desktop sans Apple Pay local (souvent Chrome Windows) | Option Apple Pay avec **scan QR** iPhone (iOS 18+) si supporté |
| Navigateur / région non supportés | Pas de bouton Apple Pay → carte / Google Pay |

- [ ] Tester en **Test mode** Stripe (domaines Test) avec une carte réelle dans Wallet — **aucun débit** en sandbox wallets selon les pratiques Stripe / RC
- [ ] Tester le parcours « Continuer » jusqu’à l’activation de l’entitlement dans RC → Customer

---

## Partie 5 — Google Pay (côté Google / Stripe)

Google Pay web **n’est pas** Play Billing. C’est le wallet via Stripe dans le même checkout.

### Phase 1 — Activation

- [ ] Avec RC Billing : une fois le domaine Payment Method Domains **Enabled**, Google Pay apparaît à côté de la carte quand le navigateur le permet
- [ ] Vérifier Stripe Dashboard → Payment methods : Google Pay disponible pour votre compte
- [ ] Si besoin d’un profil marchand étendu : [Google Pay & Wallet Console](https://pay.google.com/business/console) (souvent géré via Stripe)

### Phase 2 — Domaines (identique Apple Pay)

- [ ] Domaine(s) de checkout enregistrés en Test **et** Live (Cas B Partie 4)
- [ ] HTTPS obligatoire

### Phase 3 — Comportement attendu

| Contexte | Ce que voit l’utilisateur |
|----------|---------------------------|
| Chrome / Android avec Google Pay configuré | Bouton **G Pay** + modal (choix de carte, « Continuer ») |
| Compte Google sans moyen de paiement | Fallback carte |
| Navigateur non supporté | Pas de bouton G Pay |

- [ ] Tester le modal jusqu’à confirmation
- [ ] Vérifier l’entitlement RC (`coach_*` / `player`) sur le **même** `appUserId` = Firebase UID

---

## Partie 6 — Brancher l’app Grinta (web)

### Phase 1 — Clés

Dans `dart_defines.json` :

```json
{
  "REVENUECAT_WEB_API_KEY_SANDBOX": "rcb_sb_…",
  "REVENUECAT_WEB_API_KEY_PROD": "rcb_…",
  "REVENUECAT_IOS_API_KEY_PROD": "appl_…",
  "REVENUECAT_ANDROID_API_KEY_PROD": "goog_…"
}
```

- [ ] Clés web sandbox / prod renseignées (préfixes `rcb_sb_` / `rcb_`)
- [ ] Clés iOS / Android aussi renseignées pour les builds mobiles (sinon un abo web ne sera pas lu correctement sur device)

### Phase 2 — Build & deploy web

Debug / profile utilise automatiquement les clés **sandbox** ; release utilise **prod** (`SubscriptionEnvironment` dans `subscription_config.dart`).

```bash
# Dev web avec defines
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Build release web
flutter build web --release --dart-define-from-file=dart_defines.json
```

- [ ] **Important :** `deploy_web.sh` appelle aujourd’hui `flutter build web` **sans** `--dart-define-from-file`. Pour la prod, builder avec les defines (adapter le script ou builder à la main) avant `firebase deploy`
- [ ] Après deploy, ouvrir le paywall web connecté avec un compte Firebase

### Phase 3 — Parcours fonctionnel à valider

1. Login Firebase
2. Paywall → choisir Coach / Player + mensuel / annuel
3. `purchasePackage` ouvre le checkout RC
4. Payer avec **Apple Pay** ou **Google Pay** (ou carte)
5. Retour dans l’app → entitlement actif (`SubscriptionService.hasActivePaidSubscription`)
6. Ouvrir l’app **iOS ou Android** avec le **même** compte → accès débloqué (sans racheter)

---

## Partie 7 — Essai gratuit type Strava (optionnel)

- [ ] Configurer l’essai (ex. 30 jours) sur les produits **web** (RC Billing ou Stripe Price)
- [ ] Si vous voulez le même essai en app native : le configurer aussi sur chaque abonnement **App Store Connect** et **Play Console** (les stores gèrent l’essai IAP séparément)
- [ ] Textes checkout / paywall : « Facturé aujourd’hui 0 € », date de 1er prélèvement claire
- [ ] Lien CGU + politique de confidentialité visibles avant paiement (requis aussi pour les IAP mobiles)

---

## Partie 8 — Ce qu’il ne faut PAS confondre

| Besoin | Où le configurer | Ce n’est PAS |
|--------|------------------|--------------|
| Bouton Apple Pay sur le site | Stripe Payment Method Domains + RC Web | Abonnement App Store Connect |
| Bouton Google Pay sur le site | Idem Stripe / RC Web | Abonnement Play Console |
| Achat dans l’app iOS | App Store Connect + StoreKit via RC | Apple Pay web |
| Achat dans l’app Android | Play Console + Play Billing via RC | Google Pay web |
| Accès unifié web ↔ mobile | Même projet RC + `Purchases.logIn(firebaseUid)` + mêmes entitlements | Deux catalogues sans lien |

Les boutons Apple Pay / G Pay du checkout Strava = **wallets web**. Les abonnements dans l’app mobile Grinta restent les **IAP** de [`beta-submission-checklist.md`](./beta-submission-checklist.md).

---

## Partie 9 — Troubleshooting

| Symptôme | Cause probable | Action |
|----------|----------------|--------|
| Pas de bouton Apple Pay / G Pay | Domaine non enregistré / pas Enabled | Stripe → Payment method domains (Test **et** Live) |
| Toujours pas de wallet sur `pay.rev.cat` | Permissions Stripe app RC en attente | Approuver l’app RevenueCat dans Stripe |
| Paywall web « produit introuvable » | Offering vide ou mauvaise clé `rcb_*` | RC → offering Current + packages web ; vérifier `dart_defines.json` |
| Achat OK mais app mobile sans accès | UID RC ≠ Firebase UID, ou clés mobiles absentes | Vérifier `Purchases.logIn` + clés `appl_` / `goog_` |
| Wallets OK en local, KO en prod | Domaine Live manquant | Ajouter le host de prod en **Live** mode |
| `deploy_web.sh` sans abo | Build sans dart-defines | Ajouter `--dart-define-from-file=dart_defines.json` au build |
| Apple Pay absent sur Windows Chrome | Normal selon device | QR iPhone ou fallback carte / G Pay |

Outil Stripe pour vérifier les wallets : page de test Express Checkout Element (documentée par Stripe / RC).

---

## Ordre d’exécution recommandé

1. Entitlements RC + Stripe connecté (Test puis Live)
2. Catalogue web 8 plans + essais + offering `default`
3. Domaines Payment Method Domains (ou validation auto `pay.rev.cat`)
4. Clés `REVENUECAT_WEB_API_KEY_*` dans `dart_defines.json`
5. Test sandbox : carte → Apple Pay → Google Pay
6. Deploy web release avec defines
7. Test cross-device : abo web → entitlement visible sur iOS/Android
8. En parallèle / ensuite : IAP stores ([checklist bêta](./beta-submission-checklist.md))

---

## Checklist ultra-courte (récap)

**Apple (web)**

- [ ] Stripe lié à RC
- [ ] Domaine checkout Enabled (ou `pay.rev.cat` auto)
- [ ] Permissions app RevenueCat approuvées dans Stripe
- [ ] Test Apple Pay + scan iPhone si applicable

**Google (web)**

- [ ] Même domaine Payment Method Domains Enabled
- [ ] Test bouton G Pay + modal « Continuer »
- [ ] Entitlement RC confirmé

**Grinta**

- [ ] Clés `rcb_sb_` / `rcb_` dans `dart_defines.json`
- [ ] Offering web non vide
- [ ] Build web **avec** dart-defines
- [ ] Même Firebase UID → accès mobile
