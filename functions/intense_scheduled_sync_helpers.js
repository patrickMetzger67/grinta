/**
 * Pure helpers for Intense scheduled auto-sync (no Firebase imports).
 * Shared by `intenseScheduledSync.js` and unit tests.
 */

/**
 * Same rule as the Flutter app (`ownerUsesIntenseCloudSync`):
 * Intense kits are cloud sync even when older docs omit `withSyncing`
 * (Owner.fromMap defaults that field to `true`).
 */
function ownerUsesIntenseCloudSync(ownerData) {
  const type = String(ownerData?.typeTracker ?? '').trim().toLowerCase();
  if (type === 'intense') return true;
  return ownerData?.withSyncing === false;
}

/**
 * Mirror in-app finish/resync: only mark `isTrackerDataUploaded` when every
 * attempted device ended as `ok` or `empty` (empty GNSS = treated as success).
 * Any `error` (or no targets) must leave the flag false so the next cron retry
 * can still recover data within the Insiders retention window.
 */
function shouldMarkIntenseEventUploaded(deviceResults) {
  if (!Array.isArray(deviceResults) || deviceResults.length === 0) {
    return false;
  }
  return deviceResults.every(
    (result) => result?.status === 'ok' || result?.status === 'empty',
  );
}

function summarizeDeviceResults(deviceResults) {
  const summary = { ok: 0, empty: 0, error: 0, other: 0 };
  for (const result of deviceResults ?? []) {
    const status = result?.status;
    if (status === 'ok') summary.ok += 1;
    else if (status === 'empty') summary.empty += 1;
    else if (status === 'error') summary.error += 1;
    else summary.other += 1;
  }
  return summary;
}

module.exports = {
  ownerUsesIntenseCloudSync,
  shouldMarkIntenseEventUploaded,
  summarizeDeviceResults,
};
