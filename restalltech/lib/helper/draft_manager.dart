import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftManager {
  static const String _draftPrefix = 'draft_';
  static const String _closePrefix = 'close_ticket_';
  static const String _suspendPrefix = 'suspend_ticket_';

  // Salva una bozza di chiusura ticket
  static Future<void> saveCloseDraft(
      int ticketId, Map<String, dynamic> draftData) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_closePrefix$ticketId';
    draftData['timestamp'] = DateTime.now().toIso8601String();
    draftData['ticketId'] = ticketId;
    draftData['type'] = 'close';
    await prefs.setString(key, jsonEncode(draftData));
  }

  // Salva una bozza di sospensione ticket
  static Future<void> saveSuspendDraft(
      int ticketId, Map<String, dynamic> draftData) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_suspendPrefix$ticketId';
    draftData['timestamp'] = DateTime.now().toIso8601String();
    draftData['ticketId'] = ticketId;
    draftData['type'] = 'suspend';
    await prefs.setString(key, jsonEncode(draftData));
  }

  // Recupera una bozza di chiusura ticket
  static Future<Map<String, dynamic>?> getCloseDraft(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_closePrefix$ticketId';
    final draftString = prefs.getString(key);
    if (draftString != null) {
      return jsonDecode(draftString);
    }
    return null;
  }

  // Recupera una bozza di sospensione ticket
  static Future<Map<String, dynamic>?> getSuspendDraft(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_suspendPrefix$ticketId';
    final draftString = prefs.getString(key);
    if (draftString != null) {
      return jsonDecode(draftString);
    }
    return null;
  }

  // Elimina una bozza di chiusura
  static Future<void> deleteCloseDraft(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_closePrefix$ticketId';
    await prefs.remove(key);
  }

  // Elimina una bozza di sospensione
  static Future<void> deleteSuspendDraft(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$_suspendPrefix$ticketId';
    await prefs.remove(key);
  }

  // Ottieni tutte le bozze
  static Future<List<Map<String, dynamic>>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final drafts = <Map<String, dynamic>>[];

    for (final key in keys) {
      if (key.startsWith(_draftPrefix)) {
        final draftString = prefs.getString(key);
        if (draftString != null) {
          try {
            final draft = jsonDecode(draftString);
            drafts.add(draft);
          } catch (e) {
            print('Error decoding draft: $e');
          }
        }
      }
    }

    // Ordina per timestamp (più recenti prima)
    drafts.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp']);
      final bTime = DateTime.parse(b['timestamp']);
      return bTime.compareTo(aTime);
    });

    return drafts;
  }

  // Conta le bozze totali
  static Future<int> getDraftsCount() async {
    final drafts = await getAllDrafts();
    return drafts.length;
  }

  // Elimina tutte le bozze (utile per pulizia)
  static Future<void> deleteAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_draftPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Controlla se esiste una bozza per un ticket
  static Future<bool> hasDraft(int ticketId) async {
    final closeDraft = await getCloseDraft(ticketId);
    final suspendDraft = await getSuspendDraft(ticketId);
    return closeDraft != null || suspendDraft != null;
  }

  // Ottieni la bozza (sia chiusura che sospensione)
  static Future<Map<String, dynamic>?> getDraft(int ticketId) async {
    final closeDraft = await getCloseDraft(ticketId);
    if (closeDraft != null) return closeDraft;
    return await getSuspendDraft(ticketId);
  }

  // Elimina qualsiasi bozza per un ticket
  static Future<void> deleteDraft(int ticketId) async {
    await deleteCloseDraft(ticketId);
    await deleteSuspendDraft(ticketId);
  }
}
