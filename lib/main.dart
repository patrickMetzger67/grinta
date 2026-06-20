import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'util/app_theme.dart';
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
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/analytics/analytics_observer.dart';
import 'package:grinta/analytics/analytics_route_aware.dart';
import 'package:grinta/services/analytics_service.dart';
import 'package:grinta/widget/web_app_root.dart';

const String kStreamApiKey = 'vg9g2zz7s2fc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  ActiveSessionService.instance;
  await FeatureDiscoveryService.instance.ensureInitialized();
  await SubscriptionService.instance.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSession>(
          create: (_) => AppSession(),
        ),
        ChangeNotifierProvider<SubscriptionService>.value(
          value: SubscriptionService.instance,
        ),
      ],
      child: const MyApp(),
    ),
  );
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
        return StreamChat(
          client: _streamChatClient,
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

  Future<void> _connectStreamUser(firebase_auth.User firebaseUser) async {
    final streamUserId = firebaseUser.uid;

    // Hot restart / navigation : état AuthGate perdu, client Stream encore connecté.
    if (widget.client.state.currentUser?.id == streamUserId) {
      _connectedStreamUserId = streamUserId;
      return;
    }

    if (_connectedStreamUserId == streamUserId) {
      return;
    }

    if (_connectedStreamUserId != null &&
        _connectedStreamUserId != streamUserId) {
      await widget.client.disconnectUser();
      _connectedStreamUserId = null;
    }

    final token = await _fetchStreamToken(firebaseUser);

    final streamUser = User(
      id: streamUserId,
      extraData: {
        'name': firebaseUser.displayName ?? firebaseUser.email ?? 'Utilisateur',
        if (firebaseUser.photoURL != null) 'image': firebaseUser.photoURL!,
        if (firebaseUser.email != null) 'email': firebaseUser.email!,
      },
    );

    try {
      await widget.client.connectUser(streamUser, token);
    } on StreamChatError catch (e) {
      if (widget.client.state.currentUser?.id == streamUserId) {
        _connectedStreamUserId = streamUserId;
        return;
      }
      debugPrint('Stream connectUser failed: ${e.message}');
      rethrow;
    }
    _connectedStreamUserId = streamUserId;
  }

  Future<void> _disconnectStreamUserIfNeeded() async {
    if (_connectedStreamUserId == null &&
        widget.client.state.currentUser == null) {
      return;
    }

    await widget.client.disconnectUser();
    _connectedStreamUserId = null;
    _authenticatedSessionFuture = null;
    _authenticatedSessionForUid = null;
  }

  Future<void> _prepareAuthenticatedSession(
    firebase_auth.User firebaseUser,
  ) async {
    await ActiveSessionService.instance.ensureSessionActive();
    await _connectStreamUser(firebaseUser);
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
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final firebase_auth.User? user = snapshot.data;

        if (user == null) {
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
                                style: Theme.of(context).textTheme.titleLarge,
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

            return const WebAppRoot();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
