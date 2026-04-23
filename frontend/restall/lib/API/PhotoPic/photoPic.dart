import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/config.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PhotoPicApi {
  final String _url = apiHost + "/user/photo";

  uploadPhotoPic(image) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    var headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_jwt',
      'Cookie': '$_cookie'
    };
    var request = http.MultipartRequest('PATCH', Uri.parse(_url));
    request.headers.addAll(headers);

    final file = File(image);
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();

    final multipartFile = http.MultipartFile(
      'propic', // Replace with your field name on the server
      stream,
      length,
      filename: 'propic',
    );

    request.files.add(multipartFile);

    final response = await request.send();
    //print(response.statusCode);
    //print(response.stream);

    if (response.statusCode == 200) {
      return response;
    } else {
      //print("andato");
    }
  }

  getPhotoPic() async {
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
    //print(response.body);
    //print(response.statusCode);
    if (response.statusCode == 200) {
      //print(response.body);
      return response;
    } else {
      // FlutterPlatformAlert.showAlert(
      //   windowTitle: 'Si è verificato un errore nel caricamento della foto',
      //   text: 'Se continua a verificarsi contatta lo sviluppatore.',
      //   alertStyle: AlertButtonStyle.ok,
      //   iconStyle: IconStyle.error,
      // );
    }
  }

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
    //print(_jwt);
  }
}
