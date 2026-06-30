import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/services/matchService.dart';
import 'package:provider/provider.dart';

/// Handles `grinta://event?type=match&id=...&playerId=...` deep links.
class CalendarDeepLinkService {
  CalendarDeepLinkService._();

  static final CalendarDeepLinkService instance = CalendarDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_handleUri(initialUri));
        });
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_handleUri(uri));
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('CalendarDeepLinkService stream error: $error\n$stackTrace');
        },
      );
    } catch (e, st) {
      debugPrint('CalendarDeepLinkService.init error: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }

  Future<void> _handleUri(Uri uri) async {
    if (uri.scheme != 'grinta') return;

    final host = uri.host;
    if (host != 'event' && uri.path != '/event') return;

    final type = uri.queryParameters['type'];
    final id = uri.queryParameters['id'];
    final playerId = uri.queryParameters['playerId'];

    debugPrint(
      '[CalendarDeepLink] type=$type id=$id playerId=$playerId uri=$uri',
    );

    final context = appNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('[CalendarDeepLink] navigator context unavailable');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('[CalendarDeepLink] user not signed in');
      return;
    }

    if (playerId != null && playerId.isNotEmpty) {
      final appSession = context.read<AppSession>();
      if (appSession.selectedPlayerId != playerId &&
          appSession.currentUserPlayers.containsKey(playerId)) {
        appSession.setSelectedPlayerId(playerId);
      }
    }

    switch (type) {
      case 'match':
        await _openMatchDetail(context, matchId: id);
        break;
      case 'training':
        ShellNavigationScope.tryNavigateToTab(
          context,
          FeatureDiscoveryIds.tabAgenda,
        );
        break;
      default:
        ShellNavigationScope.tryNavigateToTab(
          context,
          FeatureDiscoveryIds.tabAgenda,
        );
        break;
    }
  }

  Future<void> _openMatchDetail(
    BuildContext context, {
    required String? matchId,
  }) async {
    if (matchId == null || matchId.isEmpty) {
      debugPrint('[CalendarDeepLink] missing match id');
      return;
    }

    final match = await MatchService().getMatchById(matchId);
    if (match == null) {
      debugPrint('[CalendarDeepLink] match not found: $matchId');
      return;
    }

    if (!context.mounted) return;

    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;
    final isManager = _isManagerForMatch(appSession, match);

    appNavigatorKey.currentState?.push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.matchDetail,
        fullscreenDialog: true,
        builder: (_) => MatchDetailScreen(
          match: match,
          isManager: isManager,
          playerId: playerId,
          initialTabIndex: 0,
        ),
      ),
    );
  }

  bool _isManagerForMatch(AppSession session, models.Match match) {
    final managedIds = session.managedTeamsIdsForSelectedSeason;
    final matchTeams = match.teams ?? const <String>[];
    return matchTeams.any(managedIds.contains);
  }
}
