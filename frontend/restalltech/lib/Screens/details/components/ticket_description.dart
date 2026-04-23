import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:restalltech/Screens/DTT/dtt.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/downloader.dart';

class TicketDescription extends StatelessWidget {
  const TicketDescription({
    Key? key,
    required this.ticket,
    this.pressOnSeeMore,
  }) : super(key: key);

  final Map<String, dynamic> ticket;

  final GestureTapCallback? pressOnSeeMore;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'chiuso':
        return Colors.green;
      case 'in corso':
        return Colors.grey;
      case 'aperto':
        return Colors.yellow[700]!;
      case 'sospeso':
        return Colors.red;
      default:
        return Colors.grey[600]!;
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'chiuso':
        return Icons.check_circle_rounded;
      case 'in corso':
        return Icons.settings_rounded;
      case 'aperto':
        return Icons.access_time_filled_rounded;
      case 'sospeso':
        return Icons.handyman_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defensive local copies to avoid passing null to Text widgets or calling
    // String methods on null values. If a field is missing/null we fallback to
    // an empty string.
    final String status = (ticket['stato'] ?? '').toString();
    final String id = (ticket['id'] ?? '').toString();
    final String ragSocAzienda = ticket['ragSocAzienda']?.toString() ?? '';
    final String nome = ticket['nome']?.toString() ?? '';
    final String cognome = ticket['cognome']?.toString() ?? '';
    final String indirizzo = ticket['indirizzo']?.toString() ?? '';
    final String rifEsterno = ticket['rifEsterno']?.toString() ?? '';
    final String tipoMacchina = ticket['tipo_macchina']?.toString() ?? '';
    final String statoMacchina = ticket['stato_macchina']?.toString() ?? '';
    final String descrizione = ticket['descrizione']?.toString() ?? '';
    final String numTel = ticket['numTel']?.toString() ?? '';
    final String partiva = ticket['partiva']?.toString() ?? '';
    final String codFisc = ticket['codFisc']?.toString() ?? '';
    final String email = ticket['email']?.toString() ?? '';
    final String data = ticket['data']?.toString() ?? '';
    final String oraPrevista = ticket['oraPrevista']?.toString() ?? '';
    final String matricola = ticket['matricola']?.toString() ?? '';
    final String modello = ticket['modello']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con stato e ID
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status).withValues(alpha: 0.1),
                  Colors.white
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  color: appBarColor,
                  iconSize: 24,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ticket #$id",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return DDTScreen(t: id);
                        },
                      ));
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('DDT', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        // Contenuto principale con cards
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Cliente
              _buildInfoCard(
                title: "Cliente",
                icon: Icons.person_rounded,
                children: [
                  _buildInfoRow(
                    "Anagrafica",
                    ragSocAzienda.isNotEmpty ? ragSocAzienda : "$nome $cognome",
                  ),
                  if (numTel.isNotEmpty)
                    _buildInfoRowWithIcon(
                        "Telefono", numTel, Icons.phone, secondaryColor),
                  if (email.isNotEmpty)
                    _buildInfoRowWithIcon(
                        "Email", email, Icons.email, secondaryColor),
                  if (partiva.isNotEmpty)
                    _buildInfoRow("P.IVA", partiva)
                  else if (codFisc.isNotEmpty)
                    _buildInfoRow("Cod. Fiscale", codFisc),
                  if (indirizzo.isNotEmpty)
                    _buildInfoRowWithIcon("Indirizzo", indirizzo,
                        Icons.location_on, secondaryColor),
                ],
              ),
              const SizedBox(height: 15),

              // Card Macchina
              _buildInfoCard(
                title: "Informazioni Macchina",
                icon: _getMachineTypeIcon(tipoMacchina),
                iconColor: _getMachineTypeColor(tipoMacchina),
                children: [
                  _buildInfoRowWithIcon(
                    "Tipo",
                    tipoMacchina.isNotEmpty
                        ? tipoMacchina.toUpperCase()
                        : 'N/D',
                    _getMachineTypeIcon(tipoMacchina),
                    _getMachineTypeColor(tipoMacchina),
                  ),
                  _buildInfoRow("Stato",
                      statoMacchina.isNotEmpty ? statoMacchina : 'N/D'),
                  if (matricola.isNotEmpty)
                    _buildInfoRowWithIcon(
                        "Matricola", matricola, Icons.tag, secondaryColor),
                  if (modello.isNotEmpty)
                    _buildInfoRowWithIcon(
                        "Modello", modello, Icons.inventory_2, secondaryColor),
                ],
              ),
              const SizedBox(height: 15),

              // Card Date e Riferimenti
              _buildInfoCard(
                title: "Date e Riferimenti",
                icon: Icons.calendar_today,
                iconColor: Colors.blue[700],
                children: [
                  if (data.isNotEmpty)
                    _buildInfoRowWithIcon(
                      "Data Apertura",
                      _formatDate(data),
                      Icons.calendar_today,
                      Colors.blue[700]!,
                    ),
                  if (oraPrevista.isNotEmpty)
                    _buildInfoRowWithIcon(
                      "Intervento Previsto",
                      _formatDate(oraPrevista),
                      Icons.event_available,
                      Colors.green[700]!,
                    ),
                  if (rifEsterno.isNotEmpty)
                    _buildInfoRowWithIcon(
                        "Rif. Esterno", rifEsterno, Icons.tag, secondaryColor),
                ],
              ),
              const SizedBox(height: 15),

              // Card Descrizione
              _buildInfoCard(
                title: "Descrizione",
                icon: Icons.description_rounded,
                children: [
                  const SizedBox(height: 8),
                  ReadMoreText(
                    descrizione.isNotEmpty
                        ? descrizione
                        : "Nessuna descrizione disponibile",
                    trimLines: 3,
                    trimCollapsedText: " Mostra altro",
                    trimExpandedText: " Mostra meno",
                    colorClickableText: kPrimaryColor,
                    trimMode: TrimMode.Line,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: appBarColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Card Documenti
              _buildInfoCard(
                title: "Documenti",
                icon: Icons.download_rounded,
                children: [
                  const SizedBox(height: 8),
                  _buildDocumentsSection(ticket),
                ],
              ),
              const SizedBox(height: 15),

              // Card Stati
              _buildInfoCard(
                title: "Storico Stati",
                icon: Icons.history_rounded,
                iconColor: Colors.purple[700],
                children: [
                  const SizedBox(height: 8),
                  _buildStatusHistorySection(ticket),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        )
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    final color = iconColor ?? secondaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
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

  Widget _buildInfoRowWithIcon(
      String label, String value, IconData icon, Color color) {
    if (value.isEmpty || value == 'N/D') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/D';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: appBarColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic> data) {
    final fogli = data['fogli'] as List<dynamic>?;

    if (fogli == null || fogli.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nessun documento disponibile',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fogli.asMap().entries.map((entry) {
        final index = entry.key;
        final documentMap = entry.value as Map<String, dynamic>;
        final fileKey = documentMap['fileKey']?.toString() ?? '';
        final location = documentMap['location']?.toString() ?? '';

        // Extract filename from fileKey (remove ticket ID prefix and timestamp)
        String fileName = fileKey;
        if (fileKey.isNotEmpty) {
          // Format: "2091_1732971371358.pdf" -> "Documento 1.pdf"
          final parts = fileKey.split('_');
          if (parts.length >= 2) {
            final extension = fileKey.split('.').last;
            fileName = 'Documento ${index + 1}.$extension';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: location.isNotEmpty
                ? () async {
                    // Download document using the download service
                    try {
                      DownloadService downloadService;
                      if (kIsWeb) {
                        downloadService = WebDownloadService();
                      } else if (Platform.isAndroid || Platform.isIOS) {
                        downloadService = MobileDownloadService();
                      } else {
                        downloadService = DesktopDownloadService();
                      }
                      await downloadService.download(url: location);
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error downloading document: $e');
                      }
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 24,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  if (location.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: kPrimaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusHistorySection(Map<String, dynamic> data) {
    final summary = data['summary'] as List<dynamic>?;

    if (summary == null || summary.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nessuno storico disponibile',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summary.asMap().entries.map((entry) {
        final index = entry.key;
        final statusEvent = entry.value as Map<String, dynamic>;
        final evento = statusEvent['evento']?.toString() ?? 'N/D';
        final dataInizio = statusEvent['dataInizio']?.toString() ?? '';
        final dataFine = statusEvent['dataFine']?.toString() ?? '';

        final isLast = index == summary.length - 1;
        final isInProgress = dataFine.isEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isInProgress
                          ? _getStatusColor(evento).withValues(alpha: 0.2)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isInProgress
                            ? _getStatusColor(evento)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(evento),
                      size: 16,
                      color: isInProgress
                          ? _getStatusColor(evento)
                          : Colors.grey[600],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? _getStatusColor(evento).withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        evento.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isInProgress
                              ? _getStatusColor(evento)
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (dataInizio.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Inizio: ${_formatDate(dataInizio)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (dataFine.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.stop_rounded,
                            size: 16,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Fine: ${_formatDate(dataFine)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (isInProgress)
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _getStatusColor(evento),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In corso...',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: _getStatusColor(evento),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
