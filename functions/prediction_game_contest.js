const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

const REGION = 'europe-west1';
const PRED_GAME_DAY_COLLECTION = 'predGameDay';
const TEAM_COLLECTION = 'team';
const ENGAGEMENT_COLLECTION = 'engagement';
const MATCH_COLLECTION = 'matchCalendar';
const MEMBER_COLLECTION = 'member';
const NOTIFICATION_COLLECTION = 'notification';

const PREDICTION_LOCK_HOURS = 12;
const PREDICTION_PICK_HOME = 1;
const PREDICTION_PICK_AWAY = 2;
const PREDICTION_PICK_DRAW = 3;

const NOTIF_TITLE = 'Pronostics';

function predGameDayDocumentId(teamId, engagementId, day) {
  return `${String(teamId || '').trim()}_${String(engagementId || '').trim()}_${day}`;
}

function normalizeText(value) {
  return (value ?? '').toString().trim();
}

function matchdayNumber(match) {
  const day = Number(match?.day);
  if (!Number.isFinite(day) || day <= 0) return null;
  return day;
}

function parseMatchDateCh(dateCh) {
  const parts = normalizeText(dateCh).split('/');
  if (parts.length !== 3) return null;
  const day = Number(parts[0]);
  const month = Number(parts[1]);
  const year = Number(parts[2]);
  if (!day || !month || !year) return null;
  return { year, month, day };
}

function parseMatchTimeCh(timeCh) {
  const parts = normalizeText(timeCh || '18:00').split(':');
  if (parts.length < 2) return null;
  const hour = Number(parts[0]);
  const minute = Number(parts[1]);
  if (!Number.isFinite(hour) || !Number.isFinite(minute)) return null;
  return { hour, minute };
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value.toDate === 'function') {
    const date = value.toDate();
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
  }
  if (typeof value.seconds === 'number') {
    return new Date(value.seconds * 1000);
  }
  if (typeof value._seconds === 'number') {
    return new Date(value._seconds * 1000);
  }
  return null;
}

function resolveMatchKickoff(match) {
  const dateParts = parseMatchDateCh(match?.dateCh);
  const timeParts = parseMatchTimeCh(match?.timeCh);
  if (dateParts && timeParts) {
    return new Date(
      dateParts.year,
      dateParts.month - 1,
      dateParts.day,
      timeParts.hour,
      timeParts.minute,
    );
  }
  return toDate(match?.timestamp);
}

function matchBelongsToPredictionEngagement(match, engagement) {
  const competitionId = normalizeText(engagement?.competitionId);
  if (!competitionId) return false;
  if (normalizeText(match?.competitionID) !== competitionId) return false;

  const group = normalizeText(engagement?.group);
  if (group && normalizeText(match?.poule) !== group) return false;

  const stage = normalizeText(engagement?.stage);
  if (stage && normalizeText(match?.stage) !== stage) return false;

  return true;
}

function predictionClosesAt(firstKickoff, lockHours = PREDICTION_LOCK_HOURS) {
  return new Date(firstKickoff.getTime() - lockHours * 60 * 60 * 1000);
}

function selectNextPredictionMatchday(matches, engagement, now, lockHours = PREDICTION_LOCK_HOURS) {
  const byDay = new Map();

  for (const match of matches || []) {
    if (match?.isMatchPlayed === true) continue;
    if (!matchBelongsToPredictionEngagement(match, engagement)) continue;
    const day = matchdayNumber(match);
    if (day == null) continue;
    if (!resolveMatchKickoff(match)) continue;
    if (!byDay.has(day)) byDay.set(day, []);
    byDay.get(day).push(match);
  }

  const days = [...byDay.keys()].sort((a, b) => a - b);
  for (const day of days) {
    const dayMatches = [...byDay.get(day)].sort((a, b) => {
      const kickA = resolveMatchKickoff(a);
      const kickB = resolveMatchKickoff(b);
      if (!kickA && !kickB) return 0;
      if (!kickA) return 1;
      if (!kickB) return -1;
      return kickA.getTime() - kickB.getTime();
    });
    const firstKickoff = resolveMatchKickoff(dayMatches[0]);
    if (!firstKickoff) continue;
    const closesAt = predictionClosesAt(firstKickoff, lockHours);
    if (!(closesAt.getTime() > now.getTime())) continue;
    return { day, matches: dayMatches, firstKickoff, closesAt };
  }

  return null;
}

function fixtureFromMatch(match) {
  return {
    matchId: normalizeText(match?.id),
    team1: normalizeText(match?.team1),
    team2: normalizeText(match?.team2),
    team1UrlLogo: normalizeText(match?.team1UrlLogo) || undefined,
    team2UrlLogo: normalizeText(match?.team2UrlLogo) || undefined,
    kickoffAt: resolveMatchKickoff(match),
    day: matchdayNumber(match),
  };
}

function buildContestDocument({
  teamId,
  engagementId,
  engagement,
  selection,
  createdAt,
}) {
  const fixtures = selection.matches
    .map(fixtureFromMatch)
    .filter((fixture) => fixture.matchId);
  return {
    teamId: normalizeText(teamId),
    engagementId: normalizeText(engagementId),
    competitionId: normalizeText(engagement?.competitionId),
    group: normalizeText(engagement?.group),
    stage: normalizeText(engagement?.stage),
    day: selection.day,
    seasonId: normalizeText(engagement?.seasonId),
    clubId: normalizeText(engagement?.clubId),
    matchIds: fixtures.map((fixture) => fixture.matchId),
    fixtures,
    firstKickoffAt: selection.firstKickoff,
    closesAt: selection.closesAt,
    createdAt: createdAt || FieldValue.serverTimestamp(),
    entries: {},
  };
}

function addUid(ids, value) {
  if (value == null) return;
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) return;
    if (trimmed.includes('/')) {
      const segment = trimmed.split('/').pop().trim();
      if (segment) ids.add(segment);
      return;
    }
    ids.add(trimmed);
    return;
  }
  if (typeof value === 'object') {
    for (const key of ['uid', 'id', 'userId', 'userID']) {
      if (value[key]) {
        addUid(ids, value[key]);
        return;
      }
    }
  }
}

function collectDirectTeamUserIds(team) {
  const ids = new Set();
  addUid(ids, team?.uid);
  for (const entry of team?.users || []) addUid(ids, entry);
  for (const entry of team?.managers || []) addUid(ids, entry);
  return ids;
}

function collectMemberIds(team) {
  const ids = new Set();
  for (const entry of team?.grintaPlayerMemberIds || []) {
    const id = normalizeText(entry);
    if (id) ids.add(id);
  }
  for (const player of team?.grintaPlayers || []) {
    const id = normalizeText(player?.playerId);
    if (id) ids.add(id);
  }
  return [...ids];
}

function memberLinkedUserIds(member) {
  const ids = new Set();
  addUid(ids, member?.userID);
  for (const entry of member?.users || []) addUid(ids, entry);
  return [...ids];
}

function notificationBody(day) {
  return `Le concours de pronostics de la journée ${day} est ouvert. Pronostique tes matchs avant le verrouillage.`;
}

function buildPredictionNotifications({
  recipientUserIds,
  contestId,
  day,
  clubId,
  createdUserId = 'system',
}) {
  return [...new Set(recipientUserIds.filter(Boolean))].map((userId) => ({
    userId,
    type: 'NotifType.predictionGame',
    sendBy: 'SendBy.notification',
    title: NOTIF_TITLE,
    body: notificationBody(day),
    objectId: contestId,
    isViewed: false,
    dateTimeCreated: FieldValue.serverTimestamp(),
    createdUserId,
    clubId: normalizeText(clubId),
    playerId: '',
  }));
}

async function collectTeamRecipientUids(db, team) {
  const ids = collectDirectTeamUserIds(team);
  const memberIds = collectMemberIds(team);
  for (const memberId of memberIds) {
    const snap = await db.collection(MEMBER_COLLECTION).doc(memberId).get();
    if (!snap.exists) continue;
    for (const uid of memberLinkedUserIds(snap.data() || {})) {
      ids.add(uid);
    }
  }
  return [...ids];
}

async function createPredictionContestsForDate({ db, now }) {
  const teamsSnap = await db
    .collection(TEAM_COLLECTION)
    .where('withPredictionGame', '==', true)
    .get();

  const summary = {
    teams: teamsSnap.size,
    created: 0,
    skippedExisting: 0,
    skippedNoEngagement: 0,
    skippedNoSelection: 0,
    notifications: 0,
  };

  for (const teamDoc of teamsSnap.docs) {
    const team = teamDoc.data() || {};
    const teamId = normalizeText(team.keyTeam) || teamDoc.id;
    const engagementId = normalizeText(team.predictionGameEngagementd);
    if (!teamId || !engagementId) {
      summary.skippedNoEngagement += 1;
      continue;
    }

    const engagementSnap = await db
      .collection(ENGAGEMENT_COLLECTION)
      .doc(engagementId)
      .get();
    if (!engagementSnap.exists) {
      summary.skippedNoEngagement += 1;
      continue;
    }
    const engagement = engagementSnap.data() || {};

    const matchesSnap = await db
      .collection(MATCH_COLLECTION)
      .where('competitionID', '==', normalizeText(engagement.competitionId))
      .get();
    const matches = matchesSnap.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() || {}),
    }));

    const selection = selectNextPredictionMatchday(matches, engagement, now);
    if (!selection) {
      summary.skippedNoSelection += 1;
      continue;
    }

    const contestId = predGameDayDocumentId(teamId, engagementId, selection.day);
    const existing = await db.collection(PRED_GAME_DAY_COLLECTION).doc(contestId).get();
    if (existing.exists) {
      summary.skippedExisting += 1;
      continue;
    }

    const contest = buildContestDocument({
      teamId,
      engagementId,
      engagement,
      selection,
    });
    await db.collection(PRED_GAME_DAY_COLLECTION).doc(contestId).set(contest);

    const recipientUserIds = await collectTeamRecipientUids(db, team);
    const notifications = buildPredictionNotifications({
      recipientUserIds,
      contestId,
      day: selection.day,
      clubId: team.clubId || engagement.clubId || '',
    });
    for (const notification of notifications) {
      await db.collection(NOTIFICATION_COLLECTION).add(notification);
    }

    summary.created += 1;
    summary.notifications += notifications.length;
  }

  return summary;
}

function createCreatePredictionGameContests() {
  return onSchedule(
    {
      schedule: '0 8 * * 3',
      timeZone: 'Europe/Paris',
      region: REGION,
      timeoutSeconds: 540,
    },
    async () => {
      const db = getFirestore();
      const result = await createPredictionContestsForDate({
        db,
        now: new Date(),
      });
      console.log('[createPredictionGameContests]', JSON.stringify(result));
      return result;
    },
  );
}

module.exports = {
  PREDICTION_LOCK_HOURS,
  PREDICTION_PICK_HOME,
  PREDICTION_PICK_AWAY,
  PREDICTION_PICK_DRAW,
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
  createPredictionContestsForDate,
  createCreatePredictionGameContests,
};
