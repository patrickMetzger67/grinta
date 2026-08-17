# App Store rejection — 14 août 2026 (build 1.0.0+8)

Submission ID: `287921bc-b858-4fdc-a7ac-25bc28eaf1da`  
Device: iPad Air 11-inch (M3)  
Version reviewed: 1.0.0+8 (7)

> **Update 16–17 août 2026 :** Apple a confirmé le même motif Guideline 4 sur
> le build **1.0.0+8**. Voir `app-store-rejection-2026-08-16-siwa.md` et
> soumettre **1.0.0+10**.

## Motif

**Guideline 4 — Design / Sign in with Apple**

> The app offers Sign in with Apple as a login option but does not follow the design and user experience requirements for Sign in with Apple. Specifically, users are required to provide their name and/or email address after using Sign in with Apple even though that information is already provided by the Authentication Services framework.

Le correctif du 12 août (préremplissage + champs en lecture seule) ne suffisait pas :

1. Apple n’envoie **prénom / nom / e-mail que lors de la première autorisation**. Aux connexions suivantes (dont Review), `givenName` / `familyName` sont `null`.
2. Firebase Auth ne renseigne en général **pas** `displayName` pour Apple, donc les champs restaient **vides et obligatoires**.
3. Apple considère que **demander** nom / e-mail après SIWA est un refus, même si les champs sont préremplis.

## Correctif (build 1.0.0+9)

- Capturer `givenName` / `familyName` / `email` depuis le credential Apple (pas seulement `user.displayName`).
- Les **persister** localement (SharedPreferences, clé = Apple `userIdentifier`) pour les autorisations suivantes.
- Après Apple / Google : **ne plus afficher** les champs prénom, nom et e-mail. Un texte explique que l’identité IdP est utilisée.
- Ne plus les exiger à la validation. Date de naissance + nationalité restent demandées (contrôle d’âge, non fournis par Apple).
- Fallbacks si Apple n’a rien envoyé (partie locale de l’e-mail Hide My Email, sinon « Player ») pour ne jamais bloquer l’inscription sur un champ identité.

## Réponse type App Review

```text
Hello App Review Team,

Thank you for the Guideline 4 feedback on submission 287921bc-b858-4fdc-a7ac-25bc28eaf1da (Grinta 1.0.0+8).

We revised the Sign in with Apple flow in this build (1.0.0+9):

- After Sign in with Apple, the app no longer asks the user to enter their name or email. Those fields are not shown.
- Name and email come from the Authentication Services credential (givenName, familyName, email), including Hide My Email / private relay.
- Because Apple only returns name/email on the first authorization, we persist them and reuse them on later sign-ins.
- The remaining profile step only collects information Apple does not provide (date of birth and nationality) for our 13+ age gate.

Please review this updated build.

Best regards,
Patrick Metzger
```
