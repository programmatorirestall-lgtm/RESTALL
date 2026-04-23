import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restall/Screens/details/components/body.dart';
import 'package:restall/Screens/details/details_screen.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/TicketList.dart';

class TicketCard extends StatefulWidget {
  const TicketCard({super.key, required this.ticket});
  final Ticket ticket;

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return const Color(0xFF4CAF50);
      case "Annullato":
        return const Color(0xFFE53E3E);
      case "In corso":
        return const Color(0xFF3182CE);
      case "Aperto":
        return const Color(0xFFECC94B);
      case "Sospeso":
        return const Color(0xFFED8936);
      default:
        return const Color(0xFF718096);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Chiuso":
        return Icons.check_circle_rounded;
      case "Annullato":
        return Icons.cancel_rounded;
      case "In corso":
        return Icons.settings_rounded;
      case "Aperto":
        return Icons.schedule_rounded;
      case "Sospeso":
        return Icons.pause_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(widget.ticket.stateT);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(widget.ticket.stateT),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            widget.ticket.stateT,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF718096),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xFF4A5568),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailsScreen(ticket: widget.ticket),
          ),
        );
      },
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          _controller.forward();
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF7FAFC),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color(0x1A000000)
                      : const Color(0x0D000000),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Accent stripe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getStatusColor(widget.ticket.stateT),
                            _getStatusColor(widget.ticket.stateT)
                                .withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Status Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getStatusColor(widget.ticket.stateT)
                                    .withOpacity(0.1),
                                _getStatusColor(widget.ticket.stateT)
                                    .withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(widget.ticket.stateT)
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            _getStatusIcon(widget.ticket.stateT),
                            color: _getStatusColor(widget.ticket.stateT),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row with ID and status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${widget.ticket.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Color(0xFF1A202C),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  _buildStatusBadge(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Info rows
                              _buildInfoRow(
                                'Tipo:',
                                widget.ticket.typeM,
                                Icons.precision_manufacturing_rounded,
                              ),
                              _buildInfoRow(
                                'Stato:',
                                widget.ticket.stateM,
                                Icons.info_outline_rounded,
                              ),
                              _buildInfoRow(
                                'Data:',
                                widget.ticket.data,
                                Icons.calendar_today_rounded,
                              ),
                            ],
                          ),
                        ),
                        // Arrow indicator
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
