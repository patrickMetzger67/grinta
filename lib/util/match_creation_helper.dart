import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_deletion_access.dart';
import 'package:http/http.dart' as http;

import '../model/club.dart';
import '../model/match.dart';
import '../model/season.dart';
import '../model/team.dart';
import 'buildTimestampFromDateAndTime.dart';

const String kGoogleMapsGeocodingApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyDyHHcP9py2HCyx18Ssels7qqygKxeUZG0',
);

/// Common match durations (minutes).
const List<int> kMatchDurationOptions = <int>[45, 60, 75, 90, 105, 120, 150];

/// Canonical Firestore values for [Match.surfaceDeJeu].
const String kMatchSurfaceSynthetic = 'Synthétique';
const String kMatchSurfaceNatural = 'Pelouse naturelle';

const List<String> kMatchSurfaceOptions = <String>[
  kMatchSurfaceSynthetic,
  kMatchSurfaceNatural,
];

/// Formats a date as `dd/MM/yyyy` for [Match.dateCh].
String formatMatchDateCh(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Formats a [TimeOfDay] as `HH:mm` for [Match.timeCh].
String formatMatchTimeCh(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Parses [Match.dateCh] (`dd/MM/yyyy`) into a local date.
DateTime? parseMatchDateCh(String? dateCh) {
  final String raw = dateCh?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parts = raw.split('/');
  if (parts.length != 3) return null;

  try {
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  } catch (_) {
    return null;
  }
}

/// Parses [Match.timeCh] (`HH:mm`) into a [TimeOfDay].
TimeOfDay? parseMatchTimeCh(String? timeCh) {
  final String raw = timeCh?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parts = raw.split(':');
  if (parts.length != 2) return null;

  try {
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  } catch (_) {
    return null;
  }
}

/// Returns the single team id when [Match.teams] contains exactly one entry.
String? singleManagedMatchTeamId(Match match) {
  final List<dynamic>? rawTeams = match.teams;
  if (rawTeams == null || rawTeams.length != 1) {
    return null;
  }

  final String teamId = rawTeams.first?.toString().trim() ?? '';
  if (teamId.isEmpty) {
    return null;
  }
  return teamId;
}

/// Team ids from [Match.teams] that the signed-in user can manage.
List<String> managedMatchTeamIds(Match match, AppSession session) {
  final List<dynamic>? rawTeams = match.teams;
  if (rawTeams == null || rawTeams.isEmpty) {
    return const <String>[];
  }

  final List<String> managedTeamIds = <String>[];
  for (final dynamic raw in rawTeams) {
    final String teamId = raw?.toString().trim() ?? '';
    if (teamId.isEmpty) {
      continue;
    }

    Team? team;
    for (final Team candidate in session.teamsForAgendaSelectedSeason) {
      if (candidate.keyTeam?.trim() == teamId) {
        team = candidate;
        break;
      }
    }
    if (team == null) {
      continue;
    }

    if (canManageTeam(
      team,
      session.user?.uid,
      isManager: session.managedTeamsIdsForSelectedSeason.contains(teamId),
    )) {
      managedTeamIds.add(teamId);
    }
  }

  return managedTeamIds;
}

/// True when the user can manage at least one team listed in [Match.teams].
bool canManageMatch(Match match, AppSession session) {
  return managedMatchTeamIds(match, session).isNotEmpty;
}

/// Shows a confirmation dialog before deleting or removing a managed match.
Future<bool> confirmDeleteMatch(
  BuildContext context, {
  required Match match,
  required bool isScrapping,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;
  final String title = isScrapping
      ? l10n.matchRemoveFromTeamConfirmTitle
      : l10n.matchDeleteConfirmTitle;
  final String message = isScrapping
      ? l10n.matchRemoveFromTeamConfirmMessage
      : l10n.matchDeleteConfirmMessage;

  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true)
                .pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

/// Deletes or partially removes a match after confirmation.
Future<bool> deleteManagedMatch(
  BuildContext context, {
  required Match match,
  required AppSession session,
  VoidCallback? onDeleted,
}) async {
  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    return false;
  }

  final List<String> managedTeamIds = managedMatchTeamIds(match, session);
  if (managedTeamIds.isEmpty) {
    return false;
  }

  final bool isScrapping = match.isScrapping ?? true;
  final confirmed = await confirmDeleteMatch(
    context,
    match: match,
    isScrapping: isScrapping,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }

  final l10n = context.l10n;
  final String successMessage = isScrapping
      ? l10n.matchRemovedFromTeam
      : l10n.matchDeleted;
  final String errorMessage = l10n.matchDeleteError;
  final MatchService matchService = MatchService();

  try {
    if (isScrapping) {
      for (final String teamId in managedTeamIds) {
        await matchService.removeTeamFromMatch(
          matchId: matchId,
          teamId: teamId,
        );
      }
    } else {
      await matchService.deleteMatch(matchId);
    }
    onDeleted?.call();

    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      AppSnackbar.show(rootContext, successMessage, isError: false);
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.show(context, errorMessage);
    }
    return false;
  }
}

/// Builds a multiline postal address from club fields.
String buildClubMultilineAddress(Club club) {
  final parts = <String>[];
  final address = club.address?.trim() ?? '';
  if (address.isNotEmpty) {
    parts.add(address);
  }

  final zipCode = club.zipCode?.trim() ?? '';
  final city = club.city?.trim() ?? '';
  final cityLine = [zipCode, city]
      .where((part) => part.isNotEmpty)
      .join(' ')
      .trim();
  if (cityLine.isNotEmpty) {
    parts.add(cityLine);
  }

  return parts.join('\n');
}

/// Best-effort geocoding used to validate an address before navigation links.
Future<bool> geocodeAddressForNavigation(String address) async {
  final query = address.trim();
  if (query.isEmpty) return false;

  final apiKey = kGoogleMapsGeocodingApiKey.trim();
  if (apiKey.isEmpty || apiKey == 'TA_CLE_GOOGLE_MAPS_ICI') {
    return true;
  }

  try {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'address': query,
        'key': apiKey,
        'language': 'fr',
        'region': 'fr',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? 'UNKNOWN';
    if (status != 'OK') return false;

    final results = data['results'] as List<dynamic>?;
    return results != null && results.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Builds one [Match] document for manual creation from the agenda form.
Match buildMatchForCreation({
  required DateTime date,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required bool isHome,
  required bool isFriendly,
  required String opponentName,
  String? opponentAffiliation,
  String? opponentLogoUrl,
  required String venueAddress,
  String? surfaceDeJeu,
  required bool withTracker,
  String? ownerId,
  Club? ownClub,
}) {
  final String? teamId = team.keyTeam?.trim();
  final String? clubId = team.clubId?.trim();
  final String ownClubName = ownClub?.name?.trim().isNotEmpty == true
      ? ownClub!.name!.trim()
      : (team.name?.trim() ?? '');
  final String ownLogo = ownClub?.logo?.trim() ?? '';
  final String trimmedOpponentName = opponentName.trim();
  final String trimmedOpponentAffiliation = opponentAffiliation?.trim() ?? '';
  final String trimmedOpponentLogo = opponentLogoUrl?.trim() ?? '';
  final String trimmedVenue = venueAddress.trim();

  final String dateCh = formatMatchDateCh(date);
  final String timeCh = formatMatchTimeCh(time);
  final Timestamp timestamp = buildTimestampFromDateAndTime(
    date: dateCh,
    time: timeCh,
  );

  String team1;
  String team2;
  String affiliationTeam1 = '';
  String affiliationTeam2 = '';
  String team1UrlLogo = '';
  String team2UrlLogo = '';
  final List<String> clubs = <String>[];
  String whereIsPlayed = '';

  if (isHome) {
    team1 = ownClubName;
    team2 = trimmedOpponentName;
    if (clubId != null && clubId.isNotEmpty) {
      affiliationTeam1 = clubId;
      clubs.add(clubId);
      whereIsPlayed = clubId;
    }
    if (trimmedOpponentAffiliation.isNotEmpty) {
      affiliationTeam2 = trimmedOpponentAffiliation;
      if (clubs.length > 1) {
        clubs[1] = trimmedOpponentAffiliation;
      } else {
        clubs.add(trimmedOpponentAffiliation);
      }
    }
    team1UrlLogo = ownLogo;
    team2UrlLogo = trimmedOpponentLogo;
  } else {
    team1 = trimmedOpponentName;
    team2 = ownClubName;
    if (trimmedOpponentAffiliation.isNotEmpty) {
      affiliationTeam1 = trimmedOpponentAffiliation;
      clubs.add(trimmedOpponentAffiliation);
      whereIsPlayed = trimmedOpponentAffiliation;
    }
    if (clubId != null && clubId.isNotEmpty) {
      affiliationTeam2 = clubId;
      clubs.add(clubId);
    }
    team1UrlLogo = trimmedOpponentLogo;
    team2UrlLogo = ownLogo;
  }

  return Match(
    chType: isFriendly ? 'Amical' : '',
    dateCh: dateCh,
    timeCh: timeCh,
    timestamp: timestamp,
    duration: durationMinutes,
    day: 0,
    seasonID: season.ref?.id,
    team1: team1,
    team2: team2,
    affiliationTeam1: affiliationTeam1,
    affiliationTeam2: affiliationTeam2,
    team1UrlLogo: team1UrlLogo,
    team2UrlLogo: team2UrlLogo,
    terrainAdresse1: trimmedVenue,
    isReport: false,
    isOwnClub: isHome,
    isMatchPlayed: false,
    isMatchVisible: true,
    homeScore: 0,
    outSideScore: 0,
    tab: '',
    tour: '',
    teamID: teamId ?? '',
    teams: teamId == null || teamId.isEmpty ? <dynamic>[] : <dynamic>[teamId],
    clubs: clubs,
    whereIsPlayed: whereIsPlayed,
    isAdded: true,
    withTracker: withTracker,
    ownerId: withTracker ? (ownerId ?? '') : '',
    isTrackerDataUploaded: false,
    soccerType: team.soccerType ?? 11,
    surfaceDeJeu: surfaceDeJeu?.trim() ?? '',
    isStatApplied: false,
    isScrapping: false,
  );
}

/// Applies agenda form values to an existing match while preserving unrelated fields.
Match buildMatchForUpdate({
  required Match existing,
  required DateTime date,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required bool isHome,
  required bool isFriendly,
  required String opponentName,
  String? opponentAffiliation,
  String? opponentLogoUrl,
  required String venueAddress,
  String? surfaceDeJeu,
  required bool withTracker,
  String? ownerId,
  Club? ownClub,
}) {
  final Match updated = buildMatchForCreation(
    date: date,
    time: time,
    durationMinutes: durationMinutes,
    team: team,
    season: season,
    isHome: isHome,
    isFriendly: isFriendly,
    opponentName: opponentName,
    opponentAffiliation: opponentAffiliation,
    opponentLogoUrl: opponentLogoUrl,
    venueAddress: venueAddress,
    surfaceDeJeu: surfaceDeJeu,
    withTracker: withTracker,
    ownerId: ownerId,
    ownClub: ownClub,
  );

  updated.id = existing.id;
  updated.ref = existing.ref;
  updated.isAdded = existing.isAdded ?? true;
  updated.day = existing.day;
  updated.tour = existing.tour;
  updated.competitionID = existing.competitionID;
  updated.poule = existing.poule;
  updated.stage = existing.stage;
  updated.isMatchPlayed = existing.isMatchPlayed;
  updated.homeScore = existing.homeScore;
  updated.outSideScore = existing.outSideScore;
  updated.tab = existing.tab;
  updated.isReport = existing.isReport;
  updated.isTeam1Forfeit = existing.isTeam1Forfeit;
  updated.isTeam2Forfeit = existing.isTeam2Forfeit;
  updated.isMatchVisible = existing.isMatchVisible;
  updated.isStatApplied = existing.isStatApplied;
  updated.isTrackerDataUploaded = existing.isTrackerDataUploaded;
  updated.mvpManaged = existing.mvpManaged;
  updated.isMvpStarted = existing.isMvpStarted;
  updated.highLightsManagerUid = existing.highLightsManagerUid;
  updated.isInHighLight = existing.isInHighLight;
  updated.liveFollowers = existing.liveFollowers;
  updated.dateTimeConvo = existing.dateTimeConvo;
  updated.messageConvo = existing.messageConvo;
  updated.addressConvo = existing.addressConvo;
  updated.fieldId = existing.fieldId;
  updated.fieldGpsCorners = existing.fieldGpsCorners;
  updated.url = existing.url;
  updated.urlMatchDetails = existing.urlMatchDetails;
  updated.description = existing.description;
  updated.centralReferee = existing.centralReferee;
  updated.assistantReferee1 = existing.assistantReferee1;
  updated.assistantReferee2 = existing.assistantReferee2;
  updated.principalObserver = existing.principalObserver;
  updated.assistantObserver = existing.assistantObserver;
  updated.accompanyingDelegate = existing.accompanyingDelegate;
  updated.terrainAddress2 = existing.terrainAddress2;
  updated.nomDuTerrain = existing.nomDuTerrain;
  updated.isScrapping = existing.isScrapping;

  return updated;
}
