import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/match_location_service.dart';
import 'package:grinta/services/opponent_typical_team_chat_context.dart';
import 'package:grinta/services/player_activity_report_chat_context.dart';
import 'package:grinta/services/player_chat_stats_service.dart';
import 'package:grinta/services/teams_per_club_service.dart';
import 'package:grinta/services/weather_service.dart';
import 'package:grinta/util/calendar_event_formatter.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:intl/intl.dart';

/// Builds sanitized app context sent with each Gemini chat request.
///
/// To expose a new data type to Ask Diego, extend [buildContext] here, then
/// document the capability in `functions/ask_diego_prompt.js` and
/// `lib/config/ask_diego_capabilities.dart`.
class ChatContextService {
  ChatContextService({
    AgendaService? agendaService,
    TeamsPerClubService? teamsPerClubService,
    PlayerChatStatsService? playerChatStatsService,
    MatchLocationService? matchLocationService,
    WeatherService? weatherService,
    OpponentTypicalTeamChatContext? opponentTypicalTeamChatContext,
    PlayerActivityReportChatContext? playerActivityReportChatContext,
  })  : _agendaService = agendaService ?? AgendaService(),
        _teamsPerClubService = teamsPerClubService ?? TeamsPerClubService(),
        _playerChatStatsService =
            playerChatStatsService ?? PlayerChatStatsService(),
        _matchLocationService = matchLocationService ?? MatchLocationService(),
        _weatherService = weatherService ?? WeatherService(),
        _opponentTypicalTeamChatContext =
            opponentTypicalTeamChatContext ?? OpponentTypicalTeamChatContext(),
        _playerActivityReportChatContext =
            playerActivityReportChatContext ?? PlayerActivityReportChatContext();

  final AgendaService _agendaService;
  final TeamsPerClubService _teamsPerClubService;
  final PlayerChatStatsService _playerChatStatsService;
  final MatchLocationService _matchLocationService;
  final WeatherService _weatherService;
  final OpponentTypicalTeamChatContext _opponentTypicalTeamChatContext;
  final PlayerActivityReportChatContext _playerActivityReportChatContext;

  Future<Map<String, dynamic>> buildContext({
    required AppSession session,
    required String localeCode,
    String? userMessage,
    bool preloadNextMatchTypicalTeam = true,
  }) async {
    final userId = session.user?.uid;
    final season = session.selectedSeason;
    final seasonId = season?.ref?.id;
    final player = session.selectedPlayer;
    final teams = session.teamsForAgendaSelectedSeason;

    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final weekStart = _startOfWeek(now);
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weekEndInclusive = weekEndExclusive.subtract(const Duration(days: 1));

    final seasonRanges = resolveSeasonPeriodRanges(
      seasonId: seasonId ?? '',
      season: season,
    );
    final seasonStart = DateUtils.dateOnly(seasonRanges.fullSeason.start);
    final seasonEnd = DateUtils.dateOnly(seasonRanges.fullSeason.end);
    final queryRange = resolveAgendaQueryRange(
      seasonStart: seasonStart,
      seasonEnd: seasonEnd,
      today: today,
    );
    final lastWeekStart = _startOfLastWeek(today);
    final lastWeekEnd = _endOfLastWeek(today);

    List<AgendaItem> seasonItems = const <AgendaItem>[];
    final String? selectedMemberId = session.selectedPlayerId?.trim();
    if (teams.isNotEmpty ||
        (selectedMemberId != null && selectedMemberId.isNotEmpty)) {
      try {
        seasonItems = await _agendaService.loadAgendaItems(
          teams: teams,
          seasonId: seasonId,
          start: queryRange.start,
          end: queryRange.end,
          memberId: selectedMemberId,
        );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('ChatContext loadAgendaItems failed: $error\n$stackTrace');
        }
        seasonItems = const <AgendaItem>[];
      }
    }

    if (kDebugMode) {
      final teamIds = teams
          .map((Team team) => team.keyTeam)
          .whereType<String>()
          .where((String id) => id.trim().isNotEmpty)
          .toList();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final sampleDates = seasonItems
          .take(3)
          .map((AgendaItem item) => dateFormat.format(item.startAt))
          .join(', ');
      final lastWeekItemCount = seasonItems
          .where(
            (AgendaItem item) => _isWithinInclusiveDateRange(
              item.startAt,
              lastWeekStart,
              lastWeekEnd,
            ),
          )
          .length;
      debugPrint(
        'ChatContext agenda: itemCount=${seasonItems.length} '
        'weekItemCount=${seasonItems.where((AgendaItem item) => _isWithinInclusiveDateRange(item.startAt, weekStart, weekEndInclusive)).length} '
        'lastWeekItemCount=$lastWeekItemCount '
        'teamCount=${teams.length} teamIds=$teamIds seasonId=$seasonId '
        'seasonRange=$seasonStart → $seasonEnd '
        'queryRange=${dateFormat.format(queryRange.start)} → ${dateFormat.format(queryRange.end)} '
        'week=$weekStart → $weekEndInclusive '
        'lastWeek=$lastWeekStart → $lastWeekEnd '
        'firstDates=${sampleDates.isEmpty ? '(none)' : sampleDates}',
      );
    }

    final weekItems = seasonItems
        .where(
          (AgendaItem item) => _isWithinInclusiveDateRange(
            item.startAt,
            weekStart,
            weekEndInclusive,
          ),
        )
        .toList();
    final lastWeekItems = seasonItems
        .where(
          (AgendaItem item) => _isWithinInclusiveDateRange(
            item.startAt,
            lastWeekStart,
            lastWeekEnd,
          ),
        )
        .toList();

    final teamNames = _teamNameById(teams);
    final nextMatchItem = _findNextMatchItem(seasonItems, now);
    final userPosition = await _matchLocationService.getCurrentUserPosition();
    final nextMatch = await _buildNextMatchContext(
      item: nextMatchItem,
      teams: teams,
      teamNames: teamNames,
      fallbackSeasonId: seasonId,
      userPosition: userPosition,
    );
    final agenda = await _buildSeasonAgenda(
      items: seasonItems,
      seasonId: seasonId,
      seasonStart: seasonStart,
      seasonEnd: seasonEnd,
      today: today,
      teamNames: teamNames,
      localeCode: localeCode,
      userPosition: userPosition,
      enrichWeatherForUpcomingDays: 7,
    );
    final weeklyAgenda = await _buildWeeklyAgenda(
      items: weekItems,
      weekStart: weekStart,
      weekEnd: weekEndInclusive,
      teamNames: teamNames,
      localeCode: localeCode,
      userPosition: userPosition,
      enrichWeatherForUpcomingDays: 7,
    );
    final lastWeekAgenda = await _buildWeeklyAgenda(
      items: lastWeekItems,
      weekStart: lastWeekStart,
      weekEnd: lastWeekEnd,
      teamNames: teamNames,
      localeCode: localeCode,
      userPosition: userPosition,
      enrichWeatherForUpcomingDays: 0,
    );

    Map<String, dynamic> playerStats;
    try {
      playerStats = await _playerChatStatsService
          .buildPlayerStatsContext(
            session: session,
            localeCode: localeCode,
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      playerStats = PlayerChatStatsService.unavailablePlayerStatsContext(
        session: session,
        reason: 'stats_load_failed',
      );
    }

    Map<String, dynamic>? playerActivityReport;
    try {
      playerActivityReport =
          await _playerActivityReportChatContext.buildContext(
        session: session,
        localeCode: localeCode,
        userMessage: userMessage,
        referenceDate: today,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'ChatContext playerActivityReport failed: $error\n$stackTrace',
        );
      }
    }

    Map<String, dynamic>? opponentTypicalTeam;
    try {
      opponentTypicalTeam = await _opponentTypicalTeamChatContext.buildContext(
        session: session,
        teams: teams,
        seasonId: seasonId,
        seasonItems: seasonItems,
        teamNames: teamNames,
        nextMatchContext: nextMatch,
        userMessage: userMessage,
        preloadNextMatchOpponent: preloadNextMatchTypicalTeam &&
            (userMessage == null || userMessage.trim().isEmpty),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'ChatContext opponentTypicalTeam failed: $error\n$stackTrace',
        );
      }
    }

    final managedTeamIds = session.managedTeamsIdsForSelectedSeason.toSet();
    final managerTeams = session.managerTeamsForSelectedSeason;

    return <String, dynamic>{
      'userId': userId,
      'seasonId': seasonId,
      'playerId': session.selectedPlayerId,
      'playerName': player == null ? null : playerDisplayName(player),
      'locale': localeCode,
      'today': DateFormat('yyyy-MM-dd').format(today),
      'managerAccess': <String, dynamic>{
        'isManagerOfAnyTeam': managerTeams.isNotEmpty,
        'managedTeamIds': managedTeamIds.toList()..sort(),
        'managedTeams': managerTeams
            .map(
              (Team team) => <String, dynamic>{
                'teamId': team.keyTeam,
                'name': team.name,
              },
            )
            .toList(),
      },
      'teams': teams
          .map(
            (Team team) {
              final teamId = team.keyTeam?.trim() ?? '';
              return <String, dynamic>{
                'teamId': team.keyTeam,
                'name': team.name,
                'clubId': team.clubId,
                if (teamId.isNotEmpty)
                  'isManagedByUser': managedTeamIds.contains(teamId),
              };
            },
          )
          .toList(),
      'agenda': agenda,
      'weeklyAgenda': weeklyAgenda,
      'lastWeekAgenda': lastWeekAgenda,
      if (nextMatch != null) 'nextMatch': nextMatch,
      if (userPosition != null)
        'userLocation': <String, dynamic>{
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        },
      'playerStats': playerStats,
      if (playerActivityReport != null)
        'playerActivityReport': playerActivityReport,
      if (opponentTypicalTeam != null)
        'opponentTypicalTeam': opponentTypicalTeam,
    };
  }

  /// Monday 00:00 local — aligned with the in-app agenda week view.
  static DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static DateTime _startOfLastWeek(DateTime today) {
    return _startOfWeek(today).subtract(const Duration(days: 7));
  }

  static DateTime _endOfLastWeek(DateTime today) {
    return _startOfLastWeek(today).add(const Duration(days: 6));
  }

  /// Firestore query window for chat agenda — extends strict season bounds so
  /// events visible on the agenda screen (month/week navigation) are included.
  static ({DateTime start, DateTime end}) resolveAgendaQueryRange({
    required DateTime seasonStart,
    required DateTime seasonEnd,
    required DateTime today,
  }) {
    final normalizedToday = DateUtils.dateOnly(today);
    final pastAnchor = _startOfWeek(normalizedToday).subtract(
      const Duration(days: 56),
    );
    final futureAnchor = _endOfDay(
      _startOfWeek(normalizedToday).add(const Duration(days: 13)),
    );

    final start = seasonStart.isBefore(pastAnchor) ? seasonStart : pastAnchor;
    final seasonEndOfDay = _endOfDay(seasonEnd);
    final end =
        seasonEndOfDay.isAfter(futureAnchor) ? seasonEndOfDay : futureAnchor;
    return (start: DateUtils.dateOnly(start), end: end);
  }

  static DateTime _endOfDay(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return normalized.add(
      const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
    );
  }

  static bool _isWithinInclusiveDateRange(
    DateTime date,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
  }

  static Map<String, String> _teamNameById(List<Team> teams) {
    return {
      for (final Team team in teams)
        if (team.keyTeam != null) team.keyTeam!: team.name ?? '',
    };
  }

  Future<Map<String, dynamic>> _buildSeasonAgenda({
    required List<AgendaItem> items,
    required String? seasonId,
    required DateTime seasonStart,
    required DateTime seasonEnd,
    required DateTime today,
    required Map<String, String> teamNames,
    required String localeCode,
    required ({double latitude, double longitude})? userPosition,
    required int enrichWeatherForUpcomingDays,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd', localeCode);
    final timeFormat = DateFormat('HH:mm', localeCode);
    final dayFormat = DateFormat.EEEE(localeCode);

    final sorted = List<AgendaItem>.from(items)
      ..sort((AgendaItem a, AgendaItem b) => a.startAt.compareTo(b.startAt));

    final jsonItems = <Map<String, dynamic>>[];
    for (final AgendaItem item in sorted) {
      jsonItems.add(
        await _agendaItemToJson(
          item,
          teamNames: teamNames,
          dateFormat: dateFormat,
          timeFormat: timeFormat,
          dayFormat: dayFormat,
          userPosition: userPosition,
          today: today,
          enrichWeatherForUpcomingDays: enrichWeatherForUpcomingDays,
        ),
      );
    }

    return <String, dynamic>{
      'seasonId': seasonId,
      'seasonStart': dateFormat.format(seasonStart),
      'seasonEnd': dateFormat.format(seasonEnd),
      'today': dateFormat.format(today),
      'itemCount': sorted.length,
      'teamIds': teamNames.keys.toList()..sort(),
      'items': jsonItems,
    };
  }

  Future<Map<String, dynamic>> _buildWeeklyAgenda({
    required List<AgendaItem> items,
    required DateTime weekStart,
    required DateTime weekEnd,
    required Map<String, String> teamNames,
    required String localeCode,
    required ({double latitude, double longitude})? userPosition,
    required int enrichWeatherForUpcomingDays,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd', localeCode);
    final timeFormat = DateFormat('HH:mm', localeCode);
    final dayFormat = DateFormat.EEEE(localeCode);
    final weekLabelFormat = DateFormat.yMMMMd(localeCode);
    final today = DateUtils.dateOnly(DateTime.now());

    final sorted = List<AgendaItem>.from(items)
      ..sort((AgendaItem a, AgendaItem b) => a.startAt.compareTo(b.startAt));

    final jsonItems = <Map<String, dynamic>>[];
    for (final AgendaItem item in sorted) {
      jsonItems.add(
        await _agendaItemToJson(
          item,
          teamNames: teamNames,
          dateFormat: dateFormat,
          timeFormat: timeFormat,
          dayFormat: dayFormat,
          userPosition: userPosition,
          today: today,
          enrichWeatherForUpcomingDays: enrichWeatherForUpcomingDays,
        ),
      );
    }

    return <String, dynamic>{
      'weekStart': dateFormat.format(weekStart),
      'weekEnd': dateFormat.format(weekEnd),
      'weekLabel':
          'Semaine du ${weekLabelFormat.format(weekStart)} au ${weekLabelFormat.format(weekEnd)}',
      'itemCount': sorted.length,
      'items': jsonItems,
    };
  }

  Future<Map<String, dynamic>> _agendaItemToJson(
    AgendaItem item, {
    required Map<String, String> teamNames,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
    required DateFormat dayFormat,
    required ({double latitude, double longitude})? userPosition,
    required DateTime today,
    required int enrichWeatherForUpcomingDays,
  }) async {
    final match = item.match;
    final teamId = match?.teamID?.trim();
    final teamName = teamId != null ? teamNames[teamId] : null;

    final map = <String, dynamic>{
      'id': item.id,
      'date': dateFormat.format(item.startAt),
      'time': timeFormat.format(item.startAt),
      'dayOfWeek': dayFormat.format(item.startAt),
      'type': _contextTypeForItem(item),
      'title': item.title,
      if (teamName != null && teamName.isNotEmpty) 'teamName': teamName,
      if (item.subtitle != null && item.subtitle!.isNotEmpty)
        'subtitle': item.subtitle,
      'isDone': item.isDone,
    };

    if (match != null) {
      map['matchId'] = match.id;
      map['opponent'] = _opponentNameForMatch(match, teamId, teamName);
      map['team1'] = match.team1;
      map['team2'] = match.team2;
      if (teamId != null) {
        map['teamId'] = teamId;
      }
      map['isMatchPlayed'] = match.isMatchPlayed ?? false;
      if (match.isMatchPlayed == true) {
        map['homeScore'] = match.homeScore;
        map['outSideScore'] = match.outSideScore;
      }
      map.addAll(_matchStaticContextFields(match));
      await _enrichMatchLocationWeather(
        map: map,
        match: match,
        dateIso: dateFormat.format(item.startAt),
        time: timeFormat.format(item.startAt),
        userPosition: userPosition,
        today: today,
        enrichWeatherForUpcomingDays: enrichWeatherForUpcomingDays,
      );
    }

    final training = item.training;
    if (training != null) {
      map['trainingId'] = training.ref?.id;
    }

    return map;
  }

  static String _contextTypeForItem(AgendaItem item) {
    switch (item.type) {
      case AgendaItemType.match:
        return 'match';
      case AgendaItemType.entrainement:
      case AgendaItemType.preparationPhysique:
        return 'training';
      case AgendaItemType.nonSport:
        return 'event';
    }
  }

  static AgendaItem? _findNextMatchItem(
    List<AgendaItem> items,
    DateTime now,
  ) {
    AgendaItem? candidate;
    for (final item in items) {
      if (item.type != AgendaItemType.match) continue;
      if (item.isDone || !item.startAt.isAfter(now)) continue;
      if (candidate == null || item.startAt.isBefore(candidate.startAt)) {
        candidate = item;
      }
    }
    return candidate;
  }

  Future<Map<String, dynamic>?> _buildNextMatchContext({
    required AgendaItem? item,
    required List<Team> teams,
    required Map<String, String> teamNames,
    required String? fallbackSeasonId,
    required ({double latitude, double longitude})? userPosition,
  }) async {
    if (item?.match == null) return null;

    final match = item!.match!;
    final teamId = match.teamID?.trim();
    final teamName = teamId != null ? teamNames[teamId] : null;
    final opponentName = _opponentNameForMatch(match, teamId, teamName);

    final map = <String, dynamic>{
      'matchId': match.id,
      'teamId': teamId,
      'teamName': teamName,
      'opponent': opponentName,
      'team1': match.team1,
      'team2': match.team2,
      'date': DateFormat('yyyy-MM-dd').format(item.startAt),
      'time': DateFormat('HH:mm').format(item.startAt),
      'startAt': DateFormat('yyyy-MM-dd HH:mm').format(item.startAt),
      'day': match.day,
      'competitionId': match.competitionID,
      'poule': match.poule,
      'stage': match.stage,
    };

    map.addAll(_matchStaticContextFields(match));
    await _enrichMatchLocationWeather(
      map: map,
      match: match,
      dateIso: DateFormat('yyyy-MM-dd').format(item.startAt),
      time: DateFormat('HH:mm').format(item.startAt),
      userPosition: userPosition,
      today: DateUtils.dateOnly(DateTime.now()),
      enrichWeatherForUpcomingDays: 14,
      alwaysEnrichWeather: true,
    );

    Team? team;
    if (teamId != null) {
      for (final Team candidate in teams) {
        if (candidate.keyTeam == teamId) {
          team = candidate;
          break;
        }
      }
    }
    team ??= teams.isNotEmpty ? teams.first : null;

    if (team != null) {
      final competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
        team: team,
        match: match,
        fallbackSeasonId: fallbackSeasonId,
        teamsPerClubService: _teamsPerClubService,
      );
      if (competitionUrl != null && competitionUrl.isNotEmpty) {
        map['competitionUrl'] = competitionUrl;
      }

      final opponent = opponentForMatch(
        match: match,
        teamId: team.keyTeam ?? '',
        clubId: team.clubId,
      );
      if (opponent != null) {
        map['opponentKey'] = opponent.key;
        map['opponentName'] = opponent.displayName;
        if (opponent.affiliation != null && opponent.affiliation!.isNotEmpty) {
          map['opponentAffiliation'] = opponent.affiliation;
        }
        if (opponent.clubId != null && opponent.clubId!.isNotEmpty) {
          map['opponentClubId'] = opponent.clubId;
        }
      } else if (opponentName != null && opponentName.isNotEmpty) {
        map['opponentName'] = opponentName;
        map['opponentKey'] = opponentStableKey(displayName: opponentName);
      }
    }

    return map;
  }

  static Map<String, dynamic> _matchStaticContextFields(grinta_match.Match match) {
    final map = <String, dynamic>{};
    final surface = match.surfaceDeJeu?.trim() ?? '';
    if (surface.isNotEmpty) {
      map['surfaceDeJeu'] = surface;
    }

    final venueName = match.nomDuTerrain?.trim() ?? '';
    if (venueName.isNotEmpty) {
      map['venueName'] = venueName;
    }

    final venueAddress = match.terrainAdresse1?.trim() ?? '';
    if (venueAddress.isNotEmpty) {
      map['venueAddress'] = venueAddress;
    }

    final location = CalendarEventFormatter.matchLocation(match);
    if (location != null && location.isNotEmpty) {
      map['location'] = location;
    }

    final mapsUrl = CalendarEventFormatter.mapsUrl(match);
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      map['mapsUrl'] = mapsUrl;
    }

    final coords = CalendarEventFormatter.matchCoordinates(match);
    if (coords != null) {
      map['latitude'] = coords.latitude;
      map['longitude'] = coords.longitude;
    }

    final competitionId = match.competitionID?.trim() ?? '';
    if (competitionId.isNotEmpty) {
      map['competitionId'] = competitionId;
    }

    final poule = match.poule?.trim() ?? '';
    if (poule.isNotEmpty) {
      map['poule'] = poule;
    }

    final stage = match.stage?.trim() ?? '';
    if (stage.isNotEmpty) {
      map['stage'] = stage;
    }

    final tour = match.tour?.trim() ?? '';
    if (tour.isNotEmpty) {
      map['tour'] = tour;
    }

    if ((match.day ?? 0) > 0) {
      map['day'] = match.day;
    }

    final chType = match.chType?.trim() ?? '';
    if (chType.isNotEmpty) {
      map['chType'] = chType;
    }

    return map;
  }

  Future<void> _enrichMatchLocationWeather({
    required Map<String, dynamic> map,
    required grinta_match.Match match,
    required String dateIso,
    required String time,
    required ({double latitude, double longitude})? userPosition,
    required DateTime today,
    required int enrichWeatherForUpcomingDays,
    bool alwaysEnrichWeather = false,
  }) async {
    final matchDay = DateTime.tryParse(dateIso);
    final bool withinWeatherWindow = matchDay != null &&
        !matchDay.isBefore(today) &&
        !matchDay.isAfter(
          today.add(Duration(days: enrichWeatherForUpcomingDays)),
        );
    final bool shouldEnrich = alwaysEnrichWeather || withinWeatherWindow;

    final gpsCoords = CalendarEventFormatter.matchCoordinates(match);
    if (gpsCoords != null) {
      map['latitude'] = gpsCoords.latitude;
      map['longitude'] = gpsCoords.longitude;
    }

    if (!shouldEnrich) return;

    final coords =
        gpsCoords ?? await _matchLocationService.resolveMatchCoordinates(match);
    if (coords != null) {
      map['latitude'] = coords.latitude;
      map['longitude'] = coords.longitude;
    }

    if (userPosition != null && coords != null) {
      map['distanceKm'] = _matchLocationService.distanceKm(
        fromLatitude: userPosition.latitude,
        fromLongitude: userPosition.longitude,
        toLatitude: coords.latitude,
        toLongitude: coords.longitude,
      );
    }

    if (coords != null) {
      final weather = await _weatherService.fetchMatchDayForecast(
        latitude: coords.latitude,
        longitude: coords.longitude,
        dateIso: dateIso,
        hourMinute: time,
      );
      if (weather != null) {
        map['weather'] = weather;
      }
    }
  }

  static String? _opponentNameForMatch(
    grinta_match.Match match,
    String? teamId,
    String? teamName,
  ) {
    final t1 = (match.team1 ?? '').trim();
    final t2 = (match.team2 ?? '').trim();

    if (teamName != null && teamName.isNotEmpty) {
      if (t1.toLowerCase() == teamName.toLowerCase()) return t2;
      if (t2.toLowerCase() == teamName.toLowerCase()) return t1;
    }

    if (teamId != null && teamId.isNotEmpty && match.teamID == teamId) {
      return t2.isNotEmpty ? t2 : t1;
    }

    return t2.isNotEmpty ? t2 : t1;
  }
}
