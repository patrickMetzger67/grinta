const { onRequest } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');

const USERS_COLLECTION = 'users';
const ACCOUNT_STATUS_ACTIVE = 'active';
const ACCOUNT_STATUS_PENDING = 'pendingParentalConsent';

function readToken(req) {
  const fromQuery = req.query?.token;
  if (typeof fromQuery === 'string' && fromQuery.trim()) {
    return fromQuery.trim();
  }
  const fromBody = req.body?.token;
  if (typeof fromBody === 'string' && fromBody.trim()) {
    return fromBody.trim();
  }
  return null;
}

function htmlPage({ title, heading, body, ok }) {
  const accent = ok ? '#F95C1B' : '#B42318';
  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>
    body { margin:0; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif; background:#F7F7F8; color:#1C1C1E; }
    .card { max-width:480px; margin:48px auto; background:#fff; border:1px solid #E5E5EA; border-radius:16px; padding:28px; }
    h1 { margin:0 0 12px; font-size:22px; color:${accent}; }
    p { margin:0; line-height:1.55; color:#6E6E73; }
  </style>
</head>
<body>
  <div class="card">
    <h1>${heading}</h1>
    <p>${body}</p>
  </div>
</body>
</html>`;
}

/**
 * Public HTTPS endpoint: parent opens the email link to approve a 13–14 account.
 *
 * Deploy:
 *   firebase deploy --only functions:approveParentalConsent
 */
function createApproveParentalConsent() {
  return onRequest(
    {
      region: 'europe-west1',
      cors: true,
      invoker: 'public',
    },
    async (req, res) => {
      if (req.method !== 'GET' && req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
      }

      const token = readToken(req);
      if (!token) {
        res.status(400).send(
          htmlPage({
            title: 'Lien invalide',
            heading: 'Lien invalide',
            body: 'Ce lien d’autorisation parentale est incomplet.',
            ok: false,
          }),
        );
        return;
      }

      try {
        const db = getFirestore();
        const snap = await db
          .collection(USERS_COLLECTION)
          .where('parentalConsentToken', '==', token)
          .limit(1)
          .get();

        if (snap.empty) {
          res.status(404).send(
            htmlPage({
              title: 'Lien expiré',
              heading: 'Lien introuvable ou déjà utilisé',
              body: 'Demandez à votre enfant de renvoyer l’e-mail d’autorisation depuis l’application.',
              ok: false,
            }),
          );
          return;
        }

        const doc = snap.docs[0];
        const data = doc.data() || {};
        const status = (data.accountStatus || '').toString();

        if (status === ACCOUNT_STATUS_ACTIVE) {
          res.status(200).send(
            htmlPage({
              title: 'Déjà autorisé',
              heading: 'Compte déjà autorisé',
              body: 'Le compte Grinta Performance est déjà actif. Votre enfant peut se connecter.',
              ok: true,
            }),
          );
          return;
        }

        if (status && status !== ACCOUNT_STATUS_PENDING) {
          res.status(400).send(
            htmlPage({
              title: 'Impossible',
              heading: 'Autorisation impossible',
              body: 'Ce compte ne peut pas être validé via ce lien.',
              ok: false,
            }),
          );
          return;
        }

        await doc.ref.set(
          {
            accountStatus: ACCOUNT_STATUS_ACTIVE,
            parentalConsentAt: new Date(),
            parentalConsentToken: null,
          },
          { merge: true },
        );

        res.status(200).send(
          htmlPage({
            title: 'Autorisation confirmée',
            heading: 'Merci — compte autorisé',
            body: 'Le compte Grinta Performance de votre enfant est maintenant actif. Il peut se connecter à l’application.',
            ok: true,
          }),
        );
      } catch (error) {
        console.error('approveParentalConsent failed', error);
        res.status(500).send(
          htmlPage({
            title: 'Erreur',
            heading: 'Une erreur est survenue',
            body: 'Réessayez dans quelques instants ou contactez support@grinta.io.',
            ok: false,
          }),
        );
      }
    },
  );
}

module.exports = {
  createApproveParentalConsent,
};
