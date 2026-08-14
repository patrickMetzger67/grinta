# App Store rejection — 12 août 2026 (build 1.0.0+6)

Submission ID: `287921bc-b858-4fdc-a7ac-25bc28eaf1da`  
Device: iPad Air 11-inch (M3)

## Synthèse des motifs Apple

| Guideline | Problème | Où corriger |
|-----------|----------|-------------|
| **3.1.2(c)** Subscriptions | Lien **Terms of Use (EULA)** manquant dans les **métadonnées** App Store Connect (description ou champ EULA). Dans l’app, le paywall a déjà Privacy + Terms. | App Store Connect + libellé EN « Terms of Use » (code) |
| **4** Design / Sign in with Apple | Après Apple, l’app redemandait prénom / nom / email | Voir le correctif du 14 août : masquer les champs (pas seulement lecture seule) |
| **5.1.2(i)** Tracking | Privacy labels ASC indiquent du *tracking* (Purchase History, User ID) sans App Tracking Transparency | App Store Connect → App Privacy : **retirer le tracking** si Grinta ne tracke pas pour la pub / data brokers |
| **5.1.1(ii)** Purpose strings | Camera / location trop vagues ou hors contexte (captures Review) | `ios/Runner/Info.plist` |
| **2.1** Info Needed | Questions sur l’IA tierce (Ask Gio / Gemini) | Réponse App Review (ci-dessous) |
| **2.1(b)** IAP introuvables | Reviewer ne trouve pas les abonnements sandbox | Réponse App Review + Paid Apps Agreement |

---

## Actions code (cette branche)

- Purpose strings camera / location / photos / micro clarifiées avec exemples.
- Sign in with Apple / Google : seed du profil depuis `displayName` + `email` Auth ; champs identité en lecture seule s’ils sont déjà fournis.
- Libellé EN paywall / footer : **Terms of Use**.

Rebuild iOS + nouvelle soumission après les actions Connect ci-dessous.

---

## Actions App Store Connect (manuel)

1. **EULA / Terms of Use**
   - Soit coller votre EULA custom dans App Store Connect → App → **License Agreement** (EULA).
   - Soit ajouter dans la **Description** App Store une ligne claire, ex. :
     `Terms of Use (EULA): https://www.grinta.io/conditionsutilisation`
   - Privacy Policy field : `https://www.grinta.io/politiquedeconfidentialite`

2. **App Privacy / Tracking (5.1.2)**
   - Si Grinta **ne lie pas** les données à des données tierces pour la publicité et **ne partage pas** avec un data broker → dans App Privacy, indiquer que l’app **ne tracke pas**.
   - Ne déclarer Purchase History / User ID comme *Used to Track You* que si c’est vraiment le cas.
   - Sinon il faudrait implémenter App Tracking Transparency (non recommandé si vous ne trackez pas).

3. **Paid Apps Agreement**
   - Business → Contracts : le Account Holder doit accepter le **Paid Apps Agreement** pour que les IAP sandbox fonctionnent pour Review.

4. **Notes pour la Review** (coller dans App Review Information)

---

## Réponse type à coller dans « Répondre à l’équipe de vérification »

```text
Hello App Review Team,

Thank you for the feedback on submission 287921bc-b858-4fdc-a7ac-25bc28eaf1da (Grinta 1.0.0+6).

=== Guideline 2.1 — Third-party AI ===
Yes. The in-app assistant “Ask Gio” uses Google Gemini (third-party AI) via our Firebase Cloud Functions backend.

Personal information sent to the AI:
- Only the user’s typed (or spoken-then-transcribed) question text.
- Optional app context needed to answer (e.g. team/schedule/stats summaries already available in the user’s Grinta account).
We do not send the user’s password. Microphone audio is used on-device for speech-to-text; the transcript may be included in the Ask Gio request. Profile photos and Health/wearable raw data are not sent to Gemini for chat.

=== Guideline 2.1(b) — How to find In-App Purchases ===
Test account: [FILL_DEMO_EMAIL] / [FILL_DEMO_PASSWORD]
(Use a sandbox Apple ID. Ensure the account has no active paid subscription, or use a fresh sandbox tester.)

Steps:
1. Launch Grinta and sign in with the demo account (or create an account with Sign in with Apple).
2. Complete or skip member profile if prompted (birth date + nationality required for age gate).
3. On Dashboard / Agenda, tap the “Go Premium” / “View plans” banner.
   OR: open Settings (gear) → Subscription → Subscribe / Change plan.
4. The paywall lists Coach Basic / Elite / Pro and Player, monthly and yearly, with App Store prices, Privacy Policy and Terms of Use links, then Subscribe.

Products expected:
- Grinta Coach Basic (monthly/yearly)
- Coach Elite (monthly/yearly)
- Coach Pro (monthly/yearly)
- Grinta Performance Player (monthly/yearly)

Product IDs: io.grinta.app.coach.basic.monthly|yearly, …elite…, …pro…, io.grinta.app.player.monthly|yearly.

=== Guideline 3.1.2 — Subscriptions metadata ===
We updated App Store metadata with a functional Terms of Use (EULA) link:
https://www.grinta.io/conditionsutilisation
Privacy Policy: https://www.grinta.io/politiquedeconfidentialite
In-app paywall already shows title, duration, price, Privacy Policy and Terms of Use.

=== Guideline 4 — Sign in with Apple ===
Fixed in this build: after Sign in with Apple, the app does not ask for name or email. Those values come from Authentication Services (and are stored for later sign-ins, since Apple only sends them on first authorization). The remaining profile fields (birth date, nationality) are app-specific for age gating and are not provided by Apple.

=== Guideline 5.1.1 — Purpose strings ===
Updated camera and location (and related) usage descriptions with clear examples in Info.plist.

=== Guideline 5.1.2 — Tracking / ATT ===
Grinta does not track users for advertising or share data with data brokers on iOS. We updated App Privacy in App Store Connect to reflect that tracking is not used. ATT is therefore not shown.

Please let us know if you need a screen recording of the subscription flow.

Best regards,
Patrick Metzger
```

Remplace `[FILL_DEMO_EMAIL]` / `[FILL_DEMO_PASSWORD]` avant envoi.

---

## Checklist avant resoumission

- [ ] Rebuild iOS avec les correctifs Info.plist + Sign in with Apple
- [ ] Description / EULA ASC mis à jour
- [ ] App Privacy : tracking désactivé (si applicable)
- [ ] Paid Apps Agreement accepté
- [ ] Compte sandbox + notes Review renseignés
- [ ] Réponse App Review envoyée avec les réponses 2.1 / 2.1(b)
