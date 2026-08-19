const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore } = require('firebase-admin/firestore');
const {
  readNonEmptyString,
  hasPremiumFromUserData,
  hasActiveRevenueCatEntitlements,
  sanitizeGroupName,
  sanitizeAvatarColor,
  sanitizeImageUrl,
  sanitizeChannelId,
  newGroupChannelId,
  buildGroupExtraData,
  isGrintaUserGroup,
  isGroupCreator,
  resolveStreamApiKey,
  streamRequest,
  channelPath,
  MAX_MEMBERS,
} = require('./chat_group_helpers');

const REGION = 'europe-west1';
const REVENUECAT_API_BASE = 'https://api.revenuecat.com/v1';

const streamApiSecret = defineSecret('STREAM_API_SECRET');
const revenueCatApiKey = defineSecret('REVENUECAT_API_KEY');

function requireAuth(request) {
  const uid = readNonEmptyString(request.auth?.uid);
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Non connecté');
  }
  return uid;
}

function requireStreamSecret() {
  const secret = readNonEmptyString(streamApiSecret.value());
  if (!secret) {
    throw new HttpsError(
      'failed-precondition',
      'Configuration Stream manquante',
    );
  }
  return {
    apiKey: resolveStreamApiKey(process.env.STREAM_API_KEY),
    apiSecret: secret,
  };
}

function mapStreamError(error) {
  const status = error?.status;
  if (status === 404) {
    return new HttpsError('not-found', 'Groupe introuvable');
  }
  if (status === 403 || status === 401) {
    return new HttpsError('permission-denied', 'Accès Stream refusé');
  }
  return new HttpsError(
    'internal',
    error?.message || 'Erreur Stream lors de la gestion du groupe',
  );
}

async function hasRevenueCatAccess(uid) {
  const apiKey = readNonEmptyString(revenueCatApiKey.value());
  if (!apiKey) return false;
  try {
    const response = await fetch(
      `${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(uid)}`,
      { headers: { Authorization: `Bearer ${apiKey}` } },
    );
    if (!response.ok) return false;
    const json = await response.json();
    return hasActiveRevenueCatEntitlements(json?.subscriber);
  } catch (error) {
    console.error('createChatGroup: RevenueCat lookup failed', {
      uid,
      error: error?.message ?? String(error),
    });
    return false;
  }
}

async function assertPremiumAccess(db, uid) {
  const snap = await db.collection('users').doc(uid).get();
  if (hasPremiumFromUserData(snap.data() ?? {})) return;
  if (await hasRevenueCatAccess(uid)) return;
  throw new HttpsError(
    'permission-denied',
    'Vous devez être abonné pour créer un groupe.',
  );
}

async function loadGroupChannel(stream, channelId) {
  try {
    const state = await streamRequest({
      ...stream,
      method: 'POST',
      path: channelPath(channelId, '/query'),
      body: { state: true, watch: false, presence: false },
    });
    const data = state.channel ?? {};
    if (!isGrintaUserGroup(data)) {
      throw new HttpsError(
        'permission-denied',
        'Ce n’est pas un groupe Messagerie',
      );
    }
    return data;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw mapStreamError(error);
  }
}

function assertCreator(channelData, uid) {
  if (!isGroupCreator(channelData, uid)) {
    throw new HttpsError(
      'permission-denied',
      'Seul le créateur peut modifier ce groupe',
    );
  }
}

function requireChannelId(data) {
  const channelId =
    sanitizeChannelId(data?.channelId) ||
    sanitizeChannelId(data?.id);
  if (!channelId) {
    throw new HttpsError('invalid-argument', 'Identifiant de groupe manquant');
  }
  return channelId;
}

/**
 * Callable: createChatGroup
 *
 * Request: { name, memberIds?, avatarColorHex?, imageUrl?, channelId? }
 * Response: { channelId, cid }
 *
 * Secrets:
 *   firebase functions:secrets:set STREAM_API_SECRET
 *   firebase functions:secrets:set REVENUECAT_API_KEY
 */
function createCreateChatGroup() {
  return onCall(
    {
      region: REGION,
      secrets: [streamApiSecret, revenueCatApiKey],
      timeoutSeconds: 30,
    },
    async (request) => {
      const uid = requireAuth(request);
      const name = sanitizeGroupName(request.data?.name);
      if (!name) {
        throw new HttpsError('invalid-argument', 'Le nom du groupe est obligatoire.');
      }

      const db = getFirestore();
      await assertPremiumAccess(db, uid);

      const stream = requireStreamSecret();
      const channelId = sanitizeChannelId(request.data?.channelId) || newGroupChannelId();
      const extraData = buildGroupExtraData({
        name,
        memberIds: request.data?.memberIds,
        currentUserId: uid,
        avatarColorHex: sanitizeAvatarColor(request.data?.avatarColorHex),
        imageUrl: sanitizeImageUrl(request.data?.imageUrl),
      });

      try {
        await streamRequest({
          ...stream,
          method: 'POST',
          path: channelPath(channelId, '/query'),
          body: {
            data: extraData,
            state: true,
            watch: false,
            presence: false,
          },
        });
      } catch (error) {
        console.error('createChatGroup Stream error', {
          uid,
          channelId,
          error: error?.message ?? String(error),
          status: error?.status,
        });
        throw mapStreamError(error);
      }

      return {
        channelId,
        cid: `messaging:${channelId}`,
      };
    },
  );
}

/**
 * Callable: updateChatGroup
 *
 * Request: { channelId, name, avatarColorHex?, imageUrl?, clearImage? }
 */
function createUpdateChatGroup() {
  return onCall(
    {
      region: REGION,
      secrets: [streamApiSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      const uid = requireAuth(request);
      const channelId = requireChannelId(request.data);
      const name = sanitizeGroupName(request.data?.name);
      if (!name) {
        throw new HttpsError('invalid-argument', 'Le nom du groupe est obligatoire.');
      }

      const stream = requireStreamSecret();
      const channelData = await loadGroupChannel(stream, channelId);
      assertCreator(channelData, uid);

      const set = {
        name,
        grinta_group: true,
      };
      const color = sanitizeAvatarColor(request.data?.avatarColorHex);
      if (color) set.grinta_avatar_color = color;
      const imageUrl = sanitizeImageUrl(request.data?.imageUrl);
      if (imageUrl) set.image = imageUrl;
      const unset = [];
      if (request.data?.clearImage === true && !imageUrl) {
        unset.push('image');
      }

      try {
        await streamRequest({
          ...stream,
          method: 'PATCH',
          path: channelPath(channelId),
          body: {
            set,
            unset: unset.length > 0 ? unset : undefined,
          },
        });
      } catch (error) {
        throw mapStreamError(error);
      }

      return { channelId, cid: `messaging:${channelId}` };
    },
  );
}

/**
 * Callable: addChatGroupMember
 *
 * Request: { channelId, userId }
 */
function createAddChatGroupMember() {
  return onCall(
    {
      region: REGION,
      secrets: [streamApiSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      const uid = requireAuth(request);
      const channelId = requireChannelId(request.data);
      const userId = readNonEmptyString(request.data?.userId);
      if (!userId) {
        throw new HttpsError('invalid-argument', 'Identifiant membre manquant');
      }

      const stream = requireStreamSecret();
      const channelData = await loadGroupChannel(stream, channelId);
      assertCreator(channelData, uid);
      if ((channelData.member_count ?? 0) >= MAX_MEMBERS) {
        throw new HttpsError(
          'invalid-argument',
          'Nombre maximal de membres atteint',
        );
      }

      try {
        await streamRequest({
          ...stream,
          method: 'POST',
          path: channelPath(channelId),
          body: { add_members: [userId] },
        });
      } catch (error) {
        throw mapStreamError(error);
      }

      return { channelId, userId };
    },
  );
}

/**
 * Callable: removeChatGroupMember
 *
 * Request: { channelId, userId }
 */
function createRemoveChatGroupMember() {
  return onCall(
    {
      region: REGION,
      secrets: [streamApiSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      const uid = requireAuth(request);
      const channelId = requireChannelId(request.data);
      const userId = readNonEmptyString(request.data?.userId);
      if (!userId) {
        throw new HttpsError('invalid-argument', 'Identifiant membre manquant');
      }
      if (userId === uid) {
        throw new HttpsError(
          'failed-precondition',
          'Le créateur ne peut pas être retiré',
        );
      }

      const stream = requireStreamSecret();
      const channelData = await loadGroupChannel(stream, channelId);
      assertCreator(channelData, uid);
      if (userId === (channelData.grinta_created_by ?? uid)) {
        throw new HttpsError(
          'failed-precondition',
          'Le créateur ne peut pas être retiré',
        );
      }

      try {
        await streamRequest({
          ...stream,
          method: 'POST',
          path: channelPath(channelId),
          body: { remove_members: [userId] },
        });
      } catch (error) {
        throw mapStreamError(error);
      }

      return { channelId, userId };
    },
  );
}

/**
 * Callable: deleteChatGroup
 *
 * Request: { channelId }
 */
function createDeleteChatGroup() {
  return onCall(
    {
      region: REGION,
      secrets: [streamApiSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      const uid = requireAuth(request);
      const channelId = requireChannelId(request.data);
      const stream = requireStreamSecret();
      const channelData = await loadGroupChannel(stream, channelId);
      assertCreator(channelData, uid);

      try {
        await streamRequest({
          ...stream,
          method: 'DELETE',
          path: channelPath(channelId),
        });
      } catch (error) {
        throw mapStreamError(error);
      }

      return { channelId, deleted: true };
    },
  );
}

module.exports = {
  createCreateChatGroup,
  createUpdateChatGroup,
  createAddChatGroupMember,
  createRemoveChatGroupMember,
  createDeleteChatGroup,
};
