# Codes promo Grinta — anti-régression

## Pourquoi les démos cassent encore sur les codes promo

Deux messages trompeurs historiques (souvent combinés) :

1. **« Code promo introuvable »** — la Cloud Function `redeemPromoCode` n’est pas déployée (ou mauvaise région).  
   Firebase renvoie un `not-found` générique. L’UI **ne doit plus** afficher « introuvable » dans ce cas — elle affiche l’échec générique (`PROMO_CALLABLE_MISSING`).

2. **« Ce code promo n’est plus valide »** — le code est OK, mais le **grant RevenueCat** échoue (`REVENUECAT_API_KEY` manquant / rejeté / entitlement absent).  
   Ces erreurs serveur utilisaient un `failed-precondition` **sans** `errorCode`. L’UI ne doit **jamais** mapper un `failed-precondition` nu → « n’est plus valide » (`PROMO_INVALID` uniquement).

## Correctifs en place

| Couche | Comportement |
|--------|----------------|
| **Functions** | Lookup tolérant (casse, tirets, `#`, `codeCompact`, scan `admin_promo_codes`) |
| **Functions** | Entitlements alias (`playerGPS` / `JOUEURGPS` / `joueur_gps` → `player_gps`) — pas de faux `PROMO_INVALID` |
| **Functions** | Grant RC : retry sur aliases Joueur GPS si 404 |
| **Functions** | Miroir `subscriptionAccess` **hors** transaction (merge entitlements via `mergePromoMirrorEntitlements` ; un échec user doc ne rollback pas le redeem) |
| **Functions** | Échecs grant RC → `errorCode` (`PROMO_RC_*` / `PROMO_GRANT_FAILED`) |
| **Client** | Normalise `# JOUEURGPS` → `JOUEURGPS` (`replaceFirst`, pas le `.replace` JS) |
| **Client** | Après redeem : vérifie le miroir pour l’entitlement **attendu** (`player_gps`), pas seulement `player` déjà actif |
| **Client** | Apply RC : conserve un grant durable `player_gps` si RC ne remonte encore que `player` |
| **Client** | Abonnement déjà actif : bouton **Code promo** pour upgrade (ex. Joueur → Joueur GPS) |
| **Client** | `not-found` Firebase ≠ « introuvable » sauf `PROMO_NOT_FOUND` |
| **Client** | `failed-precondition` ≠ « n’est plus valide » sauf `PROMO_INVALID` |
| **Admin UI** | Écrit `codeCompact` à la création / édition pour accélérer le lookup |
| **Admin UI** | Dropdown + create/update persistent **uniquement** les ids canoniques (`player_gps`, jamais `playerGPS`) |
| **Tests** | `test/promo_redeem_errors_test.dart` + `functions/promo_code_helpers.test.js` |

## Déployer avant une démo (obligatoire)

```bash
# Secret RevenueCat (une fois)
firebase functions:secrets:set REVENUECAT_API_KEY

# Déployer la callable (région europe-west1)
firebase deploy --only functions:redeemPromoCode
```

Vérifier ensuite dans la Firebase Console → Functions que `redeemPromoCode` est listée en **europe-west1**.

## Créer un code de démo

1. App connectée en compte **root** → Admin → Codes promo  
2. Créer un code simple, ex. `DEMO2026` (le serveur accepte aussi `DEMO-2026`)  
3. Entitlement : pour un code type **JOUEURGPS**, choisir **Joueur GPS** (`player_gps` — jamais l’alias RC `playerGPS`) + durée + `maxUses` suffisant  
4. Tester le redeem **avant** la démo client

> La création admin était déjà sûre (dropdown + `canonicalizeOne` à l’écriture). Le bug « code n’est plus valide » / `PROMO_INVALID` venait du **redeem** face à d’anciens docs Firestore / console avec `playerGPS` **ou** le libellé / code `JOUEURGPS` stocké dans le champ entitlement. Le redeem canonicalize désormais ces alias vers `player_gps` ; un cleanup one-shot n’est pas requis, mais une édition admin d’un vieux code réécrit l’id canonique.

## Tests locaux anti-régression

```bash
# Client (classification d'erreurs — ne jamais mapper CF absente → introuvable)
flutter test test/promo_redeem_errors_test.dart

# Server (matching DEMO-2026 ↔ DEMO2026)
cd functions && npm test
```

## Région callable

Le client appelle :

```dart
FirebaseFunctions.instanceFor(region: 'europe-west1')
```

Ne pas déployer `redeemPromoCode` dans une autre région sans aligner le client.
