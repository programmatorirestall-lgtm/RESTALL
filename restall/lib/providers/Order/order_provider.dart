import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:restall/API/Order/order_api.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/models/Order.dart';
import 'package:restall/models/ReturnRequest.dart';
import 'package:restall/helper/user_id_helper.dart';
import 'package:restall/models/RefundItem.dart';
import 'package:restall/models/stripe_refund.dart';
import 'package:restall/API/api_exceptions.dart';

enum OrderStatusFilter {
  all,
  processing,
  completed,
  cancelled,
  onHold,
  pending,
  returnsPending,
  refunded,
  failed
}

class OrderProvider with ChangeNotifier {
  final OrderApi _orderApi = OrderApi();
  final UserApi _userApi = UserApi();

  List<Order> _orders = [];
  List<ReturnRequest> _returns = []; // richieste di reso/rimborso
  List<Order> _filteredOrders = [];
  List<RefundItem> _refunds = [];
  bool _isLoading = true; // Inizia a true per mostrare loading all'avvio
  String? _error;
  OrderStatusFilter _activeFilter = OrderStatusFilter.all;

  // Getters
  List<Order> get orders => _filteredOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatusFilter get activeFilter => _activeFilter;
  int get orderCount => _filteredOrders.length;
  bool get hasOrders => _orders.isNotEmpty;

  // Constructor
  OrderProvider() {
    _initializeData();
  }

  /// Inizializza i dati caricando ordini e resi
  Future<void> _initializeData() async {
    await fetchOrders();
    await fetchReturns();
  }

  /// Carica gli ordini dal server
  Future<void> fetchOrders() async {
    _error = null;

    // Mostra loading solo se non ci sono già ordini caricati
    if (_orders.isEmpty) {
      _setLoading(true);
    }

    try {
      print('📋 Caricamento ordini...');
      final response = await _orderApi.getOrders();

      if (response != null && response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _orders = responseData.map((data) => Order.fromJson(data)).toList();

        // Ordina per data decrescente (più recenti prima)
        _orders.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        _applyFilter();
        _buildRefundsList();
        print('✅ ${_orders.length} ordini caricati con successo');
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      print('❌ Errore caricamento ordini: $e');
      _error = 'Errore di connessione. Verifica la tua connessione internet.';
    } finally {
      _setLoading(false);
    }
  }

  /// Recupera le richieste di reso/rimborso per l'utente corrente
  Future<void> fetchReturns({String? status, bool showLoading = false}) async {
    // Mostra loading solo se richiesto esplicitamente (es. pull-to-refresh)
    if (showLoading && _returns.isEmpty) {
      _setLoading(true);
    }

    try {
      print('📋 Caricamento refund requests (status: $status)...');
      final userId = await UserIdHelper.getCurrentUserId();
      if (userId == null) {
        _error = 'Utente non autenticato';
        if (showLoading) _setLoading(false);
        notifyListeners();
        return;
      }

      final response =
          await _orderApi.getRefundRequestsByUserId(userId, status: status);

      if (response != null && response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _returns = responseData
            .map((data) => ReturnRequest.fromJson(data as Map<String, dynamic>))
            .toList();

        // Ordina per data decrescente (usa createdAt)
        _returns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ ${_returns.length} refund requests caricati con successo');
        print('📋 Lista returns: ${_returns.map((r) => 'ID: ${r.id}, Status: ${r.status}').join(', ')}');
      } else if (response != null && response.statusCode == 404) {
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map &&
              errorBody['error'] ==
                  'Nessuna richiesta trovata per questo utente') {
            _returns = [];
            print('ℹ️ Nessuna refund request trovata per questo utente.');
          }
        } catch (e) {
          // Se non è il messaggio atteso, gestisci come errore normale
          _handleApiError(response);
          _returns = [];
        }
      } else {
        _handleApiError(response);
        _returns = [];
      }
    } catch (e) {
      print('❌ Errore caricamento refund requests: $e');
      _error = 'Errore di connessione. Verifica la tua connessione internet.';
      _returns = [];
    } finally {
      if (showLoading) _setLoading(false);
      notifyListeners();
      _buildRefundsList();
    }
  }

  void _buildRefundsList() {
    try {
      final List<RefundItem> items = [];

      // Ordini con status refunded
      final refundedOrders = _orders
          .where((o) => o.status.toLowerCase() == 'refunded')
          .map((o) => RefundItem.fromOrder(o));

      items.addAll(refundedOrders);

      // Return requests
      final returnItems = _returns.map((r) => RefundItem.fromRequest(r));
      items.addAll(returnItems);

      // Ordina per data decrescente (date string comparata)
      items.sort((a, b) => b.dateString.compareTo(a.dateString));

      _refunds = items;
    } catch (e) {
      print('❌ Errore costruzione lista rimborsi: $e');
    }
  }

  /// Wrapper per caricare i resi senza modificare lo stato di caricamento globale
  Future<void> fetchReturnsByStatus(String status) async {
    await fetchReturns(status: status);
  }

  /// Refresh con delay visivo
  Future<void> refreshOrders() async {
    await Future.delayed(Duration(milliseconds: 300)); // Delay UX
    await fetchOrders();
  }

  /// Applica filtro per status
  void applyFilter(OrderStatusFilter filter) {
    if (_activeFilter == filter) return;

    _activeFilter = filter;
    _applyFilter();
    notifyListeners();

    print('🔍 Filtro applicato: ${filter.toString().split('.').last}');
  }

  /// Aggiorna status di un ordine (per resi)
  Future<bool> updateOrderStatus(String orderId, String newStatus,
      {String? reason}) async {
    try {
      print('✏️ Aggiornamento ordine $orderId -> $newStatus');

      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      // Aggiungi metadata per il motivo se fornito
      if (reason != null && reason.isNotEmpty) {
        updateData['meta_data'] = [
          {
            'key': 'return_reason',
            'value': reason,
          }
        ];
      }

      final response = await _orderApi.updateOrder(orderId, updateData);

      if (response != null && response.statusCode == 200) {
        final updatedOrderData = jsonDecode(response.body);
        final updatedOrder = Order.fromJson(updatedOrderData);

        // Aggiorna nella lista locale
        final index = _orders.indexWhere((o) => o.id.toString() == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
          _applyFilter();
          notifyListeners();
        }

        _showSuccessAlert('Ordine aggiornato',
            'Lo stato dell\'ordine è stato aggiornato con successo.');
        print('✅ Ordine $orderId aggiornato con successo');
        return true;
      } else {
        _handleApiError(response);
        return false;
      }
    } catch (e) {
      print('❌ Errore aggiornamento ordine: $e');
      _showErrorAlert('Errore aggiornamento',
          'Impossibile aggiornare l\'ordine. Riprova più tardi.');
      return false;
    }
  }

  /// Trova ordine per ID
  Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Recupera lista dei resi caricati
  List<ReturnRequest> get returns => List.unmodifiable(_returns);

  bool get hasReturns => _returns.isNotEmpty;

  /// Lista unificata di rimborsi (ordini refunded + return requests)
  List<RefundItem> get refunds => List.unmodifiable(_refunds);

  /// Verifica se un ordine ha una richiesta di reso attiva
  bool hasReturnRequest(int orderId) {
    return _returns.any((request) =>
      int.tryParse(request.orderId) == orderId
    );
  }

  /// Recupera la richiesta di reso per un ordine specifico
  ReturnRequest? getReturnRequestByOrderId(int orderId) {
    try {
      return _returns.firstWhere((request) =>
        int.tryParse(request.orderId) == orderId
      );
    } catch (e) {
      return null;
    }
  }

  /// Effettua il rimborso di un prodotto marketplace tramite Stripe Connect
  /// Gestito completamente da Stripe (reverse transfer automatico)
  ///
  /// [productId] - ID del prodotto da rimborsare
  /// Returns StripeRefund se il rimborso ha successo, null altrimenti
  Future<StripeRefund?> refundMarketplaceProduct(String productId) async {
    try {
      print('💳 Richiesta rimborso Stripe per prodotto #$productId...');

      final response = await _userApi.refundMarketplaceProduct(productId);

      if (response.success && response.refund.isSuccessful) {
        print('✅ Rimborso completato: ${response.refund.formattedAmount}');

        // Aggiorna gli ordini per riflettere il rimborso
        await fetchOrders();

        _showSuccessAlert(
          'Rimborso Completato',
          'Il rimborso di ${response.refund.formattedAmount} è stato processato con successo.\n\nStripe gestirà automaticamente il reverse transfer al venditore.',
        );

        return response.refund;
      } else if (response.refund.isPending) {
        print('⏳ Rimborso in elaborazione...');

        _showSuccessAlert(
          'Rimborso in Elaborazione',
          'Il rimborso di ${response.refund.formattedAmount} è in corso di elaborazione.\n\nRiceverai una notifica quando sarà completato.',
        );

        return response.refund;
      } else {
        print('❌ Rimborso fallito: ${response.refund.status}');

        _showErrorAlert(
          'Rimborso Fallito',
          response.error ?? 'Il rimborso non è stato completato. Riprova più tardi.',
        );

        return null;
      }
    } on NotFoundException catch (e) {
      print('❌ Pagamento non trovato: $e');
      _showErrorAlert(
        'Pagamento Non Trovato',
        'Non è stato trovato alcun pagamento per questo prodotto.\n\nPotrebbe essere già stato rimborsato.',
      );
      return null;
    } on UnauthorizedException catch (e) {
      print('❌ Non autorizzato: $e');
      _showErrorAlert(
        'Accesso Negato',
        'Non hai i permessi per effettuare questo rimborso.',
      );
      return null;
    } on BadRequestException catch (e) {
      print('❌ Richiesta non valida: $e');
      _showErrorAlert(
        'Richiesta Non Valida',
        e.message,
      );
      return null;
    } on ServerException catch (e) {
      print('❌ Errore server: $e');
      _showErrorAlert(
        'Errore Server',
        'Si è verificato un errore sul server.\n\nRiprova più tardi.',
      );
      return null;
    } catch (e) {
      print('❌ Errore imprevisto durante il rimborso: $e');
      _showErrorAlert(
        'Errore Rimborso',
        'Si è verificato un errore durante il processo di rimborso.\n\nRiprova più tardi o contatta il supporto.',
      );
      return null;
    }
  }

  // Private methods
  void _applyFilter() {
    // Per il filtro "resi" mostriamo la lista _returns separata
    if (_activeFilter == OrderStatusFilter.all) {
      _filteredOrders = List.from(_orders);
    } else if (_activeFilter == OrderStatusFilter.refunded) {
      // Mostra gli ordini con status 'refunded'
      _filteredOrders = _orders
          .where((order) => order.status.toLowerCase() == 'refunded')
          .toList();
    } else {
      final statusString = _getStatusFromFilter(_activeFilter);
      _filteredOrders = _orders
          .where((order) =>
              order.status.toLowerCase() == statusString.toLowerCase())
          .toList();
    }
  }

  String _getStatusFromFilter(OrderStatusFilter filter) {
    switch (filter) {
      case OrderStatusFilter.processing:
        return 'processing';
      case OrderStatusFilter.completed:
        return 'completed';
      case OrderStatusFilter.cancelled:
        return 'cancelled';
      case OrderStatusFilter.onHold:
        return 'on-hold';
      case OrderStatusFilter.pending:
        return 'pending';
      case OrderStatusFilter.returnsPending:
        return 'pending'; // usato per il mapping logico, i resi vengono presi da _returns
      case OrderStatusFilter.refunded:
        return 'refunded';
      case OrderStatusFilter.failed:
        return 'failed';
      default:
        return 'all';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleApiError(http.Response? response) {
    if (response == null) {
      _error = 'Errore di connessione al server';
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        _error = errorBody['message'] ?? 'Errore sconosciuto dal server';
      } catch (e) {
        _error = 'Errore del server (${response.statusCode})';
      }
    }

    _showErrorAlert(
        'Errore caricamento ordini', _error ?? 'Errore sconosciuto');
  }

  void _showErrorAlert(String title, String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  void _showSuccessAlert(String title, String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.information,
    );
  }
}
