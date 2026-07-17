const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const sendgridApiKey = defineSecret('SENDGRID_API_KEY');

const REGION = 'europe-west1';
const MAIL_COLLECTION = 'mail';
const PARAM_COLLECTION = 'param';
const DEFAULT_CLUB_ID = '0';
const DEFAULT_FROM_EMAIL = 'noreply@grinta.io';
const DEFAULT_REPLY_TO_EMAIL = 'contact@grinta.io';
const SENDGRID_API_URL = 'https://api.sendgrid.com/v3/mail/send';

function readNonEmptyString(value) {
  const trimmed = (value ?? '').toString().trim();
  return trimmed.length > 0 ? trimmed : null;
}

function buildDeliveryUpdate(state, { startTime, error = null, info = {} }) {
  const endTime = FieldValue.serverTimestamp();
  return {
    delivery: {
      attempts: 1,
      startTime,
      endTime,
      state,
      error,
      leaseExpireTime: null,
      info,
    },
  };
}

async function loadClubEmailParam(db, clubId) {
  const normalizedClubId = readNonEmptyString(clubId) ?? DEFAULT_CLUB_ID;
  const snap = await db.collection(PARAM_COLLECTION).doc(normalizedClubId).get();
  if (!snap.exists) {
    return {
      fromEmail: DEFAULT_FROM_EMAIL,
      replyToEmail: DEFAULT_REPLY_TO_EMAIL,
    };
  }

  const data = snap.data() ?? {};
  return {
    fromEmail:
      readNonEmptyString(data.fromEmail) ?? DEFAULT_FROM_EMAIL,
    replyToEmail:
      readNonEmptyString(data.replyToEmail) ?? DEFAULT_REPLY_TO_EMAIL,
  };
}

function normalizeAttachments(rawAttachments) {
  if (!Array.isArray(rawAttachments) || rawAttachments.length === 0) {
    return [];
  }

  const attachments = [];
  for (const entry of rawAttachments) {
    if (!entry || typeof entry !== 'object') continue;
    const content = readNonEmptyString(entry.content);
    const filename = readNonEmptyString(entry.filename);
    if (!content || !filename) continue;

    const type = readNonEmptyString(entry.type) ?? 'application/pdf';
    const disposition =
      readNonEmptyString(entry.disposition) ?? 'attachment';

    attachments.push({
      content,
      filename,
      type,
      disposition,
    });
  }
  return attachments;
}

async function sendViaSendGrid(
  apiKey,
  { to, from, replyTo, subject, text, html, attachments = [] },
) {
  const payload = {
    personalizations: [{ to: [{ email: to }] }],
    from: { email: from },
    reply_to: { email: replyTo },
    subject,
    content: [
      { type: 'text/plain', value: text },
      { type: 'text/html', value: html },
    ],
  };

  if (attachments.length > 0) {
    payload.attachments = attachments;
  }

  const response = await fetch(SENDGRID_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const body = await response.text();
  if (!response.ok) {
    let detail = body.trim();
    try {
      const parsed = JSON.parse(body);
      const messages = Array.isArray(parsed?.errors)
        ? parsed.errors.map((entry) => entry?.message).filter(Boolean)
        : [];
      if (messages.length > 0) {
        detail = messages.join('; ');
      }
    } catch (_) {
      // Keep raw body.
    }
    throw new Error(
      `SendGrid request failed (${response.status}): ${detail || 'unknown error'}`,
    );
  }

  const messageId = response.headers.get('x-message-id');
  return {
    messageId: messageId ?? null,
    accepted: [to],
    rejected: [],
    response: `SendGrid ${response.status}`,
  };
}

function createSendMailOnCreate() {
  return onDocumentCreated(
    {
      document: `${MAIL_COLLECTION}/{mailId}`,
      region: REGION,
      secrets: [sendgridApiKey],
      timeoutSeconds: 60,
    },
    async (event) => {
      const mailRef = event.data?.ref;
      const mailData = event.data?.data();
      if (!mailRef || !mailData) {
        console.warn('sendMailOnCreate: missing event data');
        return;
      }

      const startTime = FieldValue.serverTimestamp();
      const db = getFirestore();

      const to = readNonEmptyString(mailData.to);
      const message = mailData.message ?? {};
      const subject = readNonEmptyString(message.subject);
      const text = readNonEmptyString(message.text);
      const html = readNonEmptyString(message.html);
      const clubId = readNonEmptyString(mailData.clubId) ?? DEFAULT_CLUB_ID;

      if (!to || !subject || text == null || html == null) {
        await mailRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error:
              'Invalid mail document: to, message.subject, message.text, and message.html are required.',
          }),
        );
        return;
      }

      const apiKey = sendgridApiKey.value();
      if (!apiKey) {
        await mailRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error: 'SENDGRID_API_KEY secret is not configured.',
          }),
        );
        return;
      }

      let fromEmail;
      let replyToEmail;
      try {
        const clubParam = await loadClubEmailParam(db, clubId);
        fromEmail =
          readNonEmptyString(mailData.from) ?? clubParam.fromEmail;
        replyToEmail =
          readNonEmptyString(mailData.replyTo) ?? clubParam.replyToEmail;
      } catch (error) {
        console.error('sendMailOnCreate param load failed', error);
        await mailRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error: error?.message ?? String(error),
          }),
        );
        return;
      }

      const attachments = normalizeAttachments(mailData.attachments);

      try {
        const info = await sendViaSendGrid(apiKey, {
          to,
          from: fromEmail,
          replyTo: replyToEmail,
          subject,
          text,
          html,
          attachments,
        });

        await mailRef.update(
          buildDeliveryUpdate('SUCCESS', {
            startTime,
            info,
          }),
        );

        console.log('sendMailOnCreate success', {
          mailId: mailRef.id,
          to,
          clubId,
          from: fromEmail,
          attachmentCount: attachments.length,
        });
      } catch (error) {
        console.error('sendMailOnCreate SendGrid error', error);
        await mailRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error: error?.message ?? String(error),
          }),
        );
      }
    },
  );
}

module.exports = {
  createSendMailOnCreate,
  sendgridApiKey,
};
