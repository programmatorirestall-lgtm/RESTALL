import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:restalltech/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupApi {
  final String _url = apiHost + "/signup";
  late final Cookie _cookie;

  Future<int> postDataFirst(data) async {
    //print(data);
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
    print("STATUS: " + response.statusCode.toString());
    if (response.statusCode == 201) {
      await _saveJWT(response);
    }
    return response.statusCode;
  }

  Future<int> patchDataSecond(data) async {
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );
    _cookie = _getCookie(response);
    print(response.body);
    print("STATUS: " + response.statusCode.toString());
    if (response.statusCode == 201) {
      await _saveJWT(response);
      await _saveCookie(_cookie);
    }
    return response.statusCode;
  }

  Future<http.Response> addTech(data) async {
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: _setHeaders(),
    );

    print(response.body);
    print("STATUS: " + response.statusCode.toString());

    return response;
  }

  Cookie _getCookie(http.Response response) {
    print(response.headers);
    final header = response.headers['set-cookie'];
    print(header);
    if (header != null) {
      final List<String> cookiesparts = header.split(';');
      //print(cookiesparts);
      final sessionIdCookie = cookiesparts
          .firstWhere((cookie) => cookie.startsWith('RestAllSession='));
      if (sessionIdCookie.isNotEmpty) {
        return Cookie.fromSetCookieValue(header);
      }
    }
    return Cookie('', '');
  }

  Future<void> _saveCookie(Cookie cookie) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', cookie.toString());
    print("SCADENZA");
    print(cookie.expires);
  }

  Future<void> _saveJWT(http.Response response) async {
    final _prefs = await SharedPreferences.getInstance();

    final _data = jsonDecode(response.body);
    final _jwt = _data['jwt'];
    _prefs.setString('jwt', _jwt);
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };
}
