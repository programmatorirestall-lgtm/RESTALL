import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;

import 'package:restalltech/config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CompanyApi {
  final String _url = apiHost + "/warehouse/azienda/";

  getValue(valore) async {
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();
      final response = await http.get(
        Uri.parse("${_url}search?ragSoc=$valore"),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        // print("COMPANY: ${response.body}");
        return response;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return response;
      }
    } catch (e) {
      print('Error fetching company data: $e');
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Errore di connessione. Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
      return null;
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
