import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentIntent;
import 'package:restall/API/Checkout/checkout_api.dart';
import 'package:restall/models/payment_intent.dart';
import 'package:restall/providers/Cart/cart_provider.dart';

enum CheckoutStatus { idle, loading, processing, success, error }

class CheckoutProvider with ChangeNotifier {
  final CheckoutApi _checkoutApi = CheckoutApi();

  CheckoutStatus _status = CheckoutStatus.idle;
  String? _errorMessage;
  PaymentIntent? _paymentIntent;

  CheckoutStatus get status => _status;
  String? get errorMessage => _errorMessage;
  PaymentIntent? get paymentIntent => _paymentIntent;
  bool get isLoading => _status == CheckoutStatus.loading;
  bool get isProcessing => _status == CheckoutStatus.processing;

  // Inizializza il pagamento
  Future<bool> initializePayment({
    required CartProvider cartProvider,
    Map<String, dynamic>? customerData,
  }) async {
    try {
      _updateStatus(CheckoutStatus.loading);

      // Calcola l'importo in centesimi
      int amountInCents = (cartProvider.totalAmount * 100).round();

      if (amountInCents <= 0) {
        _setError('Importo non valido');
        return false;
      }

      // Crea il Payment Intent
      _paymentIntent = await _checkoutApi.createPaymentIntent(
        amount: amountInCents,
        currency: 'eur',
        metadata: {
          'order_type': 'cart_purchase',
          'item_count': cartProvider.itemCount.toString(),
          ...?customerData,
        },
      );

      if (_paymentIntent == null) {
        _setError('Impossibile inizializzare il pagamento');
        return false;
      }

      _updateStatus(CheckoutStatus.idle);
      return true;
    } catch (error) {
      _setError('Errore inizializzazione: $error');
      return false;
    }
  }

  // Processa il pagamento con Payment Sheet
  Future<bool> processPaymentWithSheet({
    required CartProvider cartProvider,
    BillingDetails? billingDetails,
  }) async {
    if (_paymentIntent == null) {
      _setError('Payment Intent non inizializzato');
      return false;
    }

    try {
      _updateStatus(CheckoutStatus.processing);

      // Configura il Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _paymentIntent!.clientSecret,
          merchantDisplayName: 'RestAll Shop',
          style: ThemeMode.system,
          billingDetails: billingDetails,

          // Configurazioni opzionali
          setupIntentClientSecret: null,
          customFlow: false,
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'IT',
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'IT',
            testEnv: true, // Cambia in false per produzione
          ),
        ),
      );

      // Presenta il Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Se arriviamo qui, il pagamento è stato completato
      print('✅ Pagamento completato con successo!');

      // Conferma l'ordine sul server
      final orderConfirmation = await _checkoutApi.confirmOrder(
        paymentIntentId: _paymentIntent!.id,
        orderData: {
          'items': cartProvider.items.values
              .map((item) => {
                    'product_id': item.id,
                    'quantity': item.quantity,
                    'price': item.price,
                    'title': item.title,
                  })
              .toList(),
          'total_amount': cartProvider.totalAmount,
        },
      );

      if (orderConfirmation?.statusCode == 200) {
        // Svuota il carrello dopo l'ordine confermato
        await cartProvider.clear();
        _updateStatus(CheckoutStatus.success);
        return true;
      } else {
        _setError('Pagamento effettuato ma errore nella conferma ordine');
        return false;
      }
    } on StripeException catch (e) {
      print('❌ Stripe Error: ${e.error.localizedMessage}');

      if (e.error.code == FailureCode.Canceled) {
        _setError('Pagamento annullato dall\'utente');
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

  // Processa pagamento con elementi custom
  Future<bool> processCustomPayment({
    required CartProvider cartProvider,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    if (_paymentIntent == null) {
      _setError('Payment Intent non inizializzato');
      return false;
    }

    try {
      _updateStatus(CheckoutStatus.processing);

      // Conferma il pagamento
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: _paymentIntent!.clientSecret,
        data: paymentMethodParams,
      );

      if (result.status == PaymentIntentsStatus.Succeeded) {
        // Conferma l'ordine sul server
        final orderConfirmation = await _checkoutApi.confirmOrder(
          paymentIntentId: _paymentIntent!.id,
        );

        if (orderConfirmation?.statusCode == 200) {
          await cartProvider.clear();
          _updateStatus(CheckoutStatus.success);
          return true;
        }
      }

      _setError('Pagamento non completato');
      return false;
    } on StripeException catch (e) {
      _setError(e.error.localizedMessage ?? 'Errore Stripe');
      return false;
    } catch (e) {
      _setError('Errore: $e');
      return false;
    }
  }

  // Reset dello stato
  void resetCheckout() {
    _status = CheckoutStatus.idle;
    _errorMessage = null;
    _paymentIntent = null;
    notifyListeners();
  }

  void _updateStatus(CheckoutStatus newStatus) {
    _status = newStatus;
    if (newStatus != CheckoutStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _status = CheckoutStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
