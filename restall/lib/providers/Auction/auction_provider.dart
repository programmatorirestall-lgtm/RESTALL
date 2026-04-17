// lib/providers/Auction/auction_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:restall/API/Shop/auction_api.dart';
import 'package:restall/models/Auction.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuctionStatus { idle, loading, loaded, error, bidding, buying }

class AuctionProvider with ChangeNotifier {
  final AuctionApi _auctionApi;

  List<Auction> _auctions = [];
  Auction? _selectedAuction;
  AuctionStatus _status = AuctionStatus.idle;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Paginazione
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  AuctionProvider({AuctionApi? auctionApi})
      : _auctionApi = auctionApi ?? AuctionApi() {
    _startAutoRefresh();
  }

  // --- GETTERS ---
  List<Auction> get auctions => List.unmodifiable(_auctions);
  Auction? get selectedAuction => _selectedAuction;
  AuctionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuctionStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isEmpty => _auctions.isEmpty && _status == AuctionStatus.loaded;
  bool get isBidding => _status == AuctionStatus.bidding;
  bool get isBuying => _status == AuctionStatus.buying;

  // Aste filtrate per stato
  List<Auction> get activeAuctions => _auctions
      .where((auction) => !auction.hasEnded && auction.status == 'publish')
      .toList();

  List<Auction> get endedAuctions =>
      _auctions.where((auction) => auction.hasEnded).toList();

  // --- CARICAMENTO ASTE ---

  /// Carica le aste attive con refresh opzionale
  Future<void> fetchAuctions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _auctions.clear();
    }

    _setStatus(AuctionStatus.loading);
    _clearError();

    try {
      print('🔄 Caricamento aste - Pagina: $_currentPage');

      final response = await _auctionApi.getActiveAuctions(
          page: _currentPage, limit: _itemsPerPage);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Auction> newAuctions;

        // Gestisci diversi formati di risposta
        if (data is List) {
          newAuctions = data.map((item) => Auction.fromJson(item)).toList();
        } else if (data is Map && data.containsKey('auctions')) {
          newAuctions = List.from(data['auctions'])
              .map((item) => Auction.fromJson(item))
              .toList();
        } else {
          throw Exception('Formato risposta API inaspettato');
        }

        if (refresh) {
          _auctions = newAuctions;
        } else {
          _auctions.addAll(newAuctions);
        }

        // Gestisci paginazione
        _hasMoreData = newAuctions.length == _itemsPerPage;
        if (_hasMoreData) _currentPage++;

        print(
            '✅ ${newAuctions.length} aste caricate. Totale: ${_auctions.length}');
        _setStatus(AuctionStatus.loaded);

        // Salva in cache
        await _saveAuctionsToCache();
      } else {
        throw Exception('Errore durante il caricamento delle aste');
      }
    } catch (error) {
      print('❌ Errore caricamento aste: $error');
      _setError('Impossibile caricare le aste. Riprova più tardi.');

      // Se è il primo caricamento, prova a caricare dalla cache
      if (_auctions.isEmpty) {
        await _loadAuctionsFromCache();
      }
    }
  }

  Future<Auction?> fetchAuctionDetails(String auctionId,
      {bool silent = false}) async {
    if (!silent) {
      _setStatus(AuctionStatus.loading);
    }
    _clearError();

    try {
      print('🔍 Caricamento dettagli asta: $auctionId (silent: $silent)');

      final response = await _auctionApi.getAuctionById(auctionId);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auction = Auction.fromJson(data);

        // Aggiorna l'asta nella lista se esiste
        final index = _auctions.indexWhere((a) => a.id.toString() == auctionId);
        if (index != -1) {
          _auctions[index] = auction;
        }

        // Aggiorna l'asta selezionata se corrisponde
        if (_selectedAuction?.id.toString() == auctionId) {
          _selectedAuction = auction;
        }

        if (!silent) {
          _setStatus(AuctionStatus.loaded);
        }

        // Notifica sempre per aggiornare UI
        notifyListeners();

        print('✅ Dettagli asta caricati con successo');
        return auction;
      } else {
        throw Exception('Errore durante il caricamento dei dettagli');
      }
    } catch (error) {
      print('❌ Errore caricamento dettagli asta: $error');
      if (!silent) {
        _setError('Impossibile caricare i dettagli dell\'asta');
      }
      return null;
    }
  }

  /// Piazza un'offerta con feedback immediato
  Future<bool> placeBid(String auctionId, String userId, double amount) async {
    _setStatus(AuctionStatus.bidding);
    _clearError();

    try {
      print('🎯 Piazzamento offerta: €$amount su asta $auctionId');

      final response = await _auctionApi.placeBid(auctionId, userId, amount);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Offerta piazzata: ${data['message']}');

        // 🚀 AGGIORNAMENTO IMMEDIATO DELL'ASTA
        // Non aspettare, aggiorna immediatamente i dati locali se possibile
        if (data.containsKey('auction')) {
          final updatedAuction = Auction.fromJson(data['auction']);

          // Aggiorna nella lista
          final index =
              _auctions.indexWhere((a) => a.id.toString() == auctionId);
          if (index != -1) {
            _auctions[index] = updatedAuction;
          }

          // Aggiorna l'asta selezionata
          if (_selectedAuction?.id.toString() == auctionId) {
            _selectedAuction = updatedAuction;
          }
        }

        _setStatus(AuctionStatus.loaded);

        // Schedula un refresh completo dopo un breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchAuctionDetails(auctionId, silent: true);
        });

        return true;
      } else if (response != null) {
        // Gestisci errori specifici (es. offerta troppo bassa)
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Offerta non valida';
        _setError(message);
        _setStatus(AuctionStatus.loaded);
        return false;
      } else {
        throw Exception('Errore di connessione durante l\'offerta');
      }
    } catch (error) {
      print('❌ Errore piazzamento offerta: $error');
      _setError('Impossibile piazzare l\'offerta. Riprova più tardi.');
      _setStatus(AuctionStatus.loaded);
      return false;
    }
  }

  /// Gestione timer più intelligente per aste live
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_auctions.isNotEmpty) {
        // Aggiorna solo i tempi, non fare chiamate API frequenti
        notifyListeners();

        // Refresh completo ogni 2 minuti per aste non critiche
        if (timer.tick % 6 == 0) {
          _refreshActiveAuctions();
        }
      }
    });
  }

  /// Refresh leggero delle aste attive senza mostrare loading
  Future<void> _refreshActiveAuctions() async {
    try {
      final response =
          await _auctionApi.getActiveAuctions(page: 1, limit: _itemsPerPage);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Auction> updatedAuctions;

        if (data is List) {
          updatedAuctions = data.map((item) => Auction.fromJson(item)).toList();
        } else if (data is Map && data.containsKey('auctions')) {
          updatedAuctions = List.from(data['auctions'])
              .map((item) => Auction.fromJson(item))
              .toList();
        } else {
          return;
        }

        // Aggiorna solo le aste esistenti, non sostituire tutto
        bool hasUpdates = false;
        for (final updatedAuction in updatedAuctions) {
          final index = _auctions.indexWhere((a) => a.id == updatedAuction.id);
          if (index != -1) {
            // CORREZIONE: usa endTime invece di endDate
            if (_auctions[index].currentBid != updatedAuction.currentBid ||
                _auctions[index].currentBidder !=
                    updatedAuction.currentBidder ||
                _auctions[index].endTime != updatedAuction.endTime) {
              _auctions[index] = updatedAuction;
              hasUpdates = true;
            }
          }
        }

        // Notifica solo se ci sono stati aggiornamenti reali
        if (hasUpdates) {
          notifyListeners();
          print('🔄 Aste aggiornate automaticamente');
        }
      }
    } catch (error) {
      // Ignora errori del refresh automatico per non disturbare l'utente
      print('⚠️ Refresh automatico fallito: $error');
    }
  }

  /// Carica più aste (paginazione infinita)
  Future<void> loadMoreAuctions() async {
    if (_isLoadingMore || !_hasMoreData || _status == AuctionStatus.loading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _auctionApi.getActiveAuctions(
          page: _currentPage, limit: _itemsPerPage);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Auction> newAuctions;

        if (data is List) {
          newAuctions = data.map((item) => Auction.fromJson(item)).toList();
        } else if (data is Map && data.containsKey('auctions')) {
          newAuctions = List.from(data['auctions'])
              .map((item) => Auction.fromJson(item))
              .toList();
        } else {
          newAuctions = [];
        }

        _auctions.addAll(newAuctions);
        _hasMoreData = newAuctions.length == _itemsPerPage;
        if (_hasMoreData) _currentPage++;

        print('✅ ${newAuctions.length} aste aggiuntive caricate');
        await _saveAuctionsToCache();
      }
    } catch (error) {
      print('❌ Errore caricamento aste aggiuntive: $error');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Acquista un'asta (solo per il vincitore)
  Future<Map<String, dynamic>?> buyAuction(String auctionId, String userId,
      {String? paymentMethodId}) async {
    _setStatus(AuctionStatus.buying);
    _clearError();

    try {
      print('💳 Acquisto asta: $auctionId');

      final response = await _auctionApi.buyAuction(auctionId, userId,
          paymentMethodId: paymentMethodId);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final paymentStatus = data['paymentIntent']?['status'];
        if (paymentStatus == 'succeeded') {
          print('✅ Acquisto asta completato con successo');

          // Rimuovi l'asta dalla lista (ora è privata)
          _auctions
              .removeWhere((auction) => auction.id.toString() == auctionId);
          if (_selectedAuction?.id.toString() == auctionId) {
            _selectedAuction = null;
          }

          _setStatus(AuctionStatus.loaded);
          return data;
        } else {
          _setError('Pagamento non completato. Stato: $paymentStatus');
          _setStatus(AuctionStatus.loaded);
          return data; // Restituisci i dati per gestire nel UI
        }
      } else if (response != null) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Errore durante l\'acquisto';
        _setError(message);
        _setStatus(AuctionStatus.loaded);
        return null;
      } else {
        throw Exception('Errore di connessione durante l\'acquisto');
      }
    } catch (error) {
      print('❌ Errore acquisto asta: $error');
      _setError('Impossibile completare l\'acquisto. Riprova più tardi.');
      _setStatus(AuctionStatus.loaded);
      return null;
    }
  }

  //
  // --- CACHE E PERSISTENZA ---

  static const String _cacheKey = 'cached_auctions';

  Future<void> _saveAuctionsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auctionsJson =
          _auctions.map((auction) => auction.toJson()).toList();
      final cacheData = {
        'auctions': auctionsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (error) {
      print('⚠️ Errore salvataggio cache aste: $error');
    }
  }

  Future<void> _loadAuctionsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        final timestamp = data['timestamp'] as int;
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

        // Cache valida per 10 minuti
        if (cacheAge < 600000) {
          final auctionsList = data['auctions'] as List;
          _auctions =
              auctionsList.map((item) => Auction.fromJson(item)).toList();

          print('📱 ${_auctions.length} aste caricate dalla cache');
          _setStatus(AuctionStatus.loaded);
        }
      }
    } catch (error) {
      print('⚠️ Errore caricamento cache aste: $error');
    }
  }

  // --- UTILITY E STATO ---

  void _setStatus(AuctionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuctionStatus.error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Pulisce la selezione corrente
  void clearSelection() {
    if (_selectedAuction != null) {
      _selectedAuction = null;
      notifyListeners();
    }
  }

  /// Refresh manuale delle aste
  Future<void> refresh() async {
    await fetchAuctions(refresh: true);
  }

  /// Cerca aste per nome o descrizione
  List<Auction> searchAuctions(String query) {
    if (query.isEmpty) return _auctions;

    final lowercaseQuery = query.toLowerCase();
    return _auctions.where((auction) {
      return auction.name.toLowerCase().contains(lowercaseQuery) ||
          auction.description.toLowerCase().contains(lowercaseQuery) ||
          auction.sku.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra aste per prezzo
  List<Auction> filterByPriceRange(double minPrice, double maxPrice) {
    return _auctions.where((auction) {
      final currentBid = auction.currentBid;
      return currentBid >= minPrice && currentBid <= maxPrice;
    }).toList();
  }

  /// Ordina aste per criteri diversi
  List<Auction> sortAuctions(SortCriteria criteria, {bool ascending = true}) {
    final sortedList = List<Auction>.from(_auctions);

    switch (criteria) {
      case SortCriteria.name:
        sortedList.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case SortCriteria.currentBid:
        sortedList.sort((a, b) => ascending
            ? a.currentBid.compareTo(b.currentBid)
            : b.currentBid.compareTo(a.currentBid));
        break;
      case SortCriteria.timeRemaining:
        sortedList.sort((a, b) {
          final aTime = a.timeRemaining?.inSeconds ?? 0;
          final bTime = b.timeRemaining?.inSeconds ?? 0;
          return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
        });
        break;
      case SortCriteria.endTime:
        sortedList.sort((a, b) => ascending
            ? (a.endTime ?? DateTime.now())
                .compareTo(b.endTime ?? DateTime.now())
            : (b.endTime ?? DateTime.now())
                .compareTo(a.endTime ?? DateTime.now()));
        break;
    }

    return sortedList;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

enum SortCriteria {
  name,
  currentBid,
  timeRemaining,
  endTime,
}
