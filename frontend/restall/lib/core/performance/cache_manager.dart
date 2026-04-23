import 'dart:async';

/// Una classe entry per la cache che contiene i dati e la scadenza.
class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry({required this.data, required this.expiryTime});

  /// Controlla se l'entry della cache è scaduta.
  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

/// Un gestore di cache in memoria, semplice e generico, con supporto per TTL (Time-To-Live).
/// Utilizza il pattern Singleton per garantire una singola istanza in tutta l'app.
class CacheManager {
  // Singleton instance
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal() {
    // Avvia un timer periodico per pulire le voci scadute.
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _clearExpired();
    });
  }

  final Map<String, _CacheEntry> _cache = {};

  /// Inserisce o aggiorna un valore nella cache.
  ///
  /// [key] L'identificatore univoco per la voce di cache.
  /// [data] I dati da memorizzare.
  /// [ttl] La durata per cui la voce di cache è considerata valida.
  ///       Se non specificato (null), la voce non scadrà mai.
  void set(String key, dynamic data, {Duration? ttl}) {
    final expiryTime = ttl != null
        ? DateTime.now().add(ttl)
        : DateTime.now().add(const Duration(days: 365)); // "Non scade mai"
    _cache[key] = _CacheEntry(data: data, expiryTime: expiryTime);
    // print('CACHE SET: $key');
  }

  /// Recupera un valore dalla cache.
  ///
  /// Restituisce i dati se la chiave esiste e la voce non è scaduta.
  /// Altrimenti, rimuove la voce (se esiste e scaduta) e restituisce null.
  /// Il tipo [T] è il tipo atteso dei dati.
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      // print('CACHE MISS: $key');
      return null;
    }

    if (entry.isExpired) {
      // print('CACHE EXPIRED: $key');
      _cache.remove(key);
      return null;
    }

    // print('CACHE HIT: $key');
    return entry.data as T?;
  }

  /// Rimuove forzatamente una voce dalla cache.
  void invalidate(String key) {
    _cache.remove(key);
    // print('CACHE INVALIDATED: $key');
  }

  /// Svuota completamente la cache.
  void clear() {
    _cache.clear();
    // print('CACHE CLEARED');
  }

  /// Rimuove tutte le voci scadute dalla cache.
  void _clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
    // print('CACHE: Expired entries cleared.');
  }

  /// Fornisce statistiche di base sulla cache per il debug.
  Map<String, dynamic> get stats {
    return {
      'currentSize': _cache.length,
      'keys': _cache.keys.toList(),
    };
  }
}
