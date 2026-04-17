import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:restalltech/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FireBaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final String _url = apiHost + "/token";

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('FCMToken', "$fCMToken");
    var data = {'FCMToken': fCMToken};
    setToken(data);
  }

  setToken(data) async {
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

    // print(response.statusCode);
    // print(response.body);
    print("FCM: " + response.body);
    return response;
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
  }
}
