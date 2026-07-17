import 'package:grinta/model/player.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:intl/intl.dart';

/// Builds [SessionStatsReport] from tracker team analysis (Stats tab data).
class SessionStatsReportService {
  SessionStatsReportService({
    TeamWorkloadSummaryService? summaryService,
    PlayerService? playerService,
  })  : _summaryService = summaryService ?? TeamWorkloadSummaryService(),
        _playerService = playerService ?? PlayerService();

  final TeamWorkloadSummaryService _summaryService;
  final PlayerService _playerService;

  /// Loads team analysis for [eventId] and resolves player display names.
  Future<SessionStatsReport?> buildReport({
    required String eventId,
    required bool isMatch,
    String? title,
    String? subtitle,
    String? teamName,
    DateTime? eventDate,
    String localeCode = 'fr',
    String unknownPlayerLabel = 'Joueur',
    DateTime? generatedAt,
    TeamWorkloadSummary? summary,
  }) async {
    final safeEventId = eventId.trim();
    if (safeEventId.isEmpty) {
      return null;
    }

    final resolvedSummary =
        summary ?? await _summaryService.getByEventId(safeEventId);
    if (resolvedSummary == null || resolvedSummary.playerScores.isEmpty) {
      return null;
    }

    final playerRows = <SessionStatsReportPlayerRow>[];
    for (final score in resolvedSummary.playerScores) {
      final Player? player = await _playerService
          .getPlayerById(score.playerId)
          .catchError((_) => null);
      final displayName = player != null
          ? playerDisplayName(player, unknownLabel: unknownPlayerLabel)
          : (score.playerId.trim().isEmpty
              ? unknownPlayerLabel
              : score.playerId.trim());

      final metrics = <String, double>{};
      final zScores = <String, double>{};
      for (final metric in kSessionStatsReportMetrics) {
        final playerMetric = score.getMetric(metric.key);
        metrics[metric.key] = playerMetric?.value ?? 0;
        if (playerMetric != null) {
          zScores[metric.key] = playerMetric.zScore;
        }
      }

      playerRows.add(
        SessionStatsReportPlayerRow(
          playerId: score.playerId,
          displayName: displayName,
          trackerId: score.trackerId,
          metrics: metrics,
          zScores: zScores,
        ),
      );
    }

    playerRows.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );

    final teamAverages = <String, double>{};
    for (final metric in kSessionStatsReportMetrics) {
      teamAverages[metric.key] =
          resolvedSummary.metricStats[metric.key]?.mean ?? 0;
    }

    final resolvedTitle = (title ?? '').trim().isNotEmpty
        ? title!.trim()
        : (isMatch ? 'Match' : 'Entraînement');

    String? dateLabel;
    if (eventDate != null) {
      dateLabel = DateFormat.yMMMMd(localeCode).format(eventDate);
    }

    return SessionStatsReport(
      eventId: safeEventId,
      title: resolvedTitle,
      subtitle: subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : null,
      dateLabel: dateLabel,
      teamName: teamName?.trim().isNotEmpty == true ? teamName!.trim() : null,
      isMatch: isMatch,
      generatedAt: generatedAt ?? DateTime.now(),
      playersCount: resolvedSummary.playersCount,
      averageWorkloadScore: resolvedSummary.averageWorkloadScore,
      sessionDuration: resolvedSummary.sessionDuration,
      teamAverages: teamAverages,
      playerRows: playerRows,
    );
  }
}
