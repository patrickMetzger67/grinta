# App Store — Refus Guideline 3.1.2 (EULA / CGU)

Checklist pour débloquer un refus App Review lié aux **abonnements auto-renouvelables** lorsque Apple indique qu’il manque un **lien fonctionnel vers les Conditions d’utilisation (EULA)** dans les métadonnées.

> **Exemple de message Apple :**  
> *Guideline 3.1.2 - Business - Payments - Subscriptions*  
> *We were unable to find the following required item(s) in your app's metadata:*  
> *– A functional link to the Terms of Use (EULA)*

Ce n’est **pas** un bug binaire : la correction se fait surtout dans **App Store Connect** (métadonnées), pas dans le code Flutter.

---

## Pages légales Grinta

| Document | URL |
|----------|-----|
| Conditions d’utilisation (EULA / CGU) | https://grinta.io/terms |
| Politique de confidentialité | https://grinta.io/privacy |

- [ ] Ouvrir chaque URL dans un navigateur **privé** et vérifier que la page charge (pas de 404, pas de maintenance).

---

## Correctifs App Store Connect

### 1. Description de l’app (obligatoire)

Chemin : **App Store Connect** → **Grinta** → **Distribution** → **iOS** → version refusée → champ **Description**.

Ajouter **en bas** de la description (FR et/ou EN selon les localisations renseignées) :

```text
Conditions d'utilisation (EULA) : https://grinta.io/terms
Politique de confidentialité : https://grinta.io/privacy
```

Version anglaise recommandée si la fiche EN existe :

```text
Terms of Use (EULA): https://grinta.io/terms
Privacy Policy: https://grinta.io/privacy
```

- [ ] Liens collés dans **Description** (pas seulement dans le texte promotionnel)
- [ ] Sauvegarder la version

> La politique de confidentialité a aussi un champ dédié dans **App Privacy** / infos app — le garder rempli avec `https://grinta.io/privacy`.  
> Pour l’EULA, Apple exige en plus le lien **dans la Description** si tu utilises l’EULA standard Apple.

### 2. Contrat de licence (EULA)

Chemin : **App Store Connect** → **Grinta** → **Distribution** → **Informations sur l’app** → **Contrat de licence** (License Agreement).

Choisir **une** option :

| Option | Action |
|--------|--------|
| **A — EULA standard Apple** | Laisser l’accord Apple sélectionné **et** garder le lien CGU dans la Description (étape 1). |
| **B — EULA personnalisé** | Choisir « Appliquer un EULA personnalisé », coller le **texte** des CGU (contenu de https://grinta.io/terms), pas seulement l’URL. |

- [ ] Option A ou B configurée et enregistrée

### 3. Liens dans l’app (binaire)

Apple exige aussi des liens **cliquables** dans l’application (paywall / réglages) vers CGU et confidentialité. Vérifier avant resoumission :

- [ ] Écran d’abonnement / paywall : liens CGU + confidentialité visibles
- [ ] Réglages / mentions légales : mêmes liens accessibles

(Si déjà en place via `legalTermsOfService` / `legalPrivacyPolicy`, rien à changer côté code pour ce refus metadata.)

### 4. Resoumettre

- [ ] Les abonnements (Player, Coach Basic, Coach Elite, etc.) restent en « Prêt pour la vérification » — c’est normal tant que la version iOS est refusée
- [ ] Une fois Description (+ licence) sauvegardée, le bouton **Soumettre à nouveau à l’équipe de vérification** se réactive
- [ ] Renvoyer la **même build** si aucun correctif binaire n’est nécessaire (sinon uploader une nouvelle build)

---

## Réponse optionnelle à Apple (Resolution Center)

Si tu veux préciser où se trouve le lien :

```text
Hello,

We have added functional links to our Terms of Use (EULA) and Privacy Policy
in the App Description metadata:

- Terms of Use: https://grinta.io/terms
- Privacy Policy: https://grinta.io/privacy

License Agreement is configured in App Information.
The same links are also available in the app (paywall / settings).

Thank you.
```

---

## Après approbation

- [ ] Vérifier sur la fiche App Store (TestFlight / prévisualisation) que les liens de la Description sont bien affichés
- [ ] Ne pas retirer ces lignes de la Description lors des prochaines mises à jour

---

## Références

- [App Review Guidelines — 3.1.2 Subscriptions](https://developer.apple.com/app-store/review/guidelines/#subscriptions)
- Checklist soumission Grinta : [beta-submission-checklist.md](./beta-submission-checklist.md)
- Facturation web : [web-billing-apple-google-pay.md](./web-billing-apple-google-pay.md)
