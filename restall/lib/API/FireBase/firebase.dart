// Sostituisci la classe FireBaseApi in lib/API/FireBase/firebase.dart

import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweet_cookie_jar/sweet_cookie_jar.dart';

class FireBaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final String _url = apiHost + "/token";

  /// 🔧 INIZIALIZZAZIONE NOTIFICHE CON GESTIONE EMULATORI
  Future<void> initNotifications() async {
    try {
      print("🔥 Inizializzazione Firebase Messaging...");

      // 📱 CONTROLLO AMBIENTE: Emulatore vs Dispositivo fisico
      bool isEmulator = await _isRunningOnEmulator();

      if (isEmulator) {
        print("📲 Rilevato emulatore - inizializzazione semplificata");
        await _initForEmulator();
      } else {
        print("📱 Rilevato dispositivo fisico - inizializzazione completa");
        await _initForPhysicalDevice();
      }
    } catch (e) {
      print("❌ Errore inizializzazione Firebase: $e");
      // ⚠️ NON BLOCCARE il login per errori Firebase
      await _handleFirebaseError(e);
    }
  }

  /// 🖥️ INIZIALIZZAZIONE PER EMULATORI
  Future<void> _initForEmulator() async {
    try {
      // Solo richiesta permessi base per emulatori
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print("🔔 Permessi notifiche emulatore: ${settings.authorizationStatus}");

      // Per gli emulatori, salva un token fittizio
      final prefs = await SharedPreferences.getInstance();
      const mockToken = "EMULATOR_FCM_TOKEN_MOCK";
      await prefs.setString('FCMToken', mockToken);

      print("✅ Firebase configurato per emulatore");
    } catch (e) {
      print("⚠️ Errore configurazione emulatore (ignorato): $e");
    }
  }

  /// 📱 INIZIALIZZAZIONE PER DISPOSITIVI FISICI
  Future<void> _initForPhysicalDevice() async {
    try {
      // Richiesta permessi completa per dispositivi fisici
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      print("🔔 Permessi notifiche: ${settings.authorizationStatus}");

      // ⏰ TIMEOUT per getToken (evita blocchi infiniti)
      final fCMToken = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("⏰ Timeout ottenimento FCM token");
          return null;
        },
      );

      if (fCMToken != null) {
        print("🔑 FCM Token ottenuto: ${fCMToken.substring(0, 20)}...");

        // Salva token nelle preferenze
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('FCMToken', fCMToken);

        // 📤 INVIA TOKEN AL SERVER (con gestione errori)
        try {
          var data = {'FCMToken': fCMToken};
          await setToken(data);
          print("✅ Token inviato al server con successo");
        } catch (e) {
          print("⚠️ Errore invio token al server (continuo comunque): $e");
        }
      } else {
        print("❌ Impossibile ottenere FCM token");
      }
    } catch (e) {
      print("❌ Errore inizializzazione dispositivo fisico: $e");
      rethrow;
    }
  }

  /// 🔍 RILEVA SE SIAMO SU EMULATORE
  Future<bool> _isRunningOnEmulator() async {
    if (kDebugMode) {
      try {
        // Su iOS Simulator, alcune chiamate Firebase falliscono
        if (Platform.isIOS) {
          // Prova a fare una chiamata rapida a Firebase
          final testToken = await _firebaseMessaging.getToken().timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );

          // Se fallisce rapidamente, probabilmente è un emulatore
          return testToken == null;
        }

        // Per Android, puoi usare altri metodi di rilevamento
        if (Platform.isAndroid) {
          // Logica per rilevare emulatori Android se necessaria
          return false; // Per ora assume dispositivo fisico
        }
      } catch (e) {
        // Se c'è un errore, probabilmente è un emulatore
        print("🔍 Rilevato emulatore tramite errore: $e");
        return true;
      }
    }

    return false; // Default: assume dispositivo fisico
  }

  /// ⚠️ GESTIONE ERRORI FIREBASE
  Future<void> _handleFirebaseError(dynamic error) async {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('apns') || errorString.contains('token')) {
      print("🔧 Errore APNS/Token - probabilmente emulatore, continuo...");

      // Salva un token fittizio per evitare crash successivi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('FCMToken',
          "FALLBACK_TOKEN_${DateTime.now().millisecondsSinceEpoch}");
    } else {
      print("🚨 Errore Firebase generico: $error");
    }
  }

  /// 📤 INVIO TOKEN AL SERVER CON GESTIONE ERRORI MIGLIORATA
  Future<http.Response?> setToken(Map<String, dynamic> data) async {
    try {
      var jwt = await _getJwt();
      var cookie = await _getCookie();

      if (jwt == null || cookie == null) {
        print("⚠️ JWT o Cookie mancanti, salto invio token");
        return null;
      }

      final response = await http.post(
        Uri.parse(_url),
        body: jsonEncode(data),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Cookie': '$cookie'
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Timeout invio token"),
      );

      print("📤 Risposta server token: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ Token registrato con successo sul server");
      } else {
        print("⚠️ Errore server registrazione token: ${response.body}");
      }

      return response;
    } catch (e) {
      print("❌ Errore invio token: $e");
      return null;
    }
  }

  /// 🍪 RECUPERA COOKIE DALLE PREFERENZE
  Future<String?> _getCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('cookie');
      return cookie;
    } catch (e) {
      print("❌ Errore recupero cookie: $e");
      return null;
    }
  }

  /// 🔑 RECUPERA JWT DALLE PREFERENZE
  Future<String?> _getJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtTemp = prefs.getString('jwt');

      if (jwtTemp == null || jwtTemp.isEmpty) {
        return null;
      }

      final jwt = Cookie.fromSetCookieValue(jwtTemp);
      return jwt.value;
    } catch (e) {
      print("❌ Errore recupero JWT: $e");
      return null;
    }
  }
}
