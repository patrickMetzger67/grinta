/**
 * Pure promo-code helpers (no Firebase). Used by redeemPromoCode and unit tests.
 *
 * Keep lookup tolerant: demos often type DEMO-2026 vs DEMO2026, or mixed case
 * document ids created outside the admin UI. Users also type a leading `#`
 * because the redeem field shows a tag icon.
 */

const CANONICAL_ENTITLEMENTS = new Set([
  'player',
  'player_gps',
  'coach_basic',
  'coach_elite',
  'coach_pro',
]);

/** RevenueCat / console / French display aliases → canonical Firestore / app ids. */
const ENTITLEMENT_ALIAS_TO_CANONICAL = new Map([
  ['player', 'player'],
  ['player_gps', 'player_gps'],
  ['playergps', 'player_gps'],
  ['player-gps', 'player_gps'],
  // Demo / admin docs sometimes store the promo code or French product name
  // as the entitlement field (JOUEURGPS) instead of player_gps.
  ['joueurgps', 'player_gps'],
  ['joueur_gps', 'player_gps'],
  ['joueur-gps', 'player_gps'],
  ['coach_basic', 'coach_basic'],
  ['coachbasic', 'coach_basic'],
  ['coach-basic', 'coach_basic'],
  ['coach_elite', 'coach_elite'],
  ['coachelite', 'coach_elite'],
  ['coach-elite', 'coach_elite'],
  ['coach_pro', 'coach_pro'],
  ['coachpro', 'coach_pro'],
  ['coach-pro', 'coach_pro'],
]);

/** Ids to try when granting a promotional entitlement via RevenueCat. */
const REVENUECAT_GRANT_IDS = {
  player_gps: ['player_gps', 'playerGPS', 'playerGps'],
};

function normalizePromoCode(raw) {
  return (raw ?? '')
    .toString()
    .trim()
    // Tag icon in the redeem UI often leads users to type "# JOUEURGPS".
    .replace(/^#+/, '')
    .trim()
    .toUpperCase()
    .replace(/\s+/g, '');
}

/** Compact form for tolerant matching (DEMO2026 == DEMO-2026). */
function compactPromoCode(normalized) {
  return normalizePromoCode(normalized).replace(/[-_.#]/g, '');
}

function promoCodeLookupCandidates(normalizedCode) {
  const upper = normalizePromoCode(normalizedCode);
  const lower = upper.toLowerCase();
  const compact = compactPromoCode(upper);
  return [
    ...new Set([upper, lower, compact, compact.toLowerCase()].filter(Boolean)),
  ];
}

/**
 * Whether a Firestore doc id / stored `code` matches the typed promo code.
 */
function promoCodesMatch(storedRaw, typedNormalized) {
  const stored = normalizePromoCode(storedRaw);
  if (!stored) return false;
  const typed = normalizePromoCode(typedNormalized);
  if (!typed) return false;
  if (stored === typed) return true;
  return compactPromoCode(stored) === compactPromoCode(typed);
}

/**
 * Map admin / console / RC entitlement strings to the canonical id used by
 * the app and VALID_ENTITLEMENTS. Returns null when unknown.
 *
 * Accepts `playerGPS` / `playerGps` / `JOUEURGPS` so a promo created against
 * RC dashboard naming or the French product label is not rejected as
 * PROMO_INVALID.
 */
function canonicalizePromoEntitlement(raw) {
  const value = (raw ?? '').toString().trim();
  if (!value) return null;
  if (CANONICAL_ENTITLEMENTS.has(value)) return value;

  const lower = value.toLowerCase();
  if (ENTITLEMENT_ALIAS_TO_CANONICAL.has(lower)) {
    return ENTITLEMENT_ALIAS_TO_CANONICAL.get(lower);
  }

  const compact = lower.replace(/[-_.\s]/g, '');
  if (ENTITLEMENT_ALIAS_TO_CANONICAL.has(compact)) {
    return ENTITLEMENT_ALIAS_TO_CANONICAL.get(compact);
  }

  return null;
}

/**
 * RevenueCat promotional grant path may use camelCase entitlement ids.
 * Always try the canonical id first, then known aliases.
 */
function revenueCatGrantEntitlementIds(canonicalEntitlement) {
  const canonical = canonicalizePromoEntitlement(canonicalEntitlement);
  if (!canonical) return [];
  const aliases = REVENUECAT_GRANT_IDS[canonical];
  if (!aliases) return [canonical];
  return [...new Set(aliases)];
}

/**
 * Merge existing subscriptionAccess.entitlements with a newly granted promo
 * entitlement. Always includes the granted id (canonical). Used so a
 * Joueur → Joueur GPS upgrade keeps `player` and adds `player_gps`.
 */
function mergePromoMirrorEntitlements(existingEntitlements, grantedEntitlement) {
  const granted = canonicalizePromoEntitlement(grantedEntitlement);
  if (!granted) return null;

  const merged = new Set();
  const list = Array.isArray(existingEntitlements) ? existingEntitlements : [];
  for (const entry of list) {
    const raw = (entry ?? '').toString().trim();
    if (!raw) continue;
    merged.add(canonicalizePromoEntitlement(raw) || raw);
  }
  merged.add(granted);
  return [...merged];
}

/**
 * Whether the mirror/list already includes the granted entitlement (aliases OK).
 * Used so ALREADY_REDEEMED only blocks when the upgrade is truly complete —
 * a prior redeem that left only `player` must not block attaching `player_gps`.
 */
function entitlementsIncludeGranted(existingEntitlements, grantedEntitlement) {
  const granted = canonicalizePromoEntitlement(grantedEntitlement);
  if (!granted) return false;
  const list = Array.isArray(existingEntitlements) ? existingEntitlements : [];
  return list.some(
    (entry) => canonicalizePromoEntitlement(entry) === granted,
  );
}

module.exports = {
  CANONICAL_ENTITLEMENTS,
  normalizePromoCode,
  compactPromoCode,
  promoCodeLookupCandidates,
  promoCodesMatch,
  canonicalizePromoEntitlement,
  revenueCatGrantEntitlementIds,
  mergePromoMirrorEntitlements,
  entitlementsIncludeGranted,
};
