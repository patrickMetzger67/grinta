import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/manage_unavailabilities_sheet.dart';
import 'package:provider/provider.dart';

/// Opens the current user's unavailabilities for the selected season.
Future<void> openMyUnavailabilitiesScreen(BuildContext context) async {
  final appSession = context.read<AppSession>();
  final Player? player = appSession.selectedPlayer;
  final String? playerId = player == null ? null : effectiveMemberId(player);

  if (player == null || playerId == null || playerId.isEmpty) {
    AppSnackbar.show(context, context.l10n.myUnavailabilitiesNoPlayer);
    return;
  }

  final String? seasonId = appSession.selectedSeason?.ref?.id;

  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.myUnavailabilities,
      builder: (_) => MyUnavailabilitiesScreen(
        player: player,
        seasonId: seasonId,
      ),
    ),
  );
}

class MyUnavailabilitiesScreen extends StatelessWidget {
  const MyUnavailabilitiesScreen({
    super.key,
    required this.player,
    this.seasonId,
  });

  final Player player;
  final String? seasonId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final String? resolvedSeasonId =
        seasonId?.trim().isNotEmpty == true
            ? seasonId!.trim()
            : context.watch<AppSession>().selectedSeason?.ref?.id;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsMyUnavailabilities,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: resolvedSeasonId == null || resolvedSeasonId.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.myUnavailabilitiesNoSeason,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            )
          : ManageUnavailabilitiesSheet(
              player: player,
              seasonId: resolvedSeasonId,
              isManager: true,
              embeddedInScreen: true,
              showCloseButton: false,
            ),
    );
  }
}
