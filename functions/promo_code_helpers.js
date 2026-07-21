/**
 * Pure promo-code helpers (no Firebase). Used by redeemPromoCode and unit tests.
 *
 * Keep lookup tolerant: demos often type DEMO-2026 vs DEMO2026, or mixed case
 * document ids created outside the admin UI.
 */

function normalizePromoCode(raw) {
  return (raw ?? '').toString().trim().toUpperCase().replace(/\s+/g, '');
}

/** Compact form for tolerant matching (DEMO2026 == DEMO-2026). */
function compactPromoCode(normalized) {
  return normalizePromoCode(normalized).replace(/[-_.]/g, '');
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

module.exports = {
  normalizePromoCode,
  compactPromoCode,
  promoCodeLookupCandidates,
  promoCodesMatch,
};
