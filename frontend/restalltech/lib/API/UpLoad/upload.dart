import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:restalltech/config.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UploadApi {
  updateSign(file) async {
    final String _url = apiHost + "/api/v1/ticket/signature";
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    var headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_jwt',
      'Cookie': '$_cookie'
    };
    print("JWT UPLOAD: $_jwt");
    print("COOKiE UPLOAD: $_cookie");

    var request = http.MultipartRequest('POST', Uri.parse(_url))
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath(
        'firma',
        file.path,
      ));

    print(file.path);

// Invio della richiesta e attesa della risposta

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    Map<String, dynamic> jsonMap = json.decode(respStr);
    print("STATUS: " + response.statusCode.toString());
    if (response.statusCode == 200) {
      print('Immagine caricata con successo!');
      print(jsonMap['file']['location']);
    } else {
      print('Errore durante il caricamento dell\'immagine');
    }
    return jsonMap['file']['location'];
  }

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
