import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/util/app_theme.dart';

Future<void> showDebugVideoAnalysisResults({
  required BuildContext context,
  required List<PlayerDistanceResult> results,
}) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final textTheme = Theme.of(dialogContext).textTheme;
      return AlertDialog(
        title: Text(l10n.debugVideoAnalyzeResultsTitle),
        content: SizedBox(
          width: 460,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.6,
            ),
            child: results.isEmpty
                ? Text(
                    l10n.debugVideoAnalyzeNoSamples,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final result in results)
                          _PlayerAnalysisTile(result: result),
                      ],
                    ),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      );
    },
  );
}

class _PlayerAnalysisTile extends StatelessWidget {
  const _PlayerAnalysisTile({required this.result});

  final PlayerDistanceResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.number == null
                      ? result.displayName
                      : '${result.number}  ${result.displayName}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.debugVideoAnalyzeDistance(
                  formatDebugVideoDistanceMeters(result.meters),
                ),
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _ballStatsLine(l10n, result),
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _ballStatsLine(AppLocalizations l10n, PlayerDistanceResult result) {
    return [
      l10n.debugVideoAnalyzeBallsPlayed(result.ballsPlayed),
      l10n.debugVideoAnalyzeBallsReceived(result.ballsReceived),
      l10n.debugVideoAnalyzeBallsGiven(result.ballsGiven),
      l10n.debugVideoAnalyzePasses(result.passes),
      l10n.debugVideoAnalyzeShots(result.shots),
    ].join('  ·  ');
  }
}
