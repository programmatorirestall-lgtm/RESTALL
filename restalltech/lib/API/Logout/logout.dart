import 'package:http/http.dart' as http;
import 'package:restalltech/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutApi {
  final String _url = apiHost + "/logout";

  logout() async {
    final response = await http.post(Uri.parse(_url));
    final prefs = await SharedPreferences.getInstance();
    bool ris = await prefs.clear();
    return ris;
  }
}
