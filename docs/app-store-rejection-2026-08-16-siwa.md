# App Store rejection — 16 août 2026 (build 1.0.0+8)

Submission ID: `287921bc-b858-4fdc-a7ac-25bc28eaf1da`  
Review date: 16 August 2026  
Devices: iPad Air 11-inch (M4), iPhone 17 Pro Max  
Version reviewed: **1.0.0+8 (8)**

## Motif (identique au 14 août)

**Guideline 4 — Design / Sign in with Apple**

> The app offers Sign in with Apple as a login option but does not follow the
> design and user experience requirements for Sign in with Apple. Specifically,
> users are required to provide their name and/or email address after using
> Sign in with Apple even though that information is already provided by the
> Authentication Services framework.

Apple a bien reviewé le binaire **+8** (avant le correctif +9). Il faut
**soumettre un nouveau build** — ne pas répondre seulement par du texte.

## Correctif (build 1.0.0+10)

Sur la base du fix +9 :

- Après Apple / Google : **aucun** champ prénom / nom / e-mail affiché.
- Identité persistée localement (Apple n’envoie name/email qu’à la 1ʳᵉ autorisation).
- **Chemin invitation** : même verrouillage identité (auparavant les champs
  restaient éditables si un code d’invitation était trouvé).
- Validation post-SIWA : seule la date de naissance + nationalité sont
  obligatoires (contrôle d’âge 13+) — pas de re-demande e-mail/téléphone.

## Réponse type App Review

```text
Hello App Review Team,

Thank you for the Guideline 4 feedback on submission
287921bc-b858-4fdc-a7ac-25bc28eaf1da (Grinta 1.0.0+8).

That build still showed a profile form that could request name/email after
Sign in with Apple. We have fixed this in build 1.0.0+10:

1. After Sign in with Apple, the app never asks the user to enter their name
   or email. Those fields are not displayed.
2. Name and email come from the Authentication Services credential
   (givenName, familyName, email), including Hide My Email / private relay.
3. Because Apple only returns name/email on the first authorization, we
   persist them locally and reuse them on later sign-ins.
4. The remaining profile step only collects information Apple does not
   provide (date of birth and nationality) for our 13+ age gate — including
   when the user links an invitation code.

Please review build 1.0.0+10.

Best regards,
Patrick Metzger
```

## Checklist soumission

- [ ] Build iOS **1.0.0+10** (Archive / Transporter ou Xcode Organizer)
- [ ] Coller la réponse ci-dessus dans Messages → Reply
- [ ] Notes Review : préciser « After Sign in with Apple, only birth date and nationality are collected; name/email are not shown »
- [ ] Tester sur iPhone + iPad : SIWA → pas de champs nom/email
