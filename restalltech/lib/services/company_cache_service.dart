import 'dart:convert';
import 'package:restalltech/API/Company/company.dart';

/// Servizio di caching per le anagrafiche aziendali
/// Riduce il numero di chiamate API memorizzando i risultati in memoria
class CompanyCacheService {
  // Singleton pattern
  static final CompanyCacheService _instance = CompanyCacheService._internal();
  factory CompanyCacheService() => _instance;
  CompanyCacheService._internal();

  // Cache storage
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Traccia i prefissi che non hanno dato risultati (per evitare ricerche inutili)
  final Set<String> _emptyResultPrefixes = {};

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 10);
  static const int _maxCacheSize = 50; // Numero massimo di query in cache

  // Lista completa delle aziende (cache iniziale)
  List<Map<String, dynamic>> _allCompanies = [];
  DateTime? _allCompaniesTimestamp;
  bool _isLoadingAll = false;

  /// Ottiene le aziende dalla cache o dal server
  /// [query] - stringa di ricerca (vuota per tutte le aziende)
  /// [forceRefresh] - se true, forza il refresh ignorando la cache
  Future<List<Map<String, dynamic>>> getCompanies(String query, {bool forceRefresh = false}) async {
    final normalizedQuery = query.toLowerCase().trim();

    // Se la query è vuota, carica tutte le aziende
    if (normalizedQuery.isEmpty) {
      return await _getAllCompanies(forceRefresh: forceRefresh);
    }

    // OTTIMIZZAZIONE: Controlla se un prefisso di questa query ha già dato risultati vuoti
    if (!forceRefresh && _hasEmptyPrefixMatch(normalizedQuery)) {
      print('⚡ Skip API call: prefisso "$normalizedQuery" già noto per risultati vuoti');
      return [];
    }

    // Prima cerca in locale nella cache completa
    if (_allCompanies.isNotEmpty && !forceRefresh) {
      final filtered = _filterCompanies(_allCompanies, normalizedQuery);
      if (filtered.isNotEmpty) {
        return filtered;
      }
    }

    // OTTIMIZZAZIONE: Cerca nei risultati di query precedenti più corte (prefissi)
    if (!forceRefresh) {
      final prefixResults = _findInPrefixCache(normalizedQuery);
      if (prefixResults != null) {
        print('⚡ Cache HIT da prefisso per query: "$normalizedQuery"');
        // Filtra localmente i risultati del prefisso
        final filtered = _filterCompanies(prefixResults, normalizedQuery);
        // Salva in cache anche questa query specifica
        _cache[normalizedQuery] = filtered;
        _cacheTimestamps[normalizedQuery] = DateTime.now();
        return filtered;
      }
    }

    // Controlla se esiste in cache e non è scaduta
    if (!forceRefresh && _cache.containsKey(normalizedQuery)) {
      final cacheTime = _cacheTimestamps[normalizedQuery];
      if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheDuration) {
        print('📦 Cache HIT per query: "$normalizedQuery"');
        return _cache[normalizedQuery]!;
      }
    }

    // Cache miss o scaduta - fetch dal server
    print('🌐 Cache MISS per query: "$normalizedQuery" - fetching from server');
    return await _fetchAndCacheCompanies(normalizedQuery);
  }

  /// Controlla se un prefisso della query ha dato risultati vuoti
  bool _hasEmptyPrefixMatch(String query) {
    // Controlla tutti i prefissi dalla lunghezza minima (3) fino alla query corrente
    for (int i = 3; i < query.length; i++) {
      final prefix = query.substring(0, i);
      if (_emptyResultPrefixes.contains(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// Cerca risultati nei prefissi già in cache
  List<Map<String, dynamic>>? _findInPrefixCache(String query) {
    // Cerca dalla query più lunga alla più corta (es: per "abcde" cerca "abcd", "abc", ecc.)
    for (int i = query.length - 1; i >= 3; i--) {
      final prefix = query.substring(0, i);

      if (_cache.containsKey(prefix)) {
        final cacheTime = _cacheTimestamps[prefix];
        if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheDuration) {
          // Trovato un prefisso valido in cache
          return _cache[prefix]!;
        }
      }
    }
    return null;
  }

  /// Carica tutte le aziende (cache iniziale)
  Future<List<Map<String, dynamic>>> _getAllCompanies({bool forceRefresh = false}) async {
    // Se la cache è valida, ritorna quella
    if (!forceRefresh &&
        _allCompanies.isNotEmpty &&
        _allCompaniesTimestamp != null &&
        DateTime.now().difference(_allCompaniesTimestamp!) < _cacheDuration) {
      print('📦 Cache HIT per tutte le aziende');
      return _allCompanies;
    }

    // Evita chiamate multiple simultanee
    if (_isLoadingAll) {
      // Aspetta che finisca il caricamento in corso
      while (_isLoadingAll) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _allCompanies;
    }

    _isLoadingAll = true;

    try {
      print('🌐 Caricamento iniziale di tutte le aziende dal server');
      final companies = await _fetchAndCacheCompanies('');
      _allCompanies = companies;
      _allCompaniesTimestamp = DateTime.now();
      return companies;
    } finally {
      _isLoadingAll = false;
    }
  }

  /// Effettua la chiamata API e salva in cache
  Future<List<Map<String, dynamic>>> _fetchAndCacheCompanies(String query) async {
    try {
      final response = await CompanyApi().getValue(query);

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> companies = data.map((item) => {
          'id': item['id'],
          'clfr': item['clfr'],
          'codCf': item['codCf'],
          'ragSoc': item['ragSoc'],
          'indir': item['indir'],
          'cap': item['cap'],
          'local': item['local'],
          'prov': item['prov'],
          'codFisc': item['codFisc'],
          'partiva': item['partiva'],
          'tel': item['tel'],
          'tel2': item['tel2'],
          'fax': item['fax'],
          'email': item['email'],
          'codsdi': item['codsdi'],
        }).toList().cast<Map<String, dynamic>>();

        // Salva in cache
        _cache[query.toLowerCase().trim()] = companies;
        _cacheTimestamps[query.toLowerCase().trim()] = DateTime.now();

        // Se la query non ha dato risultati, salva il prefisso per evitare ricerche future
        if (companies.isEmpty && query.length >= 3) {
          _emptyResultPrefixes.add(query.toLowerCase().trim());
          print('💾 Salvato prefisso vuoto: "$query"');
        }

        // Gestisci dimensione cache
        _cleanupCache();

        return companies;
      } else {
        print('Errore API: ${response?.statusCode}');
        return [];
      }
    } catch (e) {
      print('Errore nel fetch delle aziende: $e');
      return [];
    }
  }

  /// Filtra le aziende localmente
  List<Map<String, dynamic>> _filterCompanies(List<Map<String, dynamic>> companies, String query) {
    if (query.isEmpty) return companies;

    final lowerQuery = query.toLowerCase();
    return companies.where((company) {
      final ragSoc = (company['ragSoc'] ?? '').toString().toLowerCase();
      final local = (company['local'] ?? '').toString().toLowerCase();
      final codFisc = (company['codFisc'] ?? '').toString().toLowerCase();
      final partiva = (company['partiva'] ?? '').toString().toLowerCase();

      return ragSoc.contains(lowerQuery) ||
             local.contains(lowerQuery) ||
             codFisc.contains(lowerQuery) ||
             partiva.contains(lowerQuery);
    }).toList();
  }

  /// Pulisce la cache se supera la dimensione massima
  void _cleanupCache() {
    if (_cache.length > _maxCacheSize) {
      // Rimuovi le entry più vecchie
      final sortedKeys = _cacheTimestamps.keys.toList()
        ..sort((a, b) => _cacheTimestamps[a]!.compareTo(_cacheTimestamps[b]!));

      final keysToRemove = sortedKeys.take(_cache.length - _maxCacheSize);
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }

      print('🧹 Cache pulita: rimossi ${keysToRemove.length} elementi');
    }
  }

  /// Invalida tutta la cache
  void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _allCompanies.clear();
    _allCompaniesTimestamp = null;
    _emptyResultPrefixes.clear();
    print('🗑️ Cache invalidata completamente');
  }

  /// Invalida la cache per una specifica query
  void invalidateCacheForQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    _cache.remove(normalizedQuery);
    _cacheTimestamps.remove(normalizedQuery);
    print('🗑️ Cache invalidata per query: "$normalizedQuery"');
  }

  /// Preloa la cache con tutte le aziende
  Future<void> preloadCache() async {
    await _getAllCompanies(forceRefresh: true);
  }

  /// Ottiene statistiche sulla cache (per debug)
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_queries': _cache.length,
      'all_companies_cached': _allCompanies.length,
      'empty_prefixes_tracked': _emptyResultPrefixes.length,
      'cache_duration_minutes': _cacheDuration.inMinutes,
      'last_all_companies_update': _allCompaniesTimestamp?.toIso8601String(),
    };
  }
}
