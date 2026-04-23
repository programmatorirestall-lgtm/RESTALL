// lib/providers/Ticket/ticket_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/models/TicketList.dart';

class TicketProvider with ChangeNotifier {
  List<Ticket> _allTickets = [];
  List<Ticket> _openTickets = [];
  List<Ticket> _closedTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Ticket> get allTickets => _allTickets;
  List<Ticket> get openTickets => _openTickets;
  List<Ticket> get closedTickets => _closedTickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stato di caricamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Errore
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Carica tutti i ticket e li filtra
  Future<void> loadAllTickets() async {
    _setLoading(true);
    _setError(null);

    try {
      // Carica tutti i ticket
      final allResponse = await TicketApi().getData();
      if (allResponse.statusCode == 200) {
        final allBody = json.decode(allResponse.body);
        if (allBody != null && allBody['tickets'] != null) {
          _allTickets = List.from(allBody['tickets'])
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();

          // Filtra ticket aperti
          _openTickets =
              _allTickets.where((ticket) => ticket.stateT == 'Aperto').toList();
        }
      }

      // Carica ticket chiusi separatamente
      final closedResponse = await TicketApi().getClosed();
      if (closedResponse.statusCode == 200) {
        final closedBody = json.decode(closedResponse.body);
        if (closedBody != null && closedBody['tickets'] != null) {
          _closedTickets = List.from(closedBody['tickets'])
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
        }
      }

      print(
          '✅ Tickets caricati: ${_allTickets.length} totali, ${_openTickets.length} aperti, ${_closedTickets.length} chiusi');
    } catch (e) {
      print('❌ Errore caricamento ticket: $e');
      _setError('Errore durante il caricamento dei ticket');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh specifico per ticket aperti
  Future<void> refreshOpenTickets() async {
    try {
      final response = await TicketApi().getData();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          _allTickets = List.from(body['tickets'])
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
          _openTickets =
              _allTickets.where((ticket) => ticket.stateT == 'Aperto').toList();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Errore refresh ticket aperti: $e');
      _setError('Errore durante l\'aggiornamento');
    }
  }

  // Refresh specifico per tutti i ticket
  Future<void> refreshAllTickets() async {
    try {
      final response = await TicketApi().getData();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          _allTickets = List.from(body['tickets'])
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Errore refresh tutti i ticket: $e');
      _setError('Errore durante l\'aggiornamento');
    }
  }

  // Refresh specifico per ticket chiusi
  Future<void> refreshClosedTickets() async {
    try {
      final response = await TicketApi().getClosed();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          _closedTickets = List.from(body['tickets'])
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Errore refresh ticket chiusi: $e');
      _setError('Errore durante l\'aggiornamento');
    }
  }

  // Metodo chiamato dopo la creazione di un nuovo ticket
  Future<void> onTicketCreated() async {
    print('🎫 Nuovo ticket creato, aggiornamento liste...');
    await loadAllTickets();
  }

  // Pulisce gli errori
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
