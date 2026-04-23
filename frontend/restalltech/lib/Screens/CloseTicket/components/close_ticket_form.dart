import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/services/company_cache_service.dart';

import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/WareHouse/wareHouseApi.dart';
import 'package:restalltech/Screens/myTickets/components/my_ticket.dart';
import 'package:restalltech/Screens/myTickets/my_ticket_screen.dart';
import 'package:restalltech/Screens/ticket_success/ticket_success_screen.dart';

import 'package:restalltech/constants.dart';
import 'package:intl/intl.dart';
import 'package:restalltech/helper/keyboard.dart';
import 'package:restalltech/helper/draft_manager.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:restalltech/models/invoice.dart';
import 'package:search_choices/search_choices.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:restalltech/helper/barcodescanner.dart';

class CloseTicketForm extends StatefulWidget {
  const CloseTicketForm({super.key, required this.ticket});
  final Map<String, dynamic> ticket;
  @override
  State<CloseTicketForm> createState() => CloseTicketFormState();
}

class CloseTicketFormState extends State<CloseTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  TextEditingController _placeController = TextEditingController();
  TextEditingController _placeBillController = TextEditingController();
  final TextEditingController _pivaController = TextEditingController();
  final TextEditingController _codUnivocoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _numTelController = TextEditingController();
  final List<TextEditingController> _prezzoController = [];
  final TextEditingController _pzController = TextEditingController();
  final TextEditingController _ragSocController = TextEditingController();
  final TextEditingController _trasfertaController = TextEditingController();
  final TextEditingController _manodoperaController = TextEditingController();
  final TextEditingController _costoChiamataController =
      TextEditingController();
  final TextEditingController _externalTicketController =
      TextEditingController();
  final TextEditingController _signerController = TextEditingController();
  final TextEditingController _supplementoController = TextEditingController();
  String? _selectedPaymentOption;
  String? _iva = "22";
  String? _typeIntervention;
  var _isLoading = false;
  List<String> pzRicambi = [];
  List<Map<String, dynamic>> orderInfo =
      List<Map<String, dynamic>>.empty(growable: true);
  List<Map<String, dynamic>> datiMacchina =
      List<Map<String, dynamic>>.empty(growable: true);
  List<String> operatori = [];
  List<int> quantita = [];
  var _optionsAnagrafica = [];
  var _optionsRicambi = [];
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestionsAnagrafica = [];
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestionsRicambi = [];
  List<Technician> techList = [];
  bool cU = false;
  var _isOptionsAnagraficaLoading = true;
  var _isOptionsRicambiLoading = true;
  Map<String, dynamic>? _selectedCompany;
  bool _submitted = false;
  final CompanyCacheService _cacheService = CompanyCacheService();
  String? _vansValue;
  String scannedCode = '';
  List<String> _errori = [];
  int _id = -1;
  int costiOperatori = 0;
  int totManodopera = 0;
  int costoChiamata = 0;
  int costoTrasferta = 0;

  @override
  void initState() {
    super.initState();
    _getTech();
    getAnagrafica('');
    getRicambi('');
    _checkForDraft();
  }

  // Controlla se esiste una bozza salvata
  void _checkForDraft() async {
    final draft = await DraftManager.getCloseDraft(widget.ticket['id']);
    if (draft != null && mounted) {
      _showDraftDialog(draft);
    }
  }

  // Mostra dialog per recuperare la bozza
  void _showDraftDialog(Map<String, dynamic> draft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.drafts, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bozza trovata'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('È stata trovata una bozza non completata per questo ticket.'),
            SizedBox(height: 8),
            Text(
              'Salvata il: ${_formatDateTime(draft['timestamp'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              DraftManager.deleteCloseDraft(widget.ticket['id']);
              Navigator.pop(context);
            },
            child: Text('Elimina'),
          ),
          ElevatedButton(
            onPressed: () {
              _loadDraft(draft);
              Navigator.pop(context);
            },
            child: Text('Recupera'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String timestamp) {
    final dt = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  // Carica la bozza salvata
  void _loadDraft(Map<String, dynamic> draft) {
    setState(() {
      if (draft['ragSoc'] != null) _ragSocController.text = draft['ragSoc'];
      if (draft['city'] != null) _cityController.text = draft['city'];
      if (draft['place'] != null) _placeController.text = draft['place'];
      if (draft['placeBill'] != null) _placeBillController.text = draft['placeBill'];
      if (draft['piva'] != null) _pivaController.text = draft['piva'];
      if (draft['codUnivoco'] != null) _codUnivocoController.text = draft['codUnivoco'];
      if (draft['numTel'] != null) _numTelController.text = draft['numTel'];
      if (draft['description'] != null) _descriptionController.text = draft['description'];
      if (draft['externalTicket'] != null) _externalTicketController.text = draft['externalTicket'];
      if (draft['signer'] != null) _signerController.text = draft['signer'];
      if (draft['supplemento'] != null) _supplementoController.text = draft['supplemento'];
      if (draft['trasferta'] != null) _trasfertaController.text = draft['trasferta'];
      if (draft['manodopera'] != null) _manodoperaController.text = draft['manodopera'];
      if (draft['costoChiamata'] != null) _costoChiamataController.text = draft['costoChiamata'];
      if (draft['paymentOption'] != null) _selectedPaymentOption = draft['paymentOption'];
      if (draft['iva'] != null) _iva = draft['iva'];
      if (draft['typeIntervention'] != null) _typeIntervention = draft['typeIntervention'];
      if (draft['orderInfo'] != null) {
        orderInfo = List<Map<String, dynamic>>.from(draft['orderInfo']);
      }
      if (draft['datiMacchina'] != null) {
        datiMacchina = List<Map<String, dynamic>>.from(draft['datiMacchina']);
      }
      if (draft['operatori'] != null) {
        operatori = List<String>.from(draft['operatori']);
      }
    });
  }

  // Salva la bozza
  void _saveDraft() async {
    final draftData = {
      'ragSoc': _ragSocController.text,
      'city': _cityController.text,
      'place': _placeController.text,
      'placeBill': _placeBillController.text,
      'piva': _pivaController.text,
      'codUnivoco': _codUnivocoController.text,
      'numTel': _numTelController.text,
      'description': _descriptionController.text,
      'externalTicket': _externalTicketController.text,
      'signer': _signerController.text,
      'supplemento': _supplementoController.text,
      'trasferta': _trasfertaController.text,
      'manodopera': _manodoperaController.text,
      'costoChiamata': _costoChiamataController.text,
      'paymentOption': _selectedPaymentOption,
      'iva': _iva,
      'typeIntervention': _typeIntervention,
      'orderInfo': orderInfo,
      'datiMacchina': datiMacchina,
      'operatori': operatori,
    };
    await DraftManager.saveCloseDraft(widget.ticket['id'], draftData);
  }

  // Valida e mostra errori per dati non conformi
  void _showDataValidationWarning(List<String> errors) {
    if (errors.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dati Anagrafica Non Conformi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I seguenti dati non sono stati inseriti perché non conformi:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                SizedBox(height: 12),
                ...errors.map((error) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Si prega di comunicare questi problemi all\'amministrazione per la correzione dei dati in anagrafica.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Ho Capito', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void getAnagrafica(valore) async {
    setState(() => _isOptionsAnagraficaLoading = true);
    try {
      // Utilizza il servizio di cache invece di chiamare direttamente l'API
      final companies = await _cacheService.getCompanies(valore);

      setState(() {
        _optionsAnagrafica = companies;
        _getAnagraficaSuggestions();
      });
    } catch (error) {
      print(error);
    } finally {
      if (mounted) setState(() => _isOptionsAnagraficaLoading = false);
    }
  }

  void getRicambi(valore) async {
    setState(() => _isOptionsRicambiLoading = true);
    try {
      var response = await WareHouseApi().getValue(valore);

      //print("RICAMBI ${response.statusCode}");
      if (response.statusCode == 200) {
        final suggestions = json.decode(response.body);

        List<Map<String, dynamic>> mergedList = [];
        for (var articolo in suggestions) {
          mergedList.add({
            'codArticolo': articolo['codArticolo'],
            'giacenza': articolo['giacenza'],
            'prezzoFornitore': articolo['prezzoFornitore'],
            'descrizione': articolo['descrizione'],
            'sconto1': articolo['sconto1'],
            'sconto2': articolo['sconto2'],
            'sconto3': articolo['sconto3'],
            'codeAn': articolo['codeAn'],
          });
        }
        //print("suggestions: $suggestions");
        setState(() {
          _optionsRicambi = mergedList;
          _getRicambiSuggestions();
          //print(_options); // Limita a 4 suggerimenti
        });
      } else {
        throw Exception('Errore durante la richiesta al server');
      }
    } catch (error) {
      print(error);
    } finally {
      if (mounted) setState(() => _isOptionsRicambiLoading = false);
    }
  }

  getRicambio(code) async {
    final Response response = await WareHouseApi().getArticle(code);
    final List<dynamic> article = json.decode(response.body);
    if (response.statusCode == 200 && article.isNotEmpty) {
      print(response.body);
      return article[0];
    } else {
      return null;
    }
  }

  void _addProduct() {
    setState(() {
      pzRicambi.add('');
      quantita.add(0);
      _prezzoController.add(TextEditingController());
      orderInfo.add({
        'ricambiForniti': '',
        'numeroPezziRicambio': 0,
        'prezzo': 0.00,
        'provenienza': ''
      });

      print(orderInfo);
    });
  }

  void _addProductBarcode(nomeRicambi, prezzo) {
    bool exists =
        orderInfo.any((item) => item['ricambiForniti'] == nomeRicambi);

    if (exists) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Ricambio già presente',
        text: 'Il ricambio $nomeRicambi è già stato aggiunto.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.warning,
      );
    } else {
      setState(() {
        pzRicambi.add(nomeRicambi);
        quantita.add(0);
        _prezzoController.add(TextEditingController());
        orderInfo.add({
          'ricambiForniti': nomeRicambi,
          'numeroPezziRicambio': 0,
          'prezzo': prezzo,
          'provenienza': ''
        });

        print(orderInfo);
      });
    }
  }

  void _addMachine() {
    if (datiMacchina.length < 1) {
      setState(() {
        datiMacchina.add({
          'marca': '',
          'modello': '',
          'matricola': '',
          'tipo': '',
          'statoFineLavoro': ''
        });
        print(datiMacchina);
      });
    }
  }

  void _addOperatore() {
    setState(() {
      operatori.add('');
      print(operatori);
    });
  }

  void _removeOperatore(int index) {
    setState(() {
      operatori.removeAt(index);
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _prezzoController.removeAt(index);
      pzRicambi.removeAt(index);
      quantita.removeAt(index);
      orderInfo.removeAt(index);
    });
  }

  void _removeMachine(int index) {
    setState(() {
      datiMacchina.removeAt(index);
    });
  }

  void _onSubmit(ticket) {
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      print("Tipo intervento: $_typeIntervention");
      if (_typeIntervention != "Garanzia" &&
          _typeIntervention != "Manutenzione") {
        _preview(widget.ticket);
      } else {
        setState(() {
          costiOperatori = 0;
          totManodopera = 0;
          costoChiamata = 0;
          costoTrasferta = 0;
        });

        _showSummaryDialog();
      }
    } else {
      setState(() => _isLoading = false);
      // if (errori.isNotEmpty) {
      //   setState(() {
      //     _isLoading = false;
      //     _errori = errori;
      //   });
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Mancano dei campi obbligatori',
        text: 'Controlla i campi obbligatori e riprova',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.warning,
      );
      //}
    }
  }

  sign() async {
    var location = await Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new Sign(context),
          fullscreenDialog: true,
        ));
    return location;
  }

  Future<void> _getTech() async {
    var decodedToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt') as String;
      if (token != null) {
        if (token.isNotEmpty) {
          decodedToken = Jwt.parseJwt(token);
        } else {
          throw Exception('Token is empty');
        }
      }
      final Response response = await TechApi().getData();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        Iterable ticketList = body['tecnico'];
        List<Technician> techs = List<Technician>.from(
            ticketList.map((model) => Technician.fromJson(model)));
        techs.removeWhere((item) => (item.verified == "FALSE" ||
            item.id.toString() == decodedToken['id'].toString()));

        setState(() {
          techList = techs;
        });
      } else {
        throw Exception('Errore durante la richiesta al server');
      }
    } on Exception catch (error) {
      print(error);
    }
  }

  void _showSummaryDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Riepilogo dei dati",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: kPrimaryColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildSummaryRows([
                  {"Costo Operatori": "€$costiOperatori"},
                  {
                    if (_typeIntervention == 'Manutenzione')
                      "Totale Manodopera":
                          "€${_parseDecimal(_supplementoController.text).toInt()}"
                    else
                      "Totale Manodopera": "€${totManodopera}"
                  },
                  {"Costo Chiamata": "€$costoChiamata"},
                  {"Costo Trasferta": "€$costoTrasferta"},
                  {"Costo Ricambi": "€${costoRicambi()}"},
                  {"Imponibile": "€${imponibile()}"},
                  {
                    "Totale":
                        "€${imponibile() * _parseDecimal(_iva!).toInt() / 100 + imponibile()}"
                  },
                ]),
                SizedBox(height: 16),
                Divider(),
                ..._buildSummaryRows([
                  {"Rif. Esterno": _externalTicketController.text},
                  {"Ragione Sociale": _ragSocController.text},
                  {"Città": _cityController.text},
                  {"Indirizzo Intervento": _placeController.text},
                  {"Indirizzo Fatturazione": _placeBillController.text},
                  {"P. IVA/CF": _pivaController.text},
                  {"Cod. Univoco": _codUnivocoController.text},
                  {"Cellulare": _numTelController.text},
                  {"Descrizione Lavoro": _descriptionController.text},
                  {"Firmatario": _signerController.text},
                  {
                    "Metodo di Pagamento":
                        _selectedPaymentOption ?? "Non specificato"
                  },
                  {"IVA": _iva ?? "Non specificato"},
                  {
                    "Modalità Intervento":
                        _typeIntervention ?? "Non specificato"
                  },
                ]),
                if (datiMacchina.isNotEmpty) SizedBox(height: 16),
                if (datiMacchina.isNotEmpty) Divider(),
                if (datiMacchina.isNotEmpty)
                  _buildDetailedListSummary(
                    "Macchine",
                    datiMacchina,
                    [
                      "marca",
                      "modello",
                      "matricola",
                      "tipo",
                      "statoFineLavoro"
                    ],
                  ),
                SizedBox(height: 16),
                if (orderInfo.isNotEmpty) Divider(),
                if (orderInfo.isNotEmpty)
                  _buildDetailedListSummary(
                    "Ricambi",
                    orderInfo,
                    ["ricambiForniti", "numeroPezziRicambio", "prezzo"],
                  ),
                SizedBox(height: 16),
                if (operatori.isNotEmpty) Divider(),
                if (operatori.isNotEmpty)
                  _buildOperatorSummary("Altri Operatori", operatori),
              ],
            ),
          ),
          actions: [
            TextButton(
                child: Text("Modifica"),
                onPressed: () {
                  setState(() => _isLoading = false);
                  Navigator.of(context).pop();
                }),
            TextButton(
              child: Text("Conferma"),
              onPressed: () {
                Navigator.of(context).pop();
                _closeTicket(widget.ticket);
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function to parse numbers with both comma and dot as decimal separators
  double _parseDecimal(String value) {
    if (value.isEmpty) return 0.0;
    // Replace comma with dot for decimal parsing
    String normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  int costoRicambi() {
    return orderInfo.fold(
      0,
      (prev, item) =>
          prev +
          (_parseDecimal(item['prezzo'].toString()).toInt() *
              _parseDecimal(item['numeroPezziRicambio'].toString()).toInt()),
    );
  }

  num imponibile() {
    if (_typeIntervention == 'Garanzia') {
      return 0;
    } else if (_typeIntervention == 'Manutenzione') {
      return _parseDecimal(_supplementoController.text).toInt() + costoRicambi();
    } else {
      return (totManodopera + costoChiamata + costoTrasferta + costoRicambi());
    }
  }

  Widget _buildOperatorSummary(String title, List operatorIds) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: 8),
          ...operatorIds.map((id) {
            final name = _getOperatorNameById(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(name ?? "Operatore sconosciuto (ID: $id)"),
            );
          }).toList(),
        ],
      ),
    );
  }

  String? _getOperatorNameById(id) {
    final operator = techList.firstWhere(
      (tech) => tech.id.toString() == id.toString(),
      orElse: () => const Technician(
        id: -1,
        nome: '',
        cognome: '',
        verified: 'FALSE',
      ),
    );
    return operator.id != -1 ? "${operator.nome} ${operator.cognome}" : null;
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              "$title:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSummaryRows(List<Map<String, String>> rows) {
    return rows
        .map((row) => _buildSummaryRow(row.keys.first, row.values.first))
        .toList();
  }

  Widget _buildDetailedListSummary(
    String title,
    List<dynamic> items,
    List<String> keys,
  ) {
    final Map<String, String> keyLabels = {
      "marca": "Marca",
      "modello": "Modello",
      "matricola": "Matricola",
      "tipo": "Tipo",
      "statoFineLavoro": "Stato Fine Lavoro",
      "ricambiForniti": "Ricambi Forniti",
      "numeroPezziRicambio": "Numero Pezzi Ricambio",
      "prezzo": "Prezzo",
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: 16),
          ...items.map((item) {
            if (item is Map<String, dynamic>) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: keys.map((key) {
                        final label = keyLabels[key] ?? key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "$label:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "${item[key] ?? "N/A"}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  item.toString(),
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      "$title:",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    );
  }

  _preview(Map<String, dynamic> ticket) async {
    try {
      var data = {
        'indirizzo': _placeController.text,
        'operatori': operatori,
      };

      print(data);
      Response response = await TicketApi().previewTicket(data, ticket['id']);
      CircularProgressIndicator(color: secondaryColor);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        costiOperatori = body['costiOperatori'];
        totManodopera = body['totManodopera'];
        costoChiamata = body['costoChiamata'];
        costoTrasferta = body['costoTrasferta'];
        _showSummaryDialog();
      } else {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Si è verificato un errore',
          text: 'Non è stato possibile generare il riepilogo',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
        setState(() => _isLoading = false);
      }
    } on SocketException catch (e) {
      print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nella generazione del riepilogo",
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
      setState(() => _isLoading = false);
    }
  }

  _closeTicket(Map<String, dynamic> ticket) async {
    final location = await sign();
    try {
      var data = {
        'ragioneSociale': _ragSocController.text,
        'indirizzo': _placeController.text,
        'indirizzoFatturazione': _placeBillController.text,
        'citta': _cityController.text,
        'descrLavoro': _descriptionController.text,
        'numTel': _numTelController.text,
        'piva': _pivaController.text,
        'orderInfo': orderInfo,
        'firma': location,
        'ticketEsterno': _externalTicketController.text,
        'metodoPagamento': _selectedPaymentOption,
        'datiMacchina': datiMacchina,
        'infoIntervento': _typeIntervention,
        //'costoTrasferta': _trasfertaController.text.replaceFirst(RegExp(','), '.'),
        //'tot': _manodoperaController.text.replaceFirst(RegExp(','), '.'),
        'operatori': operatori,
        //'costoChiamata':_costoChiamataController.text.replaceFirst(RegExp(','), '.'),
        'iva': _iva,
        'codUnivoco': _codUnivocoController.text,
        'rifFurgone': _vansValue.toString(),
        'ragSocialeFirmatario': _signerController.text,
        'supplemento': _supplementoController.text,
      };

      print(data);
      int status = await TicketApi().closeTicket(data, ticket['id']);

      CircularProgressIndicator(color: secondaryColor);
      if (status == 200) {
        // Elimina la bozza dopo la chiusura con successo
        await DraftManager.deleteCloseDraft(ticket['id']);

        // ignore: use_build_context_synchronously
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Ticket chiuso',
          text: 'Il ticket è stato correttamente chiuso',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.exclamation,
        );
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return const MyTicketScreen();
          },
        ), ModalRoute.withName("/tickets"));
      } else {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Si è verificato un errore',
          text: 'Il ticket non è stato correttamente chiuso',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
        setState(() => _isLoading = false);

        // pzRicambi = [];
        // quantita = [];
        // orderInfo = List<Map<String, dynamic>>.empty(growable: true);
        // datiMacchina = List<Map<String, dynamic>>.empty(growable: true);
        // operatori = [];
      }
    } on SocketException catch (e) {
      print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nella chiusura del ticket",
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-complete form fields from ticket data
    if (widget.ticket['ragSocAzienda'] != null &&
        widget.ticket['ragSocAzienda'].toString().isNotEmpty &&
        _ragSocController.text.isEmpty) {
      _ragSocController.text = widget.ticket['ragSocAzienda'];
    }
    if (widget.ticket['indirizzo'] != null &&
        widget.ticket['indirizzo'].toString().isNotEmpty &&
        _placeController.text.isEmpty) {
      _placeController.text = widget.ticket['indirizzo'];
    }
    if (widget.ticket['indirizzoFatturazione'] != null &&
        widget.ticket['indirizzoFatturazione'].toString().isNotEmpty &&
        _placeBillController.text.isEmpty) {
      _placeBillController.text = widget.ticket['indirizzoFatturazione'];
    }
    if (widget.ticket['citta'] != null &&
        widget.ticket['citta'].toString().isNotEmpty &&
        _cityController.text.isEmpty) {
      _cityController.text = widget.ticket['citta'];
    }
    if (widget.ticket['rifEsterno'] != null &&
        widget.ticket['rifEsterno'].toString().isNotEmpty &&
        _externalTicketController.text.isEmpty) {
      _externalTicketController.text = widget.ticket['rifEsterno'];
    }
    if (widget.ticket['numTel'] != null &&
        widget.ticket['numTel'].toString().isNotEmpty &&
        _numTelController.text.isEmpty) {
      _numTelController.text = widget.ticket['numTel'];
    }
    // Validazione e caricamento P.IVA/CF dal server
    List<String> serverValidationErrors = [];

    if (widget.ticket['partiva'] != null &&
        widget.ticket['partiva'].toString().isNotEmpty &&
        _pivaController.text.isEmpty) {
      String partiva = widget.ticket['partiva'].toString();

      // Valida la P.IVA prima di inserirla
      if (partitaIvaRegExp.hasMatch(partiva)) {
        _pivaController.text = partiva;
        cU = true;
        if (widget.ticket['codsdi'] != null &&
            widget.ticket['codsdi'].toString().isNotEmpty &&
            _codUnivocoController.text.isEmpty) {
          _codUnivocoController.text = widget.ticket['codsdi'];
        }
      } else {
        // P.IVA non conforme dal server
        serverValidationErrors.add(
          'P.IVA "$partiva" non conforme: deve essere di 11 cifre numeriche'
        );
      }
    } else if (widget.ticket['codFisc'] != null &&
        widget.ticket['codFisc'].toString().isNotEmpty &&
        _pivaController.text.isEmpty) {
      String codFisc = widget.ticket['codFisc'].toString();

      // Valida il CF prima di inserirlo
      if (cFRegExp.hasMatch(codFisc)) {
        _pivaController.text = codFisc;
      } else {
        // CF non conforme dal server
        serverValidationErrors.add(
          'Codice Fiscale "$codFisc" non conforme: formato non valido'
        );
      }
    }

    // Mostra dialog se ci sono errori di validazione dai dati del server
    if (serverValidationErrors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDataValidationWarning(serverValidationErrors);
      });
    }
    if (widget.ticket['rifFurgone'] != null &&
        widget.ticket['rifFurgone'].toString().isNotEmpty &&
        _vansValue == null) {
      _vansValue = widget.ticket['rifFurgone'];
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Salva la bozza quando l'utente esce senza completare
          _saveDraft();
        }
      },
      child: Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [
          SizedBox(
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Anagrafica",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: ragSocialeFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Città",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: cityFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Indirizzo Intervento",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: placeFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Indirizzo Fatturazione",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: placeBillFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("P. Iva/CF",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: pIvaFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Cod. Univoco",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: codUFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Cellulare",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: cellNumberFormField(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Descrizione Lavoro",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: SizedBox(child: description()),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Macchine",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          "Inserisci le informazioni sulla macchina se necessario con il pulsante qui sotto.",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: appBarColor,
                            fontSize: 13,
                          )),
                    ),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: machine(),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Ricambi",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          "Inserisci ricambi e quantità se necessario con il pulsante qui sotto.",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: appBarColor,
                            fontSize: 13,
                          )),
                    ),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: ricambi(),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Operatori",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          "Inserisci operatori necessario con il pulsante qui sotto.",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: appBarColor,
                            fontSize: 13,
                          )),
                    ),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: operatore(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Modalità Intervento",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: typeIntevention(),
                ),
                // if (_typeIntervention != 'Cantiere' &&
                //     _typeIntervention != 'Garanzia')
                //   const Padding(
                //       padding: EdgeInsets.symmetric(vertical: defaultPadding),
                //       child: Align(
                //         alignment: Alignment.centerLeft,
                //         child: Text("Diritto Fisso",
                //             textAlign: TextAlign.start,
                //             style: TextStyle(
                //               fontWeight: FontWeight.bold,
                //               fontSize: 25,
                //             )),
                //       )),
                // if (_typeIntervention != 'Cantiere' &&
                //     _typeIntervention != 'Garanzia')
                //   Padding(
                //     padding: const EdgeInsets.only(bottom: defaultPadding),
                //     child: costoChiamata(),
                // ),

                if (_typeIntervention != 'Garanzia')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Iva",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention != 'Garanzia')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: iva(),
                  ),
                if (_typeIntervention != 'Garanzia')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Metodo di pagamento",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention != 'Garanzia')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: paymentMethod(),
                  ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Richiesta di Intervento",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: externalTicket(),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Riferimento Furgone",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: refVan(),
                ),
                if (_typeIntervention == 'Manutenzione')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Costo Contratto",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention == 'Manutenzione')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: supplementoFormField(),
                  ),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Firmatario",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          )),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: signer(),
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton.icon(
                  //onPressed: _isLoading: null ? _onSubmit,
                  onPressed: (!_isLoading && !_isOptionsAnagraficaLoading)
                      ? () {
                          setState(() => _submitted = true);
                          _onSubmit(widget.ticket);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16.0)),
                  icon: _isLoading
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Chiudi Ticket'),
                ),
                // ElevatedButton(
                //   onPressed: () {
                //     if (_formKey.currentState!.validate()) {
                //       setState(() {
                //         _isLoading = true;
                //       });
                //       _formKey.currentState!.save();
                //       _closeTicket(widget.ticket);
                //       // if all are valid then go to success screen
                //       KeyboardUtil.hideKeyboard(context);
                //     }
                //   },
                //   child: Text(
                //     "Chiudi Ticket".toUpperCase(),
                //   ),
                // ),
                const SizedBox(height: defaultPadding),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  machine() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: datiMacchina.isEmpty ? 1 : datiMacchina.length,
          itemBuilder: (BuildContext context, int index) {
            if (index == datiMacchina.length) {
              return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: SizedBox(
                          width: 60,
                          child: ElevatedButton(
                            onPressed: _addMachine,
                            child: Icon(
                              Icons.add_rounded,
                              color: primaryColor,
                            ),
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(CircleBorder()),
                              backgroundColor: MaterialStateProperty.all(
                                  secondaryColor), // Cambia colore a seconda delle tue esigenze
                              padding: MaterialStateProperty.all(EdgeInsets.all(
                                  8)), // Imposta il padding desiderato
                            ),
                          ),
                        ),
                      ),
                    ],
                  ));
            }

            return Column(
              children: [
                Text("Macchina " + (index + 1).toString(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    )),
                ListTile(
                  title: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(hintText: 'Marca'),
                        onChanged: (value) {
                          datiMacchina[index]['marca'] = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return kRicambiNullError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        decoration: InputDecoration(hintText: 'Modello'),
                        onChanged: (value) {
                          datiMacchina[index]['modello'] = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return kRicambiNullError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      TextFormField(
                        decoration: InputDecoration(hintText: 'Matricola'),
                        onChanged: (value) {
                          datiMacchina[index]['matricola'] = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return kMTRNullError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      stateMachineFormField(index),
                      SizedBox(
                        height: 8,
                      ),
                      typeMachineFormField(index)
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () => _removeMachine(index),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  ricambi() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: orderInfo.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == orderInfo.length) {
          return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: ElevatedButton(
                          onPressed: _addProduct,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(CircleBorder()),
                            backgroundColor: WidgetStateProperty.all(
                                secondaryColor), // Cambia colore a seconda delle tue esigenze
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.all(
                                    8)), // Imposta il padding desiderato
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: ElevatedButton(
                          onPressed: !_isLoading
                              ? () async {
                                  var code = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SimpleBarcodeScannerPage(),
                                      ));
                                  setState(() {
                                    if (code is String) {
                                      scannedCode = code;
                                    }
                                  });
                                  if (scannedCode.isNotEmpty &&
                                      scannedCode != '-1') {
                                    // if(_optionsRicambi['codeAn'] == scannedCode){
                                    //   _addProductBarcode(_optionsRicambi['descrizione'], _optionsRicambi['prezzoFornitore']);
                                    // }
                                    var ricambio =
                                        await getRicambio(scannedCode);
                                    if (ricambio != null ||
                                        ricambio.isNotEmpty) {
                                      _addProductBarcode(
                                          ricambio['descrizione'],
                                          ricambio['prezzoFornitore']);
                                    } else {
                                      await FlutterPlatformAlert.showAlert(
                                        windowTitle: 'Ricambio non trovato',
                                        text:
                                            'Il ricambio non è presente nel magazzino',
                                        alertStyle: AlertButtonStyle.ok,
                                        iconStyle: IconStyle.warning,
                                      );
                                    }
                                    //print(ricambio['descrizione']);
                                  }

                                  //addToSummary(code); // Aggiunge il codice al riepilogo
                                  // // Torna alla schermata di riepilogo
                                }
                              : null,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(CircleBorder()),
                            backgroundColor: WidgetStateProperty.all(
                                secondaryColor), // Cambia colore a seconda delle tue esigenze
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.all(
                                    8)), // Imposta il padding desiderato
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Ricambio ${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            // Form Ricambi
            ricambiForm(index),
            SizedBox(height: 12),
            // Dropdown Provenienza Ricambio
            DropdownButtonFormField<String>(
              value: orderInfo[index]['provenienza'].toString().isEmpty
                  ? null
                  : orderInfo[index]['provenienza'],
              decoration: InputDecoration(
                hintText: 'Provenienza ricambio',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.warehouse_outlined),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: kPrimaryLightColor,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Magazzino',
                  child: Text('Magazzino'),
                ),
                DropdownMenuItem(
                  value: 'Furgone',
                  child: Text('Furgone'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  orderInfo[index]['provenienza'] = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Seleziona la provenienza del ricambio';
                }
                return null;
              },
            ),
            SizedBox(height: 12), // Spaziatura tra i widget
            // Campo numero pezzi
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: TextFormField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]{1,3}$')),
                    ],
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'pz.',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(defaultPadding),
                        child: Icon(Icons.pin_rounded),
                      ),
                    ),
                    onChanged: (value) {
                      orderInfo[index]['numeroPezziRicambio'] =
                          int.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value!.isEmpty || int.tryParse(value) == 0) {
                        return kpzNullError;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Campo prezzo
                Flexible(
                  flex: 2,
                  child: TextFormField(
                    controller: _prezzoController[index],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Prezzo',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(defaultPadding),
                        child: Icon(Icons.euro_rounded),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[\.,]?\d{0,2}$'),
                      ),
                    ],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      pzRicambi[index] = value;
                      orderInfo[index]['prezzo'] =
                          value.replaceFirst(RegExp(','), '.');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Pulsante di rimozione
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: Icon(Icons.remove_circle),
                label: Text("Rimuovi ricambio ${index + 1}"),
                onPressed: () => _removeProduct(index),
              ),
            ),
            Divider(thickness: 1), // Separatore tra i ricambi
          ],
        );
      },
    );
  }

  operatore() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: operatori.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == operatori.length) {
          return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: SizedBox(
                      width: 60,
                      child: ElevatedButton(
                        onPressed: _addOperatore,
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(const CircleBorder()),
                          backgroundColor: WidgetStateProperty.all(
                              secondaryColor), // Cambia colore a seconda delle tue esigenze
                          padding: WidgetStateProperty.all(const EdgeInsets.all(
                              8)), // Imposta il padding desiderato
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ));
        }
        return Column(
          children: [
            Text("Operatore " + (index + 1).toString(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            ListTile(
              title: DropdownButtonFormField(
                hint: const Text('Tecnico'),

                borderRadius: const BorderRadius.all(Radius.circular(30)),
                dropdownColor: kPrimaryLightColor,
                //value: temp.cognome+""+ temp.nome,
                //value: techList.map((techs) {return techs.id;},
                onTap: () {},
                validator: (_dropdownValue) {
                  if (_dropdownValue == null) {
                    return kStateMNullError;
                  }
                  return null;
                },
                onChanged: (value) async {
                  if (operatori.any((item) => item == value.toString())) {
                    _removeOperatore(index);
                    await FlutterPlatformAlert.showAlert(
                      windowTitle: 'Operatore già presente',
                      text: 'L\'operatore è già stato aggiunto.',
                      alertStyle: AlertButtonStyle.ok,
                      iconStyle: IconStyle.warning,
                    );
                    _addOperatore();
                  } else {
                    operatori[index] = value.toString();
                  }
                },
                items: techList.map((techs) {
                  return DropdownMenuItem(
                    value: techs.id,
                    child: Text(
                      techs.cognome + " " + techs.nome,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => _removeOperatore(index),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  manodopera() {
    return TextFormField(
      controller: _manodoperaController,
      decoration: const InputDecoration(
        hintText: "Manodopera",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.euro_rounded),
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(
            r'^\d+[\.,]?\d{0,2}')), // Accetta solo numeri e al massimo una virgola
      ],
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      // validator: (value) {
      //   if (double.tryParse(value!) == null) {
      //     return 'Inserisci un prezzo valido';
      //   }
      //   return null;
      // },
    );
  }

  TextFormField description() {
    return TextFormField(
      controller: _descriptionController,
      //expands: true,
      maxLines: 5,
      textInputAction: TextInputAction.done,
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Descrivi il problema",
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Icon(Icons.edit_rounded),
        ),
      ),
    );
  }

  placeFormField() {
    return TextFormField(
      controller: _placeController,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return kAddressNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Indirizzo Intervento",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.place_rounded),
        ),
      ),
    );
  }

  placeBillFormField() {
    return TextFormField(
      controller: _placeBillController,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return kAddressNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Indirizzo Fatturazione",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.place_rounded),
        ),
      ),
    );
  }

  ricambiForm(index) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildRicambiSearchModal(index),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimaryLightColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: orderInfo[index]['ricambiForniti'].toString().isEmpty
                ? Colors.grey.shade300
                : secondaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: orderInfo[index]['ricambiForniti'].toString().isEmpty
                  ? Colors.grey
                  : secondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                orderInfo[index]['ricambiForniti'].toString().isEmpty
                    ? "Seleziona Ricambio"
                    : orderInfo[index]['ricambiForniti'],
                style: TextStyle(
                  fontSize: 16,
                  color: orderInfo[index]['ricambiForniti'].toString().isEmpty
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.search,
              color: secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<Map<String, dynamic>>> _getRicambiSuggestions() {
    // Get the current text from the text controller.

    // Clear the suggestions.
    _suggestionsRicambi.clear();

    // Iterate over the data and add any maps that match the search text to the suggestions.
    for (Map<String, dynamic> map in _optionsRicambi) {
      if (map['descrizione'] != null && map['codeAn'] != null) {
        final String name = map['descrizione'];
        final String codice = map['codeAn'];

        _suggestionsRicambi.add(DropdownMenuItem(
            value: map,
            child: Row(
              children: [
                Text("$codice ",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(name)
              ],
            )));
      }
    }

    // Limit the suggestions to 4 items.

    return _suggestionsRicambi;
  }

  ragSocialeFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected company card
        if (_selectedCompany != null && _ragSocController.text.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withValues(alpha: 0.15),
                  secondaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: secondaryColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ragSocController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_cityController.text.isNotEmpty)
                            Text(
                              _cityController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      color: secondaryColor,
                      onPressed: () {
                        setState(() {
                          _selectedCompany = null;
                          _ragSocController.text = '';
                          _placeBillController.text = '';
                          _placeController.text = '';
                          _cityController.text = '';
                          _pivaController.text = '';
                          _numTelController.text = '';
                          cU = false;
                        });
                      },
                    ),
                  ],
                ),
                if (_placeBillController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _placeBillController.text,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_pivaController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _pivaController.text,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

        // Search button
        TextFormField(
          controller: _ragSocController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Cerca Anagrafica',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.business),
            ),
            suffixIcon: _isOptionsAnagraficaLoading
                ? const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(Icons.search),
                  ),
            errorText: _submitted && _ragSocController.text.isEmpty
                ? kAnagrafNullError
                : null,
          ),
          validator: (value) {
            if (!_submitted) return null;
            if (value == null || value.isEmpty) {
              return kAnagrafNullError;
            }
            return null;
          },
          onTap: _isOptionsAnagraficaLoading
              ? null
              : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildAnagraficaSearchModal(),
                  );
                },
        ),
      ],
    );
  }

  List<DropdownMenuItem<Map<String, dynamic>>> _getAnagraficaSuggestions() {
    // Get the current text from the text controller.
    final String text = _ragSocController.text;

    // Clear the suggestions.
    _suggestionsAnagrafica.clear();

    // Iterate over the data and add any maps that match the search text to the suggestions.
    for (Map<String, dynamic> map in _optionsAnagrafica) {
      final String name = map['ragSoc'];

      _suggestionsAnagrafica.add(DropdownMenuItem(
        value: map,
        child: Text(name),
      ));
    }

    // Limit the suggestions to 4 items.

    return _suggestionsAnagrafica;
  }

  Widget _buildAnagraficaSearchModal() {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> displayedCompanies =
        List.from(_optionsAnagrafica);
    bool isSearching = false;
    Timer? debounceTimer;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Filter function (client-side)
        void filterCompanies(String query) {
          setModalState(() {
            if (query.isEmpty) {
              displayedCompanies = List.from(_optionsAnagrafica);
            } else {
              displayedCompanies = _optionsAnagrafica
                  .where((company) {
                    final ragSoc =
                        (company['ragSoc'] ?? '').toString().toLowerCase();
                    final local =
                        (company['local'] ?? '').toString().toLowerCase();
                    return ragSoc.contains(query.toLowerCase()) ||
                        local.contains(query.toLowerCase());
                  })
                  .toList()
                  .cast<Map<String, dynamic>>();
            }
          });
        }

        // Search function con debounce (usa il cache service)
        void searchCompanies(String query) async {
          // Prima cerca in locale per feedback immediato
          filterCompanies(query);

          if (query.length < 3) {
            return;
          }

          // Cancella il timer precedente
          debounceTimer?.cancel();

          // Crea un nuovo timer che aspetta 500ms prima di fare la chiamata API
          debounceTimer = Timer(const Duration(milliseconds: 500), () async {
            setModalState(() {
              isSearching = true;
            });

            try {
              // Utilizza il servizio di cache
              final companies = await _cacheService.getCompanies(query);
              setModalState(() {
                // Merge: aggiungi nuovi risultati senza duplicati
                final existingIds =
                    _optionsAnagrafica.map((e) => e['id']).toSet();

                final uniqueNewResults = companies
                    .where((item) => !existingIds.contains(item['id']))
                    .toList();

                _optionsAnagrafica.addAll(uniqueNewResults);

                // Filtra di nuovo per mostrare risultati rilevanti
                filterCompanies(query);
                isSearching = false;
              });
            } catch (e) {
              print('Error searching companies: $e');
              setModalState(() {
                isSearching = false;
              });
            }
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: secondaryColor,
                        ),
                        const Expanded(
                          child: Text(
                            'Cerca Anagrafica',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search field
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cerca per nome o città...',
                        prefixIcon:
                            const Icon(Icons.search, color: secondaryColor),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      filterCompanies('');
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: secondaryColor.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: secondaryColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: secondaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.length >= 3) {
                          searchCompanies(value);
                        } else {
                          filterCompanies(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Results list
              Expanded(
                child: displayedCompanies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchController.text.isEmpty
                                  ? 'Inizia a cercare...'
                                  : 'Nessun risultato trovato',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedCompany = null;
                                    _ragSocController.text =
                                        searchController.text;
                                  });
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Inserisci manualmente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedCompanies.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final company = displayedCompanies[index];
                          final ragSoc = company['ragSoc']?.toString() ?? '';
                          final local = company['local']?.toString() ?? '';
                          final indir = company['indir']?.toString() ?? '';
                          final piva = company['piva']?.toString() ?? '';

                          return InkWell(
                            onTap: () {
                              List<String> validationErrors = [];

                              setState(() {
                                _selectedCompany = company;
                                _ragSocController.text = ragSoc;
                                _cityController.text = local;
                                _placeController.text = indir;
                                _placeBillController.text = indir;

                                // Compila P.IVA o Codice Fiscale con validazione
                                if (company['partiva'] != null &&
                                    company['partiva'].toString().isNotEmpty) {
                                  String partiva = company['partiva'].toString();

                                  // Valida la P.IVA
                                  if (partitaIvaRegExp.hasMatch(partiva)) {
                                    _pivaController.text = partiva;
                                    cU = true;
                                    // Compila Codice SDI se disponibile
                                    if (company['codsdi'] != null &&
                                        company['codsdi']
                                            .toString()
                                            .isNotEmpty) {
                                      _codUnivocoController.text =
                                          company['codsdi'];
                                    }
                                  } else {
                                    // P.IVA non conforme
                                    validationErrors.add(
                                      'P.IVA "$partiva" non conforme: deve essere di 11 cifre numeriche'
                                    );
                                    cU = false;
                                  }
                                } else if (company['codFisc'] != null &&
                                    company['codFisc'].toString().isNotEmpty) {
                                  String codFisc = company['codFisc'].toString();

                                  // Valida il Codice Fiscale
                                  if (cFRegExp.hasMatch(codFisc)) {
                                    _pivaController.text = codFisc;
                                    cU = false;
                                  } else {
                                    // CF non conforme
                                    validationErrors.add(
                                      'Codice Fiscale "$codFisc" non conforme: formato non valido'
                                    );
                                  }
                                }

                                // Compila telefono
                                if (company['tel'] != null &&
                                    company['tel'].toString().isNotEmpty) {
                                  _numTelController.text = company['tel'];
                                } else if (company['tel2'] != null &&
                                    company['tel2'].toString().isNotEmpty) {
                                  _numTelController.text = company['tel2'];
                                }
                              });

                              Navigator.pop(context);

                              // Mostra il dialog se ci sono errori di validazione
                              if (validationErrors.isNotEmpty) {
                                Future.delayed(Duration(milliseconds: 300), () {
                                  _showDataValidationWarning(validationErrors);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: secondaryColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
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
                                            color: secondaryColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.business,
                                            color: secondaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            ragSoc,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (local.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            local,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (indir.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.place,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              indir,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (piva.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.numbers,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'P.IVA: $piva',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRicambiSearchModal(int index) {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> displayedRicambi = List.from(_optionsRicambi);
    bool isSearching = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Filter function (client-side)
        void filterRicambi(String query) {
          setModalState(() {
            if (query.isEmpty) {
              displayedRicambi = List.from(_optionsRicambi);
            } else {
              displayedRicambi = _optionsRicambi
                  .where((ricambio) {
                    final descrizione =
                        (ricambio['descrizione'] ?? '').toString().toLowerCase();
                    final codice =
                        (ricambio['codeAn'] ?? '').toString().toLowerCase();
                    final codArticolo =
                        (ricambio['codArticolo'] ?? '').toString().toLowerCase();
                    return descrizione.contains(query.toLowerCase()) ||
                        codice.contains(query.toLowerCase()) ||
                        codArticolo.contains(query.toLowerCase());
                  })
                  .toList()
                  .cast<Map<String, dynamic>>();
            }
          });
        }

        // Search function (server-side for new queries)
        void searchRicambi(String query) async {
          // Prima cerca in locale
          filterRicambi(query);

          if (query.length < 2) {
            return;
          }

          setModalState(() {
            isSearching = true;
          });

          try {
            Response? response = await WareHouseApi().getValue(query);
            if (response != null && response.statusCode == 200) {
              List<dynamic> newResults = jsonDecode(response.body);
              setModalState(() {
                // Merge: aggiungi nuovi risultati senza duplicati
                final existingCodes =
                    _optionsRicambi.map((e) => e['codArticolo']).toSet();

                final uniqueNewResults = newResults
                    .where((item) => !existingCodes.contains(item['codArticolo']))
                    .toList();

                _optionsRicambi
                    .addAll(uniqueNewResults.cast<Map<String, dynamic>>());

                // Filtra di nuovo per mostrare risultati rilevanti
                filterRicambi(query);
                isSearching = false;
              });
            } else {
              setModalState(() {
                isSearching = false;
              });
            }
          } catch (e) {
            print('Error searching ricambi: $e');
            setModalState(() {
              isSearching = false;
            });
          }
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: secondaryColor,
                        ),
                        const Expanded(
                          child: Text(
                            'Cerca Ricambio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search field
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cerca per nome, codice...',
                        prefixIcon:
                            const Icon(Icons.search, color: secondaryColor),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      filterRicambi('');
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: secondaryColor.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: secondaryColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: secondaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        if (value.length >= 2) {
                          searchRicambi(value);
                        } else {
                          filterRicambi(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Results list
              Expanded(
                child: displayedRicambi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchController.text.isEmpty
                                  ? 'Inizia a cercare...'
                                  : 'Nessun ricambio trovato',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    orderInfo[index]['ricambiForniti'] =
                                        searchController.text;
                                    pzRicambi[index] = searchController.text;
                                  });
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Inserisci manualmente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedRicambi.length,
                        separatorBuilder: (context, idx) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final ricambio = displayedRicambi[idx];
                          final descrizione =
                              ricambio['descrizione']?.toString() ?? '';
                          final codeAn = ricambio['codeAn']?.toString() ?? '';
                          final codArticolo =
                              ricambio['codArticolo']?.toString() ?? '';
                          final giacenza =
                              ricambio['giacenza']?.toString() ?? '0';
                          final prezzo =
                              ricambio['prezzoFornitore']?.toString() ?? '0';

                          return InkWell(
                            onTap: () {
                              bool exists = orderInfo.any((item) =>
                                  item['ricambiForniti'] == descrizione);

                              if (exists) {
                                FlutterPlatformAlert.showAlert(
                                  windowTitle: 'Ricambio già presente',
                                  text:
                                      'Il ricambio $descrizione è già stato aggiunto.',
                                  alertStyle: AlertButtonStyle.ok,
                                  iconStyle: IconStyle.warning,
                                );
                              } else {
                                setState(() {
                                  orderInfo[index]['ricambiForniti'] =
                                      descrizione;
                                  orderInfo[index]['prezzo'] = prezzo;
                                  pzRicambi[index] = descrizione;
                                  _prezzoController[index].text = prezzo;
                                });
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: secondaryColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: secondaryColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: secondaryColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          codeAn.isNotEmpty
                                              ? codeAn
                                              : codArticolo,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          descrizione,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Giacenza: $giacenza',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.euro,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$prezzo €',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  pIvaFormField() {
    return TextFormField(
      controller: _pivaController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      onChanged: (value) {
        final upperValue = value.toUpperCase();
        final cursorPosition = _pivaController.selection.baseOffset;

        // Calcola la nuova posizione del cursore considerando la lunghezza del nuovo testo
        final newCursorPosition = cursorPosition > upperValue.length
            ? upperValue.length
            : cursorPosition;

        _pivaController.value = TextEditingValue(
          text: upperValue,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        );

        if (partitaIvaRegExp.hasMatch(upperValue)) {
          setState(() {
            cU = true;
          });
        } else {
          setState(() {
            cU = false;
            // Cancella il codice univoco quando la P.IVA viene cancellata
            if (upperValue.isEmpty) {
              _codUnivocoController.clear();
            }
          });
        }
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kPIVANullError;
        } else if (!partitaIvaRegExp.hasMatch(value) &&
            !cFRegExp.hasMatch(value)) {
          return kInvalidPIvaError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "P. IVA/CF",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.numbers_rounded),
        ),
      ),
    );
  }

  signer() {
    return TextFormField(
      controller: _signerController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value!.isEmpty) {
          return kSignerNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Firmatario",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.edit_note_rounded),
        ),
      ),
    );
  }

  codUFormField() {
    return TextFormField(
      controller: _codUnivocoController,
      textInputAction: TextInputAction.next,
      enabled: cU,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value!.isEmpty && partitaIvaRegExp.hasMatch(_pivaController.text)) {
          return kCodUniNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Cod. Univoco",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.numbers_rounded),
        ),
      ),
    );
  }

  DropdownButtonFormField<String> stateMachineFormField(index) {
    String? _stateValue;

    return DropdownButtonFormField(
      hint: Text('Seleziona lo stato'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.flag_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _stateValue,
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kStateMNullError;
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _stateValue = newValue!;
          datiMacchina[index]['statoFineLavoro'] = newValue;
        });
      },
      items: <String>['Funzionante', 'Rallentato', 'Fermo']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField<String> typeMachineFormField(index) {
    String? _typeMValue;
    return DropdownButtonFormField(
      hint: Text('Seleziona il tipo'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.plumbing_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _typeMValue,
      onChanged: (String? newValue) {
        setState(() {
          //_typeMValue = newValue!;
          datiMacchina[index]['tipo'] = newValue;
        });
      },
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kTypeMNullError;
        }
        return null;
      },
      items: kTypeMachine,
    );
  }

  DropdownButtonFormField<String> typeIntevention() {
    return DropdownButtonFormField(
      hint: Text('Seleziona il tipo'),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.article_rounded),
        ),
      ),
      dropdownColor: kPrimaryLightColor,
      value: _typeIntervention,
      onChanged: (String? newValue) {
        setState(() {
          _typeIntervention = newValue!;

          _selectedPaymentOption = null;
        });
      },
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kTypeMNullError;
        }
        return null;
      },
      items: <String>['Fuori Garanzia', 'Garanzia', 'Manutenzione', 'Cantiere']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
          ),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField<String> refVan() {
    return DropdownButtonFormField(
      hint: Text('Seleziona il furogne'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.airport_shuttle_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _vansValue,
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kStateMNullError;
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _vansValue = newValue!;
        });
      },
      items: kVans,
    );
  }

  cellNumberFormField() {
    return TextFormField(
      controller: _numTelController,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return kPhoneNumberNullError;
        } else if (!cellRegExp.hasMatch(value)) {
          return kInvalidCellError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Cellulare",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.phone_iphone),
        ),
      ),
    );
  }

  supplementoFormField() {
    return TextFormField(
      controller: _supplementoController,
      //initialValue: "0",
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Costo Contratto',
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.euro_rounded),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return kManutetnzioneNullError;
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d+[\.,]?\d{0,2}$'),
        ),
      ],
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    );
  }

  cityFormField() {
    return TextFormField(
      controller: _cityController,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return kCittaNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Città",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.location_city_rounded),
        ),
      ),
    );
  }

  externalTicket() {
    return TextFormField(
      controller: _externalTicketController,
      textInputAction: TextInputAction.done,
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Richiesta di intervento",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.tag_rounded),
        ),
      ),
    );
  }

  DropdownButtonFormField<String> iva() {
    if (_typeIntervention == 'Garanzia' ||
        _typeIntervention == 'Manutenzione') {
      setState(() {
        _iva = '0';
      });
    } else if (_typeIntervention == 'Fuori Garanzia') {
      setState(() {
        _iva = '22';
      });
    }
    return DropdownButtonFormField(
      hint: Text('Iva'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.percent_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _iva,
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kIvaNullError;
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _iva = newValue!;
        });
      },
      onTap: () {
        return null;
      },
      items: <String>['0', '10', '22']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value.toLowerCase(),
          child: Text(
            value,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField<String> paymentMethod() {
    if (_typeIntervention == 'Garanzia') {
      setState(() {
        _selectedPaymentOption = 'Nessuno';
      });
    }
    return DropdownButtonFormField(
      hint: Text('Metodo Pagamento'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.flag_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _selectedPaymentOption,
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kPaymentNullError;
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _selectedPaymentOption = newValue!;
        });
      },
      onTap: () {
        return null;
      },
      items: <String>['Contanti', 'Carta', 'Bonifico', 'AB', 'Nessuno']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value.toLowerCase(),
          child: Text(
            value,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }

  void _showManualEntryDialog(String initialRagSoc) {
    final formKey = GlobalKey<FormState>();
    final ragSocCtrl = TextEditingController(text: initialRagSoc);
    final pivaCtrl = TextEditingController();
    final codFiscCtrl = TextEditingController();
    final codsdiCtrl = TextEditingController();
    final cittaCtrl = TextEditingController();
    final indirizzoCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.business, color: secondaryColor),
            SizedBox(width: 8),
            Text('Inserimento Manuale Anagrafica'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ragSocCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ragione Sociale *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obbligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: pivaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Partita IVA',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  onChanged: (value) {
                    // Se c'è P.IVA, abilita il campo CodSDI
                    if (value.isNotEmpty) {
                      codsdiCtrl.text = '';
                    }
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: codFiscCtrl,
                  decoration: InputDecoration(
                    labelText: 'Codice Fiscale',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLength: 16,
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: codsdiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Codice SDI',
                    prefixIcon: Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: pivaCtrl.text.isNotEmpty
                        ? 'Compilare se hai P.IVA'
                        : 'Richiede P.IVA',
                  ),
                  enabled: pivaCtrl.text.isNotEmpty,
                  maxLength: 7,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: cittaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Città',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: indirizzoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Indirizzo Fatturazione',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: telCtrl,
                  decoration: InputDecoration(
                    labelText: 'Telefono',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _selectedCompany = null; // Inserimento manuale
                  _ragSocController.text = ragSocCtrl.text;
                  _pivaController.text = pivaCtrl.text;
                  _codUnivocoController.text = codsdiCtrl.text;
                  _cityController.text = cittaCtrl.text;
                  _placeBillController.text = indirizzoCtrl.text;
                  _placeController.text = indirizzoCtrl.text;
                  _numTelController.text = telCtrl.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }
}
