// lib/Screens/Auction/auction_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Auction.dart';
import 'package:restall/providers/Auction/auction_provider.dart';
import 'package:restall/Screens/Auction/auction_detail_screen.dart';
import 'package:restall/components/auction_card.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabAnimation;
  late ScrollController _scrollController;

  String _searchQuery = '';
  SortCriteria _sortCriteria = SortCriteria.timeRemaining;
  bool _sortAscending = true;
  bool _showFab = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
    _loadInitialData();
  }

  void _initializeControllers() {
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AuctionProvider>(context, listen: false);
      if (provider.auctions.isEmpty && !provider.isLoading) {
        provider.fetchAuctions();
      }
    });
  }

  void _onScroll() {
    final provider = Provider.of<AuctionProvider>(context, listen: false);

    // FAB logic
    final shouldShowFab = _scrollController.offset > 200;
    if (shouldShowFab != _showFab) {
      setState(() => _showFab = shouldShowFab);
      if (_showFab) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    }

    // Load more auctions when reaching bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.loadMoreAuctions();
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  List<Auction> _getFilteredAuctions(AuctionProvider provider) {
    List<Auction> auctions = provider.activeAuctions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      auctions = provider.searchAuctions(_searchQuery);
      // Keep only active auctions from search results
      auctions =
          auctions.where((a) => !a.hasEnded && a.status == 'publish').toList();
    }

    // Apply sorting
    auctions = provider.sortAuctions(_sortCriteria, ascending: _sortAscending);

    return auctions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<AuctionProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: colorScheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(theme, isDark, colorScheme),
                _buildAuctionsList(provider, colorScheme),
                if (provider.isLoadingMore) _buildLoadingMoreIndicator(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _showFab ? _buildScrollToTopFab(colorScheme) : null,
    );
  }

  SliverAppBar _buildSliverAppBar(
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, colorScheme),
                  const SizedBox(height: 20),
                  _buildSearchBar(colorScheme),
                  const SizedBox(height: 16),
                  _buildSortingControls(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.gavel_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aste Live',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Partecipa alle aste in tempo reale',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cerca aste...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        style: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildSortingControls(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortCriteria>(
                value: _sortCriteria,
                onChanged: (SortCriteria? newValue) {
                  if (newValue != null) {
                    setState(() => _sortCriteria = newValue);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: SortCriteria.timeRemaining,
                    child: Text('Tempo rimanente'),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.currentBid,
                    child: Text('Offerta corrente'),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.name,
                    child: Text('Nome'),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.endTime,
                    child: Text('Data fine'),
                  ),
                ],
                style: TextStyle(color: colorScheme.onSurface),
                dropdownColor: colorScheme.surface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() => _sortAscending = !_sortAscending);
          },
          icon: Icon(
            _sortAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: colorScheme.primary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionsList(AuctionProvider provider, ColorScheme colorScheme) {
    if (provider.isLoading && provider.auctions.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.status == AuctionStatus.error && provider.auctions.isEmpty) {
      return _buildErrorState(provider, colorScheme);
    }

    final filteredAuctions = _getFilteredAuctions(provider);

    if (filteredAuctions.isEmpty && provider.auctions.isNotEmpty) {
      return _buildEmptySearchState(colorScheme);
    }

    if (filteredAuctions.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final auction = filteredAuctions[index];

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AuctionCard(
                  auction: auction,
                  onTap: () => _navigateToDetails(auction),
                  onBidPressed: () => _navigateToDetails(auction),
                ),
              ),
            );
          },
          childCount: filteredAuctions.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Caricamento aste...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AuctionProvider provider, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Errore nel caricamento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Si è verificato un errore',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Nessun risultato',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Non ci sono aste che corrispondono alla tua ricerca',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gavel_outlined,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nessuna asta attiva',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Al momento non ci sono aste attive.\nTorna più tardi per nuove opportunità!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildScrollToTopFab(ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.small(
        onPressed: _scrollToTop,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.keyboard_arrow_up_rounded),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToDetails(Auction auction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailScreen(auction: auction),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _animationController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
