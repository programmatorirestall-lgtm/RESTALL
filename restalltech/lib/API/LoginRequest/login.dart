import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:restalltech/API/Logout/logout.dart';
import 'package:restalltech/API/UserData/userData.dart';
import 'package:restalltech/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweet_cookie_jar/sweet_cookie_jar.dart';

class LoginApi {
  final String _url = apiHost + "/login";
  late final Cookie _cookie;
  late final Cookie _jwt;
  late final Cookie _refreshToken;

  Future<int> postData(data) async {
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );

    _cookie = _getCookie(response);
    _jwt = _getJWT(response);
    _refreshToken = _getRT(response);

    print(response.statusCode);

    if (response.statusCode == 200) {
      await _saveCookie(_cookie);
      await _saveJWT(_jwt);
      await _saveRT(_refreshToken);
    }
    // print(response.statusCode);
    // print(response.body);
    print(response.headers.toString());
    return response.statusCode;
  }

  Cookie _getCookie(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'RestAllSession');
      print(sessionIdCookie);
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Future<void> _saveCookie(Cookie cookie) async {
    print(cookie);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', "$cookie;");
  }

  Cookie _getJWT(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'jwt');
      print(sessionIdCookie);
      if (sessionIdCookie.isNotEmpty) {
        return sessionIdCookie;
      }
    }
    return Cookie('', '');
  }

  Future<void> _saveJWT(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('jwt', "$cookie;");
  }

  Cookie _getRT(http.Response response) {
    final header = response.headers[HttpHeaders.setCookieHeader];

    if (header != null) {
      final cookieJar = SweetCookieJar.from(response: response);

      final sessionIdCookie = cookieJar.find(name: 'refreshToken');
      print(sessionIdCookie);
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

  sessionState() async {
    try {
      Cookie _cookieTemp;
      String cookie;
      SharedPreferences _prefs = await SharedPreferences.getInstance();

      if (_prefs.getString('cookie') != null) {
        cookie = _prefs.getString('cookie') as String;
      } else {
        return null;
      }

      _cookieTemp = Cookie.fromSetCookieValue(cookie);
      print(_cookieTemp.expires);
      return (_cookieTemp.expires?.isAfter(DateTime.now()));
    } catch (e) {
      LogoutApi().logout();
    }
  }
}
