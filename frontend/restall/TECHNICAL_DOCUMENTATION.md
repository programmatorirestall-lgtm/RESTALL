# RestAll - Documentazione Tecnica Completa

## 1. Overview del Progetto

**RestAll** è un'applicazione Flutter cross-platform che integra un sistema di gestione ticket per assistenza tecnica con un e-commerce basato su WooCommerce. L'app fornisce una soluzione completa per la gestione di riparazioni e vendita di prodotti/servizi.

### 1.1 Obiettivi Principali
- **Gestione Ticket**: Apertura, tracking e gestione di richieste di assistenza tecnica
- **E-commerce Integrato**: Vendita prodotti tramite WooCommerce con pagamenti Stripe
- **Sistema Referral**: Network marketing con tracciamento referral e commissioni
- **Multi-piattaforma**: Supporto iOS, Android, Web, Desktop (Windows/macOS)

### 1.2 Target Utenti
- **Clienti finali**: Apertura ticket e acquisto prodotti
- **Tecnici**: Gestione interventi e preventivi
- **Amministratori**: Supervisione generale e analytics
- **Partner**: Gestione network referral

---

## 2. Architettura Tecnica

### 2.1 Pattern Architetturale
```
┌─────────────────┐
│   Presentation  │ ← Screens, Widgets, UI Components
├─────────────────┤
│   Business      │ ← Providers, State Management
├─────────────────┤
│   Data          │ ← API Services, Models, Cache
├─────────────────┤
│   External      │ ← Firebase, Stripe, WooCommerce
└─────────────────┘
```

**Pattern Utilizzati:**
- **Provider Pattern**: State management centralizzato
- **Repository Pattern**: Astrazione per accesso ai dati
- **Singleton**: Per servizi globali (CacheManager, ConnectionManager)
- **Factory**: Per creazione modelli da JSON

### 2.2 Struttura Modulare
```
lib/
├── API/                    # Servizi di comunicazione
├── Screens/               # Interfacce utente
├── providers/             # Gestione stato
├── models/               # Modelli dati
├── components/           # Widget riutilizzabili
├── core/                # Servizi core (cache, performance)
├── helper/              # Utilities e helper functions
└── constants.dart       # Costanti globali
```

---

## 3. Stack Tecnologico

### 3.1 Framework e Linguaggi
```yaml
Flutter SDK: >=3.0.0-35.0.dev <4.0.0
Dart Language: 3.0+
Platform Support: iOS, Android, Web, Windows, macOS
```

### 3.2 Dipendenze Principali

**Core Framework:**
- `flutter: sdk` - Framework base
- `provider: ^6.0.5` - State management
- `http: ^1.3.0` - HTTP client

**UI e Navigazione:**
- `sidebarx: ^0.17.1` - Sidebar navigation
- `flutter_svg: ^2.0.1` - SVG support
- `line_icons: ^2.0.1` - Iconografia

**Pagamenti e E-commerce:**
- `flutter_stripe: ^11.5.0` - Integrazione Stripe
- `flutter_dotenv: ^5.2.1` - Environment variables

**Backend e Storage:**
- `firebase_core: ^3.10.1` - Firebase base
- `firebase_messaging: ^15.2.1` - Push notifications
- `shared_preferences: ^2.0.17` - Storage locale
- `flutter_cache_manager: ^3.3.1` - Cache management

**Utilities:**
- `jwt_decode: ^0.3.1` - JWT token handling
- `uuid: ^4.4.0` - ID generation
- `intl: ^0.20.2` - Internazionalizzazione
- `url_launcher: ^6.2.1` - URL launcher

---

## 4. Struttura del Progetto

### 4.1 Organizzazione Directory

```
lib/
├── API/
│   ├── Cart/cart.dart              # API carrello e-commerce
│   ├── Order/order_api.dart        # API ordini WooCommerce
│   ├── Ticket/ticket.dart          # API gestione ticket
│   ├── User/user.dart              # API gestione utenti
│   ├── Shop/product.dart           # API prodotti
│   ├── PhotoPic/photoPic.dart      # API upload immagini
│   ├── FireBase/firebase.dart      # API Firebase
│   └── SignUpRequest/signup.dart   # API registrazione
│
├── Screens/
│   ├── init_screen.dart            # Splash screen
│   ├── Welcome/                    # Onboarding
│   ├── Login/                      # Autenticazione
│   ├── Signup/                     # Registrazione
│   ├── SideBar/sidebar.dart        # Layout principale
│   ├── dashboard/                  # Dashboard home
│   ├── OpenTicket/                 # Apertura ticket
│   ├── details/                    # Dettagli ticket
│   ├── shop/                       # E-commerce
│   ├── cart/                       # Carrello
│   ├── profile/                    # Profilo utente
│   └── Network/network.dart        # Rete referral
│
├── providers/
│   ├── Cart/cart_provider.dart           # Stato carrello
│   ├── Ticket/ticket_provider.dart       # Stato ticket
│   ├── Product/product_provider.dart     # Stato prodotti
│   ├── Order/order_provider.dart         # Stato ordini
│   ├── WishList/wishlist_provider.dart   # Lista desideri
│   └── Checkout/IntegratedCheckoutStatus.dart # Checkout Stripe
│
├── models/
│   ├── Product.dart                # Modello prodotto WooCommerce
│   ├── TicketList.dart            # Modello ticket
│   ├── cart_item.dart             # Modello item carrello
│   └── User.dart                  # Modello utente
│
├── core/
│   └── performance/
│       ├── cache_manager.dart      # Gestione cache
│       ├── animation_manager.dart  # Ottimizzazioni animazioni
│       └── connection_manager.dart # Gestione connettività
│
└── config.dart                    # Configurazioni API
```

### 4.2 File di Configurazione

**pubspec.yaml**: Dipendenze e metadati
**config.dart**: URL API e configurazioni ambiente
**.env**: Variabili ambiente (Stripe keys, etc.)
**firebase_options.dart**: Configurazione Firebase multi-platform

---

## 5. Modelli Dati

### 5.1 Product (WooCommerce)
```dart
class Product {
  final int id;
  final String name, description, slug, permalink, sku;
  final double regularPrice, salePrice, price, rating;
  final int quantities, totalSales, ratingCount;
  final bool onSale, virtual, downloadable, featured;
  final String stockStatus, shortDescription, type, status;
  final List<Category> categories;
  final List<Tag> tags;
  final List<ProductImage> images;
  final List<Attribute> attributes;
  final List<int> variations, relatedIds, upsellIds;
  final Map<String, dynamic> dimensions;
  final bool isFavourite, isPopular;

  // Metodi factory per JSON parsing
  factory Product.fromJson(Map<String, dynamic> json)
}
```

### 5.2 Ticket
```dart
class Ticket {
  final int id;
  final String typeM;        // Tipo macchina
  final String stateM;       // Stato macchina
  final String stateT;       // Stato ticket (Aperto/Chiuso)
  final String indirizzo;    // Indirizzo intervento
  final String data;         // Data formattata
  final String? oraPrevista; // Ora prevista intervento

  factory Ticket.fromJson(Map<String, dynamic> json)
}
```

### 5.3 CartItem
```dart
class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem copyWith({int? quantity}) // Immutability pattern
}
```

### 5.4 User
```dart
class User {
  final String id, email, name, lastName;
  final String? phone, address, city, postalCode;
  final String? referralCode, parentReferral;
  final DateTime? birthDate;
  final String? profileImageUrl;
  final String userType; // user/admin/technician
  final bool isActive;
}
```

---

## 6. API e Endpoints

### 6.1 Configurazione Base
```dart
// config.dart
String get apiHost {
  bool isProd = const bool.fromEnvironment('dart.vm.product');
  return isProd ? 'https://api.restall.it' : 'https://api.restall.it';
}
```

### 6.2 Autenticazione
**Base**: JWT tokens + Cookie session
**Headers Standard**:
```dart
{
  'Content-type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer {JWT_TOKEN}',
  'Cookie': '{SESSION_COOKIE}'
}
```

### 6.3 Endpoints Principali

#### Autenticazione
```
POST /signup                    # Registrazione utente
POST /login                     # Login
POST /logout                    # Logout
GET  /user/renew                # Rinnovo sessione
```

#### Gestione Utenti
```
GET    /user/{id}               # Dettagli utente
PUT    /user/{id}               # Aggiorna profilo
PATCH  /user/photo              # Upload foto profilo
POST   /token                   # Salva FCM token
```

#### Ticket System
```
GET  /tickets                   # Lista ticket utente
POST /tickets                   # Crea nuovo ticket
GET  /tickets/closed            # Ticket chiusi
PUT  /tickets/{id}              # Aggiorna ticket
```

#### E-commerce (WooCommerce Integration)
```
GET    /api/v1/shop/products              # Lista prodotti
GET    /api/v1/shop/products/{id}         # Dettaglio prodotto
GET    /api/v1/shop/cart                  # Carrello corrente
POST   /api/v1/shop/cart                  # Aggiungi al carrello
PUT    /api/v1/shop/cart/{item_id}        # Aggiorna quantità
DELETE /api/v1/shop/cart/{item_id}        # Rimuovi dal carrello
POST   /api/v1/shop/cart/order/intent     # Crea Payment Intent
POST   /api/v1/shop/orders                # Crea ordine
GET    /api/v1/shop/orders                # Lista ordini utente
PUT    /api/v1/shop/orders/{id}           # Aggiorna ordine
```

### 6.4 Formato Risposte API

**Successo**:
```json
{
  "status": "success",
  "data": { ... },
  "message": "Operation completed"
}
```

**Errore**:
```json
{
  "status": "error",
  "error": "Error description",
  "code": 400
}
```

---

## 7. Provider e State Management

### 7.1 Architettura Provider
```dart
MultiProvider(
  providers: [
    // Core Services
    Provider<CacheManager>.value(value: CacheManager()),
    ChangeNotifierProvider(create: (_) => AnimationManager()),
    ChangeNotifierProvider(create: (_) => ConnectionManager()),

    // Business Logic Providers
    ChangeNotifierProvider(create: (_) => TicketProvider()),
    ChangeNotifierProxyProvider2<CacheManager, ConnectionManager, CartProvider>(
      create: (context) => CartProvider(
        cacheManager: CacheManager(),
        connectionManager: ConnectionManager(),
      ),
      update: (context, cacheManager, connectionManager, previous) => CartProvider(
        cacheManager: cacheManager,
        connectionManager: connectionManager,
      ),
    ),
    ChangeNotifierProvider(create: (_) => WishlistProvider()),
    ChangeNotifierProxyProvider2<CacheManager, ConnectionManager, ProductProvider>(
      create: (context) => ProductProvider(
        cacheManager: CacheManager(),
        connectionManager: ConnectionManager(),
      ),
      update: (context, cacheManager, connectionManager, previous) => ProductProvider(
        cacheManager: cacheManager,
        connectionManager: connectionManager,
      ),
    ),
    ChangeNotifierProvider(create: (_) => IntegratedCheckoutProvider()),
    ChangeNotifierProvider(create: (_) => MySensitiveDataProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
  ],
  child: const MyApp(),
)
```

### 7.2 Provider Principali

#### CartProvider
```dart
class CartProvider with ChangeNotifier {
  // State
  Map<String, CartItem> _items = {};
  bool _isLoading = false;
  bool _isSyncing = false;

  // Getters
  Map<String, CartItem> get items;
  int get itemCount;
  double get totalAmount;
  bool get isEmpty;

  // Actions
  Future<void> addItem(Product product, {int quantity = 1});
  Future<void> updateQuantity(String productId, int quantity);
  Future<void> removeItem(String productId);
  Future<void> clear();
  Future<void> syncCartFromServer(); // Offline-first strategy
}
```

#### TicketProvider
```dart
class TicketProvider with ChangeNotifier {
  // State
  List<Ticket> _allTickets = [];
  List<Ticket> _openTickets = [];
  List<Ticket> _closedTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Actions
  Future<void> loadAllTickets();
  Future<void> refreshOpenTickets();
  Future<void> onTicketCreated();
}
```

#### IntegratedCheckoutProvider (Stripe)
```dart
enum IntegratedCheckoutStatus {
  idle, creatingIntent, processing, creatingOrder, success, error
}

class IntegratedCheckoutProvider with ChangeNotifier {
  // State
  IntegratedCheckoutStatus _status = IntegratedCheckoutStatus.idle;
  String? _errorMessage;
  Map<String, dynamic>? _paymentIntentData;
  Map<String, dynamic>? _createdOrder;

  // Main checkout flow
  Future<bool> processCompletePaymentFlow({
    required CartProvider cartProvider,
    required Map<String, dynamic> billingData,
    Map<String, dynamic>? shippingData,
    String paymentMethod = 'stripe',
    String paymentMethodTitle = 'Carta di credito',
  });
}
```

#### AnimationManager
```dart
/// Gestisce le impostazioni globali per le animazioni nell'app.
class AnimationManager with ChangeNotifier {
  bool get areAnimationsEnabled;

  void setAnimationsEnabled(bool enabled);
}
```
*   **Scopo**: Fornisce un controllo centralizzato per abilitare o disabilitare le animazioni a livello globale, utile per creare modalità a performance elevate o a ridotto consumo energetico.
*   **File**: `lib/core/performance/animation_manager.dart`
*   **Widget Associato**: `ManagedFadeTransition` è un widget personalizzato che rispetta le impostazioni di questo provider, mostrando un'animazione di dissolvenza solo se le animazioni sono abilitate.

#### MySensitiveDataProvider
```dart
class MySensitiveDataProvider extends ChangeNotifier {
  String get sensitiveData;

  void setSensitiveData(String newData);
}
```
*   **Scopo**: Un provider semplice che gestisce una singola stringa di dati sensibili. La sua funzione è quella di mantenere e notificare i cambiamenti a dati che non dovrebbero essere esposti o gestiti da altri provider più generici.
*   **File**: `lib/helper/sc.dart`

---

## 8. Flussi Principali

### 8.1 Flusso di Autenticazione
```
1. InitScreen (Splash) → verifica sessione esistente
2. Se non autenticato → WelcomeScreen → LoginScreen/SignUpScreen
3. SignUp → CompleteProfileScreen → SideBar (Main App)
4. Login diretto → SideBar (Main App)
5. JWT + Cookie storage in SharedPreferences
6. Auto-renewal sessione con refresh token
```

### 8.2 Flusso Gestione Ticket
```
1. Dashboard → "Apri Ticket" → TicketScreen
2. Form compilazione (tipo macchina, indirizzo, descrizione)
3. Invio → TicketApi.create() → conferma TicketSuccessScreen
4. Visualizzazione: SideBar → "I Miei Ticket" → UnifiedTicketsScreen
5. Dettaglio: TicketCard tap → DetailsScreen
6. Stati: Aperto → In Lavorazione → Chiuso
```

### 8.3 Flusso E-commerce Completo
```
1. Shop → ProductCard → DetailsProductScreen
2. Add to Cart → CartProvider.addItem()
3. Cart → CartScreen → Checkout
4. Billing/Shipping form → IntegratedCheckoutProvider
5. Stripe Payment Flow:
   a. createOrderOnly() → Payment Intent
   b. Stripe.presentPaymentSheet() → pagamento
   c. OrderApi.createOrder() → ordine WooCommerce
   d. CartProvider.clear() → svuotamento carrello
6. Conferma → OrderSuccessScreen
```

### 8.4 Flusso Network Referral
```
1. Signup con referral code → parent assignment
2. NetworkScreen → visualizzazione albero referral
3. Badge system basato su numero referral
4. Achievement unlock progressivo
5. Tracking commissioni e statistiche
```

---

## 9. Screen e Navigazione

### 9.1 Routing Configuration
```dart
// routes.dart
final Map<String, WidgetBuilder> routes = {
  InitScreen.routeName: (context) => const InitScreen(),
  WelcomeScreen.routeName: (context) => const WelcomeScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  SignUpScreen.routeName: (context) => const SignUpScreen(),
  SideBar.routeName: (context) => const SideBar(),
  TicketScreen.routeName: (context) => const TicketScreen(),
  // ... altre route
};
```

### 9.2 Navigazione Principale (SidebarX)
```
SideBar (Main Layout)
├── [0] Dashboard           # DashboardScreen
├── [1] Apri Ticket        # TicketScreen
├── [2] I Miei Ticket      # UnifiedTicketsScreen
├── [3] Preventivi         # PreventiviScreen
├── [4] Profitti           # ProfitsScreen
├── [5] Network            # NetworkScreen
├── [6] Shop               # ShopScreen
└── [7] Profilo            # ProfileScreen
```

### 9.3 Deep Linking
```dart
// main.dart - onGenerateRoute
if (uri.path == '/invite') {
  final code = uri.queryParameters['ref'];
  return MaterialPageRoute(
    builder: (_) => SignUpScreen(referralCode: code),
  );
}
```

### 9.4 Animazioni e Transizioni
```dart
// Esempio transition personalizzata
PageRouteBuilder(
  pageBuilder: (context, animation, _) => targetScreen,
  transitionDuration: const Duration(milliseconds: 800),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  },
);
```

---

## 10. Integrazione Servizi Esterni

### 10.1 Firebase Integration
```dart
// firebase_options.dart - Multi-platform config
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return macos;
      case TargetPlatform.windows: return windows;
    }
  }
}

// Push Notifications
class FireBaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    // Invia token al server per targeting
    setToken({'FCMToken': fCMToken});
  }
}
```

### 10.2 Stripe Integration
```dart
// main.dart - Inizializzazione
await dotenv.load(fileName: '.env');
Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
await Stripe.instance.applySettings();
Stripe.merchantIdentifier = 'merchant.restall.it';

// Processo pagamento completo
Future<bool> processCompletePaymentFlow() async {
  // 1. Crea Payment Intent
  final response = await _cartApi.createOrderOnly();
  _paymentIntentData = jsonDecode(response.body);

  // 2. Configura Payment Sheet
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'RestAll',
      billingDetails: billingDetails,
      googlePay: const PaymentSheetGooglePay(merchantCountryCode: 'IT'),
      applePay: const PaymentSheetApplePay(merchantCountryCode: 'IT'),
    ),
  );

  // 3. Presenta Payment Sheet
  await Stripe.instance.presentPaymentSheet();

  // 4. Crea ordine WooCommerce
  final orderResponse = await _orderApi.createOrder(orderData);

  return orderResponse?.statusCode == 201;
}
```

### 10.3 WooCommerce Integration
```dart
// Struttura ordine WooCommerce
Map<String, dynamic> _buildWooCommerceOrderData() {
  return {
    'billing': {
      'first_name': billingData['firstName'],
      'last_name': billingData['lastName'],
      'address_1': billingData['address'],
      'city': billingData['city'],
      'postcode': billingData['postalCode'],
      'country': billingData['country'] ?? 'IT',
      'email': billingData['email'],
      'phone': billingData['phone'],
    },
    'shipping': shippingData ?? billing,
    'line_items': cartProvider.items.values.map((item) => {
      'product_id': int.tryParse(item.id),
      'quantity': item.quantity,
    }).toList(),
    'payment_method': paymentMethod,
    'payment_method_title': paymentMethodTitle,
    'set_paid': true, // Stripe ha già processato il pagamento
  };
}
```

---

## 11. Performance e Caching

### 11.1 Strategie di Caching
```dart
// CacheManager - Singleton pattern
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _defaultTTL = Duration(minutes: 15);

  T? get<T>(String key) {
    if (_isExpired(key)) {
      remove(key);
      return null;
    }
    return _cache[key] as T?;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now().add(ttl ?? _defaultTTL);
  }
}
```

### 11.2 Offline-First Strategy (Carrello)
```dart
class CartProvider with ChangeNotifier {
  // 1. Operazioni immediate su stato locale
  Future<void> addItem(Product product) async {
    _items.update(productId, (existing) => existing.copyWith(...));
    _onCartChanged(); // Salva in SharedPreferences

    // 2. Sync asincrono con server (non blocca UI)
    _syncWithServer();
  }

  // 3. Conflict resolution: server wins
  Future<void> syncCartFromServer() async {
    try {
      final response = await _cartApi.getCart();
      if (response.statusCode == 200) {
        final serverCart = _parseServerCart(response.body);
        _items = serverCart;
        await _saveCartToPrefs();
        notifyListeners();
      }
    } catch (e) {
      // Mantiene stato locale in caso di errore
    }
  }
}
```

### 11.3 Ottimizzazioni UI
```dart
// AnimationManager - Controlla performance animazioni
class AnimationManager with ChangeNotifier {
  bool _reduceAnimations = false;
  bool get reduceAnimations => _reduceAnimations;

  void toggleAnimations() {
    _reduceAnimations = !_reduceAnimations;
    notifyListeners();
  }
}

// Lazy loading nelle liste
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    if (index >= items.length - 5) {
      _loadMoreItems(); // Pagination
    }
    return ItemWidget(items[index]);
  },
)
```

### 11.4 Connection Management
```dart
class ConnectionManager with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      // Riconnessione: sync pending operations
      _syncPendingOperations();
    }
    notifyListeners();
  }
}
```

---

## 12. Deployment e Build

### 12.1 Configurazioni Multi-Platform
```yaml
# pubspec.yaml
name: restall
version: 1.0.12+13
environment:
  sdk: '>=3.0.0-35.0.dev <4.0.0'

flutter:
  assets:
    - assets/images/
    - assets/icons/
    - .env

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/icon.jpg"
  web: true
  windows:
    generate: true
  macos:
    generate: true
```

### 12.2 Build Scripts
```bash
# Android Release
flutter build apk --release --build-name=1.0.12 --build-number=13

# iOS Release
flutter build ios --release --build-name=1.0.12 --build-number=13

# Web Release
flutter build web --release --web-renderer canvaskit

# Windows Release
flutter build windows --release

# macOS Release
flutter build macos --release
```

### 12.3 Environment Configuration
```dart
// config.dart
String get apiHost {
  bool isProd = const bool.fromEnvironment('dart.vm.product');
  if (isProd) {
    return 'https://api.restall.it'; // Production
  }
  return 'https://api.restall.it'; // Development/Staging
}

// .env file
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
API_BASE_URL=https://api.restall.it
```

### 12.4 Certificate e Signing
```
Android:
- Keystore configurato per release
- Bundle AAB per Play Store

iOS:
- Provisioning profiles per App Store
- Certificate di distribuzione

Web:
- Deploy su hosting statico
- PWA capabilities

Desktop:
- Code signing per Windows
- Notarization per macOS
```

---

## 13. Convenzioni di Codice

### 13.1 Naming Conventions
```dart
// File naming: snake_case
ticket_provider.dart
cart_screen.dart
product_detail_screen.dart

// Class naming: PascalCase
class ProductProvider extends ChangeNotifier
class CartItem
class TicketScreen extends StatefulWidget

// Variable naming: camelCase
String userName;
List<Product> productList;
bool isLoading;

// Constants: SCREAMING_SNAKE_CASE o camelCase per UI
const String API_BASE_URL = 'https://api.restall.it';
const Color primaryColor = Color.fromARGB(255, 255, 215, 0);

// Private members: underscore prefix
String _privateVariable;
void _privateMethod() {}
```

### 13.2 Struttura Widget
```dart
class ExampleScreen extends StatefulWidget {
  // 1. Static route name
  static String routeName = "/example";

  // 2. Constructor parameters
  const ExampleScreen({Key? key, this.parameter}) : super(key: key);
  final String? parameter;

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen>
    with TickerProviderStateMixin {

  // 3. Controllers e animazioni
  late AnimationController _animationController;
  final TextEditingController _textController = TextEditingController();

  // 4. State variables
  bool _isLoading = false;
  String? _errorMessage;

  // 5. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 6. Helper methods (private)
  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Data loading logic
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 7. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // 8. Build helper methods
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Example Screen'),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    return _buildContent();
  }

  Widget _buildLoadingState() => const Center(child: CircularProgressIndicator());
  Widget _buildErrorState() => Center(child: Text(_errorMessage!));
  Widget _buildContent() => Container(); // Main content
}
```

### 13.3 Error Handling Patterns
```dart
// API Calls con try-catch standard
Future<List<Product>> fetchProducts() async {
  try {
    final response = await http.get(Uri.parse('$apiHost/products'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw ApiException('Failed to load products: ${response.statusCode}');
    }
  } on SocketException {
    throw NetworkException('No internet connection');
  } on FormatException {
    throw DataException('Invalid response format');
  } catch (e) {
    throw UnknownException('Unexpected error: $e');
  }
}

// Custom Exception Classes
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
```

### 13.4 Provider Best Practices
```dart
class ExampleProvider with ChangeNotifier {
  // 1. Private state variables
  List<Item> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 2. Public getters (immutable)
  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 3. Computed getters
  int get itemCount => _items.length;
  bool get hasItems => _items.isNotEmpty;

  // 4. Private setters con notifyListeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 5. Public actions
  Future<void> loadItems() async {
    _setLoading(true);
    _setError(null);

    try {
      final newItems = await _fetchItems();
      _items = newItems;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // 6. Private helper methods
  Future<List<Item>> _fetchItems() async {
    // Implementation
  }
}
```

### 13.5 Commenti e Documentazione
```dart
/// Manages the shopping cart state and synchronization with server.
///
/// This provider implements an offline-first strategy where local changes
/// are immediately applied and then synchronized with the server.
///
/// Example usage:
/// ```dart
/// final cart = Provider.of<CartProvider>(context);
/// await cart.addItem(product, quantity: 2);
/// ```
class CartProvider with ChangeNotifier {

  /// Adds a product to the cart with specified quantity.
  ///
  /// If the product already exists, increases the quantity.
  /// Changes are immediately saved locally and synced with server.
  ///
  /// Throws [ApiException] if server sync fails.
  Future<void> addItem(Product product, {int quantity = 1}) async {
    // Implementation with detailed steps
  }

  // Internal helper method - minimal documentation
  void _onCartChanged() {
    _saveCartToPrefs();
    _syncWithServer();
    notifyListeners();
  }
}
```

---

## 14. Testing e Quality Assurance

### 14.1 Struttura Testing
```
test/
├── unit/
│   ├── providers/
│   │   ├── cart_provider_test.dart
│   │   └── ticket_provider_test.dart
│   ├── models/
│   │   ├── product_test.dart
│   │   └── ticket_test.dart
│   └── services/
│       └── api_service_test.dart
├── widget/
│   ├── screens/
│   └── components/
└── integration/
    └── app_test.dart
```

### 14.2 Unit Testing Examples
```dart
// test/unit/providers/cart_provider_test.dart
void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;
    late MockCacheManager mockCacheManager;
    late MockConnectionManager mockConnectionManager;

    setUp(() {
      mockCacheManager = MockCacheManager();
      mockConnectionManager = MockConnectionManager();
      cartProvider = CartProvider(
        cacheManager: mockCacheManager,
        connectionManager: mockConnectionManager,
      );
    });

    test('should add item to cart', () async {
      // Arrange
      final product = Product(id: 1, name: 'Test Product', price: 10.0);

      // Act
      await cartProvider.addItem(product, quantity: 2);

      // Assert
      expect(cartProvider.items.length, 1);
      expect(cartProvider.items['1']?.quantity, 2);
      expect(cartProvider.totalAmount, 20.0);
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockConnectionManager.isOnline).thenReturn(false);

      // Act & Assert
      expect(() => cartProvider.syncCartFromServer(), throwsA(isA<NetworkException>()));
    });
  });
}
```

### 14.3 Widget Testing
```dart
// test/widget/screens/login_screen_test.dart
void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email + Password
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Act
      await tester.enterText(find.byKey(Key('email_field')), 'invalid-email');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Email non valida'), findsOneWidget);
    });
  });
}
```

### 14.4 Integration Testing
```dart
// integration_test/app_test.dart
void main() {
  group('RestAll App Integration Tests', () {
    testWidgets('complete login flow', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate through login flow
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('email')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

---

## 15. Sicurezza e Best Practices

### 15.1 Gestione Sicura dei Token
```dart
class SecureTokenManager {
  static const _storage = FlutterSecureStorage();

  // Salvataggio sicuro JWT
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Recupero token con controllo scadenza
  static Future<String?> getValidToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    try {
      final payload = Jwt.parseJwt(token);
      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);

      if (expiry.isBefore(DateTime.now())) {
        await deleteToken();
        return null;
      }

      return token;
    } catch (e) {
      await deleteToken();
      return null;
    }
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
```

### 15.2 Validazione Input
```dart
// helper/validators.dart
class Validators {
  static final RegExp emailRegExp =
    RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

  static final RegExp phoneRegExp =
    RegExp(r'^(?:\+39|0039)?(?:(?:0|1)\d{1})?(?:[0-9]{6,10}));

  static final RegExp partitaIvaRegExp =
    RegExp(r'^[0-9]{11});

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email richiesta';
    }
    if (!emailRegExp.hasMatch(value)) {
      return 'Email non valida';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password richiesta';
    }
    if (value.length < 8) {
      return 'Password deve essere almeno 8 caratteri';
    }
    return null;
  }

  // Sanitizzazione input per prevenire XSS
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .trim();
  }
}
```

### 15.3 Network Security
```dart
class SecureHttpClient {
  static final HttpClient _client = HttpClient()
    ..badCertificateCallback = (cert, host, port) {
      // Solo in sviluppo - rimuovere in produzione
      return !kReleaseMode;
    };

  // Certificate pinning per produzione
  static Future<http.Response> secureRequest(
    String url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    if (kReleaseMode) {
      // Implementa certificate pinning
      return await _makeSecureRequest(url, headers: headers, body: body);
    } else {
      // Sviluppo - permetti self-signed certificates
      return await http.post(Uri.parse(url), headers: headers, body: body);
    }
  }
}
```

### 15.4 Data Encryption
```dart
class DataEncryption {
  static const _key = 'your-encryption-key-32-characters';

  // Crittografia dati sensibili prima del salvataggio
  static String encryptSensitiveData(String data) {
    final key = encrypt.Key.fromBase64(_key);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptSensitiveData(String encryptedData) {
    final parts = encryptedData.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    final key = encrypt.Key.fromBase64(_key);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}
```

---

## 16. Monitoraggio e Analytics

### 16.1 Crash Reporting
```dart
// main.dart - Global error handling
void main() async {
  // Setup crash reporting
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };

  runApp(MyApp());
}

// Custom error reporting
class ErrorReporter {
  static void reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? customData,
  }) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      printDetails: true,
      information: customData?.entries
          .map((e) => DiagnosticsProperty(e.key, e.value))
          .toList(),
    );
  }

  static void logEvent(String event, Map<String, dynamic> parameters) {
    FirebaseAnalytics.instance.logEvent(
      name: event,
      parameters: parameters,
    );
  }
}
```

### 16.2 Performance Monitoring
```dart
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};

  static void startTrace(String traceName) {
    _startTimes[traceName] = DateTime.now();
    FirebasePerformance.instance.newTrace(traceName).start();
  }

  static void endTrace(String traceName) {
    final startTime = _startTimes.remove(traceName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      FirebasePerformance.instance.newTrace(traceName).stop();

      // Log custom metrics
      FirebaseAnalytics.instance.logEvent(
        name: 'performance_trace',
        parameters: {
          'trace_name': traceName,
          'duration_ms': duration.inMilliseconds,
        },
      );
    }
  }
}

// Usage in API calls
Future<List<Product>> fetchProducts() async {
  PerformanceMonitor.startTrace('fetch_products');
  try {
    final products = await _productApi.getProducts();
    return products;
  } finally {
    PerformanceMonitor.endTrace('fetch_products');
  }
}
```

### 16.3 User Analytics
```dart
class UserAnalytics {
  static void trackScreenView(String screenName) {
    FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }

  static void trackUserAction(String action, Map<String, dynamic> parameters) {
    FirebaseAnalytics.instance.logEvent(
      name: action,
      parameters: parameters,
    );
  }

  static void trackPurchase(double value, String currency, List<CartItem> items) {
    FirebaseAnalytics.instance.logPurchase(
      value: value,
      currency: currency,
      parameters: {
        'items': items.map((item) => {
          'item_id': item.id,
          'item_name': item.title,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
      },
    );
  }

  static void setUserProperties(String userId, Map<String, String> properties) {
    FirebaseAnalytics.instance.setUserId(id: userId);
    properties.forEach((key, value) {
      FirebaseAnalytics.instance.setUserProperty(name: key, value: value);
    });
  }
}
```

---

## 17. Ottimizzazioni Avanzate

### 17.1 Lazy Loading e Pagination
```dart
class ProductListProvider with ChangeNotifier {
  static const int _pageSize = 20;

  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;

  Future<void> loadInitialProducts() async {
    _currentPage = 1;
    _products.clear();
    _hasMoreData = true;
    await _loadProducts();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMoreData) return;

    _currentPage++;
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProducts = await _productApi.getProducts(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (newProducts.length < _pageSize) {
        _hasMoreData = false;
      }

      _products.addAll(newProducts);
    } catch (e) {
      _currentPage--; // Rollback su errore
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ListView con pagination automatica
class ProductListView extends StatefulWidget {
  @override
  _ProductListViewState createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more quando si è vicini alla fine
      context.read<ProductListProvider>().loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          controller: _scrollController,
          itemCount: provider.products.length + (provider.hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.products.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return ProductCard(product: provider.products[index]);
          },
        );
      },
    );
  }
}
```

### 17.2 Image Optimization
```dart
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const OptimizedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.error, color: Colors.grey),
      ),
      memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
      memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}
```

### 17.3 Memory Management
```dart
class MemoryEfficientProvider with ChangeNotifier {
  Timer? _cleanupTimer;
  final Map<String, DateTime> _lastAccessed = {};
  static const Duration _maxAge = Duration(minutes: 30);

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performCleanup();
    });
  }

  void _performCleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _lastAccessed.forEach((key, lastAccess) {
      if (now.difference(lastAccess) > _maxAge) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _removeFromCache(key);
    }
  }

  void _updateLastAccessed(String key) {
    _lastAccessed[key] = DateTime.now();
  }
}
```

---

## 18. Troubleshooting e FAQ

### 18.1 Problemi Comuni

**Build Errors:**
```bash
# Gradle version conflicts
cd android && ./gradlew clean
flutter clean
flutter pub get
flutter build apk

# iOS dependency issues
cd ios && rm -rf Pods Podfile.lock
pod install
cd .. && flutter clean && flutter pub get

# Web CORS issues
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Runtime Issues:**
```dart
// HTTP Certificate errors in development
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => !kReleaseMode;
  }
}

// Memory leaks da AnimationController
@override
void dispose() {
  _controller?.dispose(); // Sempre dispose dei controller
  _subscription?.cancel(); // Cancel stream subscriptions
  super.dispose();
}
```

### 18.2 Performance Issues
```dart
// ListView performance per liste grandi
ListView.builder( // ✅ Corretto
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// Evitare
Column(children: items.map((item) => ItemWidget(item)).toList()); // ❌ Lento

// Provider rebuild optimization
Consumer<MyProvider>(
  builder: (context, provider, child) {
    return ExpensiveWidget(data: provider.specificData);
  },
);

// Meglio con Selector per rebuild mirati
Selector<MyProvider, SpecificData>(
  selector: (context, provider) => provider.specificData,
  builder: (context, data, child) => ExpensiveWidget(data: data),
);
```

### 18.3 State Management Issues
```dart
// ❌ Errore comune: modificare stato durante build
Widget build(BuildContext context) {
  if (someCondition) {
    provider.updateState(); // ERRORE: setState durante build
  }
  return Container();
}

// ✅ Corretto: usa addPostFrameCallback
Widget build(BuildContext context) {
  if (someCondition) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.updateState();
    });
  }
  return Container();
}
```

---

## 19. Roadmap e Future Enhancements

### 19.1 Planned Features
- **Real-time Updates**: WebSocket integration per notifiche live
- **Advanced Analytics**: Dashboard completa con metriche business
- **Multi-language**: Supporto completo i18n/l10n
- **Dark Theme**: Tema scuro con preferenze utente
- **Offline Mode**: Funzionalità complete offline con sync
- **Voice Commands**: Integrazione comandi vocali
- **AR Features**: Realtà aumentata per preview prodotti

### 19.2 Technical Improvements
- **Migration to Riverpod**: Da Provider a Riverpod per better DX
- **GraphQL Integration**: Sostituzione REST con GraphQL
- **Microservices**: Separazione backend in microservizi
- **CI/CD Pipeline**: Automazione completa deploy
- **A/B Testing**: Framework per test di funzionalità
- **Advanced Caching**: Redis/Memcached integration

### 19.3 Platform Expansion
- **Apple Watch**: Companion app per watchOS
- **Android TV**: Versione per smart TV
- **Linux Desktop**: Supporto piattaforma Linux
- **PWA Enhanced**: Progressive Web App avanzata

---

## 20. Conclusioni

RestAll rappresenta un esempio completo di applicazione Flutter enterprise-grade che integra:

- **Architettura Scalabile**: Pattern Provider con separazione chiara delle responsabilità
- **Integrazione Multi-Servizio**: WooCommerce, Stripe, Firebase in modo coeso
- **User Experience Moderna**: UI/UX con animazioni fluide e feedback visuale
- **Performance Ottimizzate**: Caching, lazy loading, offline-first strategy
- **Sicurezza Enterprise**: Token management, validazione input, error handling
- **Cross-Platform**: Supporto completo iOS, Android, Web, Desktop

La documentazione fornisce una base solida per:
- **Onboarding** sviluppatori nel progetto
- **Manutenzione** e debugging efficace
- **Estensioni** future con pattern consolidati
- **Best Practices** Flutter in contesto reale

Per domande specifiche o approfondimenti su particolari sezioni, consultare il codice sorgente o contattare il team di sviluppo.
