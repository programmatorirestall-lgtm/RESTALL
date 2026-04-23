import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final DateTime data;
  final String ragSociale;
  final String email;

  get getData => this.data;
  get getRagSociale => this.ragSociale;
  get getEmail => this.email;

  User({required this.ragSociale, required this.email, required this.data});
}

Future<User> setUserData() async {
  final _prefs = await SharedPreferences.getInstance();
  var _jwt;
  _jwt = Jwt.parseJwt(_prefs.getString('jwt') as String);
  return User(
      ragSociale: _jwt['ragSociale'] as String,
      email: _jwt['email'] as String,
      data: _jwt['data'] as DateTime);
}
