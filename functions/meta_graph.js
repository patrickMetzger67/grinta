const { defineSecret } = require('firebase-functions/params');

/**
 * Meta Graph helpers (Instagram + Facebook Page only).
 *
 * Snapchat: out of scope — no official insights API for this product slice.
 * WhatsApp stays on the native share sheet (no Graph media id, no insights).
 */

const metaAppId = defineSecret('META_APP_ID');
const metaAppSecret = defineSecret('META_APP_SECRET');

const GRAPH_API_VERSION = (process.env.META_GRAPH_VERSION || 'v21.0').trim();
const GRAPH_BASE = `https://graph.facebook.com/${GRAPH_API_VERSION}`;
const FACEBOOK_DIALOG_URL = `https://www.facebook.com/${GRAPH_API_VERSION}/dialog/oauth`;

const META_SCOPES = [
  'pages_show_list',
  'pages_read_engagement',
  'pages_manage_posts',
  'instagram_basic',
  'instagram_content_publish',
  'instagram_manage_insights',
  'business_management',
].join(',');

const IG_INSIGHTS_METRICS = 'impressions,reach,total_interactions';
const IG_INSIGHTS_METRICS_FALLBACK = 'views,reach,total_interactions';
const FB_INSIGHTS_METRICS =
  'post_impressions,post_impressions_unique,post_engaged_users';

const INTEGRATIONS_COLLECTION = 'meta_integrations';
const PENDING_COLLECTION = 'meta_oauth_pending';
const META_SYNC_COLLECTION = 'metaSync';
const META_SYNC_DOC_ID = 'account';

/**
 * App id/secret from env (Firebase secrets are injected as env vars when bound).
 * Do not invent credentials — leave empty until META_APP_ID / META_APP_SECRET
 * are set in Functions config.
 */
function readMetaAppCredentials() {
  const appId = (process.env.META_APP_ID || '').toString().trim();
  const appSecret = (process.env.META_APP_SECRET || '').toString().trim();
  return { appId, appSecret };
}

/**
 * Real Graph media / post ids only — not iOS/Android share-sheet activity types.
 * IG media ids are numeric; FB feed posts are usually `{pageId}_{postId}`.
 */
function looksLikeMetaPlatformShareId(platformShareId, where) {
  const id = (platformShareId ?? '').toString().trim();
  const network = (where ?? '').toString().trim().toLowerCase();
  if (!id) return false;
  if (network === 'whatsapp' || network === 'snapchat') return false;
  // Share-sheet activity ids contain letters / dots (e.g. com.burbn.instagram…).
  if (/[a-zA-Z.]/.test(id) && !/^\d+_\d+$/.test(id)) return false;
  if (network === 'instagram') return /^\d{10,}$/.test(id);
  if (network === 'facebook') {
    return /^\d+_\d+$/.test(id) || /^\d{10,}$/.test(id);
  }
  return false;
}

function buildInstagramInsightsRequest(mediaId, accessToken, metrics) {
  const params = new URLSearchParams({
    metric: metrics || IG_INSIGHTS_METRICS,
    access_token: accessToken,
  });
  return {
    method: 'GET',
    url: `${GRAPH_BASE}/${encodeURIComponent(mediaId)}/insights?${params}`,
  };
}

function buildFacebookInsightsRequest(postId, accessToken) {
  const params = new URLSearchParams({
    metric: FB_INSIGHTS_METRICS,
    access_token: accessToken,
  });
  return {
    method: 'GET',
    url: `${GRAPH_BASE}/${encodeURIComponent(postId)}/insights?${params}`,
  };
}

function metricValue(entry) {
  const values = Array.isArray(entry?.values) ? entry.values : [];
  const last = values.length ? values[values.length - 1] : null;
  const raw = last?.value ?? entry?.value ?? 0;
  const n = Number(raw);
  return Number.isFinite(n) ? n : 0;
}

/**
 * Map Graph insights payload → views / interactions.
 */
function parseGraphInsights(payload, where) {
  const rows = Array.isArray(payload?.data) ? payload.data : [];
  const byName = new Map();
  for (const row of rows) {
    const name = (row?.name ?? '').toString();
    if (name) byName.set(name, metricValue(row));
  }

  const network = (where ?? '').toString().trim().toLowerCase();
  if (network === 'instagram') {
    const views = Math.max(
      byName.get('impressions') ?? 0,
      byName.get('views') ?? 0,
      byName.get('reach') ?? 0,
    );
    const interactions = Math.max(
      byName.get('total_interactions') ?? 0,
      byName.get('engagement') ?? 0,
    );
    return { views, interactions };
  }

  const views = Math.max(
    byName.get('post_impressions') ?? 0,
    byName.get('post_impressions_unique') ?? 0,
  );
  const interactions = byName.get('post_engaged_users') ?? 0;
  return { views, interactions };
}

function graphErrorMessage(payload, status) {
  const fromGraph = payload?.error?.message ?? payload?.error?.error_user_msg;
  if (fromGraph) return String(fromGraph);
  return `Meta Graph request failed (${status}).`;
}

async function graphGetJson(url, fetchImpl = fetch) {
  const response = await fetchImpl(url, { method: 'GET' });
  const raw = await response.text();
  let parsed = null;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch {
    parsed = null;
  }
  return { ok: response.ok, status: response.status, parsed, raw };
}

/**
 * Fetch impressions/reach + engagement for a Meta media/post id.
 *
 * Uses the user's stored Page token. App id/secret are only needed to refresh
 * an expired user token (TODO if META_APP_ID / META_APP_SECRET are unset).
 *
 * @returns {{ views: number, interactions: number, postUrl: string|null, skipped: boolean, error?: string }}
 */
async function fetchMetaGraphInsights(share, options = {}) {
  const platformShareId = (share.platformShareId ?? '').toString().trim();
  const where = (share.where ?? '').toString().trim().toLowerCase();
  const fetchImpl = options.fetchImpl || fetch;
  const pageToken = (options.pageAccessToken ?? '').toString().trim();

  if (!looksLikeMetaPlatformShareId(platformShareId, where)) {
    return {
      views: Number(share.views ?? 0),
      interactions: Number(share.interactions ?? 0),
      postUrl: share.postUrl || null,
      skipped: true,
    };
  }

  if (!pageToken) {
    // Real request shape is still built so tests can assert it.
    const preview =
      where === 'facebook'
        ? buildFacebookInsightsRequest(platformShareId, 'PAGE_ACCESS_TOKEN')
        : buildInstagramInsightsRequest(platformShareId, 'PAGE_ACCESS_TOKEN');
    return {
      views: Number(share.views ?? 0),
      interactions: Number(share.interactions ?? 0),
      postUrl: share.postUrl || null,
      skipped: true,
      error:
        'TODO: no stored Page token — user must connect Instagram/Facebook OAuth. ' +
        `Would GET ${preview.url.replace('PAGE_ACCESS_TOKEN', '{token}')}`,
    };
  }

  const primary =
    where === 'facebook'
      ? buildFacebookInsightsRequest(platformShareId, pageToken)
      : buildInstagramInsightsRequest(platformShareId, pageToken);
  let result = await graphGetJson(primary.url, fetchImpl);

  if (
    !result.ok &&
    where === 'instagram' &&
    /metric/i.test(result.parsed?.error?.message ?? result.raw ?? '')
  ) {
    const fallback = buildInstagramInsightsRequest(
      platformShareId,
      pageToken,
      IG_INSIGHTS_METRICS_FALLBACK,
    );
    result = await graphGetJson(fallback.url, fetchImpl);
  }

  if (!result.ok) {
    return {
      views: Number(share.views ?? 0),
      interactions: Number(share.interactions ?? 0),
      postUrl: share.postUrl || null,
      skipped: true,
      error: graphErrorMessage(result.parsed, result.status),
    };
  }

  const parsed = parseGraphInsights(result.parsed, where);
  return {
    views: parsed.views,
    interactions: parsed.interactions,
    postUrl: share.postUrl || null,
    skipped: false,
  };
}

async function refreshLongLivedUserToken(userToken, fetchImpl = fetch) {
  const { appId, appSecret } = readMetaAppCredentials();
  if (!appId || !appSecret) {
    return {
      accessToken: userToken,
      refreshed: false,
      error:
        'TODO: set META_APP_ID and META_APP_SECRET (env / Firebase secrets) to refresh tokens.',
    };
  }

  const params = new URLSearchParams({
    grant_type: 'fb_exchange_token',
    client_id: appId,
    client_secret: appSecret,
    fb_exchange_token: userToken,
  });
  const url = `${GRAPH_BASE}/oauth/access_token?${params}`;
  const result = await graphGetJson(url, fetchImpl);
  const accessToken = (result.parsed?.access_token ?? '').toString().trim();
  if (!result.ok || !accessToken) {
    return {
      accessToken: userToken,
      refreshed: false,
      error: graphErrorMessage(result.parsed, result.status),
    };
  }
  return {
    accessToken,
    refreshed: true,
    expiresIn: Number(result.parsed?.expires_in ?? 0) || null,
  };
}

module.exports = {
  metaAppId,
  metaAppSecret,
  GRAPH_API_VERSION,
  GRAPH_BASE,
  FACEBOOK_DIALOG_URL,
  META_SCOPES,
  IG_INSIGHTS_METRICS,
  IG_INSIGHTS_METRICS_FALLBACK,
  FB_INSIGHTS_METRICS,
  INTEGRATIONS_COLLECTION,
  PENDING_COLLECTION,
  META_SYNC_COLLECTION,
  META_SYNC_DOC_ID,
  readMetaAppCredentials,
  looksLikeMetaPlatformShareId,
  buildInstagramInsightsRequest,
  buildFacebookInsightsRequest,
  parseGraphInsights,
  fetchMetaGraphInsights,
  refreshLongLivedUserToken,
  graphGetJson,
};
