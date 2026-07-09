import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/player_activity_report_service.dart';
import 'package:grinta/util/ask_diego_activity_period.dart';

/// Intent detection and activity-report context for Ask Gio.
class PlayerActivityReportChatContext {
  PlayerActivityReportChatContext({
    PlayerActivityReportService? playerActivityReportService,
  }) : _playerActivityReportService =
            playerActivityReportService ?? PlayerActivityReportService();

  final PlayerActivityReportService _playerActivityReportService;

  static const Duration _computeTimeout = Duration(seconds: 25);

  static final RegExp _activityIntentPattern = RegExp(
    r'(?:bilan|resume|resumé|résumé|synthese|synthèse|summary|report|recap|récap).{0,40}(?:activite|activité|activity|entrainements?|trainings?|performance?s?)'
    r'|(?:mon|ma|mes|my)\s+(?:activite|activité|activity|performances?|stats?\s+(?:personnelles?|tracker)?)'
    r'|activity\s+summary'
    r'|(?:bilan|resume|resumé|résumé)\s+(?:de\s+|sur\s+|du\s+|d(?:e\s+|u\s+))(?:mon\s+)?(?:activite|activité)'
    r'|(?:combien|how\s+many).{0,60}(?:entrainements?|trainings?|matchs?|matches?).{0,40}(?:present|présent|joue|played|particip)',
    caseSensitive: false,
  );

  static final RegExp _periodPattern = RegExp(
    r'\b(?:janvier|january|januar|fevrier|february|februar|mars|march|marz|marzo|avril|april|abril|aprile|mai|may|maggio|mayo|juin|june|juni|junio|giugno|juillet|july|juli|julio|luglio|aout|august|augustus|agosto|septembre|september|septiembre|settembre|octobre|october|oktober|octubre|ottobre|novembre|november|noviembre|decembre|december|dezember|diciembre|dicembre)\b|'
    r'\b(?:semaine|week|settimana|woche|semana)\s+(?:derniere|dernière|passee|passée|precedente|précédente|last|previous|scorsa|letzte|pasada|anterior)\b|'
    r'\b(?:cette|this|questa|diese|esta)\s+(?:semaine|week|settimana|woche|semana)\b|'
    r'\b(?:mois|month|mese|mes)\s+(?:dernier|last|scorso|letzten|pasado|anterior)\b|'
    r'\b(?:last|derniers?|ultimi|letzten?)\s+\d{1,3}\s+(?:days?|jours?|giorni|tage)\b|'
    r'\b\d{4}[-/]\d{1,2}\b',
    caseSensitive: false,
  );

  /// Whether [message] asks for a period-based personal activity report.
  static bool detectsActivityReportIntent(String? message) {
    final normalized = message?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }

    if (_activityIntentPattern.hasMatch(normalized)) {
      return true;
    }

    final hasSummaryWord = RegExp(
      r'(?:bilan|resume|resumé|résumé|synthese|synthèse|summary|recap|récap|report)',
      caseSensitive: false,
    ).hasMatch(normalized);
    if (hasSummaryWord && _periodPattern.hasMatch(normalized)) {
      return true;
    }

    final hasPeriod = _periodPattern.hasMatch(normalized);
    final hasPersonalStats = RegExp(
      r'\b(?:mon|ma|mes|my)\s+(?:activite|activité|activity|temps\s+de\s+jeu|presence|présence|assiduite|performances?|stats?)\b|'
      r'\b(?:temps\s+de\s+jeu|playing\s+time|training\s+attendance|tracker)\b',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasPeriod && hasPersonalStats;
  }

  Future<Map<String, dynamic>?> buildContext({
    required AppSession session,
    required String localeCode,
    String? userMessage,
    required DateTime referenceDate,
  }) async {
    final message = userMessage?.trim() ?? '';
    if (!detectsActivityReportIntent(message)) {
      return null;
    }

    final period = parseActivityPeriodFromMessage(
      message: message,
      referenceDate: referenceDate,
      localeCode: localeCode,
    );

    if (period == null) {
      return <String, dynamic>{
        'dataUnavailableReason': 'period_not_understood',
        'requestedMessage': message,
      };
    }

    try {
      return await _playerActivityReportService
          .buildActivityReport(
            session: session,
            period: period,
            localeCode: localeCode,
          )
          .timeout(_computeTimeout);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'PlayerActivityReportChatContext failed: $error\n$stackTrace',
        );
      }
      return <String, dynamic>{
        'period': period.toJson(),
        'dataUnavailableReason': 'report_load_failed',
        'requestedMessage': message,
      };
    }
  }
}
