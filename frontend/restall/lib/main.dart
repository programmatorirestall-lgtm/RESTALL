import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:restall/Screens/Signup/signup_screen.dart';

import 'package:app_links/app_links.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:restall/Screens/init_screen.dart';
import 'package:restall/Screens/details_product/details_product_screen.dart';
import 'package:restall/helper/sc.dart';
import 'package:restall/models/Product.dart' show Product;
import 'package:restall/providers/Auction/auction_provider.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/Checkout/IntegratedCheckoutStatus.dart';
import 'package:restall/providers/Order/order_provider.dart';
import 'package:restall/providers/Product/product_provider.dart';
import 'package:restall/core/performance/cache_manager.dart';
import 'package:restall/core/performance/animation_manager.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/providers/Profile/profile_provider.dart';
import 'package:restall/providers/Ticket/ticket_provider.dart';
import 'package:restall/providers/WishList.dart/wishlist_provider.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';
import 'package:restall/providers/ShopNavigation/shop_navigation_provider.dart';
import 'package:restall/routes.dart';
import 'package:restall/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:window_size/window_size.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Inizializza Stripe solo su piattaforme supportate (non web)
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
      await Stripe.instance.applySettings();
      Stripe.merchantIdentifier = 'merchant.restall.it';
    } catch (e) {
      print('⚠️ Errore inizializzazione Stripe: $e');
    }
  }

  // 🔥 INIZIALIZZAZIONE FIREBASE CON GESTIONE EMULATORI
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      print("✅ Firebase Core inizializzato");

      // 🔧 CONFIGURAZIONE SPECIFICA PER DEBUG/EMULATORI
      if (kDebugMode) {
        print("🔧 Modalità debug - configurazione Firebase per sviluppo");

        // Per iOS Simulator, potresti voler configurare settings specifici
        if (Platform.isIOS) {
          print("📱 iOS rilevato - configurazione per Simulator compatibile");
        }
      }
    } catch (e) {
      print("⚠️ Errore inizializzazione Firebase Core: $e");
      // ⚠️ NON BLOCCARE l'app per errori Firebase
      print("🚀 Continuo avvio app senza Firebase...");
    }
  }

  if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
    setWindowTitle('RestAll');
    setWindowMinSize(const Size(200, 200));
    setWindowMaxSize(Size.infinite);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<CacheManager>.value(value: CacheManager()),
        ChangeNotifierProvider(create: (_) => AnimationManager()),
        ChangeNotifierProvider(create: (_) => ConnectionManager()),
        ChangeNotifierProvider(
          create: (context) => AuctionProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TicketProvider(),
        ),
        ChangeNotifierProxyProvider2<CacheManager, ConnectionManager,
            CartProvider>(
          create: (context) => CartProvider(
            cacheManager: CacheManager(),
            connectionManager: ConnectionManager(),
          ),
          update: (context, cacheManager, connectionManager, previous) =>
              CartProvider(
            cacheManager: cacheManager,
            connectionManager: connectionManager,
          ),
        ),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProxyProvider2<CacheManager, ConnectionManager,
            ProductProvider>(
          create: (context) => ProductProvider(
            cacheManager: CacheManager(),
            connectionManager: ConnectionManager(),
          ),
          update: (context, cacheManager, connectionManager, previous) =>
              ProductProvider(
            cacheManager: cacheManager,
            connectionManager: connectionManager,
          ),
        ),
        ChangeNotifierProvider(create: (_) => IntegratedCheckoutProvider()),
        ChangeNotifierProvider(create: (_) => MySensitiveDataProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => RefundRequestProvider()),
        ChangeNotifierProvider(create: (_) => ShopNavigationProvider()),
        ChangeNotifierProxyProvider2<CacheManager, ConnectionManager,
            ProfileProvider>(
          create: (context) => ProfileProvider(
            cacheManager: Provider.of<CacheManager>(context, listen: false),
            connectionManager:
                Provider.of<ConnectionManager>(context, listen: false),
            userApi: UserApi(),
          ),
          update: (context, cacheManager, connectionManager, previous) =>
              ProfileProvider(
            cacheManager: cacheManager,
            connectionManager: connectionManager,
            userApi: UserApi(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Gestisce deep links quando l'app è già aperta
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Gestisce deep link quando l'app viene aperta da un link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'stripe-return') {
      // L'utente è tornato da Stripe onboarding
      // Verifica lo stato dell'account Stripe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileProvider = Provider.of<ProfileProvider>(
            navigatorKey.currentContext!,
            listen: false);
        profileProvider.checkStripeAccountStatus();
      });
    } else if (uri.path == '/invite') {
      // Gestione referral (già esistente)
      final code = uri.queryParameters['ref'];
      if (code != null) {
        navigatorKey.currentState?.pushNamed(
          SignUpScreen.routeName,
          arguments: {'referralCode': code},
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // RISOLUZIONE CONFLITTO: Rimuovi 'home' e usa solo 'initialRoute' + 'routes'
      initialRoute: InitScreen.routeName,
      routes: routes,
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        // Handle deep links for referral codes
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == '/invite') {
          final code = uri.queryParameters['ref'];
          return MaterialPageRoute(
            builder: (_) => SignUpScreen(referralCode: code),
            settings: settings,
          );
        }

        if (settings.name == DetailsProductScreen.routeName) {
          final product = settings.arguments
              as Product; // Cambiato da ProductDetailsArguments a Product
          return MaterialPageRoute(
            builder: (context) => DetailsProductScreen(
                productId: product.id), // product invece di args.product
            settings: settings,
          );
        }

        // Fallback per route non trovate
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Pagina non trovata',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      title: 'RestAll',
      debugShowCheckedModeBanner: false,
      theme: theme(),
    );
  }
}
