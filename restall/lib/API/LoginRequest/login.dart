import 'dart:convert';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Logout/logout.dart';

import 'package:restall/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweet_cookie_jar/sweet_cookie_jar.dart';

class LoginApi {
  final String _url = apiHost + "/login";
  late final Cookie _cookie;
  late final Cookie _jwt;
  late final Cookie _refreshToken;
  final dio = Dio();

  postData(data) async {
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );

    //print("response: ${response.headers}");
    //print("body: ${response.body}");

    _cookie = _pickCookie(response);
    _jwt = _pickJWT(response);
    _refreshToken = _pickRT(response);

    if (response.statusCode == 200) {
      await _saveCookie(_cookie);
      await _saveJWT(_jwt);
      await _saveRT(_refreshToken);
    }
    // //print(response.statusCode);
    // //print(response.body);
    ////print(response.body);
    return response;
  }

  postData2(data) async {
    final response = await dio.post(
      _url,
      data: jsonEncode(data),
      options:
          Options(headers: _setHeaders(), extra: {"withCredentials": true}),
    );

    if (kDebugMode) {
      //print("header login: ${response.headers}");
      //print("body login: ${response.data}");
    }

    // //print(response.statusCode);
    // //print(response.body);
    ////print(response.body);
    return response;
  }

  Cookie _pickCookie(http.Response response) {
    ////print("response: ${response.body}");
    final header = response.headers[HttpHeaders.setCookieHeader];
    ////print("header: $header");

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'RestAllSession');
      ////print("sessionIdCookie: $sessionIdCookie");
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Future<void> _saveCookie(Cookie cookie) async {
    print("Cookie: $cookie");
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', "$cookie;");
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

  Future<void> _saveJWT(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('jwt', "$cookie;");
    print("JWT: $cookie");
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

  Future<void> _saveRT(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('RT', cookie.toString());
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

  setCookie(value) {
    Cookie.fromSetCookieValue(value);
  }

  bool _isJwtValid(String? jwtToken) {
    if (jwtToken == null || jwtToken.isEmpty) return false;

    try {
      // Pulisci il token
      String cleanToken = jwtToken.replaceAll(RegExp(r'^jwt=|;$'), '').trim();

      // Verifica formato JWT (3 parti separate da punti)
      if (cleanToken.split('.').length != 3) return false;

      // Decodifica e verifica scadenza
      Map<String, dynamic> decoded = Jwt.parseJwt(cleanToken);

      if (decoded.containsKey('exp')) {
        int exp = decoded['exp'];
        DateTime expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        bool isValid = expDate.isAfter(DateTime.now());
        print(isValid ? "✅ JWT valido" : "❌ JWT scaduto");
        return isValid;
      }

      // Se non ha campo exp, considera valido
      return true;
    } catch (e) {
      print("❌ Errore validazione JWT: $e");
      return false;
    }
  }

  sessionState() async {
    try {
      SharedPreferences _prefs = await SharedPreferences.getInstance();

      // Verifica presenza dei token necessari
      String? cookie = _prefs.getString('cookie');
      String? jwt = _prefs.getString('jwt');

      if (cookie == null || jwt == null) {
        print("⚠️ Token mancanti");
        return false;
      }

      // Validazione del cookie
      try {
        Cookie _cookieTemp = Cookie.fromSetCookieValue(cookie);

        // Verifica scadenza cookie
        if (_cookieTemp.expires != null) {
          bool isValid = _cookieTemp.expires!.isAfter(DateTime.now());
          print(isValid ? "✅ Cookie valido" : "❌ Cookie scaduto");
          return isValid;
        }

        // Se non ha expires, considera il JWT
        return _isJwtValid(jwt);
      } catch (cookieError) {
        print("⚠️ Errore parsing cookie: $cookieError");
        // Fallback su validazione JWT
        return _isJwtValid(jwt);
      }
    } catch (e) {
      print("❌ Errore sessionState: $e");
      // ⚠️ NON fare logout automatico, ritorna false
      return false;
    }
  }
}
