import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;

import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweet_cookie_jar/sweet_cookie_jar.dart';

class RenewSessionApi {
  final String _url = apiHost + "/user/renew/";
  late final Cookie _cookie;
  late final Cookie _jwt;
  late final Cookie _refreshToken;

  Future<http.Response?> renew() async {
    try {
      var _rt = await _getRT();
      var _cookie = await _getCookie();

      // ⚠️ CONTROLLO: se non ci sono token, non tentare il rinnovo
      if (_rt == null || _cookie == null) {
        print("⚠️ Token mancanti per il rinnovo");
        return null;
      }

      print("🔄 Tentativo rinnovo sessione...");

      final response = await http.get(
        Uri.parse(_url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_rt',
          'Cookie': '$_cookie'
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("⏱️ Timeout rinnovo sessione");
          throw TimeoutException("Rinnovo sessione timeout");
        },
      );

      print("📡 Risposta rinnovo: ${response.statusCode}");

      if (response.statusCode == 200) {
        // ✅ Estrai e salva i nuovi token
        _cookie = _pickCookie(response);
        _jwt = _pickJWT(response);
        _refreshToken = _pickRT(response);

        await _saveCookie(_cookie);
        await _saveJWT(_jwt);
        await _saveRT(_refreshToken);

        print("✅ Sessione rinnovata con successo!");
        return response;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // ❌ Token non validi - non salvare nulla
        print("❌ Refresh token non valido (${response.statusCode})");
        return response;
      } else {
        // ⚠️ Altri errori
        print("⚠️ Errore rinnovo sessione: ${response.statusCode}");
        return response;
      }
    } catch (e) {
      print("❌ Eccezione durante rinnovo: $e");

      // ⚠️ NON mostrare alert in caso di errore
      // L'app gestirà il logout se necessario
      return null;
    }
  }

  Cookie _pickCookie(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'RestAllSession');
      //print(sessionIdCookie);
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Cookie _pickJWT(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'jwt');
      //print(sessionIdCookie);
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Cookie _pickRT(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'refreshToken');
      //print(sessionIdCookie);
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Future<void> _saveCookie(Cookie cookie) async {
    //print(cookie);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', "$cookie;");
  }

  Future<void> _saveJWT(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('jwt', "$cookie;");
  }

  Future<void> _saveRT(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('RT', cookie.toString());
  }

  setCookie(value) {
    Cookie.fromSetCookieValue(value);
  }

  _getCookie() async {
    final _prefs = await SharedPreferences.getInstance();
    var _cookie = _prefs.getString('cookie');
    //print(_cookie);
    return _cookie;
  }

  _getRT() async {
    String _jwtTemp;
    Cookie _jwt;
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getString('RT') != null) {
      _jwtTemp = _prefs.getString('RT') as String;
    } else {
      return null;
    }

    _jwt = Cookie.fromSetCookieValue(_jwtTemp);

    //if(_jwt.expires!.isAfter(DateTime.now())){
    return _jwt.value;
    //}
  }
}
