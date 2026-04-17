import 'dart:math' show min;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserIdHelper {
  static String? _cachedUserId;

  /// Recupera l'ID utente dal JWT in modo sicuro e lo cache
  static Future<String?> getCurrentUserId() async {
    // Se già in cache, restituisci subito
    if (_cachedUserId != null) {
      return _cachedUserId;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Prima prova a recuperare da cache locale
      final cachedId = prefs.getString('user_id');
      if (cachedId != null && cachedId.isNotEmpty) {
        _cachedUserId = cachedId;
        return _cachedUserId;
      }

      // Se non in cache, estrai dal JWT
      final jwtToken = prefs.getString('jwt');

      if (jwtToken == null || jwtToken.isEmpty) {
        print('⚠️ JWT token non trovato');
        return null;
      }

      // Pulisci il token dal formato cookie
      String cleanToken = _cleanJwtToken(jwtToken);

      // Verifica formato JWT valido
      if (!_isValidJwtFormat(cleanToken)) {
        print('❌ JWT formato non valido');
        return null;
      }

      // Decodifica JWT
      final decodedToken = Jwt.parseJwt(cleanToken);
      final userId = decodedToken['id'];

      if (userId != null) {
        final userIdString = userId.toString();

        // Cache in memoria e in SharedPreferences
        _cachedUserId = userIdString;
        await prefs.setString('user_id', userIdString);

        print('✅ ID utente estratto e salvato: $userIdString');
        return userIdString;
      } else {
        print('❌ ID utente non trovato nel JWT payload');
        return null;
      }
    } catch (error) {
      print('❌ Errore recupero ID utente: $error');
      return null;
    }
  }

  /// Pulisce il token JWT dal formato cookie
  static String _cleanJwtToken(String jwtToken) {
    String cleanToken = jwtToken;

    if (jwtToken.startsWith('jwt=')) {
      // Formato: "jwt=TOKEN_VALUE Expires=..."
      final startIndex = 4; // "jwt=".length
      final spaceIndex = jwtToken.indexOf(' ', startIndex);
      final semicolonIndex = jwtToken.indexOf(';', startIndex);

      int endIndex = jwtToken.length;
      if (spaceIndex != -1) endIndex = min(endIndex, spaceIndex);
      if (semicolonIndex != -1) endIndex = min(endIndex, semicolonIndex);

      cleanToken = jwtToken.substring(startIndex, endIndex);
    } else {
      // Rimuovi caratteri problematici
      cleanToken = jwtToken.split(' ')[0].replaceAll(';', '').trim();
    }

    return cleanToken;
  }

  /// Verifica se il token ha formato JWT valido (xxx.yyy.zzz)
  static bool _isValidJwtFormat(String token) {
    return token.contains('.') && token.split('.').length == 3;
  }

  /// Invalida la cache (da chiamare al logout)
  static void clearCache() {
    _cachedUserId = null;
  }

  /// Verifica se l'utente è autenticato
  static Future<bool> isUserAuthenticated() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// Recupera informazioni complete dell'utente dal JWT
  static Future<Map<String, dynamic>?> getUserInfoFromJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt');

      if (jwtToken == null || jwtToken.isEmpty) {
        return null;
      }

      final cleanToken = _cleanJwtToken(jwtToken);

      if (!_isValidJwtFormat(cleanToken)) {
        return null;
      }

      final decodedToken = Jwt.parseJwt(cleanToken);
      return decodedToken;
    } catch (error) {
      print('❌ Errore recupero info utente: $error');
      return null;
    }
  }
}
