import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/LoginRequest/login.dart';
import 'package:restall/API/Renew%20Session/renew_session.dart';
import 'package:restall/config.dart';
import 'package:restall/models/TicketList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreventiviApi {
  final String _url = apiHost + "/api/v1/preventivi/";

  PreventiviApi() {
    if (LoginApi().sessionState() == true) {
      RenewSessionApi().renew();
      //print("ren");
    }
  }
  getAll() async {
    ////print(data);
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
    //print("PREVENTIVI ${response.statusCode}: ${response.body}");
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

  uploadPreventivo({isFinal = false, required file, required id}) async {
    //print("ID: $id");
    try {
      var _jwt = await _getJwt();
      var _cookie = await _getCookie();

      var headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      };
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${_url}allegato"),
      );
      request.headers.addAll(headers);

      request.files.add(
          await http.MultipartFile.fromPath('allegatoPreventivo', file.path));
      request.fields['idPreventivo'] = id.toString();
      request.fields['isFinal'] = isFinal.toString();

      // Invia la richiesta
      var response = await request.send();

      // Gestisci la risposta
      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        //print('Upload riuscito! URL: ${responseData['url']}');
        return response;
      } else {
        //print('Errore durante l\'upload: ${response.statusCode}');
        //print('Errore durante l\'upload: ${response.reasonPhrase}');
        //print( 'Errore durante l\'upload: ${await response.stream.bytesToString()}');
        return response;
      }
    } catch (e) {
      //print('Errore: $e');
    }
  }

  Future<int> changeStatusPreventivo(int id) async {
    ////print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.patch(
      Uri.parse(_url + id.toString()),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    //print(response.body);
    return response.statusCode;
  }

  getDetails(int id) async {
    ////print(data);
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
    //print("DEttagli preventivo${response.statusCode}: ${response.body}");
    if (response.statusCode == 200) {
      return response;
    } else {
      // LogoutApi().logout();
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  postData(data) async {
    ////print(data);
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

    // //print("STATUS: " + response.statusCode.toString());
    //print("Header Ticket: ${response.headers}");

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
