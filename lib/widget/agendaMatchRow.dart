import 'package:flutter/material.dart';
import 'package:grinta/model/match.dart' as grinta_match;

import '../util/app_theme.dart';

class AgendaMatchRow extends StatelessWidget {
  final grinta_match.Match match;

  const AgendaMatchRow({
    required this.match,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w400,
    ) ??
        TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        );

    String team1 = match.team1 ?? '';
    String team2 = match.team2 ?? '';

    if (team1.contains('Exempt')) team1 = 'Exempt';
    if (team2.contains('Exempt')) team2 = 'Exempt';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasTab = match.tab?.isNotEmpty ?? false;

        final double contentWidth = constraints.maxWidth > 360
            ? 360
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.team1UrlLogo?.isNotEmpty ?? false)
                            _matchLogo(context, match.team1UrlLogo!),
                          const SizedBox(width: 6),
                          if (match.isMatchPlayed == true)
                            _scoreBox(
                              context: context,
                              score: '${match.homeScore ?? 0}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        team1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                      if (match.isTeam1Forfeit == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Forfait',
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasTab) ...[
                        const SizedBox(height: 4),
                        Text(
                          match.tab ?? '',
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.isMatchPlayed == true)
                            _scoreBox(
                              context: context,
                              score: '${match.outSideScore ?? 0}',
                            ),
                          const SizedBox(width: 6),
                          if (match.team2UrlLogo?.isNotEmpty ?? false)
                            _matchLogo(context, match.team2UrlLogo!),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        team2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                      if (match.isTeam2Forfeit == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Forfait',
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scoreBox({
    required BuildContext context,
    required String score,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        score,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _matchLogo(BuildContext context, String url) {
    final colors = context.appColors;
    final safeUrl = url.trim();

    if (safeUrl.isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            safeUrl,
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('LOGO ERROR url=$safeUrl');
              debugPrint('error=$error');

              return Icon(
                Icons.broken_image_outlined,
                size: 16,
                color: colors.textSecondary,
              );
            },
          ),
        ),
      ),
    );
  }
}