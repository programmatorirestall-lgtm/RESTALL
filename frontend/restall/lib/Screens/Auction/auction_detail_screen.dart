// lib/Screens/Auction/auction_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:restall/API/Shop/auction_api.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/user_id_helper.dart';
import 'package:restall/models/Auction.dart';
import 'package:restall/providers/Auction/auction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailScreen({
    super.key,
    required this.auction,
  });

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _refreshTimer;
  Timer? _liveBidTimer;
  final TextEditingController _bidController = TextEditingController();
  final FocusNode _bidFocusNode = FocusNode();

  Auction? _currentAuction;
  String? _currentUserId;
  bool _isCurrentUserWinner = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
    _setupAnimations();
    _loadUserData();
    _startLiveUpdates(); // Cambiato da _startPeriodicRefresh
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _liveBidTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _bidController.dispose();
    _bidFocusNode.dispose();
    super.dispose();
  }

  /// 🔥 SISTEMA LIVE UPDATE AGGRESSIVO
  void _startLiveUpdates() {
    // Timer per countdown visivo ogni secondo
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Aggiorna solo la UI del countdown
      }
    });

    // Timer per refresh dati dell'asta più frequente quando è attiva
    _startBidRefreshTimer();
  }

  void _startBidRefreshTimer() {
    _liveBidTimer?.cancel();

    // Frequenza basata su quanto tempo rimane
    Duration refreshInterval = _getRefreshInterval();

    _liveBidTimer = Timer.periodic(refreshInterval, (timer) {
      if (mounted && !(_currentAuction?.hasEnded ?? true) && !_isRefreshing) {
        _refreshAuctionDataLive();
      }
    });
  }

  /// Determina l'intervallo di refresh basato sul tempo rimanente
  Duration _getRefreshInterval() {
    final timeRemaining = _currentAuction?.timeRemaining;

    if (timeRemaining == null) return const Duration(seconds: 30);

    if (timeRemaining.inMinutes <= 5) {
      return const Duration(
          seconds: 2); // Super aggressivo negli ultimi 5 minuti
    } else if (timeRemaining.inMinutes <= 30) {
      return const Duration(seconds: 5); // Molto frequente nell'ultima mezz'ora
    } else if (timeRemaining.inHours <= 1) {
      return const Duration(seconds: 10); // Frequente nell'ultima ora
    } else {
      return const Duration(seconds: 15); // Normale per aste più lunghe
    }
  }
// AGGIORNA lib/Screens/Auction/auction_detail_screen.dart

  /// 🚀 REFRESH LIVE SENZA LOADING VISIVO CON FEEDBACK MIGLIORATO
  Future<void> _refreshAuctionDataLive() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      final provider = Provider.of<AuctionProvider>(context, listen: false);

      // Salva lo stato precedente per confronto
      final oldBid = _currentAuction?.currentBid ?? 0.0;
      final oldBidder = _currentAuction?.currentBidder ?? '';
      final oldBidCount = _currentAuction?.bidCount ?? 0;

      final updated = await provider
          .fetchAuctionDetails(widget.auction.id.toString(), silent: true);

      if (updated != null && mounted) {
        setState(() {
          _currentAuction = updated;
          _checkIfCurrentUserWinner();
        });

        // 🔥 FEEDBACK DETTAGLIATO PER CAMBIAMENTI

        // Nuova offerta
        if (updated.currentBid > oldBid) {
          print('💰 NUOVA OFFERTA: €$oldBid → €${updated.currentBid}');
          _showNewBidFeedback(updated.currentBid, updated.currentBidder);

          // Animazione più intensa per offerte significative
          if (updated.currentBid - oldBid > 50) {
            _triggerIntenseFeedback();
          }
        }

        // Nuovo offerente
        if (updated.currentBidder != oldBidder &&
            updated.currentBidder.isNotEmpty) {
          print('👤 NUOVO OFFERENTE: $oldBidder → ${updated.currentBidder}');
        }

        // Più offerte
        if (updated.bidCount > oldBidCount) {
          print('🔢 CONTATORE OFFERTE: $oldBidCount → ${updated.bidCount}');
        }

        // Riavvia timer con intervallo aggiornato se necessario
        final newInterval = _getRefreshInterval();
        if (_liveBidTimer?.isActive == true) {
          final currentInterval = Duration(seconds: 15); // Assumi default
          if (newInterval != currentInterval) {
            _startBidRefreshTimer();
          }
        }
      }
    } catch (error) {
      print('⚠️ Errore refresh live: $error');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Feedback visivo per nuove offerte con informazioni dettagliate
  void _showNewBidFeedback(double newBid, String bidder) {
    // Vibrazione appropriata
    HapticFeedback.lightImpact();

    // Animazione pulse
    _pulseController.reset();
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Messaggio contestuale
    String message;
    if (bidder == _currentUserId) {
      message =
          '🎉 La tua offerta di €${newBid.toStringAsFixed(2)} è stata confermata!';
    } else {
      message = '💰 Nuova offerta: €${newBid.toStringAsFixed(2)}';
      if (_isCurrentUserWinner) {
        message += ' - Sei stato superato!';
      }
    }

    // SnackBar con azione
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              bidder == _currentUserId ? Icons.celebration : Icons.trending_up,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bidder == _currentUserId
            ? Colors.green
            : (_isCurrentUserWinner ? Colors.orange : Colors.blue),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        action: bidder != _currentUserId
            ? SnackBarAction(
                label: 'RILANCIA',
                textColor: Colors.white,
                onPressed: () {
                  final suggestedBid =
                      newBid + (_currentAuction?.bidIncrement ?? 10);
                  _bidController.text = suggestedBid.toString();
                  _bidFocusNode.requestFocus();
                },
              )
            : null,
      ),
    );
  }

  /// Feedback intenso per offerte molto alte
  void _triggerIntenseFeedback() {
    // Vibrazione più forte
    HapticFeedback.mediumImpact();

    // Pulse multipli
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  /// 🎯 PIAZZA OFFERTA CON REFRESH IMMEDIATO
  Future<void> _placeBid() async {
    if (_currentUserId == null) {
      _showErrorDialog('Errore', 'Utente non autenticato');
      return;
    }

    final bidText = _bidController.text.trim();
    if (bidText.isEmpty) {
      _showErrorDialog('Errore', 'Inserisci un importo per l\'offerta');
      return;
    }

    final bidAmount = double.tryParse(bidText);
    if (bidAmount == null || bidAmount <= 0) {
      _showErrorDialog('Errore', 'Importo non valido');
      return;
    }

    final currentBid = _currentAuction?.currentBid ?? widget.auction.currentBid;
    if (bidAmount <= currentBid) {
      _showErrorDialog('Errore',
          'L\'offerta deve essere superiore a €${currentBid.toStringAsFixed(2)}');
      return;
    }

    // Dismiss keyboard
    _bidFocusNode.unfocus();

    final provider = Provider.of<AuctionProvider>(context, listen: false);
    final success = await provider.placeBid(
      widget.auction.id.toString(),
      _currentUserId!,
      bidAmount,
    );

    if (success) {
      _bidController.clear();

      // ✨ REFRESH IMMEDIATO DOPO OFFERTA PIAZZATA
      await _refreshAuctionDataLive();

      _showSuccessDialog('Offerta piazzata!',
          'La tua offerta di €${bidAmount.toStringAsFixed(2)} è stata registrata.');

      // Riavvia timer con intervallo più aggressivo
      _startBidRefreshTimer();
    }
  }

  debugTEST() async {
    // Nel tuo AuctionProvider o widget
    final auctionApi = AuctionApi();
    await auctionApi.debugAuthStatus();
    final isAuthOk = await auctionApi.testAuthentication();
    print('Auth test result: $isAuthOk');
    final prefs = await SharedPreferences.getInstance();
    print('JWT: ${prefs.getString('jwt')}');
    print('Cookie: ${prefs.getString('cookie')}');
    print('RT: ${prefs.getString('RT')}');
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Start pulsing if urgent
    if ((_currentAuction?.timeRemaining?.inHours ?? 999) < 1) {
      _pulseController.repeat(reverse: true);
    }
  }

  // Sostituisci il metodo _loadUserData() con questo:
  Future<void> _loadUserData() async {
    try {
      _currentUserId = await UserIdHelper.getCurrentUserId();

      if (_currentUserId != null) {
        print('✅ ID utente caricato: $_currentUserId');
        _checkIfCurrentUserWinner();
      } else {
        print('❌ Impossibile recuperare ID utente');
        _handleAuthError();
      }
    } catch (error) {
      print('❌ Errore caricamento dati utente: $error');
      _handleAuthError();
    }
  }

// Aggiungi questo metodo se non presente
  void _handleAuthError() {
    if (mounted) {
      _showErrorDialog('Errore di autenticazione',
          'Impossibile identificare l\'utente. Effettua nuovamente il login.');
    }
  }

  void _checkIfCurrentUserWinner() {
    if (_currentUserId != null && _currentAuction != null) {
      _isCurrentUserWinner = _currentAuction!.currentBidder == _currentUserId;
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !(_currentAuction?.hasEnded ?? true)) {
        _refreshAuctionData();
      }
    });
  }

  Future<void> _refreshAuctionData() async {
    final provider = Provider.of<AuctionProvider>(context, listen: false);
    final updated =
        await provider.fetchAuctionDetails(widget.auction.id.toString());

    if (updated != null && mounted) {
      setState(() {
        _currentAuction = updated;
        _checkIfCurrentUserWinner();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<AuctionProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(colorScheme),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAuctionHeader(theme, colorScheme),
                          const SizedBox(height: 24),
                          _buildTimeAndStatus(theme, colorScheme),
                          const SizedBox(height: 24),
                          _buildCurrentBidSection(theme, colorScheme),
                          const SizedBox(height: 24),
                          _buildDescription(theme, colorScheme),
                          const SizedBox(height: 24),
                          _buildActionSection(theme, colorScheme, provider),
                          const SizedBox(
                              height: 100), // Space for bottom buttons
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<AuctionProvider>(
        builder: (context, provider, child) {
          return _buildBottomActions(provider, theme.colorScheme);
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _currentAuction?.images.isNotEmpty == true
            ? Image.network(
                _currentAuction!.images.first.src,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage(colorScheme);
                },
              )
            : _buildPlaceholderImage(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.gavel_outlined,
          size: 80,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildAuctionHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(colorScheme),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getStatusTextColor(colorScheme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'ID: ${_currentAuction?.id ?? widget.auction.id}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentAuction?.name ?? widget.auction.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (_currentAuction?.sku.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            'SKU: ${_currentAuction!.sku}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeAndStatus(ThemeData theme, ColorScheme colorScheme) {
    final timeRemaining = _currentAuction?.timeRemaining;
    final hasEnded = _currentAuction?.hasEnded ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEnded
              ? colorScheme.error
              : ((timeRemaining?.inHours ?? 999) < 1)
                  ? colorScheme.error
                  : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasEnded ? Icons.timer_off_rounded : Icons.schedule_rounded,
                color: hasEnded ? colorScheme.error : colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasEnded ? 'Asta terminata' : 'Tempo rimanente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!hasEnded && timeRemaining != null)
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Text(
                          _formatDetailedTimeRemaining(timeRemaining),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: timeRemaining.inHours < 1
                                ? colorScheme.error
                                : colorScheme.onPrimary,
                          ),
                        ),
                      )
                    else
                      Text(
                        hasEnded ? 'Asta conclusa' : 'Tempo non disponibile',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentAuction?.endTime != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fine asta: ${_formatEndTime(_currentAuction!.endTime!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentBidSection(ThemeData theme, ColorScheme colorScheme) {
    final currentBid = _currentAuction?.currentBid ?? widget.auction.currentBid;
    final currentBidder =
        _currentAuction?.currentBidder ?? widget.auction.currentBidder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.euro_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offerta corrente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '€${currentBid.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCurrentUserWinner) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'TUA OFFERTA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (currentBidder.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Offerente attuale: ${_maskBidder(currentBidder)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, ColorScheme colorScheme) {
    final description =
        _currentAuction?.description ?? widget.auction.description;

    if (description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrizione',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Html(
            data: description,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                color: colorScheme.onSurface,
                lineHeight: const LineHeight(1.6),
              ),
              "p": Style(
                margin: Margins.only(bottom: 8),
              ),
              "strong": Style(
                fontWeight: FontWeight.bold,
              ),
              "b": Style(
                fontWeight: FontWeight.bold,
              ),
              "em": Style(
                fontStyle: FontStyle.italic,
              ),
              "i": Style(
                fontStyle: FontStyle.italic,
              ),
              "ul": Style(
                margin: Margins.only(left: 16, bottom: 8),
              ),
              "ol": Style(
                margin: Margins.only(left: 16, bottom: 8),
              ),
              "li": Style(
                margin: Margins.only(bottom: 4),
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(
      ThemeData theme, ColorScheme colorScheme, AuctionProvider provider) {
    final hasEnded = _currentAuction?.hasEnded ?? true;

    if (hasEnded) {
      return _buildEndedAuctionActions(theme, colorScheme, provider);
    }

    return _buildActiveBiddingSection(theme, colorScheme, provider);
  }

  Widget _buildActiveBiddingSection(
      ThemeData theme, ColorScheme colorScheme, AuctionProvider provider) {
    final currentBid = _currentAuction?.currentBid ?? widget.auction.currentBid;
    final minBidIncrement = 10.0; // Incremento minimo
    final suggestedBid = currentBid + minBidIncrement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piazza la tua offerta',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _bidController,
                focusNode: _bidFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Importo offerta (€)',
                  hintText: '€${suggestedBid.toStringAsFixed(2)}',
                  prefixIcon: Icon(
                    Icons.euro_rounded,
                    color: colorScheme.onPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Offerta minima: €${suggestedBid.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _bidController.text = suggestedBid.toStringAsFixed(2);
                    },
                    child: const Text(
                      'Usa minima',
                      style: TextStyle(color: secondaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (provider.errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              provider.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildEndedAuctionActions(
      ThemeData theme, ColorScheme colorScheme, AuctionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _isCurrentUserWinner
                ? Icons.celebration_rounded
                : Icons.timer_off_rounded,
            size: 48,
            color: _isCurrentUserWinner ? Colors.green : colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _isCurrentUserWinner ? 'Congratulazioni!' : 'Asta terminata',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isCurrentUserWinner ? Colors.green : colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isCurrentUserWinner
                ? 'Hai vinto l\'asta! Procedi al pagamento per completare l\'acquisto.'
                : 'Questa asta è terminata. Controlla le altre aste disponibili.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
      AuctionProvider provider, ColorScheme colorScheme) {
    final hasEnded = _currentAuction?.hasEnded ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: hasEnded
            ? _buildEndedBottomActions(provider, colorScheme)
            : _buildActiveBottomActions(provider, colorScheme),
      ),
    );
  }

  Widget _buildActiveBottomActions(
      AuctionProvider provider, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: provider.isBidding ? null : _placeBid,
            icon: provider.isBidding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gavel_rounded),
            label: Text(provider.isBidding ? 'Piazzando...' : 'Piazza offerta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _refreshAuctionData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: secondaryColor,
            ),
            label: const Text(
              'Aggiorna',
              style: TextStyle(color: secondaryColor),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndedBottomActions(
      AuctionProvider provider, ColorScheme colorScheme) {
    if (!_isCurrentUserWinner) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Torna alle aste'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: provider.isBuying ? null : _buyAuction,
            icon: provider.isBuying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment_rounded),
            label: Text(provider.isBuying ? 'Elaborando...' : 'Acquista ora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Indietro'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _buyAuction() async {
    if (_currentUserId == null) {
      _showErrorDialog('Errore', 'Utente non autenticato');
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Conferma acquisto',
      'Vuoi procedere all\'acquisto di questa asta per €${(_currentAuction?.currentBid ?? widget.auction.currentBid).toStringAsFixed(2)}?',
    );

    if (!confirmed) return;

    try {
      // Initialize Stripe payment
      await _processStripePayment();
    } catch (e) {
      _showErrorDialog('Errore pagamento',
          'Si è verificato un errore durante il pagamento: $e');
    }
  }

  Future<void> _processStripePayment() async {
    final provider = Provider.of<AuctionProvider>(context, listen: false);

    try {
      // Create payment intent and get client secret
      final result = await provider.buyAuction(
        widget.auction.id.toString(),
        _currentUserId!,
      );

      if (result == null) {
        return; // Error handled by provider
      }

      final paymentIntent = result['paymentIntent'];
      if (paymentIntent == null || paymentIntent['client_secret'] == null) {
        _showErrorDialog('Errore', 'Impossibile inizializzare il pagamento');
        return;
      }

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'RestAll Auctions',
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      if (mounted) {
        _showSuccessDialog(
          'Acquisto completato!',
          'Hai acquistato con successo l\'asta "${_currentAuction?.name ?? widget.auction.name}"',
        );

        // Navigate back to auctions list
        Navigator.pop(context);
      }
    } on StripeException catch (e) {
      String errorMessage = 'Pagamento annullato';

      switch (e.error.code) {
        case FailureCode.Canceled:
          errorMessage = 'Pagamento annullato dall\'utente';
          break;
        case FailureCode.Failed:
          errorMessage = 'Pagamento fallito: ${e.error.localizedMessage}';
          break;
        default:
          errorMessage = 'Errore Stripe: ${e.error.localizedMessage}';
      }

      _showErrorDialog('Errore pagamento', errorMessage);
    }
  }

  // --- UTILITY METHODS ---

  Color _getStatusColor(ColorScheme colorScheme) {
    final hasEnded = _currentAuction?.hasEnded ?? true;
    if (hasEnded) return colorScheme.errorContainer;

    final timeRemaining = _currentAuction?.timeRemaining;
    if (timeRemaining != null && timeRemaining.inHours < 1) {
      return colorScheme.errorContainer;
    }

    return colorScheme.primaryContainer;
  }

  Color _getStatusTextColor(ColorScheme colorScheme) {
    final hasEnded = _currentAuction?.hasEnded ?? true;
    if (hasEnded) return colorScheme.onErrorContainer;

    final timeRemaining = _currentAuction?.timeRemaining;
    if (timeRemaining != null && timeRemaining.inHours < 1) {
      return colorScheme.onErrorContainer;
    }

    return colorScheme.onPrimaryContainer;
  }

  String _getStatusText() {
    final hasEnded = _currentAuction?.hasEnded ?? true;
    if (hasEnded) return 'TERMINATA';

    final timeRemaining = _currentAuction?.timeRemaining;
    if (timeRemaining != null && timeRemaining.inHours < 1) {
      return 'URGENTE';
    }

    return 'LIVE';
  }

  String _formatDetailedTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours % 24}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatEndTime(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);

    if (difference.isNegative) {
      return 'Terminata il ${endTime.day}/${endTime.month}/${endTime.year} alle ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
    }

    return '${endTime.day}/${endTime.month}/${endTime.year} alle ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  String _maskBidder(String bidder) {
    if (bidder.length <= 3) return bidder;
    return '${bidder.substring(0, 3)}***';
  }

  // --- DIALOG METHODS ---

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
