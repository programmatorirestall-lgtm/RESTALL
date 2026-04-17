import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/downloader.dart';
import 'package:restall/helper/dropdowncomntainer.dart';
import 'package:restall/models/TicketList.dart';
import 'package:restall/test.dart';

class TicketDescription extends StatelessWidget {
  const TicketDescription({
    Key? key,
    required this.ticket,
    this.pressOnSeeMore,
  }) : super(key: key);

  final Map<String, dynamic> ticket;
  final GestureTapCallback? pressOnSeeMore;

  Color _getStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return Colors.green;
      case "Annullato":
        return Colors.red;
      case "In corso":
        return Colors.blue;
      case "Aperto":
        return Colors.orange;
      case "Sospeso":
        return Colors.grey;
      default:
        return Colors.grey;
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
        return Icons.access_time_filled_rounded;
      case "Sospeso":
        return Icons.pause_circle_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isExpandable = false}) {
    if (isExpandable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReadMoreText(
          value,
          preDataText: "$label: ",
          preDataTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          trimLines: 3,
          trimCollapsedText: "\nMostra altro",
          trimExpandedText: "\nMostra meno",
          colorClickableText: appBarColor,
          trimMode: TrimMode.Line,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tech = ticket['id_tecnico'] != null
        ? "Tecnico assegnato"
        : "Tecnico non assegnato";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header con stato e numero ticket
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(ticket['stato']),
                    _getStatusColor(ticket['stato']).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(ticket['stato']).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(ticket['stato']),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ticket #${ticket['id']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            ticket['stato'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sezione Dettagli
            _buildSectionCard(
              title: "Dettagli",
              icon: Icons.engineering_rounded,
              children: [
                _buildInfoRow("Tecnico", tech),
                if (ticket['id_tecnico'] != null) ...[
                  _buildInfoRow(
                    "Data Prevista",
                    DateFormat("dd/MM/yyyy", "it_IT")
                        .format(DateTime.parse(ticket['oraPrevista'])),
                  ),
                  _buildInfoRow(
                    "Ora Prevista",
                    DateFormat('HH:mm')
                        .format(DateTime.parse(ticket['oraPrevista'])),
                  ),
                ],
              ],
            ),

            // Sezione Info Personali
            _buildSectionCard(
              title: "Info Personali",
              icon: Icons.person_rounded,
              children: [
                _buildInfoRow("Indirizzo", ticket['indirizzo'],
                    isExpandable: true),
              ],
            ),

            // Sezione Info Macchina
            _buildSectionCard(
              title: "Info Macchina",
              icon: Icons.precision_manufacturing_rounded,
              children: [
                _buildInfoRow("Tipo", ticket['tipo_macchina'],
                    isExpandable: true),
                _buildInfoRow("Stato", ticket['stato_macchina'],
                    isExpandable: true),
              ],
            ),

            // Sezione Descrizione
            _buildSectionCard(
              title: "Descrizione",
              icon: Icons.description_rounded,
              children: [
                ReadMoreText(
                  ticket['descrizione'],
                  trimLines: 4,
                  trimCollapsedText: "\nMostra altro",
                  trimExpandedText: "\nMostra meno",
                  colorClickableText: appBarColor,
                  trimMode: TrimMode.Line,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),

            // Sezione Download
            _buildSectionCard(
              title: "Download",
              icon: Icons.download_rounded,
              children: [
                DropDownContainer(data: ticket),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
