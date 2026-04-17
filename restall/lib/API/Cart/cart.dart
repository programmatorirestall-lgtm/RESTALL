import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/API/Renew%20Session/renew_session.dart';

import 'package:restall/config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CartApi {
  final String _url = "$apiHost/api/v1/shop/cart/";

  // CartApi() {
  //   RenewSessionApi().renew();
  // }

  addCart(data) async {
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

    print("STATUS CART: " + response.statusCode.toString());
    print("Header Cart: ${response.headers}");
    return response;
  }

  getCart() async {
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
    print("Status code Cart: ${response.statusCode}");

    if (response.statusCode == 200) {
      print("Body Cart: ${response.body}");
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

  createOrderWithPayment(String paymentMethod) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.post(
      Uri.parse("$_url/order/$paymentMethod"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    return response;
  }

  // createOrderOnly() async {
  //   var _jwt = await _getJwt();
  //   var _cookie = await _getCookie();
  //   final response = await http.post(
  //     Uri.parse("$_url/order/create-only"),
  //     headers: {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $_jwt',
  //       'Cookie': '$_cookie'
  //     },
  //   );

  //   return response;
  // }

  createOrderOnly() async {
    final url = Uri.parse("${_url}order/intent");
    print('🔵 Sending POST request to: $url');

    var _jwt = await _getJwt();
    var _cookie = await _getCookie();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_jwt',
          'Cookie': '$_cookie'
        },
        body: json.encode({
          'payment_method_configuration': 'pmc_1QaiRQRo9l9N3ttB0dD9npVa',
        }),
      );

      print('🟢 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final body = json.decode(response.body);

      if (body['error'] != null) {
        print('❌ Error from server: ${body['error']}');
        throw Exception(body['error']);
      }

      print('✅ Order intent created successfully: $body');
      return response;
    } catch (e) {
      print('🔥 Exception caught in createOrderOnly: $e');
      rethrow;
    }
  }
}
