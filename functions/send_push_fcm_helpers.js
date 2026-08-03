/** Grinta PWA icons (Firebase Hosting site `grinta`). */
const GRINTA_ICON_192 = 'https://grinta.web.app/icons/Icon-192.png';
const GRINTA_ICON_512 = 'https://grinta.web.app/icons/Icon-512.png';

/**
 * Aserstein legacy defaults (shared Firebase project). Prefer explicit
 * `data.icon` / Storage URLs when Aserstein callers need a different asset.
 */
const ASERSTEIN_ICON = 'https://aserstein-2453e.web.app/favicon.png';

const BRAND_GRINTA = 'grinta';
const BRAND_ASERSTEIN = 'aserstein';

function readNonEmptyString(value) {
  const trimmed = (value ?? '').toString().trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeTokenList(raw) {
  if (!Array.isArray(raw)) return [];
  return [
    ...new Set(
      raw
        .map((token) => (token ?? '').toString().trim())
        .filter((token) => token.length > 0),
    ),
  ];
}

/**
 * Resolve push brand. Grinta app always sends `brand: "grinta"` and uses
 * platform clubId `"0"`. Prefer explicit brand; fall back to clubId `"0"` →
 * Grinta so clubId-only callers stay on Grinta icons.
 */
function resolveBrand(rawBrand, clubId) {
  const brand = (rawBrand ?? '').toString().trim().toLowerCase();
  if (brand === BRAND_GRINTA || brand === BRAND_ASERSTEIN) {
    return brand;
  }
  // Unknown / missing brand: Grinta platform club → grinta, else grinta default
  // (Grinta owns this CF; never fall through to a free-form brand string).
  if (clubId === '0' || !brand) {
    return BRAND_GRINTA;
  }
  return BRAND_GRINTA;
}

function isGrintaAssetUrl(url) {
  if (!url) return false;
  const lower = url.toLowerCase();
  if (lower.includes('aserstein') || lower.endsWith('/favicon.png')) {
    return false;
  }
  return (
    lower.includes('grinta.web.app/icons/') ||
    (lower.includes('logoclubs') && lower.includes('grinta')) ||
    lower.includes('/icons/icon-')
  );
}

function resolveBrandAssets(brand, overrides = {}) {
  const overrideIcon = readNonEmptyString(overrides.icon);
  const overrideImage = readNonEmptyString(overrides.image);

  if (brand === BRAND_ASERSTEIN) {
    return {
      icon: overrideIcon ?? ASERSTEIN_ICON,
      image: overrideImage ?? ASERSTEIN_ICON,
    };
  }
  return {
    // Grinta: ignore non-Grinta overrides that might leak Aserstein favicons.
    icon: isGrintaAssetUrl(overrideIcon) ? overrideIcon : GRINTA_ICON_192,
    image: isGrintaAssetUrl(overrideImage) ? overrideImage : GRINTA_ICON_512,
  };
}

/** FCM `data` values must be strings. */
function stringifyDataValue(value) {
  if (value == null) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  try {
    return JSON.stringify(value);
  } catch (_) {
    return String(value);
  }
}

function buildDataPayload({
  type,
  payload,
  brand,
  icon,
  image,
  title,
  body,
  clubId,
}) {
  const data = {
    brand,
    icon,
    image,
    clubId,
  };

  if (title) data.title = title;
  if (body) data.body = body;
  if (type) data.type = type;

  if (payload && typeof payload === 'object' && !Array.isArray(payload)) {
    for (const [key, value] of Object.entries(payload)) {
      const asString = stringifyDataValue(value);
      if (asString == null) continue;
      // Do not let nested payload overwrite brand icons with legacy Aserstein URLs.
      if (key === 'icon' || key === 'image' || key === 'brand') continue;
      data[key] = asString;
    }
  }

  if (type) data.type = type;

  return data;
}

function isInvalidTokenError(error) {
  const code = (error?.code ?? '').toString();
  return (
    code.includes('registration-token-not-registered') ||
    code.includes('invalid-registration-token') ||
    code.includes('invalid-argument')
  );
}

module.exports = {
  readNonEmptyString,
  normalizeTokenList,
  resolveBrand,
  resolveBrandAssets,
  isGrintaAssetUrl,
  buildDataPayload,
  isInvalidTokenError,
  BRAND_GRINTA,
  BRAND_ASERSTEIN,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
  ASERSTEIN_ICON,
};
