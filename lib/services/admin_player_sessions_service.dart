import 'package:flutter/foundation.dart';
import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/player_photo_resolver.dart';

/// GPS analyses for one player id in [[start], [end]].
typedef AdminGpsDocsLoader = Future<List<TrackerAnalysisDoc>> Function(
  String playerId, {
  DateTime? start,
  DateTime? end,
});

/// Polar analyses for one player id in [[start], [end]].
typedef AdminPolarListLoader = Future<List<PolarSessionAnalysis>> Function(
  String playerId, {
  DateTime? start,
  DateTime? end,
});

/// Personal sport activities for one member id in [[start], [end]).
typedef AdminPersonalLoader = Future<List<PersonalSportActivity>> Function({
  required String memberId,
  required DateTime start,
  required DateTime end,
});

/// Match / training lookup used to label a session row.
typedef AdminEventMetaLoader
    = Future<({bool isMatch, String? ownerId, String? teamId})> Function(
        String eventId);

/// Loads GPS / Polar / personal-sport sessions for an admin player view.
class AdminPlayerSessionsService {
  AdminPlayerSessionsService({
    PolarSessionAnalysisService? polarService,
    PersonalSportActivityService? personalSportService,
    MatchService? matchService,
    TrainingService? trainingService,
    AdminGpsDocsLoader? gpsDocsLoader,
    AdminPolarListLoader? polarListLoader,
    AdminPersonalLoader? personalLoader,
    AdminEventMetaLoader? eventMetaLoader,
  })  : _polarService = polarService,
        _personalSportService = personalSportService,
        _matchService = matchService,
        _trainingService = trainingService,
        _gpsDocsLoader = gpsDocsLoader,
        _polarListLoader = polarListLoader,
        _personalLoader = personalLoader,
        _eventMetaLoader = eventMetaLoader;

  PolarSessionAnalysisService? _polarService;
  PersonalSportActivityService? _personalSportService;
  MatchService? _matchService;
  TrainingService? _trainingService;
  final AdminGpsDocsLoader? _gpsDocsLoader;
  final AdminPolarListLoader? _polarListLoader;
  final AdminPersonalLoader? _personalLoader;
  final AdminEventMetaLoader? _eventMetaLoader;

  PolarSessionAnalysisService get _effectivePolar =>
      _polarService ??= PolarSessionAnalysisService();

  PersonalSportActivityService get _effectivePersonal =>
      _personalSportService ??= PersonalSportActivityService();

  MatchService get _effectiveMatch => _matchService ??= MatchService();

  TrainingService get _effectiveTraining =>
      _trainingService ??= TrainingService();

  /// Merged sessions for [player] in [[start], [end]] (inclusive), newest first.
  ///
  /// GPS, Polar and personal sources are loaded independently: one failure is
  /// logged and skipped so the others still appear. Throws only when every
  /// source failed (the UI then shows a load error rather than an empty list).
  Future<List<AdminPlayerSessionItem>> loadSessions({
    required Player player,
    required DateTime start,
    required DateTime end,
  }) async {
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    if (memberId.isEmpty) return const <AdminPlayerSessionItem>[];

    final lookupIds = playerMemberLookupIds(player);
    final ids = lookupIds.isEmpty ? <String>{memberId} : lookupIds;

    final items = <AdminPlayerSessionItem>[];
    final seenKeys = <String>{};

    final kit = await _loadGpsAndPolarForIds(
      ids: ids,
      start: start,
      end: end,
      items: items,
      seenKeys: seenKeys,
    );

    var personalOk = false;
    try {
      final personalItems = await _loadPersonalForIds(
        ids: ids,
        start: start,
        end: end,
      );
      personalOk = true;
      for (final activity in personalItems) {
        final id = activity.id?.trim() ?? '';
        final key = 'personal:$id';
        if (id.isNotEmpty && !seenKeys.add(key)) continue;
        items.add(
          AdminPlayerSessionItem(
            kind: AdminPlayerSessionKind.personalSport,
            sessionDate: activity.startAt,
            eventId: id,
            personalSport: activity,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('AdminPlayerSessionsService personal failed: $e\n$st');
    }

    items.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    if (items.isEmpty && !kit.gpsOk && !kit.polarOk && !personalOk) {
      throw StateError('Failed to load GPS, Polar and personal sessions');
    }
    return items;
  }

  Future<({bool gpsOk, bool polarOk})> _loadGpsAndPolarForIds({
    required Set<String> ids,
    required DateTime start,
    required DateTime end,
    required List<AdminPlayerSessionItem> items,
    required Set<String> seenKeys,
  }) async {
    var gpsOk = false;
    var polarOk = false;

    for (final playerId in ids) {
      List<TrackerAnalysisDoc> gpsDocs = const [];
      try {
        gpsDocs = await _loadGpsDocs(playerId, start: start, end: end);
        gpsOk = true;
      } catch (e, st) {
        debugPrint(
          'AdminPlayerSessionsService GPS playerId=$playerId failed: $e\n$st',
        );
      }

      for (final doc in gpsDocs) {
        final eventId = doc.analysis.eventId.trim();
        if (eventId.isEmpty) continue;
        final key = 'gps:$eventId:${doc.docId}';
        if (!seenKeys.add(key)) continue;

        final meta = await _resolveEventMeta(eventId);
        items.add(
          AdminPlayerSessionItem(
            kind: AdminPlayerSessionKind.gps,
            sessionDate:
                doc.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            eventId: eventId,
            analysisDocId: doc.docId,
            trackerId: doc.analysis.trackerId,
            ownerId: meta.ownerId,
            teamId: meta.teamId,
            isMatch: meta.isMatch,
          ),
        );
      }

      List<PolarSessionAnalysis> polarList = const [];
      try {
        polarList = await _loadPolar(playerId, start: start, end: end);
        polarOk = true;
      } catch (e, st) {
        debugPrint(
          'AdminPlayerSessionsService Polar playerId=$playerId failed: $e\n$st',
        );
      }

      for (final analysis in polarList) {
        final eventId = analysis.eventId.trim();
        if (eventId.isEmpty) continue;
        final key = 'polar:$eventId:${analysis.docId}';
        if (!seenKeys.add(key)) continue;

        final meta = await _resolveEventMeta(eventId);
        final date = analysis.startedAt ??
            analysis.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        items.add(
          AdminPlayerSessionItem(
            kind: AdminPlayerSessionKind.polar,
            sessionDate: date,
            eventId: eventId,
            analysisDocId: analysis.docId,
            trackerId: analysis.trackerId,
            ownerId: meta.ownerId,
            teamId: meta.teamId,
            isMatch: meta.isMatch,
          ),
        );
      }
    }

    return (gpsOk: gpsOk, polarOk: polarOk);
  }

  Future<List<PersonalSportActivity>> _loadPersonalForIds({
    required Set<String> ids,
    required DateTime start,
    required DateTime end,
  }) async {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive =
        DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    final byId = <String, PersonalSportActivity>{};
    Object? lastError;
    StackTrace? lastStack;
    var anySuccess = false;

    for (final memberId in ids) {
      try {
        final personal = await _loadPersonal(
          memberId: memberId,
          start: rangeStart,
          end: rangeEndExclusive,
        );
        anySuccess = true;
        for (final activity in personal) {
          final id = activity.id?.trim() ?? '';
          if (id.isEmpty) continue;
          byId[id] = activity;
        }
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        debugPrint(
          'AdminPlayerSessionsService personal memberId=$memberId failed: $e\n$st',
        );
      }
    }

    if (!anySuccess && lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    return byId.values.toList();
  }

  Future<List<TrackerAnalysisDoc>> _loadGpsDocs(
    String playerId, {
    required DateTime start,
    required DateTime end,
  }) {
    final loader = _gpsDocsLoader;
    if (loader != null) {
      return loader(playerId, start: start, end: end);
    }
    return TrackerAnalysisService.getAnalysisDocsByPlayer(
      playerId,
      start: start,
      end: end,
    );
  }

  Future<List<PolarSessionAnalysis>> _loadPolar(
    String playerId, {
    required DateTime start,
    required DateTime end,
  }) {
    final loader = _polarListLoader;
    if (loader != null) {
      return loader(playerId, start: start, end: end);
    }
    return _effectivePolar.listByPlayerId(
      playerId,
      start: start,
      end: end,
    );
  }

  Future<List<PersonalSportActivity>> _loadPersonal({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    final loader = _personalLoader;
    if (loader != null) {
      return loader(memberId: memberId, start: start, end: end);
    }
    return _effectivePersonal.fetchNonPrivateOwnedBetweenDates(
      memberId: memberId,
      start: start,
      end: end,
    );
  }

  Future<_EventMeta> _resolveEventMeta(String eventId) async {
    final loader = _eventMetaLoader;
    if (loader != null) {
      final meta = await loader(eventId);
      return _EventMeta(
        isMatch: meta.isMatch,
        ownerId: meta.ownerId,
        teamId: meta.teamId,
      );
    }

    try {
      final match = await _effectiveMatch.getMatchById(eventId);
      if (match != null) {
        return _EventMeta(
          isMatch: true,
          ownerId: match.ownerId,
          teamId: match.teamID,
        );
      }
    } catch (e, st) {
      debugPrint(
        'AdminPlayerSessionsService match meta eventId=$eventId: $e\n$st',
      );
    }

    try {
      final training = await _effectiveTraining.getTrainingById(eventId);
      if (training != null) {
        return _EventMeta(
          isMatch: false,
          ownerId: training.ownerId,
          teamId: training.teamId,
        );
      }
    } catch (e, st) {
      debugPrint(
        'AdminPlayerSessionsService training meta eventId=$eventId: $e\n$st',
      );
    }

    try {
      final training = await _effectiveTraining.getTrainingByDocId(eventId);
      if (training != null) {
        return _EventMeta(
          isMatch: false,
          ownerId: training.ownerId,
          teamId: training.teamId,
        );
      }
    } catch (e, st) {
      debugPrint(
        'AdminPlayerSessionsService training doc meta eventId=$eventId: $e\n$st',
      );
    }

    return const _EventMeta(isMatch: false);
  }
}

class _EventMeta {
  const _EventMeta({
    required this.isMatch,
    this.ownerId,
    this.teamId,
  });

  final bool isMatch;
  final String? ownerId;
  final String? teamId;
}
