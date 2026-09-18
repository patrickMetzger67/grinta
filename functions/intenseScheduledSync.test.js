const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  ownerUsesIntenseCloudSync,
  shouldMarkIntenseEventUploaded,
  summarizeDeviceResults,
} = require('./intense_scheduled_sync_helpers');

describe('ownerUsesIntenseCloudSync', () => {
  it('treats typeTracker=intense as cloud even when withSyncing is missing/true', () => {
    assert.equal(ownerUsesIntenseCloudSync({ typeTracker: 'intense' }), true);
    assert.equal(
      ownerUsesIntenseCloudSync({ typeTracker: 'intense', withSyncing: true }),
      true,
    );
    assert.equal(
      ownerUsesIntenseCloudSync({ typeTracker: 'Intense', withSyncing: true }),
      true,
    );
  });

  it('treats withSyncing=false as cloud for other types', () => {
    assert.equal(
      ownerUsesIntenseCloudSync({ typeTracker: 'polar', withSyncing: false }),
      true,
    );
  });

  it('rejects USB / default syncing owners', () => {
    assert.equal(
      ownerUsesIntenseCloudSync({ typeTracker: 'inspirit', withSyncing: true }),
      false,
    );
    assert.equal(ownerUsesIntenseCloudSync({ typeTracker: 'polar' }), false);
    assert.equal(ownerUsesIntenseCloudSync({}), false);
  });
});

describe('shouldMarkIntenseEventUploaded', () => {
  it('requires at least one device result', () => {
    assert.equal(shouldMarkIntenseEventUploaded([]), false);
    assert.equal(shouldMarkIntenseEventUploaded(null), false);
    assert.equal(shouldMarkIntenseEventUploaded(undefined), false);
  });

  it('marks uploaded when every device is ok or empty (in-app parity)', () => {
    assert.equal(
      shouldMarkIntenseEventUploaded([{ status: 'ok' }, { status: 'empty' }]),
      true,
    );
    assert.equal(shouldMarkIntenseEventUploaded([{ status: 'empty' }]), true);
    assert.equal(shouldMarkIntenseEventUploaded([{ status: 'ok' }]), true);
  });

  it('does not mark uploaded when any device errored (retry next cron)', () => {
    assert.equal(
      shouldMarkIntenseEventUploaded([
        { status: 'ok' },
        { status: 'error', message: 'timeout' },
      ]),
      false,
    );
    assert.equal(
      shouldMarkIntenseEventUploaded([{ status: 'error' }]),
      false,
    );
  });
});

describe('summarizeDeviceResults', () => {
  it('counts ok/empty/error', () => {
    assert.deepEqual(
      summarizeDeviceResults([
        { status: 'ok' },
        { status: 'empty' },
        { status: 'error' },
        { status: 'weird' },
      ]),
      { ok: 1, empty: 1, error: 1, other: 1 },
    );
  });
});
