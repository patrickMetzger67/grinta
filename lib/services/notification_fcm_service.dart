import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/config/fcm_config.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/feature_discovery/shell_navigation_scope.dart';
import 'package:grinta/firebase_options.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/screen/session_player_feeling_screen.dart';
import 'package:grinta/screen/teamDetailScreen.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/internal_notification_navigation.dart';
import 'package:grinta/services/notification_fcm_platform.dart';
import 'package:grinta/services/notification_fcm_web_notify.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:grinta/screen/chat/stream_channel_ui_helpers.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/chat_fcm_notification.dart';
import 'package:grinta/util/staff_session_access.dart';
import 'package:grinta/widget/grinta_stream_message_input.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Push notification (FCM) setup, token persistence, and tap navigation.
///
/// Cloud Functions (region `europe-west1`):
/// - `sendPushFCMNotification` — [`functions/send_push_fcm.js`](../../functions/send_push_fcm.js);
///   see [fcm_config.dart] for dual-brand payload (`brand`: `grinta` | `aserstein`)
/// - `sendSms` — payload: to, message, clubId (not in this repo)
///
/// ## Web support
/// - Token registration, permission prompt, foreground display (browser Notification
///   API), and [FirebaseMessaging.onMessageOpenedApp] work when the app tab is open.
/// - Background delivery uses [web/firebase-messaging-sw.js]; requires a VAPID public
///   key via `--dart-define=FCM_WEB_VAPID_KEY=…` (see [fcm_config.dart]).
///
/// ## Web limitations (firebase_messaging_web)
/// - [FirebaseMessaging.getInitialMessage] always returns null — no cold-start deep link.
/// - [FirebaseMessaging.onBackgroundMessage] is not wired on web; background handling
///   lives in the service worker only (focus tab, no Dart navigation).
/// - [FirebaseMessaging.onTokenRefresh] is a no-op stream on web — re-fetch on login.
/// - subscribeToTopic / unsubscribeFromTopic are unsupported on web.
/// - Requires HTTPS (or localhost) and a browser with Push API / service workers.
class NotificationFCMService {
  NotificationFCMService._();

  static final NotificationFCMService instance = NotificationFCMService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      _localNotificationsPlugin;

  static const String androidChannelId = 'fcm_channel';
  static const String _androidChannelName = 'Notifications';

  static bool _initialized = false;
  static bool _localNotificationsReady = false;
  static Timer? _iosFcmTokenRetryTimer;
  static StreamChatClient? _streamClient;

  /// Conversation currently on screen — suppress duplicate chat alerts.
  static String? activeChatChannelCid;

  /// Call from [main] after [Firebase.initializeApp].
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (kIsWeb) {
        await _initWeb();
      } else {
        await _initNative();
      }
    } catch (e, st) {
      debugPrint('NotificationFCMService.init() error: $e\n$st');
    }
  }

  static Future<void> _initWeb() async {
    final supported = await _messaging.isSupported();
    if (!supported) {
      debugPrint('[FCM web] Push not supported in this browser.');
      return;
    }

    if (!fcmWebVapidKeyConfigured) {
      debugPrint(
        '[FCM web] FCM_WEB_VAPID_KEY not set — skipping token registration. '
        'Add the Web Push public key to dart_defines.json and rebuild.',
      );
    }

    await _requestPermissions();
    if (fcmWebVapidKeyConfigured) {
      await _registerFCMToken();
    }
    _registerHandlers();
    _registerAuthTokenSync();

    // getInitialMessage() is always null on web — no cold-start deep link.
  }

  static Future<void> _initNative() async {
    await _requestPermissions();
    await _createAndroidChannelIfNeeded();
    await _initializeLocalNotifications();
    await _registerFCMToken();
    _registerHandlers();
    _registerAuthTokenSync();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleOpenFromData(initialMessage.data));
      });
    }
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      return;
    }

    if (NotificationFcmPlatform.isIOS) {
      await _messaging.setAutoInitEnabled(true);
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (NotificationFcmPlatform.isAndroid) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      if (await Permission.notification.isDenied ||
          await Permission.notification.isRestricted) {
        await Permission.notification.request();
      }
    }
  }

  static Future<void> _createAndroidChannelIfNeeded() async {
    if (kIsWeb || !NotificationFcmPlatform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      androidChannelId,
      _androidChannelName,
      description: 'Canal principal FCM',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings(kFcmAndroidNotificationIcon);

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    if (_localNotificationsReady) return;

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final type = data['type']?.toString().trim() ?? '';
            if (!EshopConfigService.instance.commerceNotificationsEnabled &&
                isCommerceNotificationPayloadType(type)) {
              return;
            }
            if (type == 'trainingReminder' ||
                type == 'matchOpponentStatsReminder') {
              unawaited(InternalNotificationNavigation.handlePayload(data));
            } else {
              unawaited(_handleOpenFromData(data));
            }
          });
        } catch (e, st) {
          debugPrint('Local notif tap parse error: $e\n$st');
        }
      },
    );
    _localNotificationsReady = true;
  }

  /// Safe to call from the FCM background isolate (re-inits the plugin).
  static Future<void> ensureLocalNotificationsReady() async {
    if (kIsWeb) return;
    await _createAndroidChannelIfNeeded();
    await _initializeLocalNotifications();
  }

  static void bindStreamClient(StreamChatClient? client) {
    _streamClient = client;
  }

  /// Registers the current FCM token with Stream Chat for offline/background
  /// delivery when the Stream dashboard has Firebase push configured.
  static Future<void> registerTokenWithStream([
    StreamChatClient? client,
  ]) async {
    final streamClient = client ?? _streamClient;
    if (streamClient == null || streamClient.state.currentUser == null) {
      return;
    }
    try {
      final token = await _getFcmToken();
      if (token == null || token.isEmpty) return;
      await streamClient.addDevice(token, PushProvider.firebase);
    } catch (e, st) {
      debugPrint('NotificationFCMService: Stream addDevice failed: $e\n$st');
    }
  }

  /// Foreground / background local alert for any FCM type (Android + iOS).
  static Future<void> showLocalPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? notificationKey,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;
    final trimmedBody = body.trim();

    if (kIsWeb) {
      await showWebForegroundNotification(
        title: trimmedTitle,
        body: trimmedBody,
      );
      return;
    }

    try {
      await ensureLocalNotificationsReady();
      await _localNotificationsPlugin.show(
        notificationIdForKey(notificationKey ?? trimmedTitle),
        trimmedTitle,
        trimmedBody,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            _androidChannelName,
            icon: kFcmAndroidNotificationIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload == null ? null : jsonEncode(payload),
      );
    } catch (e, st) {
      debugPrint(
        'NotificationFCMService: local push notification failed: $e\n$st',
      );
    }
  }

  /// Chat-originated local banner (Stream events while the app is open).
  static Future<void> showIncomingChatNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? notificationKey,
  }) {
    return showLocalPushNotification(
      title: title,
      body: body,
      payload: payload,
      notificationKey: notificationKey,
    );
  }

  static Future<void> showRemoteMessageAsLocalNotification(
    RemoteMessage message,
  ) async {
    if (kIsWeb) return;
    if (!shouldDisplayRemoteFcm(
      data: message.data,
      activeChatChannelCid: activeChatChannelCid,
    )) {
      return;
    }

    final parsed = parseFcmNotification(
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
      data: message.data,
    );
    if (parsed == null) return;

    final key = firstNonEmptyText([
      parsed.payload['cid']?.toString(),
      parsed.payload['id']?.toString(),
      parsed.payload['channel_id']?.toString(),
      parsed.payload['type']?.toString(),
      parsed.title,
    ]);

    await showLocalPushNotification(
      title: parsed.title,
      body: parsed.body,
      payload: parsed.payload,
      notificationKey: key,
    );
  }

  /// Web requires [kFcmWebVapidKey]; native uses default APNs/FCM registration.
  static Future<String?> _getFcmToken() async {
    if (kIsWeb) {
      if (!fcmWebVapidKeyConfigured) return null;
      return _messaging.getToken(vapidKey: kFcmWebVapidKey);
    }
    if (NotificationFcmPlatform.isIOS) {
      return _getFcmTokenWithIosApnsRetry();
    }
    return _messaging.getToken();
  }

  static bool _isApnsTokenNotSetError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('apns-token-not-set') ||
        text.contains('apns token has not been received');
  }

  /// iOS may not have an APNS token at cold start (simulator/device timing).
  static Future<String?> _getFcmTokenWithIosApnsRetry() async {
    const attempts = 5;
    const delay = Duration(milliseconds: 800);

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null && attempt < attempts - 1) {
          await Future<void>.delayed(delay);
          continue;
        }
        return await _messaging.getToken();
      } catch (e) {
        if (_isApnsTokenNotSetError(e) && attempt < attempts - 1) {
          await Future<void>.delayed(delay);
          continue;
        }
        if (_isApnsTokenNotSetError(e)) {
          _scheduleIosFcmTokenRetry();
          return null;
        }
        rethrow;
      }
    }

    _scheduleIosFcmTokenRetry();
    return null;
  }

  static void _scheduleIosFcmTokenRetry() {
    if (kIsWeb || !NotificationFcmPlatform.isIOS) return;
    _iosFcmTokenRetryTimer?.cancel();
    _iosFcmTokenRetryTimer = Timer(const Duration(seconds: 5), () {
      unawaited(_registerFCMToken());
    });
  }

  static Future<void> _registerFCMToken() async {
    try {
      final token = await _getFcmToken();
      if (token == null || token.isEmpty) return;

      debugPrint('FCM token: $token');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await saveTokenToFirestore(uid);
      }
    } catch (e, st) {
      if (_isApnsTokenNotSetError(e)) {
        _scheduleIosFcmTokenRetry();
        return;
      }
      debugPrint('FCM token registration failed: $e\n$st');
    }
  }

  static void _registerAuthTokenSync() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) return;
      unawaited(saveTokenToFirestore(user.uid));
    });

    if (kIsWeb) {
      // onTokenRefresh is a no-op stream on web; token is re-fetched on sign-in.
      return;
    }

    _messaging.onTokenRefresh.listen((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(saveTokenToFirestore(uid));
      }
      unawaited(registerTokenWithStream());
    });
  }

  static void _registerHandlers() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[FCM foreground] data=${message.data}');

      final type = message.data['type']?.toString().trim() ?? '';
      if (!EshopConfigService.instance.commerceNotificationsEnabled &&
          isCommerceNotificationPayloadType(type)) {
        debugPrint('[FCM foreground] commerce notification suppressed: $type');
        return;
      }

      final notification = message.notification;
      if (notification == null) {
        if (kIsWeb) {
          final parsed = parseFcmNotification(data: message.data);
          if (parsed != null) {
            await showWebForegroundNotification(
              title: parsed.title,
              body: parsed.body,
              icon: _foregroundIconFromMessage(message),
            );
          }
          return;
        }
        await showRemoteMessageAsLocalNotification(message);
        return;
      }

      if (kIsWeb) {
        await showWebForegroundNotification(
          title: notification.title,
          body: notification.body,
          icon: _foregroundIconFromMessage(message),
        );
        return;
      }

      // iOS already presents the APNs alert (all types) via
      // setForegroundNotificationPresentationOptions + AppDelegate.willPresent.
      if (NotificationFcmPlatform.isIOS) {
        return;
      }

      await showRemoteMessageAsLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM opened] data=${message.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleOpenFromData(message.data));
      });
    });
  }

  static Future<void> _handleOpenFromData(Map<String, dynamic> data) async {
    debugPrint('[FCM navigation] data=$data');

    final context = appNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('[FCM navigation] navigator context unavailable');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('[FCM navigation] user not signed in');
      return;
    }

    final id = data['id']?.toString();
    final type = data['type']?.toString();
    final body = data['body']?.toString();

    if (!EshopConfigService.instance.commerceNotificationsEnabled &&
        isCommerceNotificationPayloadType(type)) {
      debugPrint('[FCM navigation] commerce notification suppressed: $type');
      return;
    }

    try {
      switch (type) {
        case 'mvpOpenVoting':
          // TODO: dedicated MVP voting screen when available in Grinta.
          await _openMatchDetail(
            context,
            matchId: id,
            initialTabIndex: 0,
          );
          break;

        case 'RPEBefore':
          debugPrint(
            '[FCM navigation] RPEBefore stub (eventId=$id)',
          );
          _navigateToShellTab(context, FeatureDiscoveryIds.tabAgenda);
          break;

        case 'RPEAfter':
          await _openSessionFeelingRecap(
            context,
            eventId: id,
            eventType: data['eventType']?.toString(),
            playerId: data['playerId']?.toString(),
            teamId: data['teamId']?.toString(),
          );
          break;

        case 'event':
          // TODO: partner event detail screen when available in Grinta.
          debugPrint('[FCM navigation] event notification stub (eventId=$id)');
          _navigateToShellTab(context, FeatureDiscoveryIds.tabAgenda);
          break;

        case 'highlights':
          await _openMatchDetail(
            context,
            matchId: id,
            initialTabIndex: 3,
          );
          break;

        case 'convocation':
          await _openMatchDetail(
            context,
            matchId: id,
            initialTabIndex: 1,
            convocationBody: body,
          );
          break;

        case 'chat':
        case 'chatGroup':
        case 'message.new':
        case 'notification.message_new':
          await _openChatChannel(
            context,
            channelId: id ??
                data['cid']?.toString() ??
                data['channel_id']?.toString(),
          );
          break;

        case 'payment':
          // TODO: loyalty / payment detail screen when available in Grinta.
          debugPrint('[FCM navigation] payment notification stub (id=$id)');
          _navigateToShellTab(context, FeatureDiscoveryIds.tabDashboard);
          break;

        case 'teamDetail':
          await _openTeamDetail(
            context,
            teamId: id,
            seasonId: data['seasonId']?.toString(),
          );
          break;

        case 'trainingReminder':
        case 'matchOpponentStatsReminder':
          await InternalNotificationNavigation.handlePayload(data);
          break;

        default:
          _navigateToShellTab(context, FeatureDiscoveryIds.tabDashboard);
          break;
      }
    } catch (e, st) {
      debugPrint('_handleOpenFromData error: $e\n$st');
    }
  }

  static void _navigateToShellTab(BuildContext context, String featureId) {
    if (ShellNavigationScope.tryNavigateToTab(context, featureId)) {
      return;
    }
    debugPrint('[FCM navigation] shell tab $featureId unavailable');
  }

  /// Opens the session feeling recap from an in-app notification tap.
  static Future<void> openSessionFeelingFromNotification({
    required String eventId,
    String? playerId,
    String? eventType,
    String? teamId,
  }) async {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    await _openSessionFeelingRecap(
      context,
      eventId: eventId,
      eventType: eventType,
      playerId: playerId,
      teamId: teamId,
    );
  }

  static Future<void> _openSessionFeelingRecap(
    BuildContext context, {
    required String? eventId,
    String? eventType,
    String? playerId,
    String? teamId,
  }) async {
    final trimmedEventId = eventId?.trim() ?? '';
    if (trimmedEventId.isEmpty) {
      debugPrint('[FCM navigation] missing feeling event id');
      return;
    }

    final appSession = context.read<AppSession>();
    final resolvedPlayerId =
        (playerId?.trim().isNotEmpty == true)
            ? playerId!.trim()
            : (appSession.selectedPlayerId?.trim() ?? '');
    if (resolvedPlayerId.isEmpty) {
      debugPrint('[FCM navigation] missing feeling player id');
      _navigateToShellTab(context, FeatureDiscoveryIds.tabAgenda);
      return;
    }

    // Open immediately — type/team resolution happens inside the screen.
    final typeKey = (eventType ?? '').trim().toLowerCase();
    final SessionFeelingScreenEventType? screenType = switch (typeKey) {
      'match' => SessionFeelingScreenEventType.match,
      'training' => SessionFeelingScreenEventType.training,
      _ => null,
    };

    appNavigatorKey.currentState?.push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.sessionPlayerFeeling,
        fullscreenDialog: true,
        builder: (_) => SessionPlayerFeelingScreen(
          eventId: trimmedEventId,
          playerId: resolvedPlayerId,
          eventType: screenType,
          teamId: teamId?.trim(),
        ),
      ),
    );
  }

  static Future<void> _openMatchDetail(
    BuildContext context, {
    required String? matchId,
    required int initialTabIndex,
    String? convocationBody,
  }) async {
    if (matchId == null || matchId.isEmpty) {
      debugPrint('[FCM navigation] missing match id');
      return;
    }

    final match = await MatchService().getMatchById(matchId);
    if (match == null) {
      debugPrint('[FCM navigation] match not found: $matchId');
      return;
    }

    if (convocationBody != null && convocationBody.isNotEmpty) {
      debugPrint('[FCM navigation] convocation body: $convocationBody');
    }

    if (!context.mounted) return;

    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;
    final isManager = canAccessMatchSessionDetails(match, appSession);

    appNavigatorKey.currentState?.push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.matchDetail,
        fullscreenDialog: true,
        builder: (_) => MatchDetailScreen(
          match: match,
          isManager: isManager,
          playerId: playerId,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  static Future<void> _openTeamDetail(
    BuildContext context, {
    required String? teamId,
    String? seasonId,
  }) async {
    final trimmedTeamId = teamId?.trim() ?? '';
    if (trimmedTeamId.isEmpty) {
      debugPrint('[FCM navigation] missing team id');
      _navigateToShellTab(context, FeatureDiscoveryIds.tabDashboard);
      return;
    }

    final team = await TeamService().getTeamById(trimmedTeamId);
    if (!context.mounted) return;
    if (team == null) {
      debugPrint('[FCM navigation] team not found: $trimmedTeamId');
      _navigateToShellTab(context, FeatureDiscoveryIds.tabDashboard);
      return;
    }

    if (!context.mounted) return;

    final trimmedSeasonId = seasonId?.trim();
    appNavigatorKey.currentState?.push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.teamDetail,
        builder: (_) => TeamDetailScreen(
          team: team,
          seasonId:
              trimmedSeasonId != null && trimmedSeasonId.isNotEmpty
                  ? trimmedSeasonId
                  : null,
          isManager: false,
        ),
      ),
    );
  }

  static Future<void> _openChatChannel(
    BuildContext context, {
    required String? channelId,
  }) async {
    if (channelId == null || channelId.isEmpty) {
      _navigateToShellTab(context, FeatureDiscoveryIds.tabChat);
      return;
    }

    final client = StreamChat.maybeOf(context)?.client;
    if (client == null) {
      debugPrint('[FCM navigation] Stream Chat client unavailable');
      _navigateToShellTab(context, FeatureDiscoveryIds.tabChat);
      return;
    }

    try {
      final channel = await _resolveStreamChannel(client, channelId);
      if (!context.mounted) return;
      if (channel == null) {
        _navigateToShellTab(context, FeatureDiscoveryIds.tabChat);
        return;
      }

      appNavigatorKey.currentState?.push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.chatChannel,
          builder: (_) => StreamChannel(
            channel: channel,
            child: const _FcmChatChannelPage(),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('[FCM navigation] open chat failed: $e\n$st');
      if (context.mounted) {
        _navigateToShellTab(context, FeatureDiscoveryIds.tabChat);
      }
    }
  }

  static Future<Channel?> _resolveStreamChannel(
    StreamChatClient client,
    String rawId,
  ) async {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) return null;

    Channel channel;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final type = parts.first;
      final id = parts.sublist(1).join(':');
      channel = client.channel(type, id: id);
    } else {
      channel = client.channel('messaging', id: trimmed);
    }

    await channel.watch();
    return channel;
  }

  /// Reads Grinta FCM device tokens from `users/{uid}/fcmTokens` (document ids).
  ///
  /// Prefers tokens with `app: [FcmConfig.brandGrinta]`. When none match, falls
  /// back to legacy documents without `app`, excluding `app: aserstein`.
  static Future<List<String>> fetchFcmTokensForUser(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return const [];

    try {
      final tokensRef = FirebaseFirestore.instance
          .collection('users')
          .doc(trimmedUid)
          .collection('fcmTokens');

      final brandedSnapshot = await tokensRef
          .where('app', isEqualTo: FcmConfig.brandGrinta)
          .get();

      if (brandedSnapshot.docs.isNotEmpty) {
        return _tokenIdsFromSnapshotDocs(brandedSnapshot.docs);
      }

      final allSnapshot = await tokensRef.get();
      return _tokenIdsFromSnapshotDocs(
        allSnapshot.docs.where((doc) {
          final app = doc.data()['app']?.toString().trim() ?? '';
          return app.isEmpty || app == FcmConfig.brandGrinta;
        }),
      );
    } catch (e, st) {
      debugPrint('fetchFcmTokensForUser error uid=$trimmedUid: $e\n$st');
      return const [];
    }
  }

  static List<String> _tokenIdsFromSnapshotDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => doc.id.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// Reads FCM tokens for each uid in [uids] and returns a deduplicated list.
  static Future<List<String>> fetchFcmTokensForUsers(
    Iterable<String> uids,
  ) async {
    final trimmedUids = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet();
    if (trimmedUids.isEmpty) return const [];

    final tokenLists = await Future.wait(
      trimmedUids.map(fetchFcmTokensForUser),
    );

    return tokenLists
        .expand((tokens) => tokens)
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Persists the device FCM token under `users/{uid}/fcmTokens/{token}`.
  ///
  /// Sets `app: [FcmConfig.brandGrinta]` so Grinta sends do not target Aserstein
  /// tokens in the shared Firebase project.
  static Future<bool> saveTokenToFirestore(String uid) async {
    if (uid.isEmpty) return false;
    if (kIsWeb && !fcmWebVapidKeyConfigured) return false;

    try {
      final token = await _getFcmToken();
      if (token == null || token.isEmpty) return false;

      final tokensRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);

      final snapshot = await tokensRef.get();

      if (snapshot.exists) {
        await tokensRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'app': FcmConfig.brandGrinta,
        });
      } else {
        final platform =
            kIsWeb ? 'web' : NotificationFcmPlatform.platformLabel;

        var deviceName = 'unknown';
        final deviceInfo = DeviceInfoPlugin();
        if (kIsWeb) {
          final info = await deviceInfo.webBrowserInfo;
          deviceName = '${info.browserName} ${info.platform ?? ''}'.trim();
        } else {
          deviceName = await NotificationFcmPlatform.deviceName();
        }

        await tokensRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'platform': platform,
          'device': deviceName,
          'app': FcmConfig.brandGrinta,
        });
      }

      return true;
    } on FirebaseException catch (e) {
      if (kIsWeb && e.code == 'permission-denied') {
        return false;
      }
      debugPrint('saveTokenToFirestore error: $e');
      return false;
    } catch (e, st) {
      debugPrint('saveTokenToFirestore error: $e\n$st');
      return false;
    }
  }

  /// Foreground small icon: prefer Grinta `data.icon`, ignore legacy Aserstein URLs.
  static String _foregroundIconFromMessage(RemoteMessage message) {
    final icon = message.data['icon']?.toString().trim();
    if (icon != null &&
        icon.isNotEmpty &&
        !_isLegacyAsersteinFcmIcon(icon)) {
      return icon;
    }
    return kFcmGrintaWebIconPath;
  }

  static bool _isLegacyAsersteinFcmIcon(String icon) {
    final lower = icon.toLowerCase();
    return lower.contains('aserstein-2453e') ||
        lower.contains('aserstein.web.app') ||
        lower.endsWith('/favicon.png');
  }

  /// Sends a push notification via Cloud Function `sendPushFCMNotification`.
  ///
  /// Always sends [FcmConfig.brandGrinta] so the server attaches Grinta icon/image
  /// (shared Firebase project with Aserstein). See [fcm_config.dart].
  ///
  /// The remote callable **requires** a non-empty `clubId` (returns
  /// `invalid-argument: clubId requis` otherwise). Callers may omit it; we
  /// default to `'0'` (Grinta / InvitationConfig.grintaInvitationClubId).
  ///
  /// Pass [recipientUserIds] so the CF can load `users/{uid}/fcmTokens` when
  /// [tokens] is empty, and apply quiet-hours prefs only to reminder types.
  /// Returns `true` when the Cloud Function call succeeds (including when all
  /// reminder recipients were skipped by prefs — check CF summary logs).
  Future<bool> postNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> payload,
    String? clubId,
    List<String>? recipientUserIds,
  }) async {
    final recipients = (recipientUserIds ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (tokens.isEmpty && recipients.isEmpty) {
      debugPrint('postNotification: no tokens or recipients');
      return false;
    }

    if (!EshopConfigService.instance.commerceNotificationsEnabled &&
        isCommerceNotificationPayloadType(type)) {
      debugPrint('postNotification: commerce notification suppressed: $type');
      return false;
    }

    final resolvedClubId = (clubId ?? '').trim().isNotEmpty
        ? clubId!.trim()
        : '0';

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final result =
          await functions.httpsCallable('sendPushFCMNotification').call({
        'clubId': resolvedClubId,
        'brand': FcmConfig.brandGrinta,
        // Explicit Grinta icons (CF also resolves from brand; belt-and-suspenders).
        'icon': FcmConfig.icon192Url,
        'image': FcmConfig.icon512Url,
        'title': title,
        'body': body,
        'fcmTokens': tokens,
        'type': type,
        'payload': payload,
        if (recipients.isNotEmpty) 'recipientUserIds': recipients,
      });

      debugPrint(
        'postNotification success: type=$type clubId=$resolvedClubId '
        'tokens=${tokens.length} recipients=${recipients.length} '
        'result=${result.data}',
      );
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        'postNotification CF error: type=$type clubId=$resolvedClubId '
        'code=${e.code} message=${e.message} details=${e.details}\n$st',
      );
      return false;
    } catch (e, st) {
      debugPrint(
        'postNotification error: type=$type clubId=$resolvedClubId $e\n$st',
      );
      return false;
    }
  }

  /// Sends SMS via Cloud Function `sendSms`.
  ///
  /// Returns `null` on success, or a short error description on failure
  /// (Firebase callable code/message when available).
  Future<String?> sendSmsFromFlutter({
    required String toNumber,
    required String textMessage,
    required String clubId,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final result = await functions.httpsCallable('sendSms').call({
        'to': toNumber,
        'message': textMessage,
        'clubId': clubId,
      });
      debugPrint('sendSms success: ${result.data}');
      return null;
    } on FirebaseFunctionsException catch (e, st) {
      final error = _formatFunctionsException(e);
      debugPrint(
        'sendSms error: to=$toNumber clubId=$clubId $error\n$st',
      );
      return error;
    } catch (e, st) {
      final error = e.toString();
      debugPrint(
        'sendSms error: to=$toNumber clubId=$clubId $error\n$st',
      );
      return error;
    }
  }

  static String _formatFunctionsException(FirebaseFunctionsException e) {
    final buffer = StringBuffer(e.code);
    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) {
      buffer.write(': $message');
    }
    final details = e.details;
    if (details != null) {
      buffer.write(' ($details)');
    }
    return buffer.toString();
  }
}

/// Background FCM handler (top-level, no navigation). Native only — not invoked on web.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM background] ${message.notification?.title}');
  debugPrint('[FCM background data] ${message.data}');
  // A `notification` + APNs alert / Android channel payload is already shown
  // by the OS for every type (convocation, RPE, invite, chat…). Data-only
  // deliveries still need a local notification here.
  if (message.notification != null) return;
  await NotificationFCMService.ensureLocalNotificationsReady();
  await NotificationFCMService.showRemoteMessageAsLocalNotification(message);
}

/// Minimal chat channel view for notification deep links.
class _FcmChatChannelPage extends StatelessWidget {
  const _FcmChatChannelPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: StreamChannelHeader(
        onTitleTap: () => openStreamChannelInfo(
          context,
          StreamChannel.of(context).channel,
        ),
        onImageTap: () => openStreamChannelInfo(
          context,
          StreamChannel.of(context).channel,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              messageBuilder: (
                context,
                details,
                messages,
                defaultWidget,
              ) {
                return decorateStreamChatMessage(
                  defaultWidget: defaultWidget,
                  isMyMessage: details.isMyMessage,
                );
              },
            ),
          ),
          const GrintaStreamMessageInput(),
        ],
      ),
    );
  }
}
