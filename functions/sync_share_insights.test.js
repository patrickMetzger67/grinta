const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  fetchShareInsightsPlaceholder,
  computeInsightsDelta,
  POINTS_PER_VIEW,
  POINTS_PER_INTERACTION,
} = require('./sync_share_insights');

describe('fetchShareInsightsPlaceholder', () => {
  it('skips when no platform id or post URL', () => {
    const result = fetchShareInsightsPlaceholder({ where: 'whatsapp' });
    assert.equal(result.skipped, true);
    assert.equal(result.views, 0);
    assert.equal(result.interactions, 0);
  });

  it('does not invent counts when an id exists', () => {
    const result = fetchShareInsightsPlaceholder({
      platformShareId: 'net.whatsapp.WhatsApp.ShareExtension',
      views: 3,
      interactions: 1,
    });
    assert.equal(result.skipped, true);
    assert.equal(result.views, 3);
    assert.equal(result.interactions, 1);
  });
});

describe('computeInsightsDelta', () => {
  it('computes non-negative deltas and point increments', () => {
    const delta = computeInsightsDelta(
      { views: 2, interactions: 1 },
      { views: 10, interactions: 4, postUrl: 'https://example.test/p' },
    );
    assert.equal(delta.viewDelta, 8);
    assert.equal(delta.interactionDelta, 3);
    assert.equal(delta.viewPointsDelta, 8 * POINTS_PER_VIEW);
    assert.equal(delta.interactionPointsDelta, 3 * POINTS_PER_INTERACTION);
    assert.equal(delta.postUrl, 'https://example.test/p');
  });

  it('never decreases stored counts', () => {
    const delta = computeInsightsDelta(
      { views: 5, interactions: 2 },
      { views: 1, interactions: 0 },
    );
    assert.equal(delta.views, 5);
    assert.equal(delta.interactions, 2);
    assert.equal(delta.viewDelta, 0);
    assert.equal(delta.interactionDelta, 0);
  });
});
