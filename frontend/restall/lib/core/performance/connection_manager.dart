import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Gestisce lo stato della connettività di rete e fornisce logiche di retry.
///
/// Utilizza il pattern `ChangeNotifier` per permettere ai widget di reagire
/// ai cambiamenti dello stato della connessione.
class ConnectionManager with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isOnline = true;

  /// Restituisce `true` se il dispositivo ha una connessione di rete attiva.
  bool get isOnline => _isOnline;

  ConnectionManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Ottieni lo stato iniziale
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    // Sottoscrivi ai cambiamenti
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consideriamo online se c'è almeno un risultato diverso da `none`.
    final newStatus = results.any((result) => result != ConnectivityResult.none);

    if (newStatus != _isOnline) {
      _isOnline = newStatus;
      // print('CONNECTION STATUS: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    }
  }

  /// Esegue una funzione asincrona con una logica di retry.
  ///
  /// Tenta di eseguire l'operazione [operation] per un massimo di [retries] volte.
  /// Utilizza un backoff esponenziale per i ritardi tra i tentativi.
  /// Non fallisce immediatamente se il dispositivo appare offline, ma tenta comunque
  /// l'operazione (utile su web dove connectivity_plus può essere inaffidabile).
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int retries = 3,
  }) async {
    // Rimosso il check isOnline per evitare falsi negativi, specialmente su web
    // Lasciamo che sia il catch dell'errore effettivo a gestire problemi di rete

    int attempt = 0;
    while (attempt < retries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          // print('EXECUTE WITH RETRY: Max retries reached. Throwing error.');
          rethrow;
        }
        final delay = Duration(seconds: 2 * attempt); // Backoff esponenziale
        // print('EXECUTE WITH RETRY: Attempt $attempt failed. Retrying in $delay...');
        await Future.delayed(delay);
      }
    }
    // Questo punto non dovrebbe essere mai raggiunto, ma per sicurezza...
    throw const NetworkException('Operazione fallita dopo multipli tentativi.');
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

/// Eccezione personalizzata per errori di rete.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}
