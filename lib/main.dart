import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grinta/screen/dashboardScreen.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'package:grinta/provider/appSession.dart';
import 'util/app_theme.dart';
import 'package:grinta/widget/web_app_root.dart';

const String kStreamApiKey = 'vg9g2zz7s2fc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSession>(
          create: (_) => AppSession(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  late final FirebaseAnalyticsObserver _analyticsObserver =
  FirebaseAnalyticsObserver(analytics: _analytics);

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grinta',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      navigatorObservers: [_analyticsObserver],
      locale: _locale,
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
        '/home': (context) => kIsWeb ? const WebAppRoot() : const DashboardScreen(),
        '/product': (context) => const ProductScreen(),
        '/cart': (context) => const CartScreen(),
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
  Future<void>? _streamConnectionFuture;
  String? _streamFutureForUid;
  String? _connectedStreamUserId;

  Future<void> _connectStreamUser(firebase_auth.User firebaseUser) async {
    final streamUserId = firebaseUser.uid;
    // Vérifie que l'identifiant utilisé respecte bien le format attendu par Stream.

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

    await widget.client.connectUser(streamUser, token);
    _connectedStreamUserId = streamUserId;
  }

  Future<void> _disconnectStreamUserIfNeeded() async {
    if (_connectedStreamUserId == null) return;

    await widget.client.disconnectUser();
    _connectedStreamUserId = null;
    _streamConnectionFuture = null;
    _streamFutureForUid = null;
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

        if (_streamConnectionFuture == null || _streamFutureForUid != user.uid) {
          _streamFutureForUid = user.uid;
          _streamConnectionFuture = _connectStreamUser(user);
        }

        return FutureBuilder<void>(
          future: _streamConnectionFuture,
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
                                'Connexion Stream impossible',
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
                                    _streamConnectionFuture =
                                        _connectStreamUser(user);
                                  });
                                },
                                child: const Text('Réessayer'),
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

            if (kIsWeb) {
              return const WebAppRoot();
            }

            return const DashboardScreen();
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

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  void initState() {
    super.initState();
    _logViewItem();
  }

  Future<void> _logViewItem() async {
    await FirebaseAnalytics.instance.logViewItem(
      currency: 'EUR',
      value: 49.90,
      items: [
        AnalyticsEventItem(
          itemId: '123',
          itemName: 'Maillot domicile',
          itemCategory: 'eshop',
          price: 49.90,
        ),
      ],
    );
  }

  Future<void> _logAddToCart() async {
    await FirebaseAnalytics.instance.logAddToCart(
      currency: 'EUR',
      value: 49.90,
      items: [
        AnalyticsEventItem(
          itemId: '123',
          itemName: 'Maillot domicile',
          itemCategory: 'eshop',
          price: 49.90,
          quantity: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produit'),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Maillot domicile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '49,90 €',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _logAddToCart();

                    if (!context.mounted) return;
                    Navigator.pushNamed(context, '/cart');
                  },
                  child: const Text('Ajouter au panier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _logBeginCheckout() async {
    await FirebaseAnalytics.instance.logBeginCheckout(
      value: 49.90,
      currency: 'EUR',
      items: [
        AnalyticsEventItem(
          itemId: '123',
          itemName: 'Maillot domicile',
          itemCategory: 'eshop',
          price: 49.90,
          quantity: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre panier',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1 article - 49,90 €',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _logBeginCheckout();
                  },
                  child: const Text('Commencer le paiement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}