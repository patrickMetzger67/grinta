import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/util/session_tracker_kit.dart';
import 'package:grinta/widget/match_tracker_stats_table.dart';
import 'package:grinta/widget/polar_analysis/match_polar_stats_table.dart';

/// Team session analysis host: GPS table or Polar cardio table.
///
/// When the event owner is a Polar kit (`typeTracker == polar`), shows
/// [MatchPolarStatsTable] instead of [MatchTrackerStatsTable].
class SessionTrackerStatsView extends StatelessWidget {
  const SessionTrackerStatsView({
    super.key,
    required this.eventId,
    this.ownerId,
    this.teamId,
    this.realtime = true,
    this.padding = EdgeInsets.zero,
    this.isMatch = true,
    this.reportTitle,
    this.reportSubtitle,
    this.reportTeamName,
    this.reportEventDate,
    this.reportMatch,
    this.showEmailReport,
  });

  final String eventId;
  final String? ownerId;
  final String? teamId;
  final bool realtime;
  final EdgeInsetsGeometry padding;
  final bool isMatch;
  final String? reportTitle;
  final String? reportSubtitle;
  final String? reportTeamName;
  final DateTime? reportEventDate;
  final grinta_match.Match? reportMatch;
  final bool? showEmailReport;

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
          return Padding(
            padding: padding,
            child: Text(
              context.l10n.errorLoadingTitle,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.data == true) {
          return MatchPolarStatsTable(
            eventId: eventId,
            teamId: teamId,
            realtime: realtime,
            isMatch: isMatch,
            padding: padding,
          );
        }

        return MatchTrackerStatsTable(
          eventId: eventId,
          teamId: teamId,
          realtime: realtime,
          padding: padding,
          isMatch: isMatch,
          reportTitle: reportTitle,
          reportSubtitle: reportSubtitle,
          reportTeamName: reportTeamName,
          reportEventDate: reportEventDate,
          reportMatch: reportMatch,
          showEmailReport: showEmailReport,
        );
      },
    );
  }
}
