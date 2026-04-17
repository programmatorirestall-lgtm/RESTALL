import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restall/Screens/Preventivi/preventiviDetailScreen.dart';
import 'package:restall/constants.dart';

class PreventivoListTile extends StatefulWidget {
  final Map<String, dynamic> preventivo;

  const PreventivoListTile({Key? key, required this.preventivo})
      : super(key: key);

  @override
  State<PreventivoListTile> createState() => _PreventivoListTileState();
}

class _PreventivoListTileState extends State<PreventivoListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: _isPressed ? 4 : 8,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.grey[850] : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _animationController.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PreventivoDetailScreen(
                              idPreventivo: widget.preventivo['id']),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeInOut)),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con icona e numero preventivo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Preventivo #${widget.preventivo['id']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.preventivo['ragSocialeAzienda'] ??
                                      'Senza ragione sociale',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        isDark ? Colors.white : kPrimaryColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _getStatusColor(widget.preventivo['stato']),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                          widget.preventivo['stato'])
                                      .withOpacity(0.3),
                                  spreadRadius: 0,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.preventivo['stato'].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Data e info aggiuntive
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.preventivo['data'] != null &&
                                    widget.preventivo['data'].isNotEmpty
                                ? "Richiesto il ${DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.preventivo['data']))}"
                                : 'Nessuna data disponibile',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[400],
                          ),
                        ],
                      ),

                      // Indicatore di priorità (se presente)
                      if (widget.preventivo['priorita'] != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 16,
                              color: _getPriorityColor(
                                  widget.preventivo['priorita']),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Priorità: ${widget.preventivo['priorita']}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(
                                    widget.preventivo['priorita']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "APERTO":
        return const Color(0xFFFF9800); // Orange più moderno
      case "IN LAVORAZIONE":
        return kPrimaryColor;
      case "CONSEGNATO":
        return const Color(0xFF4CAF50); // Verde più moderno
      case "ANNULLATO":
        return const Color(0xFFF44336); // Rosso
      case "IN ATTESA":
        return const Color(0xFF9C27B0); // Viola
      default:
        return const Color(0xFF757575); // Grigio
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case "ALTA":
        return const Color(0xFFF44336);
      case "MEDIA":
        return const Color(0xFFFF9800);
      case "BASSA":
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }
}
