// Sostituisci la classe LogoutApi in lib/API/Logout/logout.dart

import 'package:http/http.dart' as http;
import 'package:restall/config.dart';
import 'package:restall/helper/user_id_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutApi {
  final String _url = apiHost + "/logout";

  Future<void> logout() async {
    try {
      // 🌐 Chiamata al server per invalidare la sessione
      final response = await http.post(Uri.parse(_url));
      print("📤 Logout response: ${response.statusCode}");
    } catch (e) {
      print("❌ Errore chiamata logout server: $e");
      // Continua comunque con la pulizia locale
    }

    // 🧹 PULIZIA LOCALE COMPLETA
    try {
      final prefs = await SharedPreferences.getInstance();

      // Rimuovi specificamente i token di autenticazione
      await prefs.remove('cookie');
      await prefs.remove('jwt');
      await prefs.remove('RT');

      // Pulizia completa delle preferenze (opzionale, ma sicura)
      await prefs.clear();

      // Pulisci la cache dell'helper utente
      UserIdHelper.clearCache();

      print("✅ Logout locale completato");
    } catch (e) {
      print("❌ Errore durante pulizia logout: $e");
    }
  }
}
