import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'asi_converter_screen.dart';
import 'asi_downloader_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'util/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logOpenProduct() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'open_product',
      parameters: {
        'source': 'home',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text("Accueil")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text("Mode sombre"),
              value: app.isDarkMode,
              onChanged: (value) {
                app.toggleTheme(value);
              },
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.usb),
                title: const Text(
                  'ASI Downloader (USB Chrome)',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                subtitle: const Text(
                  'Accès USB via WebUSB (Chrome uniquement)',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AsiDownloaderScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text(
                'Convertisseur ASI vers CSV',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
              subtitle: const Text(
                'Sélectionner un fichier .asi et lancer la conversion',
              ),
              onTap: () {
                Navigator.pushNamed(context, '/asi-converter');
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenue',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exemple avec Firebase Analytics.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _logOpenProduct();

                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/product');
                    },
                    child: const Text('Aller vers produit'),
                  ),
                ],
              ),
            ),
          ),
        ],
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