import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:provider/provider.dart';

/// Handles `grinta://event?type=match&id=...&playerId=...` deep links.
class CalendarDeepLinkService {
  CalendarDeepLinkService._();

  static final CalendarDeepLinkService instance = CalendarDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Timer? _retryTimer;
  bool _initialized = false;
  bool _shellReady = false;

  Uri? _pendingUri;
  int _retryCount = 0;

  static const int _maxRetries = 80;
  static const Duration _retryInterval = Duration(milliseconds: 250);

  /// When set, [WebAppRoot] passes this date to [AgendaScreen.initialDate].
  final ValueNotifier<DateTime?> pendingAgendaDate = ValueNotifier(null);

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      await _capturePlatformLinks(source: 'init');

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => _enqueueUri(uri, source: 'uriLinkStream'),
        onError: (Object error, StackTrace stackTrace) {
          _log('stream error: $error\n$stackTrace');
        },
      );
    } catch (e, st) {
      _log('init error: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _initialized = false;
    _shellReady = false;
  }

  /// Call when [WebAppRoot] splash overlay is gone and the shell is mounted.
  void notifyShellReady() {
    if (_shellReady) return;
    _shellReady = true;
    _log('shell ready');
    unawaited(processPendingIfReady());
  }

  /// Call when the authenticated shell is ready (e.g. after [WebAppRoot] loads).
  Future<void> processPendingIfReady() async {
    await _capturePlatformLinks(source: 'processPendingIfReady');
    if (_pendingUri == null) return;
    _retryCount = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _tryProcessPending();
  }

  Future<void> _capturePlatformLinks({required String source}) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      final latestUri = await _appLinks.getLatestLink();
      _log(
        '$source platform links initial=$initialUri latest=$latestUri '
        'pending=$_pendingUri',
      );

      for (final uri in <Uri?>[initialUri, latestUri]) {
        if (uri != null) {
          _enqueueUri(uri, source: source, scheduleProcessing: false);
        }
      }

      if (_pendingUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_tryProcessPending());
        });
      }
    } catch (e, st) {
      _log('_capturePlatformLinks($source) error: $e\n$st');
    }
  }

  void _enqueueUri(
    Uri uri, {
    required String source,
    bool scheduleProcessing = true,
  }) {
    if (!_isEventDeepLink(uri)) {
      _log('ignored non-event uri from $source: $uri');
      return;
    }

    if (_pendingUri?.toString() == uri.toString()) {
      _log('duplicate uri from $source: $uri');
      return;
    }

    _pendingUri = uri;
    _retryCount = 0;
    _log('queued from $source: $uri');

    if (!scheduleProcessing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_tryProcessPending());
    });
  }

  Future<void> _tryProcessPending() async {
    final uri = _pendingUri;
    if (uri == null) return;

    final context = appNavigatorKey.currentContext;
    if (!_isAppReady(context)) {
      _scheduleRetry();
      return;
    }

    _pendingUri = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;

    _log('processing $uri');
    await _handleUri(uri, context!);
  }

  void _scheduleRetry() {
    if (_pendingUri == null) return;
    if (_retryCount >= _maxRetries) {
      _log(
        'app not ready after $_maxRetries retries; '
        'keeping pending uri until shell/auth ready: $_pendingUri',
      );
      return;
    }

    _retryTimer?.cancel();
    _retryCount++;
    _retryTimer = Timer(_retryInterval, () {
      unawaited(_tryProcessPending());
    });
  }

  bool _isAppReady(BuildContext? context) {
    if (context == null) {
      if (kDebugMode && _retryCount.isEven) {
        _log('not ready: navigator context is null');
      }
      return false;
    }

    if (!_shellReady) {
      if (kDebugMode && _retryCount.isEven) {
        _log('not ready: shell not mounted');
      }
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode && _retryCount.isEven) {
        _log('not ready: no firebase user');
      }
      return false;
    }

    final appSession = context.read<AppSession>();
    if (appSession.isLoading) {
      if (kDebugMode && _retryCount.isEven) {
        _log('not ready: AppSession loading');
      }
      return false;
    }
    if (appSession.user?.uid != user.uid) {
      if (kDebugMode && _retryCount.isEven) {
        _log(
          'not ready: AppSession uid=${appSession.user?.uid} '
          'firebase uid=${user.uid}',
        );
      }
      return false;
    }

    return true;
  }

  static bool _isEventDeepLink(Uri uri) {
    if (uri.scheme != 'grinta') return false;

    final host = uri.host;
    final path = uri.path;
    if (host == 'event') return true;
    if (path == '/event' || path == 'event') return true;
    return false;
  }

  Future<void> _handleUri(Uri uri, BuildContext context) async {
    final type = uri.queryParameters['type'];
    final id = uri.queryParameters['id'];
    final playerId = uri.queryParameters['playerId'];

    _log('type=$type id=$id playerId=$playerId uri=$uri');

    if (!context.mounted) return;

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
        await _openTraining(context, trainingId: id);
        break;
      case 'personalSport':
        _navigateToAgenda(context);
        _showComingSoonSnackbar(context);
        break;
      case 'nonSport':
      case 'event':
        _navigateToAgenda(context);
        break;
      default:
        _log('unknown type=$type');
        _navigateToAgenda(context);
        break;
    }
  }

  Future<void> _openTraining(
    BuildContext context, {
    required String? trainingId,
  }) async {
    DateTime? trainingDate;
    if (trainingId != null && trainingId.isNotEmpty) {
      final training = await TrainingService().getTrainingById(trainingId);
      trainingDate = training?.dateTime?.toDate();
    }

    if (trainingDate != null) {
      pendingAgendaDate.value = DateUtils.dateOnly(trainingDate);
    }

    if (!context.mounted) return;
    _navigateToAgenda(context);
    _showComingSoonSnackbar(context);
  }

  Future<void> _openMatchDetail(
    BuildContext context, {
    required String? matchId,
  }) async {
    if (matchId == null || matchId.isEmpty) {
      _log('missing match id');
      return;
    }

    final match = await MatchService().getMatchById(matchId);
    if (match == null) {
      _log('match not found: $matchId');
      if (context.mounted) {
        AppSnackbar.show(
          context,
          context.l10n.errorGeneric('match'),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;
    final isManager = _isManagerForMatch(appSession, match);

    _pushMatchDetailAfterFrames(
      match: match,
      isManager: isManager,
      playerId: playerId,
    );
  }

  void _pushMatchDetailAfterFrames({
    required models.Match match,
    required bool isManager,
    required String? playerId,
  }) {
    void push() {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        _log('navigator unavailable when pushing match detail');
        return;
      }

      _log('pushing MatchDetailScreen matchId=${match.id}');
      navigator.push(
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        push();
      });
    });
  }

  void _navigateToAgenda(BuildContext context) {
    if (ShellNavigationScope.tryNavigateToTab(
      context,
      FeatureDiscoveryIds.tabAgenda,
    )) {
      _log('navigated to agenda tab');
      return;
    }
    _log('agenda tab navigation unavailable');
  }

  void _showComingSoonSnackbar(BuildContext context) {
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.matchDetailTrackerKitComingSoon,
      isError: false,
    );
  }

  bool _isManagerForMatch(AppSession session, models.Match match) {
    final managedIds = session.managedTeamsIdsForSelectedSeason;
    final matchTeams = match.teams ?? const <String>[];
    return matchTeams.any(managedIds.contains);
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[CalendarDeepLink] $message');
  }
}
