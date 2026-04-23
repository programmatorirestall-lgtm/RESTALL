import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/config.dart';
import 'package:restalltech/models/TicketList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechApi {
  final String _url = "$apiHost/api/v1/tecnico/";

  Future<int> postData(data) async {
    //print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
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

    // print("STATUS: " + response.statusCode.toString());
    // print("Body: " + response.body);
    return response.statusCode;
  }

  getData() async {
    //print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    // print("STATUS: " + response.statusCode.toString());
    print("Body: " + response.body);
    print(response.body);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  setPaga(data, id) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.patch(
      Uri.parse("${_url}pagamento/$id"),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("PAGA: " + response.body + " " + response.statusCode.toString());

    return response.statusCode;
  }

  getTechbyID(id) async {
    //print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse(_url + id.toString()),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    // print("STATUS: " + response.statusCode.toString());
    print("Body: " + response.body);
    //print(response.body);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  setStatusTech(data, id) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.patch(
      Uri.parse(_url + id.toString()),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("Stato tecnico: " +
        response.body +
        " " +
        response.statusCode.toString());

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
