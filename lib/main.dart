import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'util/app_theme.dart';
import 'util/stream_chat_theme.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';

import 'core/extensions/l10n_extension.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/active_session_service.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/analytics/analytics_observer.dart';
import 'package:grinta/analytics/analytics_route_aware.dart';
import 'package:grinta/services/analytics_service.dart';
import 'package:grinta/widget/web_app_root.dart';
import 'package:grinta/services/notification_fcm_service.dart';
import 'package:grinta/services/stream_chat_push_service.dart';
import 'package:grinta/services/internal_reminder_service.dart';
import 'package:grinta/services/calendar_deep_link_service.dart';
import 'package:grinta/services/fitbit_deep_link_service.dart';
import 'package:grinta/services/polar_deep_link_service.dart';
import 'package:grinta/services/strava_deep_link_service.dart';
import 'package:grinta/services/whoop_deep_link_service.dart';
import 'package:grinta/services/oura_deep_link_service.dart';
import 'package:grinta/services/auth_display_name_sync.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/auth_display_name.dart';
import 'package:grinta/services/biometric_unlock_service.dart';
import 'package:grinta/widget/parental_consent_pending_screen.dart';
import 'package:grinta/widget/biometric_lock_gate.dart';
import 'package:grinta/util/account_age_gate.dart';
import 'package:grinta/util/firebase_auth_ready.dart';
import 'package:grinta/model/player.dart';

const String kStreamApiKey = 'vg9g2zz7s2fc';
const Duration _kSessionPrepTimeout = Duration(seconds: 30);

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash up during Firebase / services boot (Android + iOS).
  // On web the package is a no-op; web uses its own boot splash in index.html.
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Must be registered before runApp so the background isolate can display
    // data-only FCM (Stream / chat) when Android has killed the UI process.
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // Independent bootstraps after Firebase — run in parallel to shorten web blank time.
    await Future.wait<void>([
      NotificationFCMService.init(),
      InternalReminderService.instance.init(),
      CalendarDeepLinkService.instance.init(),
      WhoopDeepLinkService.instance.init(),
      OuraDeepLinkService.instance.init(),
      StravaDeepLinkService.instance.init(),
      PolarDeepLinkService.instance.init(),
      FitbitDeepLinkService.instance.init(),
    ]);

    if (kIsWeb) {
      await firebase_auth.FirebaseAuth.instance.setPersistence(
        firebase_auth.Persistence.LOCAL,
      );
    }

    // Restaure la session Firebase persistée avant le premier frame.
    await waitForFirebaseAuthReady(firebase_auth.FirebaseAuth.instance);

    ActiveSessionService.instance;
    UserTrialService.instance;
    UserRootService.instance;

    await Future.wait<void>([
      FeatureDiscoveryService.instance.ensureInitialized(),
      UserTrialService.instance.ensureInitialized(),
      UserRootService.instance.ensureInitialized(),
      SubscriptionService.instance.ensureInitialized(),
      SubscriptionLimitsService.instance.ensureInitialized(),
      EshopConfigService.instance.ensureInitialized(),
      BiometricUnlockService.instance.ensureInitialized(),
    ]);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSession>(
            create: (_) => AppSession(),
          ),
          ChangeNotifierProvider<SubscriptionService>.value(
            value: SubscriptionService.instance,
          ),
          ChangeNotifierProvider<UserTrialService>.value(
            value: UserTrialService.instance,
          ),
          ChangeNotifierProvider<UserRootService>.value(
            value: UserRootService.instance,
          ),
          ChangeNotifierProvider<EshopConfigService>.value(
            value: EshopConfigService.instance,
          ),
        ],
        child: const MyApp(),
      ),
    );

    if (!kIsWeb) {
      widgetsBinding.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  } catch (_) {
    if (!kIsWeb) {
      FlutterNativeSplash.remove();
    }
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final AppAnalyticsObserver _analyticsObserver = AppAnalyticsObserver(
    analytics: AnalyticsService.instance,
  );

  late final StreamChatClient _streamChatClient = StreamChatClient(
    kStreamApiKey,
    logLevel: kIsWeb ? Level.OFF : Level.WARNING,
  );

  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Locale? get _effectiveLocale => _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      key: ValueKey(_effectiveLocale?.languageCode ?? 'system'),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      navigatorObservers: [_analyticsObserver, appRouteObserver],
      locale: _effectiveLocale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (_locale != null) {
          return _locale!;
        }
        if (deviceLocale == null) {
          return supportedLocales.first;
        }
        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalStreamChatLocalizations.delegates,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('de'),
        Locale('es'),
        Locale('it'),
      ],
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final appColors = Theme.of(context).extension<AppColors>()!;

        return StreamChat(
          client: _streamChatClient,
          streamChatThemeData: GrintaStreamChatTheme.themeFor(
            brightness: brightness,
            colors: appColors,
          ),
          streamChatConfigData: GrintaStreamChatTheme.config(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(client: _streamChatClient),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const WebAppRoot(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.client,
  });

  final StreamChatClient client;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _authenticatedSessionFuture;
  String? _authenticatedSessionForUid;
  String? _connectedStreamUserId;
  late final Future<void> _authReadyFuture;
  firebase_auth.User? _persistedUser;
  firebase_auth.User? _previousAuthUser;
  bool _seenAuthEmission = false;

  @override
  void initState() {
    super.initState();
    final auth = firebase_auth.FirebaseAuth.instance;
    _persistedUser = auth.currentUser;
    // main() already awaited auth readiness; skip duplicate wait when possible.
    if (_persistedUser != null) {
      _authReadyFuture = Future<void>.value();
    } else {
      _authReadyFuture = waitForFirebaseAuthReady(auth).then((_) {
        _persistedUser ??= auth.currentUser;
      });
    }
  }

  void _syncBiometricAuthState(firebase_auth.User? user) {
    if (!_seenAuthEmission) {
      _seenAuthEmission = true;
      _previousAuthUser = user;
      if (user != null) {
        unawaited(BiometricUnlockService.instance.bindUser(user.uid));
      }
      return;
    }

    if (user != null && _previousAuthUser == null) {
      // Fresh sign-in (password / social) — skip lock for this session.
      BiometricUnlockService.instance.markUnlocked();
      unawaited(BiometricUnlockService.instance.bindUser(user.uid));
    } else if (user == null && _previousAuthUser != null) {
      BiometricUnlockService.instance.onSignedOut();
    } else if (user != null) {
      unawaited(BiometricUnlockService.instance.bindUser(user.uid));
    }

    _previousAuthUser = user;
  }

  Future<ResolvedAuthDisplayName> _resolveStreamDisplayName(
    firebase_auth.User firebaseUser,
  ) async {
    Player? member;
    if (mounted) {
      final session = context.read<AppSession>();
      member = session.selectedPlayer;
      final memberName = composeAuthDisplayName(
        firstName: member?.firstName,
        lastName: member?.lastName,
      );
      if (memberName.isEmpty) {
        for (final player in session.currentUserPlayers.values) {
          final name = composeAuthDisplayName(
            firstName: player.firstName,
            lastName: player.lastName,
          );
          if (name.isNotEmpty) {
            member = player;
            break;
          }
        }
      }
    }

    UserProfile? account;
    try {
      account = await UserService().getById(firebaseUser.uid);
    } catch (e, st) {
      debugPrint('AuthGate: users/${firebaseUser.uid} name lookup failed: $e\n$st');
    }

    return resolveAuthDisplayName(
      memberFirstName: member?.firstName,
      memberLastName: member?.lastName,
      accountFirstName: account?.firstName,
      accountLastName: account?.lastName,
      authDisplayName: firebaseUser.displayName,
      email: firebaseUser.email ?? account?.email,
    );
  }

  Future<void> _connectStreamUser(firebase_auth.User firebaseUser) async {
    final streamUserId = firebaseUser.uid;
    AuthDisplayNameSync.instance.bindStreamClient(widget.client);

    final resolved = await _resolveStreamDisplayName(firebaseUser);
    await AuthDisplayNameSync.instance.persistResolved(
      resolved,
      photoUrl: firebaseUser.photoURL,
    );

    // Hot restart / navigation : état AuthGate perdu, client Stream encore connecté.
    if (widget.client.state.currentUser?.id == streamUserId) {
      _connectedStreamUserId = streamUserId;
      await _startChatPush();
      return;
    }

    if (_connectedStreamUserId == streamUserId) {
      await _startChatPush();
      return;
    }

    if (_connectedStreamUserId != null &&
        _connectedStreamUserId != streamUserId) {
      await StreamChatPushService.instance.stop();
      await widget.client.disconnectUser();
      _connectedStreamUserId = null;
    }

    final token = await _fetchStreamToken(firebaseUser);

    final streamUser = User(
      id: streamUserId,
      extraData: AuthDisplayNameSync.instance.streamExtraData(
        resolved: resolved,
        photoUrl: firebaseUser.photoURL,
      ),
    );

    try {
      await widget.client.connectUser(streamUser, token);
    } on StreamChatError catch (e) {
      if (widget.client.state.currentUser?.id == streamUserId) {
        _connectedStreamUserId = streamUserId;
        await AuthDisplayNameSync.instance.syncStreamUser(
          uid: streamUserId,
          resolved: resolved,
          photoUrl: firebaseUser.photoURL,
        );
        await _startChatPush();
        return;
      }
      debugPrint('Stream connectUser failed: ${e.message}');
      rethrow;
    }
    _connectedStreamUserId = streamUserId;
    await _startChatPush();
  }

  Future<void> _startChatPush() async {
    await StreamChatPushService.instance.start(
      widget.client,
      fallbackTitle: mounted ? context.l10n.navChat : null,
    );
  }

  Future<void> _disconnectStreamUserIfNeeded() async {
    if (_connectedStreamUserId == null &&
        widget.client.state.currentUser == null) {
      return;
    }

    await StreamChatPushService.instance.stop();
    await widget.client.disconnectUser();
    AuthDisplayNameSync.instance.bindStreamClient(null);
    _connectedStreamUserId = null;
    _authenticatedSessionFuture = null;
    _authenticatedSessionForUid = null;
  }

  Future<void> _prepareAuthenticatedSession(
    firebase_auth.User firebaseUser,
  ) async {
    // Identify RevenueCat with Firebase UID before UI gates / paywall so
    // entitlements follow the user onto this device (not anonymous RC ids).
    await SubscriptionService.instance
        .ensureUserLinked()
        .timeout(_kSessionPrepTimeout, onTimeout: () {
      debugPrint('ensureUserLinked timed out; continuing session prep');
    });
    await UserTrialService.instance.ensureInitialized();
    await UserRootService.instance.ensureInitialized();

    await ActiveSessionService.instance
        .ensureSessionActive()
        .timeout(_kSessionPrepTimeout, onTimeout: () {
      debugPrint('ensureSessionActive timed out; continuing to AppSession init');
    });

    final firebase_auth.User? liveUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (liveUser == null || liveUser.uid != firebaseUser.uid) {
      throw StateError('Session utilisateur perdue pendant la préparation.');
    }

    if (mounted) {
      final appSession = context.read<AppSession>();
      await appSession.init().timeout(_kSessionPrepTimeout, onTimeout: () {
        debugPrint('AppSession.init timed out; continuing to Stream connect');
        appSession.releaseStuckInit(expectedUid: firebaseUser.uid);
      });
      InternalReminderService.instance.onSessionReady();
      // Init already resolves avatars; on web skip a second refresh that would
      // stack with userChanges/idTokenChanges listeners and web avatar polling.
      if (mounted && !kIsWeb) {
        await context
            .read<AppSession>()
            .refreshPlayerAvatarUrls(allowWebRetry: false)
            .timeout(_kSessionPrepTimeout, onTimeout: () {
          debugPrint(
            'refreshPlayerAvatarUrls timed out; continuing to Stream connect',
          );
        });
      }
    }

    final firebase_auth.User? afterInitUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (afterInitUser == null || afterInitUser.uid != firebaseUser.uid) {
      throw StateError('Session utilisateur perdue après initialisation.');
    }

    await _connectStreamUser(afterInitUser).timeout(_kSessionPrepTimeout);
  }

  Future<String> _fetchStreamToken(firebase_auth.User firebaseUser) async {
    final functions = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    );

    final callable = functions.httpsCallable('getStreamUserToken');
    final result = await callable();

    final data = Map<String, dynamic>.from(result.data as Map);
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Token Stream manquant dans la réponse.');
    }

    return token;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _authReadyFuture,
      builder: (context, authReadySnapshot) {
        if (authReadySnapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }

        return StreamBuilder<firebase_auth.User?>(
          stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: firebase_auth.FirebaseAuth.instance.currentUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null &&
                firebase_auth.FirebaseAuth.instance.currentUser == null) {
              return const _LoadingScreen();
            }

            final auth = firebase_auth.FirebaseAuth.instance;
            final firebase_auth.User? liveUser = auth.currentUser;
            final firebase_auth.User? streamUser = snapshot.data;

            // Explicit sign-out: stream and live user both null → drop cached user.
            if (snapshot.hasData &&
                streamUser == null &&
                liveUser == null) {
              _persistedUser = null;
            }

            final firebase_auth.User? user = liveUser ??
                streamUser ??
                (isFirebaseAuthDefinitelySignedOut(auth) ? null : _persistedUser);

            if (user != null) {
              _persistedUser = user;
            } else {
              _authenticatedSessionFuture = null;
              _authenticatedSessionForUid = null;
            }

            _syncBiometricAuthState(user);

            if (user == null) {
              if (!isFirebaseAuthDefinitelySignedOut(auth)) {
                return const _LoadingScreen();
              }

              return FutureBuilder<void>(
                future: _disconnectStreamUserIfNeeded(),
                builder: (context, _) {
                  return const LoginScreen();
                },
              );
            }

            if (_authenticatedSessionFuture == null ||
                _authenticatedSessionForUid != user.uid) {
              _authenticatedSessionForUid = user.uid;
              _authenticatedSessionFuture = _prepareAuthenticatedSession(user);
            }

            return FutureBuilder<void>(
              future: _authenticatedSessionFuture,
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState != ConnectionState.done) {
                  return const _LoadingScreen();
                }

                if (streamSnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, size: 40),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.errorStreamConnection,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${streamSnapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _authenticatedSessionFuture =
                                            _prepareAuthenticatedSession(user);
                                      });
                                    },
                                    child: Text(context.l10n.actionRetry),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final firebase_auth.User? confirmedUser = auth.currentUser;
                if (confirmedUser == null || confirmedUser.uid != user.uid) {
                  if (!isFirebaseAuthDefinitelySignedOut(auth)) {
                    return const _LoadingScreen();
                  }
                  return FutureBuilder<void>(
                    future: _disconnectStreamUserIfNeeded(),
                    builder: (context, _) => const LoginScreen(),
                  );
                }

                final appSession = context.watch<AppSession>();
                if (appSession.user?.uid != confirmedUser.uid) {
                  if (appSession.isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      context.read<AppSession>().releaseStuckInit(
                            expectedUid: confirmedUser.uid,
                          );
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      unawaited(context.read<AppSession>().init());
                    });
                  }
                  return const _LoadingScreen();
                }

                return _AccountAccessGate(user: confirmedUser);
              },
            );
          },
        );
      },
    );
  }
}

/// Blocks the main shell until parental consent is granted (13–14 accounts).
class _AccountAccessGate extends StatelessWidget {
  const _AccountAccessGate({required this.user});

  final firebase_auth.User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _LoadingScreen();
        }

        final data = snapshot.data?.data();
        final status = data?[UserDocumentFields.accountStatus]
                ?.toString()
                .trim() ??
            UserAccountStatus.active;

        final birthRaw = data?[UserDocumentFields.birthDay]?.toString();
        final birthDate = Player.parseBirthDay(birthRaw);
        if (birthDate != null) {
          final ageGate = classifyAccountAge(
            ageYearsFromBirthDate(birthDate),
          );
          if (ageGate == AccountAgeGateResult.blockedUnderage) {
            return const _UnderageBlockedScreen();
          }
        }

        if (status == UserAccountStatus.pendingParentalConsent) {
          final first = data?[UserDocumentFields.firstName]?.toString() ?? '';
          final last = data?[UserDocumentFields.lastName]?.toString() ?? '';
          final name = '$first $last'.trim();
          return ParentalConsentPendingScreen(
            uid: user.uid,
            childDisplayName: name.isEmpty ? null : name,
            parentEmail:
                data?[UserDocumentFields.parentEmail]?.toString(),
          );
        }

        return const BiometricLockGate(
          child: WebAppRoot(),
        );
      },
    );
  }
}

/// Shown if a session somehow has an under-13 birth date on the user doc.
class _UnderageBlockedScreen extends StatelessWidget {
  const _UnderageBlockedScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 56,
                    color: colors.danger,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.accountAgeBlockedUnderage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () async {
                      await firebase_auth.FirebaseAuth.instance.signOut();
                    },
                    child: Text(l10n.actionLogout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
          backgroundColor: colors.border.withValues(alpha: 0.35),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
