import 'package:flutter/material.dart' hide kToolbarHeight;
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';

class ImageGalleryScreen extends StatefulWidget {
  final List<ProductImage> images;
  final int initialIndex;
  final String heroTag;

  const ImageGalleryScreen({
    Key? key,
    required this.images,
    this.initialIndex = 0,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _uiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Animazioni per entrata
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Controllo visibilità UI
    _uiController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _uiController.forward();

    // Auto-hide UI dopo 3 secondi
    _startUIHideTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _uiController.dispose();
    super.dispose();
  }

  void _startUIHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showUI) {
        _toggleUI();
      }
    });
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiController.forward();
      _startUIHideTimer();
    } else {
      _uiController.reverse();
    }
  }

  void _onImageTap() {
    _toggleUI();
  }

  String _getImageUrl(int index) {
    if (widget.images.isEmpty) {
      return "https://i0.wp.com/restall.it/wp-content/uploads/2023/11/logo.png?fit=75%2C75&ssl=1";
    }
    return widget.images[index].src;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                // Immagini con zoom
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    if (!_showUI) _toggleUI();
                  },
                  itemCount: widget.images.isEmpty ? 1 : widget.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: _onImageTap,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Hero(
                            tag: index == widget.initialIndex
                                ? widget.heroTag
                                : 'gallery_$index',
                            child: Container(
                              width: size.width,
                              height: size.height,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                              ),
                              child: Image.network(
                                _getImageUrl(index),
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: primaryColor,
                                      strokeWidth: 3,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          size: 64,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Immagine non disponibile',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // UI Overlay con animazioni
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // Top bar con close button
                          Container(
                            height: kToolbarHeight +
                                MediaQuery.of(context).padding.top,
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                // Close button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                                const Spacer(),
                                // Counter
                                if (widget.images.length > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentIndex + 1} / ${widget.images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Bottom indicators
                          if (widget.images.length > 1)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: index == _currentIndex ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: index == _currentIndex
                                          ? primaryColor
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
