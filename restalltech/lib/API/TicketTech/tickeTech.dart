import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/config.dart';
import 'package:restalltech/models/TicketList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTApi {
  final String _url = apiHost + "/api/v1/ticket/tecnico";

  Future<http.Response> getData(int techId) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse('$_url/$techId'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print("TicketTech GET - STATUS: ${response.statusCode}");
    print("TicketTech GET - Body: ${response.body}");
    return response;
  }

  Future<int> postData(data) async {
    //print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    print("Data" + data.toString());
    final response = await http.post(
      Uri.parse(_url),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("STATUS: " + response.statusCode.toString());
    print("Body: " + response.body);
    return response.statusCode;
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_getJwt().toString()}',
        'Cookie': _getCookie().toString()
      };

  _getCookie() async {
    final _prefs = await SharedPreferences.getInstance();
    var _cookie = _prefs.getString('cookie');
    print(_cookie);
    return _cookie;
  }

  _getJwt() async {
    String _jwtTemp;
    Cookie _jwt;
    final _prefs = await SharedPreferences.getInstance();

    if (_prefs.getString('jwt') != null) {
      _jwtTemp = _prefs.getString('jwt') as String;
    } else {
      return null;
    }

    _jwt = Cookie.fromSetCookieValue(_jwtTemp);

    //if(_jwt.expires!.isAfter(DateTime.now())){
    return _jwt.value;
    //}
    print(_jwt);
  }
}
