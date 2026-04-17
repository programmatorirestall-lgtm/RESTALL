import 'package:flutter/material.dart';
import 'package:restalltech/Screens/details/details_screen.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/TicketList.dart';

class TicketCard extends StatefulWidget {
  const TicketCard({super.key, required this.ticket});
  final Ticket ticket;

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  Color _getStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return Colors.green;
      case "In corso":
        return Colors.grey;
      case "Aperto":
        return Colors.yellow[700]!;
      case "Sospeso":
        return Colors.red;
      default:
        return Colors.grey[600]!;
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

  Color _getMachineTypeColor(String type) {
    switch (type) {
      case "Climatizzazione":
        return Color(0xFF00BCD4);
      case "Aspirazione":
        return Color(0xFF607D8B);
      case "Caldo":
        return Color(0xFFFF5722);
      case "Freddo":
        return Color(0xFF2196F3);
      case "Altro":
        return Color(0xFF6C63FF);
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getMachineTypeIcon(String type) {
    switch (type) {
      case "Climatizzazione":
        return Icons.thermostat;
      case "Aspirazione":
        return Icons.air;
      case "Caldo":
        return Icons.local_fire_department;
      case "Freddo":
        return Icons.ac_unit;
      case "Altro":
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.ticket.stateT ?? 'N/D';
    final statusColor = _getStatusColor(status);
    final nomeCompleto = widget.ticket.ragSoc;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(ticket: widget.ticket),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Header con status
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.15),
                      statusColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome cliente prominente
                          Text(
                            nomeCompleto,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          // Numero ticket e stato
                          Row(
                            children: [
                              Text(
                                'Ticket #${widget.ticket.id ?? 'N/D'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenuto
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonna sinistra
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Data e ora apertura
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.blue[700]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aperto il: ${_getAperturaDateTime()}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Stato macchina
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.ticket.stateM?.trim().isNotEmpty ==
                                          true
                                      ? widget.ticket.stateM!
                                      : 'N/D',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider verticale
                    Container(
                      width: 1,
                      height: 60,
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.grey[300],
                    ),

                    // Colonna destra
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo macchina
                          Row(
                            children: [
                              Icon(
                                  _getMachineTypeIcon(
                                      widget.ticket.typeM ?? ''),
                                  size: 16,
                                  color: _getMachineTypeColor(
                                      widget.ticket.typeM ?? '')),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.ticket.typeM?.trim().isNotEmpty == true
                                      ? widget.ticket.typeM!.toUpperCase()
                                      : 'N/D',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _getMachineTypeColor(
                                        widget.ticket.typeM ?? ''),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Intervento programmato
                          if (widget.ticket.oraPrevista != null &&
                              widget.ticket.oraPrevista!.trim().isNotEmpty) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event_available_rounded,
                                          size: 14, color: Colors.green[700]),
                                      SizedBox(width: 6),
                                      Text(
                                        'Previsto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDateTimeString(
                                        widget.ticket.oraPrevista!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTimeString(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getAperturaDateTime() {
    if (widget.ticket.createdAt != null) {
      final dt = widget.ticket.createdAt!;
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (widget.ticket.data.isNotEmpty) {
      return widget.ticket.data;
    }
    return 'N/D';
  }
}
