import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/API/api_exceptions.dart';
import 'package:restall/core/performance/cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:restall/API/Logout/logout.dart';
import 'package:restall/Screens/Welcome/welcome_screen.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/main.dart';
import 'package:restall/models/UserProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileState { idle, loading, error }

class ProfileProvider with ChangeNotifier {
  final UserApi _userApi;
  final CacheManager _cacheManager;
  final ConnectionManager _connectionManager;

  ProfileProvider({
    required UserApi userApi,
    required CacheManager cacheManager,
    required ConnectionManager connectionManager,
  })  : _userApi = userApi,
        _cacheManager = cacheManager,
        _connectionManager = connectionManager {
    // Carica il profilo all'avvio
    fetchProfile();
  }

  ProfileState _state = ProfileState.loading;
  UserProfile? _userProfile;
  String? _errorMessage;
  String? _userId;

  // Getters
  ProfileState get state => _state;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  /// Getter utility per verificare se il venditore è verificato
  bool get isSellerVerified => _userProfile?.sellerStatus == 'verified';

  /// Getter utility per verificare se il venditore è in attesa di verifica
  bool get isSellerPending => _userProfile?.sellerStatus == 'pending';

  /// Getter per l'ID account Stripe
  String? get stripeAccountId => _userProfile?.stripeAccountId;

  static const _profileCacheKey = 'user_profile';

  /// Carica il profilo utente, con una strategia cache-first e retry.
  Future<void> fetchProfile({bool forceRefresh = false}) async {
    _state = ProfileState.loading;
    _errorMessage = null;
    if (forceRefresh) {
      // Invalida la cache se si forza l'aggiornamento
      _cacheManager.invalidate(_profileCacheKey);
    }
    notifyListeners();

    // 1. Prova a caricare dalla cache
    if (!forceRefresh) {
      try {
        final cachedProfileJson = _cacheManager.get<String>(_profileCacheKey);
        if (cachedProfileJson != null) {
          final cachedProfile = userProfileFromJson(cachedProfileJson);

          // Se la cache non ha i campi seller, invalida e ricarica da rete
          if (cachedProfile.isSeller == null && cachedProfile.sellerStatus == null) {
            print('⚠️ DEBUG: Cache senza dati seller, invalido e ricarico da rete');
            _cacheManager.invalidate(_profileCacheKey);
            // Continua con il caricamento da rete
          } else {
            _userProfile = cachedProfile;
            _state = ProfileState.idle;
            notifyListeners();
            // Lancia una sincronizzazione in background non bloccante
            _syncProfileInBackground();
            return;
          }
        }
      } catch (e) {
        // Errore nella deserializzazione della cache, procedi con la fetch
      }
    }

    // 2. Se non in cache o se forzato, carica dalla rete
    try {
      await _loadUserIdFromToken();
      if (_userId == null) {
        throw UnauthorizedException(
            "ID utente non trovato. Effettua nuovamente il login.");
      }

      final profile = await _connectionManager.executeWithRetry(
        () => _userApi.getData(),
      );

      // Il backend GET /user/me NON restituisce isSeller, quindi chiamiamo
      // sempre seller-status per determinare se l'utente è venditore e il suo stato
      UserProfile finalProfile = profile;

      try {
        print('🔍 DEBUG: Chiamata seller-status per verificare stato venditore...');
        final status = await _userApi.getSellerStatus();

        final chargesEnabled = status['charges_enabled'] == true;
        final payoutsEnabled = status['payouts_enabled'] == true;
        final detailsSubmitted = status['details_submitted'] == true;
        final isVerified = chargesEnabled && payoutsEnabled && detailsSubmitted;

        print('✅ DEBUG: seller-status risposta: isVerified=$isVerified');

        // Se abbiamo ricevuto una risposta, l'utente È un venditore
        finalProfile = profile.copyWith(
          isSeller: true,
          sellerStatus: isVerified ? 'verified' : 'pending',
          stripeAccountId: status['stripeAccountId'],
        );
      } catch (e) {
        print('⚠️ DEBUG: seller-status non disponibile (utente non è venditore): $e');
        // Se otteniamo un errore (400/404), l'utente non è un venditore
        finalProfile = profile.copyWith(
          isSeller: false,
          sellerStatus: null,
        );
      }

      _userProfile = finalProfile;
      // Salva in cache come stringa JSON
      _cacheManager.set(_profileCacheKey, userProfileToJson(finalProfile),
          ttl: const Duration(hours: 1));
      _state = ProfileState.idle;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ProfileState.error;
    } catch (e) {
      _errorMessage = "Si è verificato un errore inaspettato.";
      _state = ProfileState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Esegue un aggiornamento in background per mantenere i dati freschi
  /// senza mostrare un indicatore di caricamento all'utente.
  Future<void> _syncProfileInBackground() async {
    try {
      await _loadUserIdFromToken();
      final profile = await _userApi.getData();

      // Verifica anche lo stato seller in background
      UserProfile finalProfile = profile;

      try {
        print('🔍 DEBUG Background: Chiamata seller-status...');
        final status = await _userApi.getSellerStatus();

        final chargesEnabled = status['charges_enabled'] == true;
        final payoutsEnabled = status['payouts_enabled'] == true;
        final detailsSubmitted = status['details_submitted'] == true;
        final isVerified = chargesEnabled && payoutsEnabled && detailsSubmitted;

        print('✅ DEBUG Background: seller-status risposta: isVerified=$isVerified');

        finalProfile = profile.copyWith(
          isSeller: true,
          sellerStatus: isVerified ? 'verified' : 'pending',
          stripeAccountId: status['stripeAccountId'],
        );
      } catch (e) {
        print('⚠️ DEBUG Background: seller-status non disponibile: $e');
        finalProfile = profile.copyWith(
          isSeller: false,
          sellerStatus: null,
        );
      }

      if (finalProfile != _userProfile) {
        _userProfile = finalProfile;
        _cacheManager.set(_profileCacheKey, userProfileToJson(finalProfile),
            ttl: const Duration(hours: 1));
        notifyListeners();
      }
    } catch (e) {
      // Fallimento silenzioso, l'utente ha ancora i dati in cache
    }
  }

  /// Aggiorna i dati del profilo utente.
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    //print('🔄 ProfileProvider.updateProfile chiamato');
    //print('📋 Dati da aggiornare: ${updatedProfile.toJson()}');

    _state = ProfileState.loading;
    notifyListeners();

    try {
      if (_userId == null) {
        await _loadUserIdFromToken(); // Riprova a caricare l'ID
        if (_userId == null) {
          throw UnauthorizedException(
              "Impossibile aggiornare: ID utente non trovato.");
        }
      }

      //print('👤 Aggiornamento per utente ID: $_userId');

      await _userApi.updateProfile(updatedProfile, _userId!);

      //print('✅ Profilo aggiornato ricevuto: ${updatedProfile.toJson()}');

      _userProfile = updatedProfile;
      // Invalida la cache e la aggiorna con i nuovi dati
      _cacheManager.set(_profileCacheKey, userProfileToJson(updatedProfile),
          ttl: const Duration(hours: 1));
      _state = ProfileState.idle;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      //print('❌ Errore ProfileProvider: ${e.message}');
      _errorMessage = e.message;
      _state = ProfileState.error;
      notifyListeners();
      return false;
    } catch (e) {
      //print('❌ Errore generico ProfileProvider: $e');
      _errorMessage = "Errore inaspettato durante l'aggiornamento.";
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Recupera l'ID utente dal token JWT salvato.
  Future<void> _loadUserIdFromToken() async {
    if (_userId != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenRaw = prefs.getString('jwt');
      if (tokenRaw != null && tokenRaw.isNotEmpty) {
        String token;
        if (tokenRaw.contains('=')) {
          token = Cookie.fromSetCookieValue(tokenRaw).value;
        } else {
          token = tokenRaw;
        }
        final decodedToken = Jwt.parseJwt(token);
        _userId = decodedToken['id'];
      }
    } catch (e) {
      _userId = null; // Resetta in caso di token malformato
    }
  }

  /// Elimina il profilo utente.
  Future<bool> deleteProfile() async {
    _state = ProfileState.loading;
    notifyListeners();

    try {
      if (_userId == null) {
        throw UnauthorizedException(
            "Impossibile eliminare: ID utente non trovato.");
      }
      await _userApi.deleteProfile(_userId!);

      // Logout e pulizia
      await LogoutApi().logout();
      _cacheManager.clear(); // Pulisce tutta la cache

      // Navigazione alla schermata di benvenuto
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ProfileState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Errore inaspettato durante l'eliminazione.";
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Richiede la verifica come venditore (attiva il flag isSeller)
  Future<bool> requestSellerVerification() async {
    _state = ProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Attiva il flag isSeller nel profilo
      final success = await updateProfile(_userProfile!.copyWith(
        isSeller: true,
        sellerStatus: 'pending',
      ));

      if (success) {
        print('✅ DEBUG: Flag seller attivato con successo');
        return true;
      } else {
        _errorMessage = "Errore durante l'attivazione del venditore.";
        _state = ProfileState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ DEBUG: Errore in requestSellerVerification: $e');
      _errorMessage = "Errore richiesta verifica venditore: ${e.toString()}";
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Avvia il processo di onboarding Stripe Connect
  /// Restituisce l'URL per completare l'onboarding
  Future<String?> initiateStripeOnboarding() async {
    try {
      if (_userId == null) {
        await _loadUserIdFromToken();
        if (_userId == null) {
          throw UnauthorizedException('User ID not found');
        }
      }

      // Chiama l'API per creare/recuperare l'account Stripe Connect
      final response = await _userApi.createSellerAccount();

      if (response.containsKey('url')) {
        final onboardingUrl = response['url'] as String;

        // Opzionalmente aggiorna il profilo locale con l'URL
        if (response.containsKey('accountId')) {
          _userProfile = _userProfile?.copyWith(
            stripeAccountId: response['accountId'],
          );
          notifyListeners();
        }

        return onboardingUrl;
      }

      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Errore inizializzazione Stripe: ${e.toString()}';
      return null;
    }
  }

  /// Verifica lo stato dell'account Stripe e aggiorna il profilo se verificato
  Future<bool> checkStripeAccountStatus() async {
    try {
      if (_userId == null) {
        await _loadUserIdFromToken();
        if (_userId == null) {
          throw UnauthorizedException('User ID not found');
        }
      }

      print('🔍 DEBUG: Verifica stato Stripe per userId: $_userId');

      // Chiama l'API per verificare lo stato
      final status = await _userApi.getSellerStatus();

      // print('✅ DEBUG: Risposta seller-status: $status');

      final chargesEnabled = status['charges_enabled'] == true;
      final payoutsEnabled = status['payouts_enabled'] == true;
      final detailsSubmitted = status['details_submitted'] == true;

      // Se tutto è abilitato, l'account è verificato
      final isVerified = chargesEnabled && payoutsEnabled && detailsSubmitted;

      // print('🏪 DEBUG: Account verificato? $isVerified');

      if (isVerified && _userProfile?.sellerStatus != 'verified') {
        // Aggiorna il profilo locale
        _userProfile = _userProfile?.copyWith(
          sellerStatus: 'verified',
          sellerVerifiedAt: DateTime.now(),
        );

        // Salva in cache
        if (_userProfile != null) {
          _cacheManager.set(_profileCacheKey, userProfileToJson(_userProfile!),
              ttl: const Duration(hours: 1));
        }

        notifyListeners();
      }

      return isVerified;
    } on BadRequestException {
      // 400 = account venditore Stripe non ancora creato
      // Questo è normale se l'utente ha appena attivato l'account
      // Mantieni lo stato pending, non è un errore
      return false;
    } on ApiException catch (e) {
      // print('❌ DEBUG: Errore API seller-status: ${e.message}');
      _errorMessage = e.message;
      return false;
    } catch (e) {
      // print('❌ DEBUG: Errore generico seller-status: $e');
      _errorMessage = 'Errore verifica stato Stripe: ${e.toString()}';
      return false;
    }
  }
}
