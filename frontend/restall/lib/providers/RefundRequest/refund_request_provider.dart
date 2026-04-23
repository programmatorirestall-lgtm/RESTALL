import 'package:flutter/foundation.dart';
import 'package:restall/API/Refund/refund_request_api.dart';
import 'package:restall/models/refund_request.dart';

class RefundRequestProvider with ChangeNotifier {
  final RefundRequestApi _api = RefundRequestApi();

  // State variables
  List<RefundRequest> _refundRequests = [];
  RefundRequest? _selectedRefundRequest;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<RefundRequest> get refundRequests => List.unmodifiable(_refundRequests);
  RefundRequest? get selectedRefundRequest => _selectedRefundRequest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed getters
  int get refundRequestCount => _refundRequests.length;
  bool get hasRefundRequests => _refundRequests.isNotEmpty;

  // Filtri per stato
  List<RefundRequest> get pendingRequests =>
      _refundRequests.where((req) => req.status == 'pending').toList();

  List<RefundRequest> get approvedRequests =>
      _refundRequests.where((req) => req.status == 'approved').toList();

  List<RefundRequest> get declinedRequests =>
      _refundRequests.where((req) => req.status == 'declined').toList();

  List<RefundRequest> get refundedRequests =>
      _refundRequests.where((req) => req.status == 'refunded').toList();

  // Private setters
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 📥 Carica tutte le richieste di reso
  Future<void> loadRefundRequests() async {
    _setLoading(true);
    _setError(null);

    try {
      final requests = await _api.getRefundRequests();
      if (requests != null) {
        _refundRequests = requests;
        notifyListeners();
      } else {
        _setError('Impossibile caricare le richieste di reso');
      }
    } catch (e) {
      _setError('Errore durante il caricamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 🔍 Carica una singola richiesta per dettaglio
  Future<void> loadRefundRequest(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = await _api.getRefundRequest(id);
      if (request != null) {
        _selectedRefundRequest = request;

        // Aggiorna anche nella lista se presente
        final index = _refundRequests.indexWhere((req) => req.id == id);
        if (index != -1) {
          _refundRequests[index] = request;
        }

        notifyListeners();
      } else {
        _setError('Richiesta non trovata');
      }
    } catch (e) {
      _setError('Errore durante il caricamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// ➕ Crea una nuova richiesta di reso
  Future<bool> createRefundRequest(CreateRefundRequestDto dto) async {
    _setLoading(true);
    _setError(null);

    try {
      final newRequest = await _api.createRefundRequest(dto);
      if (newRequest != null) {
        _refundRequests.insert(0, newRequest); // Aggiungi in testa
        notifyListeners();
        return true;
      } else {
        _setError('Impossibile creare la richiesta');
        return false;
      }
    } catch (e) {
      _setError('Errore durante la creazione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ Approva una richiesta (ADMIN)
  Future<bool> approveRefundRequest(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedRequest = await _api.approveRefundRequest(id);
      if (updatedRequest != null) {
        _updateRequestInList(updatedRequest);
        return true;
      } else {
        _setError('Impossibile approvare la richiesta');
        return false;
      }
    } catch (e) {
      _setError('Errore durante l\'approvazione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ❌ Rifiuta una richiesta (ADMIN)
  Future<bool> declineRefundRequest(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedRequest = await _api.declineRefundRequest(id);
      if (updatedRequest != null) {
        _updateRequestInList(updatedRequest);
        return true;
      } else {
        _setError('Impossibile rifiutare la richiesta');
        return false;
      }
    } catch (e) {
      _setError('Errore durante il rifiuto: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 💳 Esegue il rimborso (ADMIN)
  Future<RefundResult?> executeRefund(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _api.executeRefund(id);
      if (result != null) {
        _updateRequestInList(result.refundRequest);
        return result;
      } else {
        _setError('Impossibile eseguire il rimborso');
        return null;
      }
    } catch (e) {
      _setError('Errore durante il rimborso: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper per aggiornare una richiesta nella lista
  void _updateRequestInList(RefundRequest updatedRequest) {
    final index = _refundRequests.indexWhere((req) => req.id == updatedRequest.id);
    if (index != -1) {
      _refundRequests[index] = updatedRequest;

      // Aggiorna anche la selected se corrisponde
      if (_selectedRefundRequest?.id == updatedRequest.id) {
        _selectedRefundRequest = updatedRequest;
      }

      notifyListeners();
    }
  }

  /// Cancella la richiesta selezionata
  void clearSelectedRequest() {
    _selectedRefundRequest = null;
    notifyListeners();
  }

  /// Resetta tutti gli errori
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Resetta completamente lo stato
  void reset() {
    _refundRequests = [];
    _selectedRefundRequest = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
