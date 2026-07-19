const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const MAIL_COLLECTION = 'mail';
const DEFAULT_CLUB_ID = '0';
const DEFAULT_FROM_EMAIL = 'noreply@grinta.io';
const DEFAULT_REPLY_TO_EMAIL = 'contact@grinta.io';
const DEFAULT_APP_NAME = 'Grinta Performance';
const DEFAULT_LOGO_URL =
  'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/logoClubs%2Fthumbs%2FGrinta_1920x1920.png?alt=media';
const DEFAULT_CONTINUE_URL = 'https://grinta.io';

// Grinta brand (AppColors.light)
const BRAND = {
  primary: '#F95C1B',
  secondary: '#FF8A5B',
  background: '#F7F7F8',
  surface: '#FFFFFF',
  textPrimary: '#1C1C1E',
  textSecondary: '#6E6E73',
  border: '#E5E5EA',
};

function readNonEmptyString(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function localize(locale) {
  const lang = (locale || 'fr').toString().toLowerCase().slice(0, 2);
  if (lang === 'en') {
    return {
      subject: (appName) => `Reset your ${appName} password`,
      intro: (appName) => `Reset your ${appName} password`,
      body:
        'We received a request to reset your password. Click the button below to choose a new one.',
      cta: 'Reset password',
      footer: (appName) =>
        `If you did not request this, you can ignore this email. — ${appName}`,
      text: (appName, link) =>
        `Reset your ${appName} password:\n\n${link}\n\nIf you did not request this, ignore this email.`,
    };
  }
  return {
    subject: (appName) => `Réinitialisation de votre mot de passe ${appName}`,
    intro: (appName) => `Réinitialisez votre mot de passe ${appName}`,
    body:
      'Nous avons reçu une demande de réinitialisation de votre mot de passe. Cliquez sur le bouton ci-dessous pour en choisir un nouveau.',
    cta: 'Réinitialiser mon mot de passe',
    footer: (appName) =>
      `Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail. — ${appName}`,
    text: (appName, link) =>
      `Réinitialisez votre mot de passe ${appName} :\n\n${link}\n\nSi vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.`,
  };
}

function buildHtml({ appName, logoUrl, resetLink, copy }) {
  const safeApp = escapeHtml(appName);
  const safeLogo = escapeHtml(logoUrl);
  const safeLink = escapeHtml(resetLink);
  const intro = escapeHtml(copy.intro(appName));
  const body = escapeHtml(copy.body);
  const cta = escapeHtml(copy.cta);
  const footer = escapeHtml(copy.footer(appName));

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${intro}</title>
</head>
<body style="margin:0;padding:0;background-color:${BRAND.background};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:${BRAND.background};padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background-color:${BRAND.surface};border:1px solid ${BRAND.border};border-radius:16px;overflow:hidden;">
          <tr>
            <td style="background:linear-gradient(135deg,${BRAND.primary} 0%,${BRAND.secondary} 100%);padding:28px 32px;text-align:center;">
              <img src="${safeLogo}" alt="${safeApp}" width="160" style="display:block;margin:0 auto 12px;max-width:160px;height:auto;border:0;" />
              <p style="margin:0;color:#FFFFFF;font-size:18px;font-weight:600;line-height:1.4;">${intro}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 24px;color:${BRAND.textPrimary};font-size:15px;line-height:1.6;">${body}</p>
              <table role="presentation" cellspacing="0" cellpadding="0">
                <tr>
                  <td>
                    <a href="${safeLink}" style="display:inline-block;background-color:${BRAND.primary};color:#FFFFFF;text-decoration:none;font-size:14px;font-weight:600;padding:14px 24px;border-radius:999px;">${cta}</a>
                  </td>
                </tr>
              </table>
              <p style="margin:24px 0 0;color:${BRAND.textSecondary};font-size:12px;line-height:1.5;word-break:break-all;">${safeLink}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px;border-top:1px solid ${BRAND.border};">
              <p style="margin:0;color:${BRAND.textSecondary};font-size:12px;line-height:1.6;text-align:center;">${footer}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

async function loadInvitationConfig(db) {
  try {
    const snap = await db.doc('config/invitation').get();
    const data = snap.exists ? snap.data() || {} : {};
    return {
      appDisplayName:
        readNonEmptyString(data.appDisplayName) ?? DEFAULT_APP_NAME,
      logoUrl: readNonEmptyString(data.logoUrl) ?? DEFAULT_LOGO_URL,
      fromEmail: readNonEmptyString(data.fromEmail) ?? DEFAULT_FROM_EMAIL,
      replyToEmail:
        readNonEmptyString(data.replyToEmail) ?? DEFAULT_REPLY_TO_EMAIL,
    };
  } catch (error) {
    console.warn('password_reset: config/invitation load failed', error);
    return {
      appDisplayName: DEFAULT_APP_NAME,
      logoUrl: DEFAULT_LOGO_URL,
      fromEmail: DEFAULT_FROM_EMAIL,
      replyToEmail: DEFAULT_REPLY_TO_EMAIL,
    };
  }
}

/**
 * Callable: sendPasswordResetMail
 *
 * Request: { email, locale? }
 * Response: { ok: true }
 *
 * Public (unauthenticated) — used from the login "forgot password" flow.
 * Verifies the Auth user exists, generates a reset link, queues a Grinta-branded
 * mail document for sendMailOnCreate.
 */
function createSendPasswordResetMail() {
  return onCall(
    {
      region: 'europe-west1',
      cors: true,
      invoker: 'public',
      timeoutSeconds: 30,
    },
    async (request) => {
      try {
        const email = readNonEmptyString(request.data?.email)?.toLowerCase();
        if (!email || !isValidEmail(email)) {
          throw new HttpsError('invalid-argument', 'invalid-email');
        }

        const locale = readNonEmptyString(request.data?.locale) ?? 'fr';
        const auth = getAuth();
        const db = getFirestore();

        try {
          await auth.getUserByEmail(email);
        } catch (error) {
          if (error?.code === 'auth/user-not-found') {
            throw new HttpsError('not-found', 'user-not-found');
          }
          console.error('password_reset: getUserByEmail failed', error);
          throw new HttpsError('internal', 'lookup-failed');
        }

        let resetLink;
        try {
          resetLink = await auth.generatePasswordResetLink(email, {
            url: DEFAULT_CONTINUE_URL,
            handleCodeInApp: false,
          });
        } catch (error) {
          console.error(
            'password_reset: generatePasswordResetLink failed',
            error,
          );
          throw new HttpsError('internal', 'link-failed');
        }

        const config = await loadInvitationConfig(db);
        const copy = localize(locale);
        const subject = copy.subject(config.appDisplayName);
        const text = copy.text(config.appDisplayName, resetLink);
        const html = buildHtml({
          appName: config.appDisplayName,
          logoUrl: config.logoUrl,
          resetLink,
          copy,
        });

        try {
          await db.collection(MAIL_COLLECTION).add({
            to: email,
            from: config.fromEmail,
            replyTo: config.replyToEmail,
            clubId: DEFAULT_CLUB_ID,
            message: {
              subject,
              text,
              html,
            },
          });
        } catch (error) {
          console.error('password_reset: mail queue failed', error);
          throw new HttpsError('internal', 'mail-queue-failed');
        }

        console.log('password_reset: mail queued', { email });
        return { ok: true };
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }
        console.error('password_reset: unhandled error', error);
        throw new HttpsError('internal', 'unexpected-error');
      }
    },
  );
}

module.exports = {
  createSendPasswordResetMail,
};
