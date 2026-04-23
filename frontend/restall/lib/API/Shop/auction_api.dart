// lib/API/Shop/auction_api.dart
import 'dart:convert';
import 'dart:developer' as developer show log;
import 'dart:io';
import 'dart:math';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Renew%20Session/renew_session.dart';
import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuctionApi {
  final String _baseUrl = "$apiHost/api/v1/shop/auctions";

  /// 🔍 GET /:id - Recupera i dettagli di una singola asta
  Future<http.Response?> getAuctionById(String id) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per recupero asta');
        return null;
      }

      print('🔍 Recupero dettagli asta ID: $id');

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Response getAuctionById - Status: ${response.statusCode}');
      developer.log('🟢 Response getAuctionById - Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Dettagli asta recuperati con successo');
        return response;
      } else {
        print(
            '❌ Errore recupero asta: ${response.statusCode} - ${response.body}');
        _showAlert('Errore nel recupero dettagli asta',
            'Se continua a verificarsi contatta lo sviluppatore.');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante recupero asta: $error');
      _showAlert('Errore di connessione',
          'Impossibile recuperare i dettagli dell\'asta. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// 📋 GET / - Recupera tutte le aste attive (pubblicate e in corso)
  Future<http.Response?> getActiveAuctions(
      {int page = 1, int limit = 20}) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per recupero aste');
        return null;
      }

      print('📋 Recupero aste attive - Pagina: $page, Limite: $limit');

      // Aggiungi parametri di paginazione
      final paginatedUrl =
          Uri.parse('$_baseUrl?page=$page&limit=$limit&status=publish');

      final response = await http.get(
        paginatedUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Response getActiveAuctions - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auctionsCount =
            data is List ? data.length : (data['auctions']?.length ?? 0);
        print('✅ $auctionsCount aste attive recuperate');
        return response;
      } else {
        print(
            '❌ Errore recupero aste: ${response.statusCode} - ${response.body}');
        _showAlert('Errore nel recupero aste attive',
            'Se continua a verificarsi contatta lo sviluppatore.');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante recupero aste: $error');
      _showAlert('Errore di connessione',
          'Impossibile recuperare le aste. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// 🎯 PUT /:id - Piazza un'offerta su un'asta
  Future<http.Response?> placeBid(
      String auctionId, String userId, double amount) async {
    try {
      print(
          '🎯 Piazzamento offerta - Asta: $auctionId, Utente: $userId, Importo: €$amount');

      // Verifica preliminare dei parametri
      if (auctionId.isEmpty || userId.isEmpty || amount <= 0) {
        _showAlert('Errore', 'Parametri non validi per l\'offerta');
        return null;
      }

      // Recupera token e cookie con gestione errori migliorata
      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null || jwt.isEmpty) {
        print('❌ JWT token non disponibile per offerta');
        _showAlert('Autenticazione richiesta',
            'Effettua il login per piazzare un\'offerta');
        return null;
      }

      print('🔑 Token JWT valido trovato');

      final response = await http.put(
        Uri.parse('$_baseUrl/$auctionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': cookie ?? '',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
        }),
      );

      print('🟢 Response placeBid - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      // Gestisci diverse tipologie di errore
      switch (response.statusCode) {
        case 200:
          print('✅ Offerta piazzata con successo');
          return response;

        case 401:
          print('❌ Errore autenticazione (401)');
          await _handleAuthenticationError();
          return null;

        case 403:
          print('❌ Accesso negato (403)');
          _showAlert('Accesso negato',
              'Non hai i permessi per piazzare questa offerta');
          return null;

        case 400:
          print('❌ Richiesta non valida (400)');
          try {
            final responseData = jsonDecode(response.body);
            final message = responseData['message'] ??
                'Offerta non valida. Verifica l\'importo.';
            _showAlert('Errore nell\'offerta', message);
          } catch (e) {
            _showAlert('Errore nell\'offerta', 'Verifica l\'importo e riprova');
          }
          return response;

        case 409:
          print('❌ Conflitto (409) - Probabilmente offerta superata');
          _showAlert('Offerta superata',
              'Un\'altra offerta è stata piazzata nel frattempo. Ricarica l\'asta.');
          return response;

        case 500:
        case 502:
        case 503:
          print('❌ Errore server (${response.statusCode})');
          _showAlert('Errore del server',
              'Problema temporaneo del server. Riprova tra qualche momento.');
          return null;

        default:
          print('❌ Errore imprevisto: ${response.statusCode}');
          try {
            final responseData = jsonDecode(response.body);
            final message = responseData['message'] ??
                'Errore durante il piazzamento dell\'offerta';
            _showAlert('Errore', message);
          } catch (e) {
            _showAlert(
                'Errore', 'Si è verificato un errore imprevisto. Riprova.');
          }
          return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante piazzamento offerta: $error');

      // Gestisci diversi tipi di eccezione
      if (error.toString().contains('SocketException')) {
        _showAlert('Errore di connessione',
            'Verifica la connessione internet e riprova.');
      } else if (error.toString().contains('TimeoutException')) {
        _showAlert(
            'Timeout', 'La richiesta sta impiegando troppo tempo. Riprova.');
      } else {
        _showAlert('Errore imprevisto',
            'Si è verificato un errore. Controlla la connessione e riprova.');
      }

      return null;
    }
  }

  // 🔍 Debug helper per controllare lo stato dell'autenticazione
  Future<void> debugAuthStatus() async {
    print('🔍 === DEBUG AUTENTICAZIONE ===');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica JWT
      final jwtRaw = prefs.getString('jwt');
      print(
          '📱 JWT raw in SharedPreferences: ${jwtRaw?.substring(0, min(50, jwtRaw.length ?? 0))}...');

      if (jwtRaw != null) {
        try {
          final jwtCleaned = jwtRaw.replaceAll(';', '').trim();
          print(
              '🧹 JWT pulito: ${jwtCleaned.substring(0, min(50, jwtCleaned.length))}...');

          if (jwtCleaned.contains('.')) {
            // Prova a decodificare il JWT
            final decoded = Jwt.parseJwt(jwtCleaned);
            print('🔓 JWT decodificato:');
            print('   - ID utente: ${decoded['id']}');
            print('   - Email: ${decoded['email']}');
            print(
                '   - Scadenza: ${DateTime.fromMillisecondsSinceEpoch((decoded['exp'] ?? 0) * 1000)}');
            print('   - Ora attuale: ${DateTime.now()}');

            final expiry = DateTime.fromMillisecondsSinceEpoch(
                (decoded['exp'] ?? 0) * 1000);
            final isExpired = expiry.isBefore(DateTime.now());
            print('   - Token scaduto: $isExpired');
          } else {
            // Prova come cookie
            final cookie = Cookie.fromSetCookieValue(jwtCleaned);
            print('🍪 Cookie JWT:');
            print('   - Nome: ${cookie.name}');
            print(
                '   - Valore: ${cookie.value.substring(0, min(30, cookie.value.length))}...');
            print('   - Scadenza: ${cookie.expires}');
            print(
                '   - Cookie scaduto: ${cookie.expires?.isBefore(DateTime.now()) ?? false}');
          }
        } catch (e) {
          print('❌ Errore decodifica JWT: $e');
        }
      } else {
        print('❌ Nessun JWT trovato');
      }

      // Verifica Cookie
      final cookieRaw = prefs.getString('cookie');
      print(
          '🍪 Cookie session: ${cookieRaw?.substring(0, min(50, cookieRaw?.length ?? 0))}...');

      // Verifica Refresh Token
      final rtRaw = prefs.getString('RT');
      print(
          '🔄 Refresh Token: ${rtRaw?.substring(0, min(30, rtRaw?.length ?? 0))}...');

      // Test chiamata API
      print('🌐 Test chiamata API...');
      final jwt = await _getJwt();
      final cookie = await _getCookie();

      print(
          '   - JWT estratto: ${jwt?.substring(0, min(30, jwt?.length ?? 0))}...');
      print(
          '   - Cookie estratto: ${cookie?.substring(0, min(30, cookie?.length ?? 0))}...');
    } catch (e) {
      print('❌ Errore nel debug: $e');
    }

    print('🔍 === FINE DEBUG ===');
  }

  /// 🧪 Test rapido di autenticazione prima di piazzare un'offerta
  Future<bool> testAuthentication() async {
    try {
      print('🧪 Test autenticazione...');

      final jwt = await _getJwt();
      final cookie = await _getCookie();

      if (jwt == null) {
        print('❌ Test fallito: JWT nullo');
        return false;
      }

      print('✅ Test riuscito: credenziali disponibili');
      return true;
    } catch (e) {
      print('❌ Test fallito con eccezione: $e');
      return false;
    }
  }

  /// 💳 POST /:id/buy - Acquista un'asta (solo vincitore, con pagamento Stripe)
  Future<http.Response?> buyAuction(String auctionId, String userId,
      {String? paymentMethodId}) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per acquisto asta');
        return null;
      }

      print('💳 Acquisto asta - ID: $auctionId, Utente: $userId');
      if (paymentMethodId != null) {
        print('💰 Payment Method ID: $paymentMethodId');
      }

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };

      if (paymentMethodId != null) {
        requestBody['paymentMethodId'] = paymentMethodId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$auctionId/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
        body: jsonEncode(requestBody),
      );

      print('🟢 Response buyAuction - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentStatus = data['paymentIntent']?['status'] ?? 'unknown';

        if (paymentStatus == 'succeeded') {
          print('✅ Acquisto asta completato con successo');
        } else {
          print('⚠️ Pagamento in stato: $paymentStatus');
        }

        return response;
      } else {
        print('❌ Errore acquisto asta: ${response.statusCode}');

        // Gestisci errori specifici di pagamento
        try {
          final responseData = jsonDecode(response.body);
          final message =
              responseData['message'] ?? 'Errore durante l\'acquisto';
          print('💬 Messaggio errore: $message');

          return response; // Restituisci la response per gestire errore nel UI
        } catch (e) {
          _showAlert('Errore durante l\'acquisto asta',
              'Se continua a verificarsi contatta lo sviluppatore.');
          return null;
        }
      }
    } catch (error) {
      print('🔥 Eccezione durante acquisto asta: $error');
      _showAlert('Errore di connessione',
          'Impossibile completare l\'acquisto. Controlla la connessione e riprova.');
      return null;
    }
  }

  /// Crea una nuova asta (metodo già presente in ProductApi)
  Future<http.Response?> createAuction(Map<String, dynamic> auctionData) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per creazione asta');
        return null;
      }

      print('🆕 Creazione nuova asta');
      print('📦 Dati asta: ${jsonEncode(auctionData)}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
        body: jsonEncode(auctionData),
      );

      print('🟢 Response createAuction - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Asta creata con successo');
        return response;
      } else {
        print(
            '❌ Errore creazione asta: ${response.statusCode} - ${response.body}');
        _showAlert('Errore nella creazione asta',
            'Se continua a verificarsi contatta lo sviluppatore.');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante creazione asta: $error');
      _showAlert('Errore di connessione',
          'Impossibile creare l\'asta. Controlla la connessione e riprova.');
      return null;
    }
  }

  // --- METODI HELPER PRIVATI ---
  Future<String?> _getJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jwtTemp = prefs.getString('jwt');

      if (jwtTemp == null || jwtTemp.isEmpty) {
        print('⚠️ JWT token non trovato in SharedPreferences');
        return null;
      }

      // CORREZIONE: Il JWT è salvato come "jwt=VALORE_TOKEN; Expires=..."
      // Estraiamo solo il valore del token JWT
      String jwtValue;

      if (jwtTemp.startsWith('jwt=')) {
        // Caso: "jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eX... Expires=..."
        // Estrai tutto tra "jwt=" e il primo spazio o ";"
        final startIndex = 4; // lunghezza di "jwt="
        final endIndex = jwtTemp.indexOf(' ', startIndex);
        final endIndexSemicolon = jwtTemp.indexOf(';', startIndex);

        int actualEndIndex = jwtTemp.length;
        if (endIndex != -1) actualEndIndex = min(actualEndIndex, endIndex);
        if (endIndexSemicolon != -1)
          actualEndIndex = min(actualEndIndex, endIndexSemicolon);

        jwtValue = jwtTemp.substring(startIndex, actualEndIndex);
      } else {
        // Rimuovi caratteri problematici e prova parsing diretto
        jwtValue = jwtTemp.replaceAll(';', '').trim();

        // Se contiene ancora spazi, prendi solo la parte prima del primo spazio
        if (jwtValue.contains(' ')) {
          jwtValue = jwtValue.split(' ')[0];
        }
      }

      print(
          '🔑 JWT estratto: ${jwtValue.substring(0, min(30, jwtValue.length))}...');

      // Verifica che il JWT abbia il formato corretto (xxx.yyy.zzz)
      if (!jwtValue.contains('.') || jwtValue.split('.').length != 3) {
        print(
            '❌ JWT formato non valido: ${jwtValue.substring(0, min(50, jwtValue.length))}');
        return null;
      }

      // Verifica scadenza opzionale (se vuoi essere super sicuro)
      try {
        final decoded = Jwt.parseJwt(jwtValue);
        final exp = decoded['exp'];
        if (exp != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (expiry.isBefore(DateTime.now())) {
            print('⚠️ JWT token scaduto');
            return null;
          }
        }
      } catch (e) {
        print('⚠️ Impossibile verificare scadenza JWT: $e');
        // Continua comunque, potrebbe funzionare
      }

      return jwtValue;
    } catch (error) {
      print('❌ Errore durante il recupero del JWT: $error');
      return null;
    }
  }

// Aggiorna anche _getCookie() per coerenza
  Future<String?> _getCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cookie = prefs.getString('cookie');

      if (cookie != null) {
        // Rimuovi eventuali caratteri problematici dal cookie
        cookie = cookie.trim();
        if (cookie.endsWith(';')) {
          cookie = cookie.substring(0, cookie.length - 1);
        }
      }

      return cookie;
    } catch (error) {
      print('❌ Errore durante il recupero del cookie: $error');
      return null;
    }
  }

  /// Gestisce gli errori di autenticazione in modo centralizzato
  Future<void> _handleAuthenticationError() async {
    _showAlert('Sessione scaduta',
        'La tua sessione è scaduta. Effettua nuovamente il login.');

    // Pulisci i dati di autenticazione
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    await prefs.remove('cookie');

    // Reindirizza al login (se hai accesso al context)
    // Navigator.pushReplacementNamed(context, '/login');
  }

  /// Tenta di rinnovare la sessione usando il refresh token
  Future<bool> _renewSession() async {
    try {
      final renewApi = RenewSessionApi();
      final response = await renewApi.renew();

      if (response != null && response.statusCode == 200) {
        print('✅ Sessione rinnovata con successo');
        return true;
      }

      print('❌ Impossibile rinnovare la sessione');
      return false;
    } catch (error) {
      print('❌ Errore durante il rinnovo sessione: $error');
      return false;
    }
  }

  void _showAlert(String title, String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }
}
