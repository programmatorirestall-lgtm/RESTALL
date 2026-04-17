import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/API/Logout/logout.dart';
import 'package:restalltech/config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class WareHouseApi {
  final String _url = apiHost + "/warehouse/";

  setRientri(data) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.post(
      Uri.parse("${_url}rientri"),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("rientri: " + response.body + " " + response.statusCode.toString());

    return response.statusCode;
  }

  getValue(valore) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse("${_url}search?descrizione=$valore"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.statusCode);
    //print("Ricambi: ${response.body}");
    if (response.statusCode == 200) {
      //print(response.body);
      return response;
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore con i ricambi',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  getRientri() async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse("${_url}rientri"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.statusCode);
    if (response.statusCode == 201) {
      print(response.body);
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

  getScarichi() async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse("${_url}scarichi"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.statusCode);
    if (response.statusCode == 201) {
      print(response.body);
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

  scarichi(data) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.post(
      Uri.parse("${_url}scarichi"),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("scarichi: " + response.body + " " + response.statusCode.toString());

    return response.statusCode;
  }

  getArticle(code) async {
    print("Code" + code.toString());
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse(_url + "code/" + code.toString()),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      print(response.body);
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

  deleteWarehouse() async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.delete(
      Uri.parse(_url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      print(response.body);
      return response;
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  updateWareHouse(xls) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    var headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_jwt',
      'Cookie': '$_cookie'
    };
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.headers.addAll(headers);

    final file = File(xls.path);
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();

    final multipartFile = http.MultipartFile(
      'warehouse', // Replace with your field name on the server
      stream,
      length,
      filename: xls.name,
    );

    request.files.add(multipartFile);

    final response = await request.send();
    print(response.statusCode);

    if (response.statusCode == 200) {
      return response;
    } else {
      print("andato");
    }
  }

  getData() async {
    var offset = 0;
    //print(data);
    var url = _url + "?limit=1000&offset=" + offset.toString();

    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    final response = await http.get(
      Uri.parse(url),
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
