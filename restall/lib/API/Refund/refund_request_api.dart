import 'dart:convert';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/config.dart';
import 'package:restall/models/refund_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RefundRequestApi {
  final String _baseUrl = "$apiHost/api/v1/shop/refund-requests";

  /// Recupera JWT token da SharedPreferences
  Future<String?> _getJwt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return null;

    // Rimuove eventuali virgolette, spazi e prefissi tipo "jwt="
    final cleanToken = token
        .replaceAll('"', '')
        .replaceAll('jwt=', '')
        .split(';')
        .first
        .trim();

    print('🔑 JWT token usato: $cleanToken');
    return cleanToken;
  }

  /// Recupera Cookie da SharedPreferences
  Future<String?> _getCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookie');
  }

  /// Mostra alert di errore autenticazione
  Future<void> _showAuthError() async {
    await FlutterPlatformAlert.showAlert(
      windowTitle: 'Autenticazione Richiesta',
      text: 'Devi effettuare il login per continuare.',
      alertStyle: AlertButtonStyle.ok,
    );
  }

  /// Mostra alert generico di errore
  Future<void> _showError(String title, String message) async {
    await FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
    );
  }

  /// 📥 GET /refund-requests - Lista tutte le richieste di reso
  Future<List<RefundRequest>?> getRefundRequests() async {
    try {
      print('📋 Recupero richieste di reso...');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta lista resi - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Trovate ${data.length} richieste di reso');
        return data.map((json) => RefundRequest.fromJson(json)).toList();
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante il recupero richieste: $error');
      await _showError('Errore di connessione',
          'Impossibile recuperare le richieste di reso. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// 🔍 GET /refund-requests/{id} - Recupera singola richiesta
  Future<RefundRequest?> getRefundRequest(int id) async {
    try {
      print('🔍 Recupero richiesta di reso #$id...');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta dettaglio reso - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        print('⚠️ Richiesta non trovata');
        await _showError('Non Trovato', 'La richiesta di reso non esiste.');
        return null;
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante il recupero richiesta: $error');
      await _showError('Errore di connessione',
          'Impossibile recuperare la richiesta. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// ➕ POST /refund-requests - Crea nuova richiesta di reso
  Future<RefundRequest?> createRefundRequest(CreateRefundRequestDto dto) async {
    try {
      print('➕ Creazione richiesta di reso...');
      print('📦 Dati: ${jsonEncode(dto.toJson())}');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: jsonEncode(dto.toJson()),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta creazione reso - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RefundRequest.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        await _showError(
            'Dati Invalidi', error['error'] ?? 'Controlla i dati inseriti.');
        return null;
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante la creazione richiesta: $error');
      await _showError('Errore di connessione',
          'Impossibile creare la richiesta. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// ✅ POST /refund-requests/{id}/approve - Approva richiesta (ADMIN)
  Future<RefundRequest?> approveRefundRequest(int id) async {
    try {
      print('✅ Approvazione richiesta #$id...');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$id/approve'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta approvazione - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        await _showError('Non Trovato', 'La richiesta di reso non esiste.');
        return null;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        await _showError(
            'Errore', error['error'] ?? 'Richiesta già processata.');
        return null;
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante l\'approvazione: $error');
      await _showError('Errore di connessione',
          'Impossibile approvare la richiesta. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// ❌ POST /refund-requests/{id}/decline - Rifiuta richiesta (ADMIN)
  Future<RefundRequest?> declineRefundRequest(int id) async {
    try {
      print('❌ Rifiuto richiesta #$id...');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$id/decline'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta rifiuto - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        await _showError('Non Trovato', 'La richiesta di reso non esiste.');
        return null;
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante il rifiuto: $error');
      await _showError('Errore di connessione',
          'Impossibile rifiutare la richiesta. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// 💳 POST /refund-requests/{id}/refund - Esegue il rimborso (ADMIN)
  Future<RefundResult?> executeRefund(int id) async {
    try {
      print('💳 Esecuzione rimborso per richiesta #$id...');

      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null) {
        print('❌ JWT token non disponibile');
        await _showAuthError();
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$id/refund'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      );

      print('🟢 Risposta rimborso - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundResult.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        await _showError(
            'Errore',
            error['error'] ??
                'La richiesta deve essere approvata prima del rimborso.');
        return null;
      } else if (response.statusCode == 500) {
        await _showError('Errore Server',
            'Errore durante il processo di rimborso Stripe o WooCommerce.');
        return null;
      } else {
        print('⚠️ Response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante il rimborso: $error');
      await _showError('Errore di connessione',
          'Impossibile eseguire il rimborso. Controlla la connessione e riprova.');
      return null;
    }
  }
}
