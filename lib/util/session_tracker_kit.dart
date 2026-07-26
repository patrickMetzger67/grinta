import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/polar_tracker_eligibility.dart';

/// Resolves the tracker kit owner for a training / match [eventId].
Future<String?> resolveEventOwnerId(String eventId) async {
  final id = eventId.trim();
  if (id.isEmpty) return null;

  try {
    final match = await MatchService().getMatchById(id);
    final matchOwner = match?.ownerId?.trim();
    if (matchOwner != null && matchOwner.isNotEmpty) return matchOwner;
  } catch (_) {}

  try {
    final training = await TrainingService().getTrainingById(id);
    final trainingOwner = training?.ownerId?.trim();
    if (trainingOwner != null && trainingOwner.isNotEmpty) {
      return trainingOwner;
    }
  } catch (_) {}

  return null;
}

/// Whether the event uses a Polar **team kit** (cardio analysis, not GPS).
Future<bool> eventUsesPolarTeamKit({
  required String eventId,
  String? ownerId,
}) async {
  final direct = ownerId?.trim();
  if (direct != null && direct.isNotEmpty) {
    return isPolarTrackerOwner(direct);
  }
  final resolved = await resolveEventOwnerId(eventId);
  return isPolarTrackerOwner(resolved);
}
