import 'package:grinta/model/answer.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/answerService.dart';
import 'package:grinta/services/effectivesService.dart';

/// Builds `{ TRACKER_DeviceOwner.docId → playerId }` for Polar kit import.
///
/// Unlike Inspirit USB sync (jersey / customName keys), Polar analysis and
/// `PolarSessionImportService` use the DeviceOwner document id
/// (`PlayerTraining.deviceId` / `PlayerCompo.deviceOwnerId`).
Future<Map<String, String>> buildPolarTrainingDevicePlayerMap({
  required Training training,
  required Map<String, DeviceOwner> ownerDevicesByDocId,
  required String seasonId,
  Future<List<Answer>> Function(String objectId)? loadAnswers,
  Future<List<String>> Function({
    required String memberId,
    required String seasonId,
  })? loadTrackerDocIdsForMember,
}) async {
  final devicePlayerMap = <String, String>{};
  final seenTrackerIds = <String>{};
  final objectId = training.trainingId ?? training.docId ?? '';
  final answers = loadAnswers != null
      ? await loadAnswers(objectId)
      : await AnswerService().getAnswersByObjectId(objectId);
  final answersMap = <String, Answer>{
    for (final answer in answers)
      if (answer.playerTraining?.playerId != null)
        answer.playerTraining!.playerId!: answer,
  };

  for (final playerTraining in training.playerTraining) {
    final playerId = playerTraining.playerId?.trim();
    if (playerId == null || playerId.isEmpty) continue;

    final answer = answersMap[playerId];
    final bool isPresent;
    if (answer == null) {
      isPresent = playerTraining.presenceType == PresenceType.present ||
          playerTraining.presenceType == PresenceType.late;
    } else {
      final presence = answer.playerTraining?.presenceType;
      isPresent = presence == PresenceType.present ||
          presence == PresenceType.late;
    }
    if (!isPresent) continue;

    String? trackerDocId = playerTraining.deviceId?.trim();
    if (trackerDocId != null &&
        trackerDocId.isNotEmpty &&
        ownerDevicesByDocId.containsKey(trackerDocId)) {
      // ok
    } else {
      trackerDocId = null;
      final candidates = loadTrackerDocIdsForMember != null
          ? await loadTrackerDocIdsForMember(
              memberId: playerId,
              seasonId: seasonId,
            )
          : (await EffectivesService().getEffectivesByMemberAndSeason(
                memberId: playerId,
                seasonId: seasonId,
              ))
                  ?.trackers ??
              const <String>[];
      for (final candidate in candidates) {
        final id = candidate.trim();
        if (id.isEmpty) continue;
        if (!ownerDevicesByDocId.containsKey(id)) continue;
        trackerDocId = id;
        break;
      }
    }

    if (trackerDocId == null || trackerDocId.isEmpty) continue;
    if (!seenTrackerIds.add(trackerDocId)) continue;
    devicePlayerMap[trackerDocId] = playerId;
  }

  return devicePlayerMap;
}

/// Same as [buildPolarTrainingDevicePlayerMap] for match composition.
Future<Map<String, String>> buildPolarMatchDevicePlayerMap({
  required MatchCompo matchCompo,
  required Map<String, DeviceOwner> ownerDevicesByDocId,
  required String? seasonId,
  EffectivesService? effectivesService,
}) async {
  final devicePlayerMap = <String, String>{};
  final seenTrackerIds = <String>{};
  final effectives = effectivesService ?? EffectivesService();

  Future<void> addFromPlayers(List<PlayerCompo>? players) async {
    if (players == null) return;
    for (final playerCompo in players) {
      final playerId = playerCompo.playerID?.trim();
      if (playerId == null || playerId.isEmpty) continue;

      String? trackerDocId = playerCompo.deviceOwnerId?.trim();
      if (trackerDocId != null &&
          trackerDocId.isNotEmpty &&
          ownerDevicesByDocId.containsKey(trackerDocId)) {
        // ok
      } else {
        trackerDocId = null;
        // customName on match compo is a jersey label for Inspirit — for Polar
        // try resolve by DeviceOwner.customName within this kit.
        final label = playerCompo.customName?.trim();
        if (label != null && label.isNotEmpty) {
          for (final entry in ownerDevicesByDocId.entries) {
            if (entry.value.customName?.trim() == label) {
              trackerDocId = entry.key;
              break;
            }
          }
        }
        if (trackerDocId == null &&
            seasonId != null &&
            seasonId.isNotEmpty) {
          final effective = await effectives.getEffectivesByMemberAndSeason(
            memberId: playerId,
            seasonId: seasonId,
          );
          for (final candidate in effective?.trackers ?? const <String>[]) {
            final id = candidate.trim();
            if (id.isEmpty) continue;
            if (!ownerDevicesByDocId.containsKey(id)) continue;
            trackerDocId = id;
            break;
          }
        }
      }

      if (trackerDocId == null || trackerDocId.isEmpty) continue;
      if (!seenTrackerIds.add(trackerDocId)) continue;
      devicePlayerMap[trackerDocId] = playerId;
    }
  }

  await addFromPlayers(matchCompo.goalkeeper);
  await addFromPlayers(matchCompo.defender);
  await addFromPlayers(matchCompo.midfielder);
  await addFromPlayers(matchCompo.midfielderAttaking);
  await addFromPlayers(matchCompo.midfielderDefensive);
  await addFromPlayers(matchCompo.stricker);
  await addFromPlayers(matchCompo.substitute);

  return devicePlayerMap;
}
