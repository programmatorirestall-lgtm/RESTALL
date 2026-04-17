import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Logout/logout.dart';
import 'package:restall/config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class WareHouseApi {
  final String _url = apiHost + "/warehouse/";

  getMachine(code) async {
    //print("Code" + code.toString());
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse(_url + "macchina/" + code.toString()),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    //print(response.statusCode);
    if (response.statusCode == 200) {
      //print(response.body);
      return response;
    } else {
      LogoutApi().logout();
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
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
    //print(_cookie);
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
