import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/admin_player_sessions_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';

void main() {
  final start = DateTime(2026, 7, 1);
  final end = DateTime(2027, 6, 30);
  final player = Player(
    firstName: 'Mohamed-Amine',
    lastName: 'Test',
    keyMember: 'member-1',
    userID: '',
  );

  TrackerAnalysisDoc gpsDoc({
    required String docId,
    required String eventId,
    required DateTime createdAt,
  }) {
    return TrackerAnalysisDoc(
      docId: docId,
      createdAt: createdAt,
      analysis: TrackerAnalysisResult.fromMap({
        'eventId': eventId,
        'playerId': 'member-1',
        'trackerId': 'trk-gps',
      }),
    );
  }

  PolarSessionAnalysis polarDoc({
    required String eventId,
    required DateTime startedAt,
  }) {
    return PolarSessionAnalysis(
      eventId: eventId,
      playerId: 'member-1',
      trackerId: 'trk-polar',
      polarDeviceId: 'AABB',
      deviceType: 'Verity Sense',
      duration: const Duration(minutes: 70),
      startedAt: startedAt,
      createdAt: startedAt,
    );
  }

  PersonalSportActivity personalDoc({
    required String id,
    required DateTime startAt,
  }) {
    return PersonalSportActivity(
      id: id,
      memberId: 'member-1',
      createdByUserId: 'user-1',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      typeId: 'run',
      visibility: PersonalSportVisibility.team,
      entryMode: PersonalSportEntryMode.import,
      title: 'Footing',
    );
  }

  AdminPlayerSessionsService service({
    AdminGpsDocsLoader? gps,
    AdminPolarListLoader? polar,
    AdminPersonalLoader? personal,
  }) {
    return AdminPlayerSessionsService(
      gpsDocsLoader: gps ??
          (playerId, {DateTime? start, DateTime? end}) async =>
              const <TrackerAnalysisDoc>[],
      polarListLoader: polar ??
          (playerId, {DateTime? start, DateTime? end}) async =>
              const <PolarSessionAnalysis>[],
      personalLoader: personal ??
          ({
            required String memberId,
            required DateTime start,
            required DateTime end,
          }) async =>
              const <PersonalSportActivity>[],
      eventMetaLoader: (eventId) async => (
        isMatch: eventId.startsWith('match'),
        ownerId: 'owner-1',
        teamId: 'team-1',
      ),
    );
  }

  test('returns GPS sessions when Polar fails', () async {
    final items = await service(
      gps: (playerId, {DateTime? start, DateTime? end}) async => [
        gpsDoc(
          docId: 'g1',
          eventId: 'train-1',
          createdAt: DateTime(2026, 8, 12),
        ),
      ],
      polar: (playerId, {DateTime? start, DateTime? end}) async {
        throw StateError('missing polar index');
      },
    ).loadSessions(player: player, start: start, end: end);

    expect(items, hasLength(1));
    expect(items.single.kind, AdminPlayerSessionKind.gps);
    expect(items.single.eventId, 'train-1');
    expect(items.single.isMatch, isFalse);
  });

  test('returns Polar sessions when GPS fails', () async {
    final items = await service(
      gps: (playerId, {DateTime? start, DateTime? end}) async {
        throw StateError('missing gps index');
      },
      polar: (playerId, {DateTime? start, DateTime? end}) async => [
        polarDoc(eventId: 'match-9', startedAt: DateTime(2026, 9, 5)),
      ],
    ).loadSessions(player: player, start: start, end: end);

    expect(items, hasLength(1));
    expect(items.single.kind, AdminPlayerSessionKind.polar);
    expect(items.single.isMatch, isTrue);
  });

  test('empty successful sources return an empty list, not an error', () async {
    final items = await service().loadSessions(
      player: player,
      start: start,
      end: end,
    );
    expect(items, isEmpty);
  });

  test('throws only when every source fails', () async {
    final load = service(
      gps: (playerId, {DateTime? start, DateTime? end}) async {
        throw StateError('gps down');
      },
      polar: (playerId, {DateTime? start, DateTime? end}) async {
        throw StateError('polar down');
      },
      personal: ({
        required String memberId,
        required DateTime start,
        required DateTime end,
      }) async {
        throw StateError('personal down');
      },
    ).loadSessions(player: player, start: start, end: end);

    await expectLater(load, throwsA(isA<StateError>()));
  });

  test('merges GPS Polar and personal newest first', () async {
    final items = await service(
      gps: (playerId, {DateTime? start, DateTime? end}) async => [
        gpsDoc(
          docId: 'g1',
          eventId: 'train-old',
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
      polar: (playerId, {DateTime? start, DateTime? end}) async => [
        polarDoc(eventId: 'match-new', startedAt: DateTime(2026, 9, 1)),
      ],
      personal: ({
        required String memberId,
        required DateTime start,
        required DateTime end,
      }) async =>
          [
        personalDoc(id: 'run-1', startAt: DateTime(2026, 8, 15)),
      ],
    ).loadSessions(player: player, start: start, end: end);

    expect(items.map((e) => e.eventId).toList(), [
      'match-new',
      'run-1',
      'train-old',
    ]);
    expect(items[1].kind, AdminPlayerSessionKind.personalSport);
  });

  test('player without a member id returns empty', () async {
    final items = await service(
      gps: (playerId, {DateTime? start, DateTime? end}) async {
        fail('should not query GPS without a member id');
      },
    ).loadSessions(
      player: Player(firstName: 'X', lastName: 'Y', keyMember: '', userID: ''),
      start: start,
      end: end,
    );
    expect(items, isEmpty);
  });
}
