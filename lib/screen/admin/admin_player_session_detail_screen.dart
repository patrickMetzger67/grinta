import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/session_player_analysis_view.dart';

/// Reuses [SessionPlayerAnalysisView] for admin GPS / Polar session detail.
class AdminPlayerSessionDetailScreen extends StatelessWidget {
  const AdminPlayerSessionDetailScreen({
    super.key,
    required this.player,
    required this.item,
  });

  final Player player;
  final AdminPlayerSessionItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final name = playerDisplayName(
      player,
      unknownLabel: l10n.entityPlayer,
    );
    final playerId = effectiveMemberId(player);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminPlayerSessionDetailTitle(name),
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SessionPlayerAnalysisView(
        eventId: item.eventId,
        ownerId: item.ownerId,
        analysisDocId: item.analysisDocId,
        trackerId: item.trackerId,
        playerId: playerId,
        teamId: item.teamId,
        playerName: name,
        player: player,
        isMatch: item.isMatch,
        showHeader: true,
        showDistanceTimeline: true,
      ),
    );
  }
}
