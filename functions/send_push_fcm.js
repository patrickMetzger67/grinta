const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getMessaging } = require('firebase-admin/messaging');
const {
  readNonEmptyString,
  normalizeTokenList,
  resolveBrand,
  resolveBrandAssets,
  buildDataPayload,
  isInvalidTokenError,
  BRAND_GRINTA,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
} = require('./send_push_fcm_helpers');

const REGION = 'europe-west1';

/**
 * Callable: sendPushFCMNotification (europe-west1)
 *
 * Request:
 * {
 *   fcmTokens: string[],
 *   clubId: string,          // Grinta platform = "0"
 *   brand?: "grinta"|"aserstein",
 *   icon?: string,
 *   image?: string,
 *   title?: string,
 *   body?: string,
 *   type?: string,
 *   payload?: object
 * }
 *
 * Response:
 * {
 *   success: true,
 *   summary: { total, successCount, failureCount, invalidTokensCount, invalidTokens }
 * }
 *
 * Deploy:
 *   firebase deploy --only functions:sendPushFCMNotification
 */
function createSendPushFCMNotification() {
  return onCall({ region: REGION, timeoutSeconds: 60 }, async (request) => {
    const data = request.data ?? {};

    const fcmTokens = normalizeTokenList(data.fcmTokens);
    if (fcmTokens.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Liste de fcmTokens requise',
      );
    }

    const clubId = readNonEmptyString(data.clubId);
    if (!clubId) {
      throw new HttpsError('invalid-argument', 'clubId requis');
    }

    const title = readNonEmptyString(data.title) ?? '';
    const body = readNonEmptyString(data.body) ?? '';
    const type = readNonEmptyString(data.type) ?? '';
    const brand = resolveBrand(data.brand, clubId);
    const assets = resolveBrandAssets(brand, {
      icon: data.icon,
      image: data.image,
    });

    const dataPayload = buildDataPayload({
      type,
      payload: data.payload,
      brand,
      icon: assets.icon,
      image: assets.image,
      title,
      body,
      clubId,
    });

    const message = {
      tokens: fcmTokens,
      notification: {
        title: title || 'Grinta',
        body: body || '',
        ...(brand === BRAND_GRINTA ? { imageUrl: assets.image } : {}),
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          // Small tray icon stays the app drawable; large image is Grinta-branded.
          imageUrl: assets.image,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            'content-available': 1,
          },
        },
        fcmOptions: {
          imageUrl: assets.image,
        },
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
        notification: {
          title: title || 'Grinta',
          body: body || '',
          icon: assets.icon,
          image: assets.image,
        },
        fcmOptions: {
          link: '/',
        },
      },
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);

      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (resp.success) return;
        if (isInvalidTokenError(resp.error)) {
          invalidTokens.push(fcmTokens[idx]);
        }
      });

      console.log(
        '[sendPushFCMNotification]',
        JSON.stringify({
          brand,
          clubId,
          type,
          total: fcmTokens.length,
          successCount: response.successCount,
          failureCount: response.failureCount,
          invalidTokensCount: invalidTokens.length,
        }),
      );

      return {
        success: true,
        summary: {
          total: fcmTokens.length,
          successCount: response.successCount,
          failureCount: response.failureCount,
          invalidTokensCount: invalidTokens.length,
          invalidTokens,
        },
      };
    } catch (error) {
      console.error('sendPushFCMNotification error', error);
      throw new HttpsError(
        'internal',
        'Échec envoi FCM.',
        error?.message ?? String(error),
      );
    }
  });
}

module.exports = {
  createSendPushFCMNotification,
  // Re-export helpers for convenience / existing require paths.
  resolveBrand,
  resolveBrandAssets,
  normalizeTokenList,
  buildDataPayload,
  BRAND_GRINTA,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
};
