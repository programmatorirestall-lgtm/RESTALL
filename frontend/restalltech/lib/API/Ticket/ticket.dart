import 'dart:convert';
import 'dart:io';

import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/API/Logout/logout.dart';
import 'package:restalltech/config.dart';
import 'package:restalltech/models/TicketList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketApi {
  final String _url = apiHost + "/api/v1/ticket/";

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

  Future<int> closeTicket(data, int id) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.post(
      Uri.parse(_url + id.toString()),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("Chiusura ticket: " +
        response.body +
        " " +
        response.statusCode.toString());

    return response.statusCode;
  }

  previewTicket(data, int id) async {
    print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.post(
      Uri.parse("${_url}preview/$id"),
      body: jsonEncode(data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    print("Preview ticket: " +
        response.body +
        " " +
        response.statusCode.toString());

    return response;
  }

  Future<int> suspendTicket(data, int id) async {
    print(data);
    try {
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

      print("Sospensione ticket: " +
          response.body +
          " " +
          response.statusCode.toString());

      return response.statusCode;
    } catch (e) {
      print("Errore durante la sospensione del ticket: $e");
      return 500; // Return error status code
    }
  }

  Future<int> setTime(data, int id) async {
    // data = {
    //   'oraPrevista': "11:45",
    // };

    print("Test: " + data.toString());
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

    print("Time: " + response.body + " " + response.statusCode.toString());

    return response.statusCode;
  }

  getDetails(int id) async {
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
    print(response.statusCode);
    print("Dettagli TICKET: ${response.body} \nFINE DETT TICKET");
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

  deleteTicket(int id) async {
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.delete(
      Uri.parse(_url + id.toString()),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );

    if (response.statusCode != 200) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
    //print(response.statusCode);
    return response.statusCode;
  }

  Future<int> startTicket(int id) async {
    //print(data);
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
    print(response.body);
    return response.statusCode;
  }

  // Future<int> suspendTicket(int id) async {
  //   //print(data);
  //   var _jwt = await _getJwt();
  //   var _cookie = await _getCookie();
  //   final response = await http.patch(
  //     Uri.parse(_url + id.toString()),
  //     headers: {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $_jwt',
  //       'Cookie': '$_cookie'
  //     },
  //   );
  //   return response.statusCode;
  // }

  getData() async {
    //print(data);
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    print("TICKET IN: " + _cookie.toString());
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

  getClosedT({required int offset, required int limit}) async {
    print("offset: $offset e limit: $limit");
    var _jwt = await _getJwt();
    var _cookie = await _getCookie();
    final response = await http.get(
      Uri.parse('${_url}closed?offset=$offset&limit=$limit'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_jwt',
        'Cookie': '$_cookie'
      },
    );
    print(
        "Ticket chiusi: \nCODE:${response.statusCode} \n\n\nBODY:${response.body}");
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

  // getClosed() async {
  //   var _jwt = await _getJwt();
  //   var _cookie = await _getCookie();
  //   final response = await http.get(
  //     Uri.parse('${_url}closed'),
  //     headers: {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $_jwt',
  //       'Cookie': '$_cookie'
  //     },
  //   );
  //   print(response.body);
  //   if (response.statusCode == 200) {
  //     return response;
  //   } else {
  //     //LogoutApi().logout();
  //     FlutterPlatformAlert.showAlert(
  //       windowTitle: 'Si è verificato un errore',
  //       text: 'Se continua a verificarsi contatta lo sviluppatore.',
  //       alertStyle: AlertButtonStyle.ok,
  //       iconStyle: IconStyle.error,
  //     );
  //   }
  // }

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
