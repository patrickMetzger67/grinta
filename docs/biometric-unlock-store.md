# Déverrouillage & connexion biométrique — éléments de soumission store

## Comportement produit

- Après création de compte (ou première connexion **email/mot de passe**), l’app propose d’activer la biométrie.
- L’utilisateur peut activer / désactiver l’option dans **Réglages**.
- **Déverrouillage** : au prochain lancement (ou retour au premier plan), Face ID / Touch ID / empreinte / face unlock déverrouille l’UI tant que la session Firebase est encore sur l’appareil.
- **Connexion** (email/mot de passe uniquement) : si l’utilisateur se déconnecte (ou perd la session), l’écran de login propose Face ID / empreinte. Après succès biométrique, l’app relit l’e-mail + mot de passe depuis le Keychain / Keystore local, puis appelle Firebase `signInWithEmailAndPassword`.
- Les comptes Google / Apple gardent uniquement le déverrouillage d’UI (pas de mot de passe à stocker).
- « Utiliser un autre compte » sur l’écran de lock efface le coffre local et désactive l’option.
- Identifiants invalides (mot de passe changé) → le coffre est vidé ; reconnexion manuelle requise.

## Stockage local

| Élément | Emplacement |
|---|---|
| Préférence unlock on/off | `SharedPreferences` |
| E-mail + mot de passe | `flutter_secure_storage` (iOS Keychain / Android Keystore) |
| Déclenchement biométrique | `local_auth` (avant lecture du coffre ou déverrouillage UI) |

Grinta **ne collecte pas** et **ne transmet pas** de données biométriques. Les templates Face ID / empreinte restent dans le Secure Enclave / TEE.

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
  > Biometric unlock/login is optional. After email account creation, users can enable Face ID / Touch ID to unlock the app UI and to sign back in after logout. Email/password are stored only in the device Keychain/Keystore. Biometric templates never leave the device.

## Google Play — Data safety

- Déclarer que l’app utilise la biométrie **uniquement en local** pour le déverrouillage / la reconnexion.
- Ne pas cocher « Collected » / « Shared » pour les données biométriques : elles ne quittent pas l’appareil.
- Permission `USE_BIOMETRIC` : usage « App lock / authentication ».

## Checklist QA avant soumission

- [ ] iOS avec Face ID : activer après signup email → kill app → relancer → Face ID (unlock)
- [ ] iOS : activer → logout → écran login → Face ID → reconnecté
- [ ] iOS sans Face ID mais Touch ID / code : fallback système OK
- [ ] Android empreinte / face unlock : mêmes scénarios unlock + login
- [ ] Réglages → désactiver → plus de lock ni bouton biométrie sur login
- [ ] « Utiliser un autre compte » sur l’écran de lock → retour login sans biométrie
- [ ] Mot de passe changé ailleurs → biométrie login échoue proprement + coffre vidé
- [ ] Connexion sur un 2ᵉ appareil (session unique) → biométrie seule ne doit pas contourner le sign-out distant (mais peut reconnecter via le coffre local)
- [ ] Compte Google / Apple : unlock OK, pas de connexion biométrique sur login
- [ ] Web : aucun écran biométrique (feature mobile only)
