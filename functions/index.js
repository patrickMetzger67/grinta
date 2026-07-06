const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { buildSystemPrompt } = require('./ask_diego_prompt');
const { GEMINI_CHAT_MODEL } = require('./gemini_chat_config');

const geminiApiKey = defineSecret('GEMINI_API_KEY');

/**
 * Callable: chatWithGemini
 *
 * Request: { message, history?, context?, locale? }
 * Response: { actions: [{ type, text?, route?, params? }] }
 *
 * Deploy:
 *   firebase functions:secrets:set GEMINI_API_KEY
 *   firebase deploy --only functions:chatWithGemini
 */
exports.chatWithGemini = onCall(
  {
    region: 'europe-west1',
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const message = (request.data?.message ?? '').toString().trim();
    if (!message) {
      throw new HttpsError('invalid-argument', 'message is required.');
    }

    const history = Array.isArray(request.data?.history)
      ? request.data.history
      : [];
    const context = request.data?.context ?? {};
    const locale = (request.data?.locale ?? 'fr').toString();

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        'failed-precondition',
        'GEMINI_API_KEY secret is not configured.',
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: GEMINI_CHAT_MODEL,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: 'application/json',
      },
      systemInstruction: buildSystemPrompt(),
    });

    const contextBlock = JSON.stringify(
      {
        userId: request.auth.uid,
        locale,
        ...context,
      },
      null,
      2,
    );

    const historyLines = history
      .slice(-10)
      .map((entry) => {
        const role = entry?.role === 'assistant' ? 'Assistant' : 'Utilisateur';
        const text = (entry?.text ?? '').toString().trim();
        return text ? `${role}: ${text}` : null;
      })
      .filter(Boolean)
      .join('\n');

    const prompt = [
      'Contexte application (JSON):',
      contextBlock,
      historyLines ? `\nHistorique récent:\n${historyLines}` : '',
      `\nQuestion utilisateur: ${message}`,
      '\nRéponds avec le JSON des actions.',
    ]
      .filter(Boolean)
      .join('\n');

    try {
      const result = await model.generateContent(prompt);
      const raw = result.response.text();
      const parsed = parseModelResponse(raw);

      return {
        actions: normalizeActions(parsed.actions),
      };
    } catch (error) {
      console.error('chatWithGemini error', error);
      throw new HttpsError(
        'internal',
        'Gemini request failed.',
        error?.message ?? String(error),
      );
    }
  },
);

function parseModelResponse(raw) {
  const trimmed = (raw ?? '').toString().trim();
  if (!trimmed) {
    return { actions: [] };
  }

  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const jsonMatch = trimmed.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return {
      actions: [{ type: 'answer', text: trimmed }],
    };
  }
}

function normalizeActions(actions) {
  if (!Array.isArray(actions) || actions.length === 0) {
    return [
      {
        type: 'answer',
        text: 'Je n\'ai pas pu formuler de réponse. Réessayez.',
      },
    ];
  }

  const normalized = [];

  for (const action of actions) {
    if (!action || typeof action !== 'object') continue;

    const type = (action.type ?? '').toString().toLowerCase();

    if (type === 'answer') {
      const text = (action.text ?? '').toString().trim();
      if (text) {
        normalized.push({ type: 'answer', text });
      }
      continue;
    }

    if (type === 'navigate') {
      const route = (action.route ?? '').toString().trim();
      if (!route) continue;
      const params =
        action.params && typeof action.params === 'object'
          ? action.params
          : {};
      normalized.push({ type: 'navigate', route, params });
    }
  }

  if (!normalized.some((a) => a.type === 'answer')) {
    normalized.unshift({
      type: 'answer',
      text: 'Voici ce que je peux vous proposer.',
    });
  }

  return normalized;
}
