const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');
const {
  readNonEmptyString,
  normalizeTokenList,
  normalizeUserIdList,
  filterTokensByRecipientPreferences,
  resolveBrand,
  resolveBrandAssets,
  BRAND_GRINTA,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
} = require('./send_push_fcm_helpers');
const {
  enqueueQuietDeferredPushes,
  sendFcmToTokens,
} = require('./pending_push');

const REGION = 'europe-west1';

/**
 * Callable: sendPushFCMNotification (europe-west1)
 *
 * Recipient prefs (`users/{uid}/app_state/notification_preferences`):
 * - remindersEnabled === false → skip (no queue)
 * - quiet days / quiet hours → enqueue `pending_push` until sendAfter
 *
 * Deploy:
 *   firebase deploy --only functions:sendPushFCMNotification,functions:drainPendingPushNotifications
 */
function createSendPushFCMNotification() {
  return onCall({ region: REGION, timeoutSeconds: 60 }, async (request) => {
    const data = request.data ?? {};
    const db = getFirestore();

    const requestedTokens = normalizeTokenList(data.fcmTokens);
    const recipientUserIds = normalizeUserIdList(
      data.recipientUserIds ?? data.userIds,
    );

    if (requestedTokens.length === 0 && recipientUserIds.length === 0) {
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

    const filtered = await filterTokensByRecipientPreferences({
      db,
      recipientUserIds,
      fcmTokens: requestedTokens,
      brand,
    });

    const deferredCount = await enqueueQuietDeferredPushes({
      db,
      quietDeferred: filtered.quietDeferred ?? [],
      clubId,
      brand,
      title,
      body,
      type,
      payload: data.payload,
      icon: assets.icon,
      image: assets.image,
    });

    const fcmTokens = filtered.tokens;
    if (fcmTokens.length === 0) {
      console.log(
        '[sendPushFCMNotification] no immediate tokens',
        JSON.stringify({
          brand,
          clubId,
          type,
          requested: requestedTokens.length,
          recipients: recipientUserIds.length,
          skippedDisabled: filtered.skippedDisabled,
          skippedQuiet: filtered.skippedQuiet,
          deferredCount,
        }),
      );
      return {
        success: true,
        summary: {
          total: 0,
          successCount: 0,
          failureCount: 0,
          invalidTokensCount: 0,
          invalidTokens: [],
          skippedDisabled: filtered.skippedDisabled,
          skippedQuiet: filtered.skippedQuiet,
          skippedUserIds: filtered.skippedUserIds,
          deferredCount,
        },
      };
    }

    try {
      const result = await sendFcmToTokens({
        tokens: fcmTokens,
        title,
        body,
        type,
        payload: data.payload,
        brand,
        clubId,
        icon: assets.icon,
        image: assets.image,
      });

      console.log(
        '[sendPushFCMNotification]',
        JSON.stringify({
          brand,
          clubId,
          type,
          total: result.total,
          successCount: result.successCount,
          failureCount: result.failureCount,
          invalidTokensCount: result.invalidTokens.length,
          skippedDisabled: filtered.skippedDisabled,
          skippedQuiet: filtered.skippedQuiet,
          deferredCount,
        }),
      );

      return {
        success: true,
        summary: {
          total: result.total,
          successCount: result.successCount,
          failureCount: result.failureCount,
          invalidTokensCount: result.invalidTokens.length,
          invalidTokens: result.invalidTokens,
          skippedDisabled: filtered.skippedDisabled,
          skippedQuiet: filtered.skippedQuiet,
          skippedUserIds: filtered.skippedUserIds,
          deferredCount,
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
  resolveBrand,
  resolveBrandAssets,
  normalizeTokenList,
  BRAND_GRINTA,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
};
