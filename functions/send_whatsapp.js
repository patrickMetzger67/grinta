const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const whatsappAccessToken = defineSecret('WHATSAPP_ACCESS_TOKEN');
const whatsappPhoneNumberId = defineSecret('WHATSAPP_PHONE_NUMBER_ID');
const whatsappVerifyToken = defineSecret('WHATSAPP_VERIFY_TOKEN');

const REGION = 'europe-west1';
const COLLECTION = 'whatsapp_messages';
const DEFAULT_API_VERSION = 'v21.0';
const DEFAULT_TEMPLATE_NAME = 'member_invitation';
const DEFAULT_TEMPLATE_LANGUAGE = 'fr';

function readNonEmptyString(value) {
  const trimmed = (value ?? '').toString().trim();
  return trimmed.length > 0 ? trimmed : null;
}

function digitsOnlyPhone(value) {
  const raw = readNonEmptyString(value);
  if (!raw) return null;
  const digits = raw.replace(/\D/g, '');
  return digits.length >= 8 ? digits : null;
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

function buildTemplatePayload({
  to,
  templateName,
  languageCode,
  bodyParameters,
}) {
  const components = [];
  if (Array.isArray(bodyParameters) && bodyParameters.length > 0) {
    components.push({
      type: 'body',
      parameters: bodyParameters.map((text) => ({
        type: 'text',
        text: String(text ?? ''),
      })),
    });
  }

  return {
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to,
    type: 'template',
    template: {
      name: templateName,
      language: { code: languageCode },
      ...(components.length > 0 ? { components } : {}),
    },
  };
}

async function sendWhatsAppTemplate(accessToken, phoneNumberId, payload, apiVersion) {
  const version = readNonEmptyString(apiVersion) ?? DEFAULT_API_VERSION;
  const url = `https://graph.facebook.com/${version}/${phoneNumberId}/messages`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const responseText = await response.text();
  let body;
  try {
    body = responseText ? JSON.parse(responseText) : {};
  } catch (_) {
    body = { raw: responseText };
  }

  if (!response.ok) {
    const detail =
      body?.error?.message ||
      body?.error?.error_user_msg ||
      responseText ||
      `HTTP ${response.status}`;
    const err = new Error(`WhatsApp Cloud API failed (${response.status}): ${detail}`);
    err.status = response.status;
    err.body = body;
    throw err;
  }

  const messageId = body?.messages?.[0]?.id ?? null;
  return {
    messageId,
    response: `WhatsApp ${response.status}`,
    accepted: [payload.to],
    rejected: [],
    waId: body?.contacts?.[0]?.wa_id ?? null,
  };
}

/**
 * Firestore trigger: send queued WhatsApp template messages via Meta Cloud API.
 *
 * Document shape (client create):
 * {
 *   to: "+33612345678",
 *   templateName?: "member_invitation",
 *   languageCode?: "fr",
 *   bodyParameters?: ["Grinta Performance", "GT1234", "https://…"],
 *   clubId?: "0",
 *   kind?: "member_invitation",
 *   invitationId?: "…",
 *   invitationCode?: "GT1234"
 * }
 */
function createSendWhatsAppOnCreate() {
  return onDocumentCreated(
    {
      document: `${COLLECTION}/{messageId}`,
      region: REGION,
      secrets: [whatsappAccessToken, whatsappPhoneNumberId],
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const messageRef = snap.ref;
      const data = snap.data() ?? {};
      const startTime = FieldValue.serverTimestamp();

      const existingDelivery = data.delivery;
      if (existingDelivery && typeof existingDelivery === 'object') {
        console.log('sendWhatsAppOnCreate skip: delivery already set', {
          messageId: messageRef.id,
        });
        return;
      }

      const to = digitsOnlyPhone(data.to);
      if (!to) {
        await messageRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error: 'missingOrInvalidPhone',
          }),
        );
        return;
      }

      const accessToken = readNonEmptyString(whatsappAccessToken.value());
      const phoneNumberId = readNonEmptyString(whatsappPhoneNumberId.value());
      if (!accessToken || !phoneNumberId) {
        await messageRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error:
              'WhatsApp secrets not configured (WHATSAPP_ACCESS_TOKEN / WHATSAPP_PHONE_NUMBER_ID)',
          }),
        );
        return;
      }

      const templateName =
        readNonEmptyString(data.templateName) ?? DEFAULT_TEMPLATE_NAME;
      const languageCode =
        readNonEmptyString(data.languageCode) ?? DEFAULT_TEMPLATE_LANGUAGE;
      const bodyParameters = Array.isArray(data.bodyParameters)
        ? data.bodyParameters
        : [];
      const apiVersion = readNonEmptyString(data.apiVersion);

      const payload = buildTemplatePayload({
        to,
        templateName,
        languageCode,
        bodyParameters,
      });

      try {
        const info = await sendWhatsAppTemplate(
          accessToken,
          phoneNumberId,
          payload,
          apiVersion,
        );
        await messageRef.update(
          buildDeliveryUpdate('SUCCESS', {
            startTime,
            info: {
              ...info,
              templateName,
              languageCode,
              to,
            },
          }),
        );
        console.log('sendWhatsAppOnCreate success', {
          messageId: messageRef.id,
          to,
          templateName,
          languageCode,
        });
      } catch (error) {
        console.error('sendWhatsAppOnCreate error', error);
        await messageRef.update(
          buildDeliveryUpdate('ERROR', {
            startTime,
            error: error?.message ?? String(error),
            info: {
              templateName,
              languageCode,
              to,
              apiBody: error?.body ?? null,
            },
          }),
        );
      }
    },
  );
}

/**
 * Meta webhook verification + inbound event sink (required for App Review).
 * GET: hub.mode / hub.verify_token / hub.challenge
 * POST: acknowledges delivery/status webhooks (stored lightly for debugging).
 */
function createWhatsAppWebhook() {
  return onRequest(
    {
      region: REGION,
      secrets: [whatsappVerifyToken],
      invoker: 'public',
    },
    async (req, res) => {
      if (req.method === 'GET') {
        const mode = readNonEmptyString(req.query['hub.mode']);
        const token = readNonEmptyString(req.query['hub.verify_token']);
        const challenge = readNonEmptyString(req.query['hub.challenge']);
        const expected = readNonEmptyString(whatsappVerifyToken.value());

        if (mode === 'subscribe' && token && expected && token === expected) {
          res.status(200).send(challenge ?? '');
          return;
        }
        res.status(403).send('Forbidden');
        return;
      }

      if (req.method === 'POST') {
        try {
          const db = getFirestore();
          await db.collection('whatsapp_webhook_events').add({
            receivedAt: FieldValue.serverTimestamp(),
            body: req.body ?? null,
          });
        } catch (error) {
          console.error('whatsappWebhook store failed', error);
        }
        res.status(200).json({ success: true });
        return;
      }

      res.status(405).send('Method Not Allowed');
    },
  );
}

module.exports = {
  createSendWhatsAppOnCreate,
  createWhatsAppWebhook,
  buildTemplatePayload,
  digitsOnlyPhone,
  whatsappAccessToken,
  whatsappPhoneNumberId,
  whatsappVerifyToken,
};
