// lib/API/Shop/product.dart - AGGIORNAMENTO con nuovi endpoint aste
import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductApi {
  final String _url = "$apiHost/api/v1/shop/prodotto";
  final String _auctionUrl = "$apiHost/api/v1/shop/auctions";
  final String _userProductUrl = "$apiHost/api/v1/shop/user/prodotto";

  // === PRODOTTI (METODI ESISTENTI) ===

  /// 🆕 POST /user/prodotto - Crea un nuovo prodotto in bozza con immagini
  Future<http.Response?> createProduct({
    required String title,
    required String description,
    required String price,
    required String category,
    List<File>? images,
  }) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per creazione prodotto');
        _showAlert('Autenticazione richiesta per creare un prodotto');
        return null;
      }

      print('🆕 Creazione nuovo prodotto: $title');

      // Crea la richiesta multipart
      var request = http.MultipartRequest('POST', Uri.parse(_userProductUrl));

      // Aggiungi gli headers
      request.headers.addAll({
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie',
      });

      // Aggiungi i campi testuali
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price;
      request.fields['category'] = category;

      // Aggiungi le immagini se presenti
      if (images != null && images.isNotEmpty) {
        for (var image in images) {
          final file = await http.MultipartFile.fromPath(
            'images', // Nome del campo come specificato nell'API
            image.path,
          );
          request.files.add(file);
        }
        print('📸 Aggiunte ${images.length} immagini');
      }

      // Invia la richiesta
      print('📤 Invio richiesta creazione prodotto...');
      final streamedResponse = await request.send();

      // Converti la risposta
      final response = await http.Response.fromStream(streamedResponse);

      print('🟢 Response createProduct - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Prodotto creato con successo');
        return response;
      } else {
        print('❌ Errore creazione prodotto: ${response.statusCode}');
        String errorMessage = 'Errore nella creazione del prodotto';

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // Usa il messaggio di default se non c'è un JSON valido
        }

        _showAlert(errorMessage);
        return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante creazione prodotto: $error');
      _showAlert('Errore di connessione durante la creazione del prodotto');
      return null;
    }
  }

  getProducts({int page = 1, int limit = 20}) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    // Aggiungi i parametri di paginazione all'URL
    final paginatedUrl = Uri.parse("$_url?page=$page&limit=$limit");

    final response = await http.get(
      paginatedUrl,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print("PRODOTTI: ${response.body}");
    print("code: ${response.statusCode}");
    if (response.statusCode == 200) {
      return response;
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  getProductDetails(id) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse("$_url/$id"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      return response;
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore con i dettagli',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  // === ASTE - NUOVI ENDPOINT IMPLEMENTATI ===

  /// 🔍 GET /auctions/:id - Recupera i dettagli di una singola asta
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
        Uri.parse('$_auctionUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Response getAuctionById - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Dettagli asta recuperati con successo');
        return response;
      } else {
        print(
            '❌ Errore recupero asta: ${response.statusCode} - ${response.body}');
        _showAlert('Errore nel recupero dettagli asta');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante recupero asta: $error');
      _showAlert('Errore di connessione durante recupero asta');
      return null;
    }
  }

  /// 📋 GET /auctions - Recupera tutte le aste attive (pubblicate e in corso)
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

      // Aggiungi parametri di paginazione e filtro status
      final paginatedUrl =
          Uri.parse('$_auctionUrl?page=$page&limit=$limit&status=publish');

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
        _showAlert('Errore nel recupero aste attive');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante recupero aste: $error');
      _showAlert('Errore di connessione durante recupero aste');
      return null;
    }
  }

  /// 🎯 PUT /auctions/:id - Piazza un'offerta su un'asta
  Future<http.Response?> placeBid(
      String auctionId, String userId, double amount) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per offerta');
        return null;
      }

      print(
          '🎯 Piazzamento offerta - Asta: $auctionId, Utente: $userId, Importo: €$amount');

      final response = await http.put(
        Uri.parse('$_auctionUrl/$auctionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
        }),
      );

      print('🟢 Response placeBid - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Offerta piazzata con successo');
        return response;
      } else {
        print('❌ Errore piazzamento offerta: ${response.statusCode}');
        // Non mostrare alert automatico, lascia gestire al chiamante
        return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante piazzamento offerta: $error');
      _showAlert('Errore di connessione durante piazzamento offerta');
      return null;
    }
  }

  /// 💳 POST /auctions/:id/buy - Acquista un'asta (solo vincitore, con pagamento Stripe)
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
        Uri.parse('$_auctionUrl/$auctionId/buy'),
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
        // Non mostrare alert automatico, lascia gestire al chiamante
        return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante acquisto asta: $error');
      _showAlert('Errore di connessione durante acquisto asta');
      return null;
    }
  }

  /// 🆕 POST /auctions - Crea una nuova asta
  createAuction(Map<String, dynamic> auctionData) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    final response = await http.post(
      Uri.parse(_auctionUrl),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
      body: jsonEncode(auctionData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Errore nella creazione asta',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  /// 📦 GET /user/prodotto - Recupera i prodotti dell'utente (draft, published, sold)
  Future<http.Response?> getUserProducts() async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per recupero prodotti utente');
        _showAlert('Autenticazione richiesta');
        return null;
      }

      print('📦 Recupero prodotti utente...');

      final response = await http.get(
        Uri.parse(_userProductUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Response getUserProducts - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Prodotti utente recuperati con successo');
        return response;
      } else {
        print('❌ Errore recupero prodotti: ${response.statusCode}');
        _showAlert('Errore nel recupero dei prodotti');
        return null;
      }
    } catch (error) {
      print('🔥 Eccezione durante recupero prodotti utente: $error');
      _showAlert('Errore di connessione durante il recupero dei prodotti');
      return null;
    }
  }

  /// ✏️ PUT /user/prodotto/{productId} - Modifica un prodotto esistente
  /// Modifica i dati di un prodotto senza alterare immagini e stato
  /// ⚠️ NON sono ammessi: images, status
  Future<http.Response?> updateProduct({
    required int productId,
    String? name,
    String? regularPrice,
    String? price,
    String? description,
    String? shortDescription,
    int? stockQuantity,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? metaData,
  }) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per modifica prodotto');
        _showAlert('Autenticazione richiesta per modificare il prodotto');
        return null;
      }

      print('✏️ Modifica prodotto ID: $productId');

      // Costruisci il body con solo i campi forniti
      final Map<String, dynamic> body = {};

      if (name != null) body['name'] = name;
      if (regularPrice != null) body['regular_price'] = regularPrice;
      if (price != null) body['price'] = price;
      if (description != null) body['description'] = description;
      if (shortDescription != null) body['short_description'] = shortDescription;
      if (stockQuantity != null) body['stock_quantity'] = stockQuantity;
      if (categories != null) body['categories'] = categories;
      if (metaData != null) body['meta_data'] = metaData;

      print('📝 Campi da aggiornare: ${body.keys.join(', ')}');

      final response = await http.put(
        Uri.parse('$_userProductUrl/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
        body: jsonEncode(body),
      );

      print('🟢 Response updateProduct - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Prodotto aggiornato con successo');
        return response;
      } else if (response.statusCode == 403) {
        print('❌ Non autorizzato a modificare questo prodotto');
        _showAlert('Non sei autorizzato a modificare questo prodotto');
        return response;
      } else if (response.statusCode == 404) {
        print('❌ Prodotto non trovato');
        _showAlert('Prodotto non trovato');
        return response;
      } else {
        print('❌ Errore modifica prodotto: ${response.statusCode}');
        String errorMessage = 'Errore nella modifica del prodotto';

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // Usa il messaggio di default se non c'è un JSON valido
        }

        _showAlert(errorMessage);
        return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante modifica prodotto: $error');
      _showAlert('Errore di connessione durante la modifica del prodotto');
      return null;
    }
  }

  /// 🗑️ DELETE /user/prodotto/{productId} - Elimina un prodotto
  /// Di default viene spostato nel cestino (trash)
  /// Usa force=true per eliminazione definitiva
  Future<http.Response?> deleteProduct({
    required int productId,
    bool force = false,
  }) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      if (_jwt == null) {
        print('❌ JWT token non disponibile per cancellazione prodotto');
        _showAlert('Autenticazione richiesta per eliminare il prodotto');
        return null;
      }

      print('🗑️ Cancellazione prodotto ID: $productId (force: $force)');

      // Costruisci l'URL con query params se necessario
      final uri = force
          ? Uri.parse('$_userProductUrl/$productId?force=true')
          : Uri.parse('$_userProductUrl/$productId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );

      print('🟢 Response deleteProduct - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['deleted']?['status'] ?? 'unknown';

        if (force || status == 'trash') {
          print('✅ Prodotto eliminato con successo (status: $status)');
        } else {
          print('⚠️ Prodotto in stato: $status');
        }

        return response;
      } else if (response.statusCode == 403) {
        print('❌ Non autorizzato a eliminare questo prodotto');
        _showAlert('Non sei autorizzato a eliminare questo prodotto');
        return response;
      } else if (response.statusCode == 404) {
        print('❌ Prodotto non trovato');
        _showAlert('Prodotto non trovato');
        return response;
      } else {
        print('❌ Errore cancellazione prodotto: ${response.statusCode}');
        String errorMessage = 'Errore nella cancellazione del prodotto';

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // Usa il messaggio di default se non c'è un JSON valido
        }

        _showAlert(errorMessage);
        return response;
      }
    } catch (error) {
      print('🔥 Eccezione durante cancellazione prodotto: $error');
      _showAlert('Errore di connessione durante la cancellazione del prodotto');
      return null;
    }
  }

  // === METODI DEPRECATI (MANTENUTI PER COMPATIBILITÀ) ===

  @deprecated
  buyAuctionLegacy(String id, String userId) async {
    print('⚠️ Metodo buyAuction deprecato, usa buyAuction con supporto Stripe');
    return await buyAuction(id, userId);
  }

  @deprecated
  getAuctionByIdLegacy(String id) async {
    print('⚠️ Metodo getAuctionById deprecato, usa la versione async');
    return await getAuctionById(id);
  }

  @deprecated
  getActiveAuctionsLegacy() async {
    print(
        '⚠️ Metodo getActiveAuctions deprecato, usa la versione con paginazione');
    return await getActiveAuctions();
  }

  // === METODI HELPER PRIVATI ===

  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookie');
  }

  Future<String?> _getJwt() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtTemp = prefs.getString('jwt');

    if (jwtTemp != null) {
      Cookie jwt = Cookie.fromSetCookieValue(jwtTemp);
      return jwt.value;
    }
    return null;
  }

  void _showAlert(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore',
      text: '$message\nSe continua a verificarsi contatta lo sviluppatore.',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }
}
