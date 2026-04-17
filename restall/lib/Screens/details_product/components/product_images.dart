// lib/Screens/details_product/components/product_images.dart
import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/components/image_gallery.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    Key? key,
    required this.product,
  }) : super(key: key);

  final Product product;

  @override
  _ProductImagesState createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages>
    with SingleTickerProviderStateMixin {
  int selectedImage = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: fastDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _currentImage {
    if (widget.product.images.isEmpty) {
      return "https://i0.wp.com/restall.it/wp-content/uploads/2023/11/logo.png?fit=75%2C75&ssl=1";
    }
    return widget.product.images[selectedImage].src;
  }

  void _openGallery() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) {
          return ImageGalleryScreen(
            images: widget.product.images,
            initialIndex: selectedImage,
            heroTag: 'product_image_${widget.product.id}',
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _onImageTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
      _openGallery();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        children: [
          // Immagine principale con effetti
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: kCardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kBorderRadius),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: GestureDetector(
                      onTap: _onImageTap,
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: kPrimaryLightColor,
                            borderRadius: BorderRadius.circular(kBorderRadius),
                          ),
                          child: Stack(
                            children: [
                              // Immagine
                              Positioned.fill(
                                child: Image.network(
                                  _currentImage,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
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
                                      color: kPrimaryLightColor,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 64,
                                            color: kLightTextColor,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Immagine non disponibile',
                                            style: TextStyle(
                                              color: kLightTextColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Overlay con icona zoom
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),

                              // Indicator se ci sono più immagini
                              if (widget.product.images.length > 1)
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${selectedImage + 1}/${widget.product.images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: defaultPadding),

          // Thumbnail images con animazioni
          if (widget.product.images.length > 1)
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: widget.product.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SmallProductImage(
                    isSelected: index == selectedImage,
                    press: () {
                      setState(() {
                        selectedImage = index;
                      });
                    },
                    image: widget.product.images[index].src,
                    index: index,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class SmallProductImage extends StatefulWidget {
  const SmallProductImage({
    super.key,
    required this.isSelected,
    required this.press,
    required this.image,
    required this.index,
  });

  final bool isSelected;
  final VoidCallback press;
  final String image;
  final int index;

  @override
  State<SmallProductImage> createState() => _SmallProductImageState();
}

class _SmallProductImageState extends State<SmallProductImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: fastDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.press();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _onTap,
            child: AnimatedContainer(
              duration: defaultDuration,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kSmallBorderRadius),
                border: Border.all(
                  color: widget.isSelected ? primaryColor : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kSmallBorderRadius - 2),
                child: Image.network(
                  widget.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: kPrimaryLightColor,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: kLightTextColor,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
