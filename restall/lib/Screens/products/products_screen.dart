import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/Screens/ProductDetailScreen/product_detail_screen.dart';
import 'package:restall/components/product_card.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Product/product_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabAnimation;
  late ScrollController _scrollController;

  String _selectedCategory = '';
  bool _showFab = false;
  bool _isSearchFocused = false;

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
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.products.isEmpty && !provider.isLoading) {
        provider.fetchProducts();
      }
    });
  }

  void _onScroll() {
    // Logica per il FAB "Scroll to Top"
    final shouldShowFab = _scrollController.offset > 200;
    if (shouldShowFab != _showFab) {
      setState(() => _showFab = shouldShowFab);
      if (_showFab) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    }

    // Logica per il Lazy Loading
    final provider = Provider.of<ProductProvider>(context, listen: false);
    // Controlla se siamo vicini alla fine della lista e non stiamo già caricando
    // Ridotto a 100px per triggerare anche con pochi prodotti
    if (_scrollController.position.extentAfter < 100 &&
        !provider.isLoading &&
        !provider.isLoadingMore &&
        provider.hasMoreProducts) {
      print('📥 Lazy loading: caricamento automatico pagina successiva');
      provider.fetchMoreProducts();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      floatingActionButton: _buildScrollToTopFab(colorScheme),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(theme, isDark, colorScheme),
            _buildCategoriesHeader(colorScheme),
            _buildProductsGrid(colorScheme),
            _buildLoadingMoreIndicator(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }

          // Mostra il pulsante "Carica altro" se ci sono più prodotti
          if (provider.hasMoreProducts && !provider.isLoading) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () {
                    print('🔽 Caricamento manuale pagina successiva');
                    provider.fetchMoreProducts();
                  },
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text('Carica altri prodotti'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            );
          }

          // Messaggio "Hai visto tutti i prodotti"
          if (!provider.hasMoreProducts && provider.products.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  '✨ Hai visto tutti i prodotti disponibili',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
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

  Future<void> _onRefresh() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchProducts(refresh: true);
    setState(() {
      _selectedCategory = '';
      _searchController.clear();
    });
  }

  SliverAppBar _buildSliverAppBar(
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
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
                  const SizedBox(height: 24),
                  _buildEnhancedSearchBar(colorScheme),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scopri i nostri',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Prodotti',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            if (provider.products.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${provider.products.length} prodotti',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedSearchBar(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: _searchController,
        onTap: () => setState(() => _isSearchFocused = true),
        onTapOutside: (_) => setState(() => _isSearchFocused = false),
        decoration: InputDecoration(
          hintText: 'Cerca il tuo prodotto ideale...',
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSearchFocused ? Icons.search_rounded : Icons.search_outlined,
              key: ValueKey(_isSearchFocused),
              color: _isSearchFocused
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<ProductProvider>(context, listen: false).searchProducts('');
    setState(() {});
  }

  void _onSearchChanged(String value) {
    setState(() {});
    Provider.of<ProductProvider>(context, listen: false).searchProducts(value);
  }

  SliverPersistentHeader _buildCategoriesHeader(ColorScheme colorScheme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 80,
        maxHeight: 80,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.background,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: _buildCategoryFilters(colorScheme),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(ColorScheme colorScheme) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final categories = ['Tutti', ...productProvider.categories];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final value = category == 'Tutti' ? '' : category;
              return _buildCategoryChip(
                  category, value, colorScheme, productProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    String value,
    ColorScheme colorScheme,
    ProductProvider productProvider,
  ) {
    final isSelected = _selectedCategory == value;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => _onCategorySelected(value, productProvider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: isSelected ? colorScheme.primary : colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? secondaryColor : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCategorySelected(String value, ProductProvider productProvider) {
    setState(() => _selectedCategory = value);
    productProvider.filterByCategory(value);
  }

  Widget _buildProductsGrid(ColorScheme colorScheme) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return SliverFillRemaining(
            child: _buildLoadingState(colorScheme),
          );
        }

        if (productProvider.products.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(colorScheme),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductItem(
                productProvider.products[index],
                index,
              ),
              childCount: productProvider.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductItem(dynamic product, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.05).clamp(0.0, 1.0),
            ((index * 0.05) + 0.2).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: Hero(
          tag: 'product_${product.id}',
          child: ProductCard(
            product: product,
            onTap: () => _navigateToProductDetail(product),
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetail(dynamic product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) =>
            ProductDetailScreen(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Caricamento prodotti...',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nessun prodotto trovato',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prova a modificare i filtri o la ricerca\nper trovare quello che stai cercando',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(
                Icons.refresh_rounded,
                color: secondaryColor,
              ),
              label: const Text(
                'Ricarica prodotti',
                style: TextStyle(color: secondaryColor),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _selectedCategory = '');
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.filterByCategory('');
    provider.searchProducts('');
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
