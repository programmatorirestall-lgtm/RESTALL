import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restalltech/config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsApi {
  final String _url = "$apiHost/api/v1/settings/";

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
    print(response.body);
    if (response.statusCode == 200) {
      return response;
    } else {
      //LogoutApi().logout();
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  setData(id, data) async {
    print("ID: $id DATA: $data");
    print("URL: $_url$id");
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.patch(
      Uri.parse("$_url$id"),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("DATA IMP: ${response.body} CODE: ${response.statusCode}");

    return response;
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
  }
}
