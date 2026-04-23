import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:restalltech/API/Preventivi/preventiviApi.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/downloader.dart';
import 'package:url_launcher/url_launcher.dart';

class PreventivoDetailScreen extends StatefulWidget {
  final int idPreventivo;

  const PreventivoDetailScreen({Key? key, required this.idPreventivo})
      : super(key: key);

  @override
  State<PreventivoDetailScreen> createState() => _PreventivoDetailScreenState();
}

class _PreventivoDetailScreenState extends State<PreventivoDetailScreen> {
  Map<String, dynamic>? preventivo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDettaglio();
  }

  Future<void> fetchDettaglio() async {
    final response = await PreventiviApi().getDetails(widget.idPreventivo);
    var body = jsonDecode(response.body);
    setState(() {
      preventivo = body;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLightColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: secondaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Dettaglio Preventivo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: secondaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Caricamento...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          : preventivo == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "Nessun dato trovato",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : body(context),
    );
  }

  body(BuildContext context) {
    final stato = (preventivo?['stato'] ?? '').toString().toUpperCase();
    final allegati =
        List<Map<String, dynamic>>.from(preventivo?['allegati'] ?? []);

    return Container(
      color: kPrimaryLightColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(thickness: 1, color: Colors.grey[200]),
                    ),
                    _buildDetails(),
                    if (allegati.isNotEmpty) ...[
                      SizedBox(height: 20),
                      _buildAllegatiList(allegati),
                    ],
                    SizedBox(height: 20),
                    _buildStatoSection(stato),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stato = (preventivo?['stato'] ?? '').toString().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description, color: secondaryColor, size: 28),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Preventivo #${preventivo?['id'] ?? 'N/D'}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    preventivo?['data'] != null &&
                            preventivo!['data'].toString().isNotEmpty
                        ? "Richiesto il ${DateFormat('dd/MM/yyyy').format(DateTime.parse(preventivo!['data']))}"
                        : 'Nessuna data disponibile',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(stato),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatoIconSmall(stato),
              SizedBox(width: 8),
              Text(
                stato,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getStatoIconSmall(String stato) {
    IconData icon;
    switch (stato) {
      case "APERTO":
        icon = Icons.access_time;
        break;
      case "IN LAVORAZIONE":
        icon = Icons.settings;
        break;
      case "CONSEGNATO":
        icon = Icons.check_circle;
        break;
      case "RIFIUTATO":
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.help_outline;
    }
    return Icon(icon, color: Colors.white, size: 16);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "APERTO":
        return Color(0xFFFF9800);
      case "IN LAVORAZIONE":
        return secondaryColor;
      case "CONSEGNATO":
        return Color(0xFF4CAF50);
      case "RIFIUTATO":
      case "ANNULLATO":
        return Color(0xFFF44336);
      default:
        return Color(0xFF757575);
    }
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_rounded, color: secondaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              "Informazioni Cliente",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _infoRow(
          "Ragione Sociale",
          preventivo?['ragSocialeAzienda'] ?? "Non disponibile",
          Icons.business,
        ),
        _infoRow(
          "Cellulare",
          preventivo?['numCellulare'] ?? "Non disponibile",
          Icons.phone,
        ),
        if (preventivo?['descrizione'] != null &&
            preventivo!['descrizione'].toString().trim().isNotEmpty)
          _infoRow(
            "Descrizione",
            preventivo!['descrizione'],
            Icons.description_outlined,
          ),
      ],
    );
  }

  Future<void> _downloadFile(url) async {
    DownloadService downloadService;
    if (kIsWeb) {
      downloadService = WebDownloadService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      downloadService = MobileDownloadService();
    } else {
      downloadService = DesktopDownloadService();
    }
    await downloadService.download(url: url);
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: secondaryColor, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: appBarColor,
                  ),
                  maxLines: label == "Descrizione" ? 5 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatoSection(String stato) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Stato: $stato",
        //     style: TextStyle(
        //         fontWeight: FontWeight.bold,
        //         fontSize: 18,
        //         color: kPrimaryColor)),
        const SizedBox(height: 8),
        if (stato == "APERTO") _buildAzioneAperto(),
        if (stato == "IN LAVORAZIONE") _buildAzioneInLavorazione(),
        if (stato == "CONSEGNATO" || stato == "RIFIUTATO") _buildChiuso(),
      ],
    );
  }

  void _rifiutaPreventivo() async {
    TextEditingController motivoController = TextEditingController();

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rifiuta Preventivo',
          style: TextStyle(
            color: secondaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inserisci il motivo del rifiuto:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: motivoController,
              cursorColor: secondaryColor,
              maxLength: 255,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Motivazione obbligatoria...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: secondaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: TextButton.styleFrom(foregroundColor: secondaryColor),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              var i = await rifiutaPreventivo(motivoController.text);
              if (i == 200) {
                Navigator.of(context).pop(motivoController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: Text('Rifiuta'),
          ),
        ],
      ),
    );
  }

  rifiutaPreventivo(String? conferma) async {
    if (conferma != null && conferma.isNotEmpty) {
      final response =
          await PreventiviApi().rifiutaPreventivo(preventivo?['id'], conferma);
      if (response == 200) {
        _showAlert('Successo', 'Il preventivo è stato rifiutato.');

        fetchDettaglio();
        return 200;
      } else {
        _showAlert('Errore', 'Si è verificato un errore durante il rifiuto.');
      }
    }
  }

  _buildChiuso() {
    if (preventivo?['urlDoc'] != null && preventivo!['urlDoc'].isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preventivo Consegnato: ",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor),
            ),
            TextButton.icon(
              icon: Icon(Icons.picture_as_pdf, color: kPrimaryColor),
              label: Text("Documento Preventivo"),
              onPressed: () async => await _downloadFile(preventivo?['urlDoc']),
            ),
          ],
        ),
      );
    } else {
      return Text("Nessun preventivo conseganto");
    }
  }

  Widget _buildAzioneAperto() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Flexible(
              flex: 4,
              child: ElevatedButton.icon(
                onPressed: _avviaPreventivo,
                icon: Icon(
                  Icons.start,
                  color: white,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                label: Text(
                  "Avvia Preventivo",
                  style: TextStyle(color: white),
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Flexible(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _rifiutaPreventivo,
                icon: Icon(
                  Icons.cancel,
                  color: white,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label:
                    Text("Rifiuta Preventivo", style: TextStyle(color: white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAzioneInLavorazione() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (preventivo?['urlDoc'] != null &&
            preventivo!['urlDoc'].toString().isNotEmpty) ...[
          Text(
            "È già stato caricato un file:",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: secondaryColor),
          ),
          ListTile(
            leading: Icon(Icons.file_present, color: kPrimaryColor),
            title: Text('File caricato'),
            onTap: () => _downloadFile(preventivo?['urlDoc']),
          ),
          Text(
            "Caricando un nuovo file, il precedente verrà sovrascritto.",
            style:
                TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: !_isLoading
                ? () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await _caricaFile();
                  }
                : null,
            icon: _isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Icon(Icons.upload_file),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            label: Text("Carica Nuovo File"),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Flexible(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: _confermaConsegnaPreventivo,
                  icon: Icon(Icons.check_circle_outline),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  label: Text("Consegna Preventivo"),
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Flexible(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: _rifiutaPreventivo,
                  icon: Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: Text("Rifiuta Preventivo"),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _confermaConsegnaPreventivo() async {
    final conferma = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Consegna Preventivo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: secondaryColor,
          ),
        ),
        content: Text(
          'Sei sicuro di voler consegnare questo preventivo?\nQuesta azione è irreversibile.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: secondaryColor),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Conferma'),
          ),
        ],
      ),
    );

    if (conferma == true) {
      final response =
          await PreventiviApi().changeStatusPreventivo(preventivo?['id']);
      if (response == 200) {
        _showAlert('Successo', 'Il preventivo è stato consegnato.');
        fetchDettaglio();
      } else {
        _showAlert('Errore', 'Si è verificato un errore durante la consegna.');
      }
    }
  }

  Widget _buildAllegatiList(List<Map<String, dynamic>> allegati) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, color: secondaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              "Allegati",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        ...allegati.map((allegato) {
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.attach_file, color: secondaryColor, size: 20),
              ),
              title: Text(
                "Allegato #${allegato['id'] ?? 'N/D'}",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new, color: secondaryColor),
                onPressed: () {
                  if (allegato['url'] != null) {
                    launchUrl(Uri.parse(allegato['url']));
                  }
                },
              ),
              onTap: () {
                if (allegato['url'] != null) {
                  launchUrl(Uri.parse(allegato['url']));
                }
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _getStatoIcon(String? stato) {
    switch (stato?.toUpperCase()) {
      case "APERTO":
        return Icon(Icons.access_time_filled_rounded,
            color: Colors.yellow, size: 50);
      case "IN LAVORAZIONE":
        return Icon(Icons.settings_rounded, color: Colors.grey, size: 50);
      case "CONSEGNATO":
        return Icon(Icons.check_circle_rounded, color: Colors.green, size: 50);
      case "RIFIUTATO":
        return Icon(Icons.cancel_rounded, color: Colors.red, size: 50);
      default:
        return Icon(Icons.help_outline, color: Colors.red, size: 50);
    }
  }

  Future<void> _avviaPreventivo() async {
    final response =
        await PreventiviApi().changeStatusPreventivo(preventivo?['id']);
    _showAlert(
        response == 200 ? 'Preventivo avviato' : 'Errore',
        response == 200
            ? 'Preventivo avviato con successo.'
            : 'Errore durante l\'avvio.');
    fetchDettaglio();
  }

  Future<void> _caricaFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      PlatformFile file = result.files.first;
      print('Path: ${file.path}');
      print('Nome: ${file.name}');
      print('Estensione: ${file.extension}');
      print('Dimensione: ${file.size}');

      var response = await PreventiviApi()
          .uploadPreventivo(file: file, preventivo: preventivo);
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Successo',
          text: 'Il file è stato caricato.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Il file non è stato caricato corrttamente.',
          text: 'In caso di problemi contatta lo sviluppatore.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String title, String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: title,
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.information,
    );
  }
}
