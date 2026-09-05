const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  predGameDayDocumentId,
  matchBelongsToPredictionEngagement,
  resolveMatchKickoff,
  matchdayNumber,
  predictionClosesAt,
  selectNextPredictionMatchday,
  buildContestDocument,
  collectDirectTeamUserIds,
  collectMemberIds,
  memberLinkedUserIds,
  buildPredictionNotifications,
} = require('./prediction_game_contest');

const engagement = {
  competitionId: 'COMP1',
  group: 'A',
  stage: 'championnat',
  seasonId: 'S26',
  clubId: 'CLUB1',
};

function match({
  id,
  day,
  dateCh,
  timeCh = '15:00',
  isMatchPlayed = false,
  competitionID = 'COMP1',
  poule = 'A',
  stage = 'championnat',
  team1 = 'Home',
  team2 = 'Away',
}) {
  return {
    id,
    day,
    dateCh,
    timeCh,
    isMatchPlayed,
    competitionID,
    poule,
    stage,
    team1,
    team2,
  };
}

describe('predGameDayDocumentId', () => {
  it('joins team, engagement and day', () => {
    assert.equal(predGameDayDocumentId(' T1 ', ' E1 ', 4), 'T1_E1_4');
  });
});

describe('matchBelongsToPredictionEngagement', () => {
  it('requires same competition, group and stage', () => {
    assert.equal(
      matchBelongsToPredictionEngagement(match({ id: 'm1', day: 1 }), engagement),
      true,
    );
    assert.equal(
      matchBelongsToPredictionEngagement(
        match({ id: 'm1', day: 1, poule: 'B' }),
        engagement,
      ),
      false,
    );
    assert.equal(
      matchBelongsToPredictionEngagement(
        match({ id: 'm1', day: 1, competitionID: 'OTHER' }),
        engagement,
      ),
      false,
    );
  });
});

describe('resolveMatchKickoff', () => {
  it('parses dateCh and timeCh as local date', () => {
    const kickoff = resolveMatchKickoff({
      dateCh: '06/09/2026',
      timeCh: '15:00',
    });
    assert.equal(kickoff.getFullYear(), 2026);
    assert.equal(kickoff.getMonth(), 8);
    assert.equal(kickoff.getDate(), 6);
    assert.equal(kickoff.getHours(), 15);
  });
});

describe('matchdayNumber', () => {
  it('ignores missing or non-positive days', () => {
    assert.equal(matchdayNumber({ day: 3 }), 3);
    assert.equal(matchdayNumber({ day: 0 }), null);
    assert.equal(matchdayNumber({}), null);
  });
});

describe('predictionClosesAt', () => {
  it('locks 12 hours before first kickoff', () => {
    const first = new Date(2026, 8, 6, 15, 0);
    assert.deepEqual(predictionClosesAt(first), new Date(2026, 8, 6, 3, 0));
  });
});

describe('selectNextPredictionMatchday', () => {
  const now = new Date(2026, 8, 3, 8, 0); // Wednesday morning

  it('picks the earliest still-open journée', () => {
    const selection = selectNextPredictionMatchday(
      [
        match({ id: 'm1', day: 4, dateCh: '30/08/2026', timeCh: '15:00' }),
        match({ id: 'm2', day: 5, dateCh: '06/09/2026', timeCh: '15:00' }),
        match({ id: 'm3', day: 5, dateCh: '06/09/2026', timeCh: '17:00' }),
        match({ id: 'm4', day: 6, dateCh: '13/09/2026', timeCh: '15:00' }),
      ],
      engagement,
      now,
    );

    assert.equal(selection.day, 5);
    assert.deepEqual(
      selection.matches.map((item) => item.id),
      ['m2', 'm3'],
    );
    assert.deepEqual(selection.firstKickoff, new Date(2026, 8, 6, 15, 0));
    assert.deepEqual(selection.closesAt, new Date(2026, 8, 6, 3, 0));
  });

  it('skips played matches and already locked days', () => {
    const selection = selectNextPredictionMatchday(
      [
        match({
          id: 'played',
          day: 5,
          dateCh: '06/09/2026',
          isMatchPlayed: true,
        }),
        match({ id: 'locked', day: 5, dateCh: '03/09/2026', timeCh: '10:00' }),
        match({ id: 'next', day: 6, dateCh: '13/09/2026', timeCh: '15:00' }),
      ],
      engagement,
      now,
    );

    assert.equal(selection.day, 6);
    assert.equal(selection.matches[0].id, 'next');
  });

  it('returns null when nothing is still open', () => {
    assert.equal(
      selectNextPredictionMatchday(
        [match({ id: 'm1', day: 4, dateCh: '01/09/2026', timeCh: '15:00' })],
        engagement,
        now,
      ),
      null,
    );
  });
});

describe('buildContestDocument', () => {
  it('snapshots fixtures and deadline', () => {
    const selection = selectNextPredictionMatchday(
      [match({ id: 'm2', day: 5, dateCh: '06/09/2026', timeCh: '15:00' })],
      engagement,
      new Date(2026, 8, 3, 8, 0),
    );
    const createdAt = new Date(2026, 8, 3, 8, 0);
    const doc = buildContestDocument({
      teamId: 'T1',
      engagementId: 'E1',
      engagement,
      selection,
      createdAt,
    });

    assert.equal(doc.teamId, 'T1');
    assert.equal(doc.engagementId, 'E1');
    assert.equal(doc.day, 5);
    assert.deepEqual(doc.matchIds, ['m2']);
    assert.equal(doc.fixtures[0].team1, 'Home');
    assert.deepEqual(doc.closesAt, new Date(2026, 8, 6, 3, 0));
    assert.deepEqual(doc.entries, {});
  });
});

describe('recipient helpers', () => {
  it('collects team users, uid and managers', () => {
    const ids = collectDirectTeamUserIds({
      uid: 'owner',
      users: ['u1', 'users/u2'],
      managers: [{ uid: 'coach' }, 'm1'],
    });
    assert.deepEqual([...ids].sort(), ['coach', 'm1', 'owner', 'u1', 'u2']);
  });

  it('collects member ids from roster fields', () => {
    assert.deepEqual(
      collectMemberIds({
        grintaPlayerMemberIds: ['p1', ''],
        grintaPlayers: [{ playerId: 'p2' }, { playerId: 'p1' }],
      }).sort(),
      ['p1', 'p2'],
    );
  });

  it('reads linked user ids from a member', () => {
    assert.deepEqual(
      memberLinkedUserIds({
        userID: 'u1',
        users: ['u2', 'users/u3'],
      }).sort(),
      ['u1', 'u2', 'u3'],
    );
  });
});

describe('buildPredictionNotifications', () => {
  it('creates one notification per unique uid', () => {
    const notifications = buildPredictionNotifications({
      recipientUserIds: ['u1', 'u1', 'u2'],
      contestId: 'T1_E1_5',
      day: 5,
      clubId: 'CLUB1',
    });
    assert.equal(notifications.length, 2);
    assert.equal(notifications[0].type, 'NotifType.predictionGame');
    assert.equal(notifications[0].objectId, 'T1_E1_5');
    assert.match(notifications[0].body, /journée 5/);
  });
});
