# Déverrouillage biométrique — éléments de soumission store

## Comportement produit

- Après création de compte (ou première connexion), l’app propose d’activer le déverrouillage biométrique.
- L’utilisateur peut activer / désactiver l’option dans **Réglages**.
- Au prochain lancement (ou retour au premier plan), Face ID / Touch ID / empreinte / face unlock déverrouille l’UI.
- **Ce n’est pas une nouvelle connexion Firebase** : la session Firebase reste celle déjà persistée sur l’appareil.
- Si la session Firebase a disparu (déconnexion, session reprise ailleurs), l’utilisateur doit se reconnecter normalement.

## Fichiers natifs (déjà dans le repo)

| Plateforme | Élément | Fichier |
|------------|---------|---------|
| iOS | `NSFaceIDUsageDescription` | `ios/Runner/Info.plist` |
| Android | `USE_BIOMETRIC` + `USE_FINGERPRINT` | `android/app/src/main/AndroidManifest.xml` |
| Android | `FlutterFragmentActivity` (requis par `local_auth`) | `android/app/src/main/kotlin/io/grinta/app/MainActivity.kt` |

## App Store Connect — App Privacy / Review

- **Face ID / Touch ID** : les modèles biométriques restent dans le Secure Enclave. Grinta **ne collecte pas** et **ne transmet pas** de données biométriques.
- Dans le questionnaire **App Privacy**, ne pas déclarer Face ID comme donnée collectée par l’app (sauf si une autre feature le fait — ce n’est pas le cas ici).
- Notes Review (optionnel) :
  > Biometric unlock is optional. After account creation, users can enable Face ID / Touch ID to unlock the app UI while the Firebase session remains on device. Biometric templates never leave the device.

## Google Play — Data safety

- Déclarer que l’app utilise la biométrie **uniquement en local** pour le déverrouillage.
- Ne pas cocher « Collected » / « Shared » pour les données biométriques : elles ne quittent pas l’appareil.
- Permission `USE_BIOMETRIC` : usage « App lock / authentication ».

## Checklist QA avant soumission

- [ ] iOS avec Face ID : activer après signup → kill app → relancer → Face ID
- [ ] iOS sans Face ID mais Touch ID / code : fallback système OK
- [ ] Android empreinte / face unlock : même scénario
- [ ] Réglages → désactiver → plus de lock
- [ ] « Utiliser un autre compte » sur l’écran de lock → retour login
- [ ] Connexion sur un 2ᵉ appareil (session unique) → biométrie seule ne doit pas contourner le sign-out distant
- [ ] Web : aucun écran biométrique (feature mobile only)
