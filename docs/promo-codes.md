# Codes promo Grinta — anti-régression

## Pourquoi « Code promo introuvable » revient en démo

Deux causes fréquentes (souvent combinées) :

1. **La Cloud Function `redeemPromoCode` n’est pas déployée** (ou mauvaise région).  
   Firebase renvoie alors un `not-found` générique. L’UI **ne doit plus** afficher « introuvable » dans ce cas — elle affiche l’échec générique (`PROMO_CALLABLE_MISSING`).

2. **Le correctif n’était pas sur `main`**.  
   Le commit du 16/07 (`Corriger le redeem code promo`) était resté sur la branche `cursor/fix-code-promo-ea82` **sans merge**. Chaque déploiement depuis `main` réintroduisait le bug.

## Correctifs en place

| Couche | Comportement |
|--------|----------------|
| **Functions** | Lookup tolérant (casse, tirets, `codeCompact`, scan `admin_promo_codes`) |
| **Functions** | Miroir `subscriptionAccess` **hors** transaction (un échec user doc ne rollback pas le redeem) |
| **Client** | `not-found` Firebase ≠ « code introuvable » sauf `errorCode: PROMO_NOT_FOUND` |
| **Admin UI** | Écrit `codeCompact` à la création / édition pour accélérer le lookup |
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
3. Entitlement + durée + `maxUses` suffisant  
4. Tester le redeem **avant** la démo client

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
