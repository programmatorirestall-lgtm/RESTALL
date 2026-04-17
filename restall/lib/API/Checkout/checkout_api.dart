import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restall/config.dart';
import 'package:restall/models/payment_intent.dart';

class CheckoutApi {
  final String _baseUrl = "$apiHost/api/v1/shop";

  // Crea Payment Intent per Stripe
  Future<PaymentIntent?> createPaymentIntent({
    required int amount, // in centesimi
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'metadata': metadata ?? {},
        }),
      );

      print('💳 Payment Intent Response: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentIntent.fromJson(data);
      } else {
        print('❌ Errore creazione Payment Intent: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('❌ Errore Payment Intent: $error');
      return null;
    }
  }

  // Conferma l'ordine dopo il pagamento
  Future<http.Response?> confirmOrder({
    required String paymentIntentId,
    Map<String, dynamic>? orderData,
  }) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      final response = await http.post(
        Uri.parse('$_baseUrl/order/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie',
        },
        body: jsonEncode({
          'payment_intent_id': paymentIntentId,
          'order_data': orderData ?? {},
        }),
      );

      print('✅ Order Confirmation Response: ${response.statusCode}');
      return response;
    } catch (error) {
      print('❌ Errore conferma ordine: $error');
      return null;
    }
  }

  // Metodi helper per JWT e Cookie (copiati dalla CartApi)
  Future<String?> _getCookie() async {
    final _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('cookie');
  }

  Future<String?> _getJwt() async {
    final _prefs = await SharedPreferences.getInstance();
    String? _jwtTemp = _prefs.getString('jwt');

    if (_jwtTemp != null) {
      Cookie _jwt = Cookie.fromSetCookieValue(_jwtTemp);
      return _jwt.value;
    }
    return null;
  }
}
