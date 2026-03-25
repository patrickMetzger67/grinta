import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:grinta/tracker/tracker_hub_view.dart';

import 'asi_converter_screen.dart';
import 'asi_downloader_screen.dart';
import 'firebase_options.dart';
import 'homeScreen.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'util/app_theme.dart';

import 'package:provider/provider.dart';
import '../provider/current_season_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentSeasonProvider>(
          create: (_) => CurrentSeasonProvider(),
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

  ThemeMode _themeMode = ThemeMode.light;

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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('de'),
        Locale('es'),
        Locale('it'),
      ],
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/asi-converter': (context) => const AsiConverterScreen(),
        '/hub-view': (context) => const TrackerHubView(
          trackerIds: [
            'TRACKER_001',
            'TRACKER_002',
            'TRACKER_003',
            'TRACKER_004',
            'TRACKER_005',
            'TRACKER_006',
          ],
        ),
        '/product': (context) => const ProductScreen(),
        '/cart': (context) => const CartScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple simple sans Firebase :
    final bool isLoggedIn = false;

    if (isLoggedIn) {
      return const HomeScreen();
    }

    return const LoginScreen();
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