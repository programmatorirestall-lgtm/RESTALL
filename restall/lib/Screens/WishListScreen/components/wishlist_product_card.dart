import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';

class WishlistProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const WishlistProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Expanded(
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Product Image
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images.first.src,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),

        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // Sale badge
        if (product.onSale)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'OFFERTA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            product.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 8),

          // Price section
          Row(
            children: [
              if (product.onSale && product.regularPrice > 0) ...[
                Text(
                  '€${product.regularPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 4),
              ],
              Text(
                '€${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: product.onSale ? Colors.red[600] : secondaryColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Stock status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStockColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStockText(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getStockColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStockColor() {
    switch (product.stockStatus.toLowerCase()) {
      case 'instock':
        return Colors.green[600]!;
      case 'outofstock':
        return Colors.red[600]!;
      case 'onbackorder':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStockText() {
    switch (product.stockStatus.toLowerCase()) {
      case 'instock':
        return 'DISPONIBILE';
      case 'outofstock':
        return 'ESAURITO';
      case 'onbackorder':
        return 'IN ARRIVO';
      default:
        return 'NON DISPONIBILE';
    }
  }
}
