import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:restall/API/Cart/cart.dart';
import 'package:restall/API/Order/order_api.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'dart:convert';

enum IntegratedCheckoutStatus {
  idle,
  creatingIntent,
  processing,
  creatingOrder,
  success,
  error
}

class IntegratedCheckoutProvider with ChangeNotifier {
  final CartApi _cartApi = CartApi();
  final OrderApi _orderApi = OrderApi();

  IntegratedCheckoutStatus _status = IntegratedCheckoutStatus.idle;
  String? _errorMessage;
  Map<String, dynamic>? _paymentIntentData;
  Map<String, dynamic>? _createdOrder;

  // Getters
  IntegratedCheckoutStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get paymentIntentData => _paymentIntentData;
  Map<String, dynamic>? get createdOrder => _createdOrder;
  bool get isLoading => _status == IntegratedCheckoutStatus.creatingIntent;
  bool get isProcessing => _status == IntegratedCheckoutStatus.processing;
  bool get isCreatingOrder => _status == IntegratedCheckoutStatus.creatingOrder;

  /// Processo completo: createOrderOnly → Stripe Payment → WooCommerce Order
  Future<bool> processCompletePaymentFlow({
    required CartProvider cartProvider,
    required Map<String, dynamic> billingData,
    Map<String, dynamic>? shippingData,
    String paymentMethod = 'stripe',
    String paymentMethodTitle = 'Carta di credito',
  }) async {
    try {
      // FASE 1: Crea Payment Intent usando createOrderOnly esistente
      _updateStatus(IntegratedCheckoutStatus.creatingIntent);
      print('🔵 Creazione Payment Intent con createOrderOnly...');

      final response = await _cartApi.createOrderOnly();

      if (response.statusCode != 200) {
        _setError('Errore nella creazione del Payment Intent');
        return false;
      }

      _paymentIntentData = jsonDecode(response.body);
      print('✅ Payment Intent data ricevuto: $_paymentIntentData');

      // DEBUG: Stampa i campi disponibili per capire la struttura
      print('🔍 Campi disponibili nella risposta:');
      _paymentIntentData!.forEach((key, value) {
        print('  - $key: $value');
      });

      // FASE 2: Verifica che abbiamo tutti i campi necessari
      String? clientSecret;
      String? customerId;
      String? ephemeralKey;

      // Tenta di estrarre il client_secret con diverse possibili chiavi
      if (_paymentIntentData!.containsKey('paymentIntent')) {
        clientSecret = _paymentIntentData!['paymentIntent'];
      } else if (_paymentIntentData!.containsKey('client_secret')) {
        clientSecret = _paymentIntentData!['client_secret'];
      } else if (_paymentIntentData!.containsKey('clientSecret')) {
        clientSecret = _paymentIntentData!['clientSecret'];
      }

      // Customer ID
      if (_paymentIntentData!.containsKey('customer')) {
        customerId = _paymentIntentData!['customer'];
      } else if (_paymentIntentData!.containsKey('customerId')) {
        customerId = _paymentIntentData!['customerId'];
      }

      // Ephemeral Key
      if (_paymentIntentData!.containsKey('ephemeralKey')) {
        ephemeralKey = _paymentIntentData!['ephemeralKey'];
      } else if (_paymentIntentData!.containsKey('ephemeral_key')) {
        ephemeralKey = _paymentIntentData!['ephemeral_key'];
      }

      print('🔍 Client Secret estratto: $clientSecret');
      print('🔍 Customer ID estratto: $customerId');
      print('🔍 Ephemeral Key estratto: $ephemeralKey');

      // Validazione del client_secret
      if (clientSecret == null || clientSecret.isEmpty) {
        _setError('Client secret mancante nella risposta del server');
        return false;
      }

      // Validazione formato client_secret (deve contenere "pi_" per PaymentIntent)
      if (!clientSecret.contains('_secret_')) {
        print('⚠️ Formato client_secret sospetto: $clientSecret');
        // Stripe si aspetta un formato tipo: pi_1234567890_secret_abcdefghijk
        _setError(
            'Formato client_secret non valido. Controlla la configurazione del server.');
        return false;
      }

      // FASE 3: Processa il pagamento Stripe
      _updateStatus(IntegratedCheckoutStatus.processing);
      print('💳 Processamento pagamento Stripe...');

      // Crea BillingDetails da Map
      final billingDetails = BillingDetails(
        name: billingData['name'] ?? '',
        email: billingData['email'] ?? '',
        phone: billingData['phone'] ?? '',
        address: Address(
          line1: billingData['address'] ?? '',
          city: billingData['city'] ?? '',
          postalCode: billingData['postalCode'] ?? '',
          country: billingData['country'] ?? 'IT',
          line2: '',
          state: '',
        ),
      );

      // Configura Payment Sheet con gestione sicura dei parametri opzionali
      final paymentSheetParams = SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'RestAll',
        style: ThemeMode.light,
        billingDetails: billingDetails,
        allowsDelayedPaymentMethods: true,
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'IT',
          testEnv: true,
        ),
        applePay: const PaymentSheetApplePay(
          merchantCountryCode: 'IT',
        ),
      );

      // Aggiungi customerId e ephemeralKey solo se disponibili
      if (customerId != null && customerId.isNotEmpty) {
        // Purtroppo non possiamo modificare paymentSheetParams dopo la creazione
        // Quindi ricreiamo con tutti i parametri
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'RestAll',
            customerId: customerId,
            customerEphemeralKeySecret: ephemeralKey, // Può essere null
            style: ThemeMode.light,
            billingDetails: billingDetails,
            allowsDelayedPaymentMethods: true,
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'IT',
              testEnv: true,
            ),
            applePay: const PaymentSheetApplePay(
              merchantCountryCode: 'IT',
            ),
          ),
        );
      } else {
        // Versione senza customer
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: paymentSheetParams,
        );
      }

      await Stripe.instance.presentPaymentSheet();
      print('✅ Pagamento Stripe completato con successo!');

      // FASE 4: Crea l'ordine WooCommerce
      _updateStatus(IntegratedCheckoutStatus.creatingOrder);
      print('📦 Creazione ordine WooCommerce...');

      final orderData = _buildWooCommerceOrderData(
        cartProvider: cartProvider,
        billingData: billingData,
        shippingData: shippingData,
        paymentMethod: paymentMethod,
        paymentMethodTitle: paymentMethodTitle,
      );

      final orderResponse = await _orderApi.createOrder(orderData);

      if (orderResponse?.statusCode == 201) {
        _createdOrder = jsonDecode(orderResponse!.body);
        print('✅ Ordine WooCommerce creato: ID ${_createdOrder!['id']}');

        // FASE 5: Svuota il carrello
        await cartProvider.clear();
        print('🛒 Carrello svuotato');

        _updateStatus(IntegratedCheckoutStatus.success);
        return true;
      } else {
        _setError(
            'Pagamento completato ma errore nella creazione ordine. Contatta il supporto.');
        print('❌ Errore creazione ordine: ${orderResponse?.statusCode}');
        print('📄 Response body: ${orderResponse?.body}');
        return false;
      }
    } on StripeException catch (e) {
      print('❌ Stripe Error: ${e.error.localizedMessage}');
      print('❌ Stripe Error Code: ${e.error.code}');
      print('❌ Stripe Error Type: ${e.error.type}');

      if (e.error.code == FailureCode.Canceled) {
        _setError('Pagamento annullato dall\'utente');
      } else if (e.error.localizedMessage?.contains('secret') == true) {
        _setError(
            'Errore nel formato del Payment Intent. Controlla la configurazione del server Stripe.');
      } else {
        _setError(e.error.localizedMessage ?? 'Errore nel pagamento');
      }
      return false;
    } catch (e) {
      print('❌ General Error: $e');
      _setError('Errore imprevisto: $e');
      return false;
    }
  }

  /// Costruisce i dati dell'ordine nel formato WooCommerce
  Map<String, dynamic> _buildWooCommerceOrderData({
    required CartProvider cartProvider,
    required Map<String, dynamic> billingData,
    Map<String, dynamic>? shippingData,
    required String paymentMethod,
    required String paymentMethodTitle,
  }) {
    // Billing data
    final billing = {
      'first_name': billingData['firstName'] ??
          billingData['name']?.split(' ').first ??
          '',
      'last_name': billingData['lastName'] ??
          billingData['name']?.split(' ').skip(1).join(' ') ??
          '',
      'address_1': billingData['address'] ?? '',
      'address_2': billingData['address2'] ?? '',
      'city': billingData['city'] ?? '',
      'state': billingData['state'] ?? '',
      'postcode': billingData['postalCode'] ?? '',
      'country': billingData['country'] ?? 'IT',
      'email': billingData['email'] ?? '',
      'phone': billingData['phone'] ?? '',
    };

    // Shipping data (usa billing se non specificato)
    final shipping = shippingData ??
        {
          'first_name': billing['first_name'],
          'last_name': billing['last_name'],
          'address_1': billing['address_1'],
          'address_2': billing['address_2'],
          'city': billing['city'],
          'state': billing['state'],
          'postcode': billing['postcode'],
          'country': billing['country'],
        };

    // Line items dal carrello
    final lineItems = cartProvider.items.values
        .map((item) => {
              'product_id': int.tryParse(item.id) ?? 0,
              'quantity': item.quantity,
              'name': item.title,
              'price': item.price.toString(),
            })
        .toList();

    return {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': true, // Ordine già pagato tramite Stripe
      'billing': billing,
      'shipping': shipping,
      'line_items': lineItems,
      'shipping_lines': [
        {
          'method_id': 'flat_rate',
          'method_title': 'Spedizione standard',
          'total': '0.00',
        }
      ],
      'meta_data': [
        {
          'key': 'stripe_payment_intent_id',
          'value': _extractPaymentIntentId(),
        },
        {
          'key': 'payment_processed_via',
          'value': 'restall_app',
        }
      ],
    };
  }

  /// Estrae l'ID del Payment Intent dal client_secret
  String _extractPaymentIntentId() {
    final clientSecret = _paymentIntentData?['paymentIntent'] ??
        _paymentIntentData?['client_secret'] ??
        _paymentIntentData?['clientSecret'] ??
        '';

    if (clientSecret.isNotEmpty && clientSecret.contains('_secret_')) {
      // Formato: pi_1234567890_secret_abcdefghijk
      return clientSecret.split('_secret_')[0];
    }

    return '';
  }

  void resetCheckout() {
    _status = IntegratedCheckoutStatus.idle;
    _errorMessage = null;
    _paymentIntentData = null;
    _createdOrder = null;
    notifyListeners();
  }

  void _updateStatus(IntegratedCheckoutStatus newStatus) {
    _status = newStatus;
    if (newStatus != IntegratedCheckoutStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _status = IntegratedCheckoutStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}

// ============================================================================
// VERSIONE SEMPLIFICATA PER IL TUO CheckOutScreen
// ============================================================================

/*
SOSTITUISCI il tuo metodo _processStripePayment() con questo:
*/

// ============================================================================
// DEBUG: METODO PER VERIFICARE LA RISPOSTA DEL TUO createOrderOnly()
// ============================================================================

Future<void> debugCreateOrderOnly() async {
  try {
    print('🔍 DEBUG: Analisi risposta createOrderOnly()');

    final response = await CartApi().createOrderOnly();
    print('📦 Status Code: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('📦 Campi disponibili:');
      data.forEach((key, value) {
        print(
            '  - $key: ${value.toString().length > 50 ? value.toString().substring(0, 50) + "..." : value}');
      });

      // Cerca possibili campi client_secret
      final possibleSecrets = [
        'paymentIntent',
        'client_secret',
        'clientSecret',
        'payment_intent_client_secret'
      ];
      for (String field in possibleSecrets) {
        if (data.containsKey(field)) {
          final value = data[field].toString();
          print(
              '🔍 Trovato possibile client_secret in "$field": ${value.length > 20 ? value.substring(0, 20) + "..." : value}');

          if (value.contains('_secret_')) {
            print('✅ Formato client_secret valido!');
          } else {
            print('❌ Formato client_secret NON valido');
          }
        }
      }
    }
  } catch (e) {
    print('❌ Errore debug: $e');
  }
}
