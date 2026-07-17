import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/agenda_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/util/ask_diego_activity_period.dart';
import 'package:grinta/util/season_period_ranges.dart';
import 'package:intl/intl.dart';

/// Intent detection + session/match PDF report context for Ask Gio.
class SessionReportChatContext {
  SessionReportChatContext({
    AgendaService? agendaService,
    TeamWorkloadSummaryService? summaryService,
  })  : _agendaService = agendaService ?? AgendaService(),
        _summaryService = summaryService ?? TeamWorkloadSummaryService();

  final AgendaService _agendaService;
  final TeamWorkloadSummaryService _summaryService;

  static const Duration _computeTimeout = Duration(seconds: 25);

  static final RegExp _reportIntentPattern = RegExp(
    r'(?:rapport|report|pdf).{0,80}(?:seance|séance|session|entrainement|entraînement|training|match)|'
    r'(?:envoie|envoyer|envoyerai|send|manda|envia|schicken).{0,80}(?:rapport|report|pdf)|'
    r"(?:m[\s']?envoyer|me\s+envoyer).{0,80}(?:pdf|rapport|report)|"
    r'(?:rapport|report).{0,80}(?:hier|yesterday|aujourd|today|avant[\s-]hier)',
    caseSensitive: false,
  );

  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  /// Whether [message] asks to email a session/match stats PDF report.
  static bool detectsSessionReportIntent(String? message) {
    final normalized = message?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }
    return _reportIntentPattern.hasMatch(normalized);
  }

  static String? extractEmailFromMessage(String? message) {
    final match = _emailPattern.firstMatch(message ?? '');
    return match?.group(0);
  }

  Future<Map<String, dynamic>?> buildContext({
    required AppSession session,
    required String localeCode,
    String? userMessage,
    required DateTime referenceDate,
  }) async {
    final message = userMessage?.trim() ?? '';
    if (!detectsSessionReportIntent(message)) {
      return null;
    }

    final period = parseActivityPeriodFromMessage(
      message: message,
      referenceDate: referenceDate,
      localeCode: localeCode,
    );

    final requestedEmail = extractEmailFromMessage(message);
    final defaultEmail = session.user?.email?.trim();

    if (period == null) {
      return <String, dynamic>{
        'dataUnavailableReason': 'period_not_understood',
        'requestedMessage': message,
        if (requestedEmail != null) 'requestedEmail': requestedEmail,
        if (defaultEmail != null && defaultEmail.isNotEmpty)
          'defaultEmail': defaultEmail,
      };
    }

    try {
      return await _buildSessionReports(
        session: session,
        period: period,
        localeCode: localeCode,
        requestedMessage: message,
        requestedEmail: requestedEmail,
        defaultEmail: defaultEmail,
      ).timeout(_computeTimeout);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('SessionReportChatContext failed: $error\n$stackTrace');
      }
      return <String, dynamic>{
        'period': period.toJson(),
        'dataUnavailableReason': 'report_load_failed',
        'requestedMessage': message,
        if (requestedEmail != null) 'requestedEmail': requestedEmail,
        if (defaultEmail != null && defaultEmail.isNotEmpty)
          'defaultEmail': defaultEmail,
      };
    }
  }

  Future<Map<String, dynamic>> _buildSessionReports({
    required AppSession session,
    required AskDiegoActivityPeriod period,
    required String localeCode,
    required String requestedMessage,
    required String? requestedEmail,
    required String? defaultEmail,
  }) async {
    final season = session.selectedSeason;
    final seasonId = season?.ref?.id;
    final teams = session.teamsForAgendaSelectedSeason;
    final memberId = session.selectedPlayerId?.trim();

    if (teams.isEmpty && (memberId == null || memberId.isEmpty)) {
      return <String, dynamic>{
        'period': period.toJson(),
        'dataUnavailableReason': 'missing_session_player_or_season',
        'requestedMessage': requestedMessage,
        if (requestedEmail != null) 'requestedEmail': requestedEmail,
        if (defaultEmail != null && defaultEmail.isNotEmpty)
          'defaultEmail': defaultEmail,
      };
    }

    final seasonRanges = resolveSeasonPeriodRanges(
      seasonId: seasonId ?? '',
      season: season,
    );
    final queryStart = DateUtils.dateOnly(period.start);
    final queryEndExclusive =
        DateUtils.dateOnly(period.end).add(const Duration(days: 1));

    final items = await _agendaService.loadAgendaItems(
      teams: teams,
      seasonId: seasonId,
      start: queryStart.isBefore(seasonRanges.fullSeason.start)
          ? DateUtils.dateOnly(seasonRanges.fullSeason.start)
          : queryStart,
      end: queryEndExclusive.isAfter(seasonRanges.fullSeason.end)
          ? DateUtils.dateOnly(seasonRanges.fullSeason.end)
              .add(const Duration(days: 1))
          : queryEndExclusive,
      memberId: memberId,
    );

    final dateFormat = DateFormat('yyyy-MM-dd', localeCode);
    final timeFormat = DateFormat('HH:mm', localeCode);
    final teamNames = <String, String>{
      for (final team in teams)
        if ((team.keyTeam ?? '').trim().isNotEmpty)
          team.keyTeam!.trim(): (team.name ?? '').trim(),
    };
    final sessions = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item.type == AgendaItemType.nonSport) continue;
      final day = DateUtils.dateOnly(item.startAt);
      if (day.isBefore(period.start) || day.isAfter(period.end)) {
        continue;
      }

      final isMatch = item.type == AgendaItemType.match;
      final eventId = item.id.trim();
      if (eventId.isEmpty) continue;

      final summary = await _summaryService.getByEventId(eventId);
      final hasStats =
          summary != null && summary.playerScores.isNotEmpty;

      final teamId = (item.match?.teamID ?? item.training?.teamId ?? '')
          .trim();
      final teamName = teamId.isNotEmpty ? teamNames[teamId] : null;

      sessions.add(<String, dynamic>{
        'eventId': eventId,
        'type': isMatch ? 'match' : 'training',
        'title': item.title,
        if ((item.subtitle ?? '').trim().isNotEmpty) 'subtitle': item.subtitle,
        if (teamId.isNotEmpty) 'teamId': teamId,
        if (teamName != null && teamName.isNotEmpty) 'teamName': teamName,
        'date': dateFormat.format(item.startAt),
        'time': timeFormat.format(item.startAt),
        'hasStats': hasStats,
        if (hasStats) 'playersCount': summary.playersCount,
        if (hasStats)
          'averageWorkloadScore':
              double.parse(summary.averageWorkloadScore.toStringAsFixed(1)),
      });
    }

    sessions.sort((a, b) {
      final dateCompare =
          (a['date'] as String).compareTo(b['date'] as String);
      if (dateCompare != 0) return dateCompare;
      return (a['time'] as String).compareTo(b['time'] as String);
    });

    return <String, dynamic>{
      'period': period.toJson(),
      'sessions': sessions,
      'sessionCount': sessions.length,
      'sessionsWithStatsCount':
          sessions.where((s) => s['hasStats'] == true).length,
      'requestedMessage': requestedMessage,
      if (requestedEmail != null) 'requestedEmail': requestedEmail,
      if (defaultEmail != null && defaultEmail.isNotEmpty)
        'defaultEmail': defaultEmail,
      if (sessions.isEmpty) 'dataUnavailableReason': 'no_sessions_in_period',
      if (sessions.isNotEmpty &&
          sessions.every((s) => s['hasStats'] != true))
        'dataUnavailableReason': 'no_stats_for_sessions',
    };
  }
}
