// lib/components/auction_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Auction.dart';

class AuctionCard extends StatefulWidget {
  final Auction auction;
  final VoidCallback? onTap;
  final VoidCallback? onBidPressed;
  final bool showBidButton;

  const AuctionCard({
    Key? key,
    required this.auction,
    this.onTap,
    this.onBidPressed,
    this.showBidButton = true,
  }) : super(key: key);

  @override
  State<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<AuctionCard>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startCountdown();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for urgent auctions
    if (widget.auction.timeRemaining != null &&
        widget.auction.timeRemaining!.inHours < 1) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Update countdown display

        // Start pulsing if less than 1 hour remaining
        if (widget.auction.timeRemaining != null &&
            widget.auction.timeRemaining!.inHours < 1 &&
            !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: _getBorderColor(colorScheme),
              width:
                  ((widget.auction.timeRemaining?.inHours ?? 0) < 1) ? 2 : 1),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _getCardGradient(colorScheme),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, colorScheme),
                const SizedBox(height: 12),
                _buildImageSection(),
                const SizedBox(height: 16),
                _buildAuctionInfo(theme, colorScheme),
                const SizedBox(height: 16),
                _buildFooter(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: widget.auction.images.isNotEmpty
            ? Image.network(
                widget.auction.images.first.src,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.gavel_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

// Aggiornamenti per auction_card.dart - Metodi modificati

  Widget _buildAuctionInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auction title
        Text(
          widget.auction.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Current bid info - aggiornato per usare startingBid
        Row(
          children: [
            Icon(
              Icons.euro_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.auction.bidCount > 0
                  ? 'Offerta corrente:'
                  : 'Prezzo di partenza:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '€${(widget.auction.bidCount > 0 ? widget.auction.currentBid : widget.auction.startingBid).toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),

        // Aggiungi informazioni sul numero di offerte se presenti
        if (widget.auction.bidCount > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.auction.bidCount} offert${widget.auction.bidCount == 1 ? 'a' : 'e'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],

        // Mostra Buy Now price se disponibile
        if (widget.auction.buyNowPrice > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Compralo subito: €${widget.auction.buyNowPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Status indicator - aggiornato per usare i nuovi metodi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(colorScheme),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusIndicatorColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.auction.getStatusText(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Auction ID
        Text(
          'ID: ${widget.auction.id}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

// Metodi helper aggiornati
  Color _getStatusIndicatorColor() {
    if (!widget.auction.hasStarted) {
      return Colors.orange; // In programma
    } else if (widget.auction.hasEnded) {
      return Colors.red; // Terminata
    } else {
      return Colors.green; // Live
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    if (!widget.auction.hasStarted) {
      return Colors.orange.withOpacity(0.2);
    } else if (widget.auction.hasEnded) {
      return colorScheme.errorContainer;
    } else {
      return colorScheme.primaryContainer;
    }
  }

  LinearGradient? _getCardGradient(ColorScheme colorScheme) {
    if (widget.auction.hasEnded) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surface,
          colorScheme.surfaceVariant.withOpacity(0.3),
        ],
      );
    }

    final timeRemaining = widget.auction.timeRemaining;
    if (timeRemaining != null && timeRemaining.inHours < 1) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.errorContainer.withOpacity(0.1),
          colorScheme.surface,
        ],
      );
    }

    return null;
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeRemaining(theme, colorScheme),
        ),
        if (widget.showBidButton && !widget.auction.hasEnded) ...[
          const SizedBox(width: 12),
          _buildBidButton(colorScheme),
        ],
      ],
    );
  }

  Widget _buildTimeRemaining(ThemeData theme, ColorScheme colorScheme) {
    final timeRemaining = widget.auction.timeRemaining;

    if (widget.auction.hasEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off_rounded,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Terminata',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (timeRemaining == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Tempo indefinito',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final isUrgent = timeRemaining.inHours < 1;
    final backgroundColor =
        isUrgent ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final textColor = isUrgent
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.timer_rounded : Icons.schedule_rounded,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTimeRemaining(timeRemaining),
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

// Soluzione alternativa più restrittiva
  Widget _buildBidButton(ColorScheme colorScheme) {
    return IntrinsicWidth(
      // Forza il widget a usare solo la larghezza necessaria
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 120, // Larghezza massima esplicita
          minHeight: 36,
          maxHeight: 40,
        ),
        child: ElevatedButton.icon(
          onPressed: widget.onBidPressed,
          icon: const Icon(Icons.gavel_rounded, size: 16),
          label: const Text(
            'Offerta',
            style: TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

// Oppure, se preferisci una soluzione più semplice, sostituisci con un Container:
  Widget _buildBidButtonSimple(ColorScheme colorScheme) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onBidPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 16,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offerta',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (widget.auction.hasEnded) {
      return colorScheme.error.withOpacity(0.5);
    }

    final timeRemaining = widget.auction.timeRemaining;
    if (timeRemaining != null && timeRemaining.inHours < 1) {
      return colorScheme.error;
    }

    return colorScheme.outline.withOpacity(0.2);
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}g ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _maskBidder(String bidder) {
    if (bidder.length <= 3) return bidder;
    return '${bidder.substring(0, 3)}***';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
