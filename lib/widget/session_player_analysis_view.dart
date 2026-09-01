import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/session_player_synthesis_share_service.dart';
import 'package:grinta/util/session_tracker_kit.dart';
import 'package:grinta/widget/polar_analysis/polar_player_analysis_widget.dart';
import 'package:grinta/widget/tracker_player_analysis_widget.dart';

/// Player session analysis host: GPS widget or Polar cardio widget.
class SessionPlayerAnalysisView extends StatelessWidget {
  const SessionPlayerAnalysisView({
    super.key,
    required this.eventId,
    this.ownerId,
    this.analysisDocId,
    this.trackerId,
    this.playerId,
    this.teamId,
    this.playerName,
    this.player,
    this.isMatch = true,
    this.showHeader = true,
    this.showDistanceTimeline = true,
    this.shareMatchContext,
  });

  final String eventId;
  final String? ownerId;
  final String? analysisDocId;
  final String? trackerId;
  final String? playerId;
  final String? teamId;
  final String? playerName;
  final Player? player;
  final bool isMatch;
  final bool showHeader;
  final bool showDistanceTimeline;
  final SessionShareMatchContext? shareMatchContext;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: eventUsesPolarTeamKit(
        eventId: eventId,
        ownerId: ownerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text(context.l10n.errorLoadingTitle));
        }

        if (snapshot.data == true) {
          return PolarPlayerAnalysisWidget(
            analysisDocId: analysisDocId,
            eventId: eventId,
            trackerId: trackerId,
            playerId: playerId,
            playerName: playerName,
            player: player,
            showHeader: showHeader,
          );
        }

        return TrackerPlayerAnalysisWidget(
          analysisDocId: analysisDocId,
          teamId: teamId,
          playerName: playerName,
          player: player,
          isMatch: isMatch,
          showHeader: showHeader,
          showDistanceTimeline: showDistanceTimeline,
          shareMatchContext: shareMatchContext,
        );
      },
    );
  }
}
