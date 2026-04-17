import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderApi {
  final String _url = "$apiHost/api/v1/shop/orders";

  final String _refundRequestUrl = "$apiHost/api/v1/shop/refund-requests";

  /// Crea un nuovo ordine in WooCommerce
  Future<http.Response?> createOrder(Map<String, dynamic> orderData) async {
    try {
      print('🛒 Creazione ordine WooCommerce...');
      print('📦 Dati ordine: ${jsonEncode(orderData)}');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse(_url),
        body: jsonEncode(orderData),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Risposta ordine - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      return response;
    } catch (error) {
      print('🔥 Eccezione durante la creazione ordine: $error');
      await _showError('Errore di connessione',
          'Impossibile completare l\'ordine. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Recupera tutti gli ordini dell'utente autenticato
  /// Il filtro email avviene automaticamente lato server
  Future<http.Response?> getOrders() async {
    try {
      print('📋 Recupero ordini utente...');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.get(
        Uri.parse(_url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Risposta ordini - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body);
        print('📦 Trovati ${orders.length} ordini');
      } else {
        print('⚠️ Response body: ${response.body}');
      }

      return response;
    } catch (error) {
      print('🔥 Eccezione durante il recupero ordini: $error');
      await _showError('Errore di connessione',
          'Impossibile recuperare gli ordini. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Recupera gli ordini filtrati per user id e opzionalmente per status
  /// Endpoint: /api/v1/shop/orders/user/:userId?status=
  Future<http.Response?> getOrdersByUserId(String userId,
      {String? status}) async {
    try {
      print('📋 Recupero ordini per utente $userId (status: $status)');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      var uri = '$_url/user/$userId';
      if (status != null && status.isNotEmpty) {
        uri += '?status=${Uri.encodeComponent(status)}';
      }

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Risposta ordini per utente - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body);
        print('📦 Trovati ${orders.length} ordini per utente $userId');
      } else {
        print('⚠️ Response body: ${response.body}');
      }

      return response;
    } catch (error) {
      print('🔥 Eccezione durante il recupero ordini per utente: $error');
      await _showError('Errore di connessione',
          'Impossibile recuperare gli ordini. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Recupera le richieste di rimborso per user id e stato
  /// Endpoint: /api/v1/shop/refund-requests/user/:userId?status=
  Future<http.Response?> getRefundRequestsByUserId(String userId,
      {String? status}) async {
    try {
      print('📋 Recupero refund requests per utente $userId (status: $status)');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      var uri = '$_refundRequestUrl/user/$userId';
      if (status != null && status.isNotEmpty) {
        uri += '?status=${Uri.encodeComponent(status)}';
      }

      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Risposta refund requests - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final refunds = jsonDecode(response.body);
        print(
            '📦 Trovate ${refunds.length} refund requests per utente $userId');
      } else {
        print('⚠️ Response body: ${response.body}');
      }

      return response;
    } catch (error) {
      print('🔥 Eccezione durante il recupero refund requests: $error');
      await _showError('Errore di connessione',
          'Impossibile recuperare le richieste di rimborso. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Crea un payment intent per un prodotto marketplace
  /// Endpoint: /api/v1/shop/cart/order/intent/marketplace/:productId
  Future<http.Response?> createMarketplacePaymentIntent(
      int productId, Map<String, dynamic> orderData) async {
    try {
      print('💳 Creazione payment intent Marketplace per prodotto $productId...');
      print('📦 Dati ordine: ${jsonEncode(orderData)}');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse('$apiHost/api/v1/shop/cart/order/intent/marketplace/$productId'),
        body: jsonEncode(orderData),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Risposta payment intent marketplace - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      return response;
    } catch (error) {
      print('🔥 Eccezione durante la creazione payment intent marketplace: $error');
      await _showError('Errore di connessione',
          'Impossibile creare il payment intent. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Aggiorna un ordine esistente (per resi e modifiche)
  /// Accetta l'oggetto WooCommerce completo come nel createOrder
  Future<http.Response?> updateOrder(
      String orderId, Map<String, dynamic> orderData) async {
    try {
      print('✏️ Aggiornamento ordine $orderId...');
      print('📦 Dati aggiornamento: ${jsonEncode(orderData)}');

      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.put(
        Uri.parse('$_url/$orderId'),
        body: jsonEncode(orderData),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print(
          '🟢 Risposta aggiornamento ordine - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final updatedOrder = jsonDecode(response.body);
        print('✅ Ordine $orderId aggiornato con successo');
        print('📊 Nuovo status: ${updatedOrder['status']}');
      } else {
        print('⚠️ Errore nell\'aggiornamento ordine');
      }

      return response;
    } catch (error) {
      print('🔥 Eccezione durante l\'aggiornamento ordine: $error');
      await _showError('Errore di connessione',
          'Impossibile aggiornare l\'ordine. Controlla la connessione e riprova.');
      return null;
    }
  }

  // Metodi helper esistenti (invariati)
  Future<void> _showAuthError() async {
    await FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore di autenticazione',
      text: 'Sessione scaduta. Effettua nuovamente il login.',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  Future<void> _showError(String title, String message) async {
    await FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  Future<String?> _getCookie() async {
    final _prefs = await SharedPreferences.getInstance();
    var _cookie = _prefs.getString('cookie');
    return _cookie;
  }

  Future<String?> _getJwt() async {
    try {
      final _prefs = await SharedPreferences.getInstance();
      String? _jwtTemp = _prefs.getString('jwt');

      if (_jwtTemp != null) {
        Cookie _jwt = Cookie.fromSetCookieValue(_jwtTemp);
        return _jwt.value;
      } else {
        print('⚠️ JWT token non trovato in SharedPreferences');
        return null;
      }
    } catch (error) {
      print('❌ Errore durante il recupero del JWT: $error');
      return null;
    }
  }
}
