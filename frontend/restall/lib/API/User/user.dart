import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/API/api_exceptions.dart';
import 'package:restall/config.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/models/UserProfile.dart';
import 'package:restall/models/stripe_refund.dart';
import 'package:restall/models/UserProducts.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserApi {
  final String _url = apiHost + "/user/";
  final http.Client _client;

  UserApi({http.Client? client}) : _client = client ?? http.Client();

  getData() async {
    return _makeRequest<UserProfile>(
      () async => _client.get(
        Uri.parse(_url + "me"),
        headers: await _getHeaders(),
      ),
      (body) {
        final data = body.containsKey('user') ? body['user'] : body;
        if (data is Map<String, dynamic>) {
          return UserProfile.fromJson(data);
        }
        throw BadResponseException(
            'Formato di risposta non valido per getData.');
      },
    );
  }

  Future<Map<String, dynamic>> getSellerDashboard() async {
    final _jwt = await _getJwt();
    if (_jwt == null) {
      throw UnauthorizedException('Token non trovato o non valido.');
    }

    try {
      final response = await _client
          .get(
            Uri.parse("${_url}seller-dashboard"),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
            'Non autorizzato. Effettua di nuovo il login.');
      } else if (response.statusCode == 403) {
        throw BadResponseException(
            'Devi completare la configurazione da venditore.');
      } else {
        throw BadResponseException(
            'Errore nel recupero dashboard: ${response.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Timeout durante il recupero della dashboard.');
    } on SocketException {
      throw NetworkException('Nessuna connessione internet.');
    }
  }

  Future<UserProductsResponse> getUserProducts() async {
    return _makeRequest<UserProductsResponse>(
      () async => _client.get(
        Uri.parse("$apiHost/api/v1/shop/user/prodotto"),
        headers: await _getHeaders(),
      ),
      (body) {
        print('📦 DEBUG UserApi: Risposta getUserProducts: $body');
        if (body is Map<String, dynamic>) {
          return UserProductsResponse.fromJson(body);
        }
        throw BadResponseException(
            'Formato di risposta non valido per getUserProducts.');
      },
    );
  }

  Future<Map<String, dynamic>> getUserDataWithProfits() async {
    final _jwt = await _getJwt();
    if (_jwt == null) {
      throw UnauthorizedException('Token non trovato o non valido.');
    }

    try {
      final response = await _client
          .get(
            Uri.parse(_url + "me"),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        // Restituisce i dati grezzi con i profitti inclusi
        return body.containsKey('user') ? body['user'] : body;
      }

      // Gestisci errori come nel metodo originale
      dynamic errorBody;
      try {
        errorBody = json.decode(response.body);
      } catch (e) {
        errorBody = {
          'message': 'Impossibile decodificare la risposta di errore.'
        };
      }

      final errorMessage =
          (errorBody is Map && errorBody.containsKey('message'))
              ? errorBody['message']
              : 'Errore sconosciuto.';

      switch (response.statusCode) {
        case 400:
          throw BadRequestException(errorMessage);
        case 401:
          throw UnauthorizedException(errorMessage);
        case 403:
          throw UnauthorizedException(errorMessage);
        case 404:
          throw NotFoundException(errorMessage);
        default:
          throw ServerException(errorMessage);
      }
    } on SocketException {
      throw NetworkException(
          'Connessione al server non riuscita. Controlla la tua connessione internet.');
    } on TimeoutException {
      throw NetworkException(
          'Il server non ha risposto in tempo. Riprova più tardi.');
    } on FormatException {
      throw BadResponseException('Formato di risposta dal server non valido.');
    }
  }

  Future<UserProfile> updateProfile(dynamic data, String id) async {
    return _makeRequest<UserProfile>(
      () async {
        String jsonBody;

        // Gestisci sia UserProfile che Map<String, dynamic>
        if (data is UserProfile) {
          jsonBody = userProfileToJson(data);
        } else if (data is Map<String, dynamic>) {
          jsonBody = jsonEncode(data);
        } else {
          throw ArgumentError(
              'updateProfile: data deve essere UserProfile o Map<String, dynamic>');
        }

        print('🔄 DEBUG UserApi: Aggiornamento profilo ID: $id');
        print('📦 DEBUG UserApi: Body: $jsonBody');

        return _client.put(
          Uri.parse(_url + id),
          body: jsonBody,
          headers: await _getHeaders(),
        );
      },
      (body) {
        print('✅ DEBUG UserApi: Risposta updateProfile: $body');

        // Gestisci la risposta che può avere strutture diverse
        Map<String, dynamic> userData;

        if (body is Map<String, dynamic>) {
          // Se c'è un wrapper "user", usalo, altrimenti usa il body direttamente
          userData = body.containsKey('user') ? body['user'] : body;
        } else {
          throw BadResponseException(
              'Formato di risposta non valido per updateProfile.');
        }

        return UserProfile.fromJson(userData);
      },
    );
  }

  Future<UserProfile> updateProfileData(Map<String, dynamic> data,
      [String? userId]) async {
    // Se userId non è fornito, prova a recuperarlo dal token
    String? targetUserId = userId;
    if (targetUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token != null && token.isNotEmpty) {
        try {
          final jwtCookie = Cookie.fromSetCookieValue(token);
          final decodedToken = Jwt.parseJwt(jwtCookie.value);
          targetUserId = decodedToken['id']?.toString();
        } catch (e) {
          //print('❌ Errore estrazione userId dal token: $e');
        }
      }
    }

    if (targetUserId == null) {
      throw UnauthorizedException('ID utente non trovato per l\'aggiornamento');
    }

    return updateProfile(data, targetUserId);
  }

  Future<void> deleteProfile(String id) async {
    await _makeRequest<void>(
      () async => _client.delete(
        Uri.parse(_url + id),
        headers: await _getHeaders(),
      ),
      (_) => null, // Success means no data to parse
    );
  }

  /// Crea un account Stripe Connect per il venditore
  /// Restituisce l'URL di onboarding Stripe
  Future<Map<String, dynamic>> createSellerAccount() async {
    return _makeRequest<Map<String, dynamic>>(
      () async => _client.post(
        Uri.parse(_url + "create-seller"),
        headers: await _getHeaders(),
      ),
      (body) {
        print('📄 Create Seller Response body: ${json.encode(body)}');
        if (body is Map<String, dynamic>) {
          return body;
        }
        throw BadResponseException(
            'Formato di risposta non valido per createSellerAccount.');
      },
    );
  }

  /// Verifica lo stato dell'account venditore Stripe
  /// Restituisce charges_enabled, payouts_enabled, details_submitted
  Future<Map<String, dynamic>> getSellerStatus() async {
    return _makeRequest<Map<String, dynamic>>(
      () async => _client.get(
        Uri.parse(_url + "seller-status"),
        headers: await _getHeaders(),
      ),
      (body) {
        print('📄 Seller Status Response body: ${json.encode(body)}');
        if (body is Map<String, dynamic>) {
          return body;
        }
        throw BadResponseException(
            'Formato di risposta non valido per getSellerStatus.');
      },
    );
  }

  /// Effettua il rimborso di un prodotto marketplace tramite Stripe Connect
  /// POST /marketplace/products/:productId/refund
  ///
  /// Stripe gestisce automaticamente:
  /// - Rimborso al cliente
  /// - Reverse transfer al venditore
  /// - Fee e riconciliazione
  Future<StripeRefundResponse> refundMarketplaceProduct(
      String productId) async {
    return _makeRequest<StripeRefundResponse>(
      () async => _client.post(
        Uri.parse("$apiHost/marketplace/products/$productId/refund"),
        headers: await _getHeaders(),
      ),
      (body) {
        if (body is Map<String, dynamic>) {
          return StripeRefundResponse.fromJson(body);
        }
        throw BadResponseException(
            'Formato di risposta non valido per refundMarketplaceProduct.');
      },
    );
  }

  Future<T> _makeRequest<T>(
    Future<http.Response> Function() request,
    T Function(dynamic body) onSuccess,
  ) async {
    final _jwt = await _getJwt();
    if (_jwt == null) {
      throw UnauthorizedException('Token non trovato o non valido.');
    }

    try {
      final response = await request().timeout(const Duration(seconds: 15));
      return _processResponse(response, onSuccess);
    } on SocketException {
      throw NetworkException(
          'Connessione al server non riuscita. Controlla la tua connessione internet.');
    } on TimeoutException {
      throw NetworkException(
          'Il server non ha risposto in tempo. Riprova più tardi.');
    } on FormatException {
      throw BadResponseException('Formato di risposta dal server non valido.');
    }
  }

  T _processResponse<T>(
      http.Response response, T Function(dynamic body) onSuccess) {
    // Debug logging commentato per produzione
    // print('📡 DEBUG: Status Code: ${response.statusCode}');
    // print('📄 DEBUG: Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

    // Handle success cases first
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // For 204 No Content, body might be empty
      if (response.body.isEmpty) {
        // print('✅ DEBUG: Risposta vuota (204 No Content)');
        return onSuccess(null);
      }

      try {
        final body = json.decode(response.body);
        return onSuccess(body);
      } catch (e) {
        // print('❌ DEBUG: Errore parsing JSON response: $e');
        throw BadResponseException(
            'Formato JSON non valido nella risposta del server.');
      }
    }

    // Handle error cases
    // print('⚠️ DEBUG: Gestione errore - Status: ${response.statusCode}');
    // print('⚠️ DEBUG: Response body raw: "${response.body}"');

    dynamic body;
    try {
      body = json.decode(response.body);
      // print('✅ DEBUG: Errore decodificato: $body');
    } catch (e) {
      // print('❌ DEBUG: Impossibile decodificare errore: $e');
      body = {
        'message':
            'Impossibile decodificare la risposta di errore. Body: ${response.body}'
      };
    }

    final errorMessage = (body is Map && body.containsKey('message'))
        ? body['message']
        : 'Errore sconosciuto.';

    // print('❌ DEBUG: Errore API: $errorMessage (Status: ${response.statusCode})');

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(errorMessage);
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw UnauthorizedException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      default:
        throw ServerException(errorMessage);
    }
  }

  getNetwork() async {
    ////print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse("${_url}network"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    ////print(response.body);
    if (response.statusCode == 200) {
      return response;
    } else {
      //LogoutApi().logout();
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore con il network',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  restorePassword(data) async {
    final response = await http.patch(
      Uri.parse("${_url}password"),
      body: jsonEncode(data),
      headers: await _getHeaders(),
    );
    return response;
  }

  // --- Metodi di utilità privati ---
  Future<Map<String, String>> _getHeaders() async {
    var jwt = await _getJwt();
    var cookie = await _getCookie();

    //print('🔑 JWT Token: ${jwt?.substring(0, 20)}...');
    //print('🍪 Cookie: $cookie');

    final headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $jwt',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };

    //print('📋 Headers preparati: ${headers.keys.join(', ')}');
    return headers;
  }

  Future<String?> _getCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var cookie = prefs.getString('cookie');

      if (cookie != null) {
        // Rimuovi eventuali caratteri problematici
        cookie = cookie.trim();
        if (cookie.endsWith(';')) {
          cookie = cookie.substring(0, cookie.length - 1);
        }
      }

      return cookie;
    } catch (error) {
      //print('❌ Errore durante il recupero del cookie: $error');
      return null;
    }
  }

  Future<String?> _getJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtRaw = prefs.getString('jwt');

      if (jwtRaw == null || jwtRaw.isEmpty) {
        //print('⚠️ JWT token non trovato');
        return null;
      }

      // Se è già pulito, restituiscilo
      if (!jwtRaw.contains('=') && !jwtRaw.contains(';')) {
        return jwtRaw;
      }

      // Altrimenti, parsalo come cookie
      final jwtCookie = Cookie.fromSetCookieValue(jwtRaw);
      return jwtCookie.value;
    } catch (error) {
      //print('❌ Errore parsing JWT: $error');
      return null;
    }
  }
}
