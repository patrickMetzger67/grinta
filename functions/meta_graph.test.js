const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  looksLikeMetaPlatformShareId,
  buildInstagramInsightsRequest,
  buildFacebookInsightsRequest,
  parseGraphInsights,
  fetchMetaGraphInsights,
  GRAPH_API_VERSION,
  IG_INSIGHTS_METRICS,
  FB_INSIGHTS_METRICS,
} = require('./meta_graph');
const { fetchShareInsights } = require('./sync_share_insights');

describe('looksLikeMetaPlatformShareId', () => {
  it('accepts Instagram numeric media ids', () => {
    assert.equal(looksLikeMetaPlatformShareId('17841405309211844', 'instagram'), true);
  });

  it('accepts Facebook page_post ids', () => {
    assert.equal(looksLikeMetaPlatformShareId('123456789_987654321', 'facebook'), true);
  });

  it('rejects share-sheet activity types', () => {
    assert.equal(
      looksLikeMetaPlatformShareId('com.burbn.instagram.shareextension', 'instagram'),
      false,
    );
    assert.equal(
      looksLikeMetaPlatformShareId('net.whatsapp.WhatsApp.ShareExtension', 'whatsapp'),
      false,
    );
    assert.equal(
      looksLikeMetaPlatformShareId('com.toyopagroup.picaboo.share', 'snapchat'),
      false,
    );
  });
});

describe('Graph insights request shape', () => {
  it('builds Instagram insights GET with metrics + token placeholder', () => {
    const req = buildInstagramInsightsRequest('17841405309211844', 'PAGE_ACCESS_TOKEN');
    assert.equal(req.method, 'GET');
    assert.match(req.url, new RegExp(`/graph\\.facebook\\.com/${GRAPH_API_VERSION}/`));
    assert.match(req.url, /17841405309211844\/insights/);
    assert.match(req.url, new RegExp(`metric=${IG_INSIGHTS_METRICS.replace(/,/g, '%2C')}`));
    assert.match(req.url, /access_token=PAGE_ACCESS_TOKEN/);
  });

  it('builds Facebook insights GET', () => {
    const req = buildFacebookInsightsRequest('123_456', 'PAGE_ACCESS_TOKEN');
    assert.equal(req.method, 'GET');
    assert.match(req.url, /123_456\/insights/);
    assert.match(req.url, new RegExp(`metric=${FB_INSIGHTS_METRICS.replace(/,/g, '%2C')}`));
  });
});

describe('parseGraphInsights', () => {
  it('reads IG impressions and total_interactions', () => {
    const parsed = parseGraphInsights(
      {
        data: [
          { name: 'impressions', values: [{ value: 40 }] },
          { name: 'reach', values: [{ value: 22 }] },
          { name: 'total_interactions', values: [{ value: 5 }] },
        ],
      },
      'instagram',
    );
    assert.equal(parsed.views, 40);
    assert.equal(parsed.interactions, 5);
  });

  it('reads Facebook post impressions and engaged users', () => {
    const parsed = parseGraphInsights(
      {
        data: [
          { name: 'post_impressions', values: [{ value: 12 }] },
          { name: 'post_engaged_users', values: [{ value: 3 }] },
        ],
      },
      'facebook',
    );
    assert.equal(parsed.views, 12);
    assert.equal(parsed.interactions, 3);
  });
});

describe('fetchMetaGraphInsights', () => {
  it('skips with a TODO when token is missing but documents the request', async () => {
    const result = await fetchMetaGraphInsights({
      where: 'instagram',
      platformShareId: '17841405309211844',
      views: 1,
      interactions: 0,
    });
    assert.equal(result.skipped, true);
    assert.match(result.error ?? '', /TODO/);
    assert.match(result.error ?? '', /insights/);
  });

  it('calls Graph with the stored page token', async () => {
    let calledUrl = '';
    const fetchImpl = async (url) => {
      calledUrl = url;
      return {
        ok: true,
        status: 200,
        text: async () =>
          JSON.stringify({
            data: [
              { name: 'impressions', values: [{ value: 9 }] },
              { name: 'total_interactions', values: [{ value: 2 }] },
            ],
          }),
      };
    };
    const result = await fetchMetaGraphInsights(
      { where: 'instagram', platformShareId: '17841405309211844' },
      { pageAccessToken: 'tok_test', fetchImpl },
    );
    assert.equal(result.skipped, false);
    assert.equal(result.views, 9);
    assert.equal(result.interactions, 2);
    assert.match(calledUrl, /access_token=tok_test/);
  });
});

describe('fetchShareInsights routing', () => {
  it('does not call Graph for WhatsApp share-sheet ids', async () => {
    let called = false;
    const result = await fetchShareInsights(
      {
        where: 'whatsapp',
        platformShareId: 'net.whatsapp.WhatsApp.ShareExtension',
        views: 0,
        interactions: 0,
      },
      {
        fetchImpl: async () => {
          called = true;
          return { ok: true, status: 200, text: async () => '{}' };
        },
      },
    );
    assert.equal(called, false);
    assert.equal(result.skipped, true);
  });
});
