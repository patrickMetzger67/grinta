import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/player_photo_resolver.dart';

/// Loads GPS / Polar / personal-sport sessions for an admin player view.
class AdminPlayerSessionsService {
  AdminPlayerSessionsService({
    PolarSessionAnalysisService? polarService,
    PersonalSportActivityService? personalSportService,
    MatchService? matchService,
    TrainingService? trainingService,
  })  : _polarService = polarService ?? PolarSessionAnalysisService(),
        _personalSportService =
            personalSportService ?? PersonalSportActivityService(),
        _matchService = matchService ?? MatchService(),
        _trainingService = trainingService ?? TrainingService();

  final PolarSessionAnalysisService _polarService;
  final PersonalSportActivityService _personalSportService;
  final MatchService _matchService;
  final TrainingService _trainingService;

  /// Merged sessions for [player] in [[start], [end]] (inclusive), newest first.
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

    for (final playerId in ids) {
      final gpsDocs = await TrackerAnalysisService.getAnalysisDocsByPlayer(
        playerId,
        start: start,
        end: end,
      );
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

      final polarList = await _polarService.listByPlayerId(
        playerId,
        start: start,
        end: end,
      );
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

    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEndExclusive =
        DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    final personal =
        await _personalSportService.fetchNonPrivateOwnedBetweenDates(
      memberId: memberId,
      start: rangeStart,
      end: rangeEndExclusive,
    );
    for (final activity in personal) {
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

    items.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return items;
  }

  Future<_EventMeta> _resolveEventMeta(String eventId) async {
    try {
      final match = await _matchService.getMatchById(eventId);
      if (match != null) {
        return _EventMeta(
          isMatch: true,
          ownerId: match.ownerId,
          teamId: match.teamID,
        );
      }
    } catch (_) {}

    try {
      final training = await _trainingService.getTrainingById(eventId);
      if (training != null) {
        return _EventMeta(
          isMatch: false,
          ownerId: training.ownerId,
          teamId: training.teamId,
        );
      }
    } catch (_) {}

    try {
      final training = await _trainingService.getTrainingByDocId(eventId);
      if (training != null) {
        return _EventMeta(
          isMatch: false,
          ownerId: training.ownerId,
          teamId: training.teamId,
        );
      }
    } catch (_) {}

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
