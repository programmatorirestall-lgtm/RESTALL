import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/API/Company/company.dart';
import 'package:restalltech/API/Tech/tech.dart';

import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/WareHouse/wareHouseApi.dart';
import 'package:restalltech/Screens/myTickets/components/my_ticket.dart';
import 'package:restalltech/Screens/myTickets/my_ticket_screen.dart';
import 'package:restalltech/Screens/ticket_success/ticket_success_screen.dart';

import 'package:restalltech/constants.dart';
import 'package:intl/intl.dart';
import 'package:restalltech/helper/keyboard.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:restalltech/models/invoice.dart';
import 'package:search_choices/search_choices.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:restalltech/helper/form_validators.dart';

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
  final TextEditingController _pivaController = TextEditingController();
  final TextEditingController _codUnivoco = TextEditingController();
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
  String? _selectedPaymentOption;
  String? _iva;
  String? _typeIntervention;
  var _isLoading = false;
  bool _submitted = false;
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
  String? _vansValue;

  @override
  void initState() {
    super.initState();
    getAnagrafica('');
    getRicambi('');
    _getTech();
  }

  void getAnagrafica(valore) async {
    try {
      var response = await CompanyApi().getValue(valore);

      if (response.statusCode == 200) {
        final suggestions = json.decode(response.body);

        List<Map<String, dynamic>> mergedList = [];
        for (var list in suggestions) {
          mergedList.add({
            'id': list['id'],
            'clfr': list['clfr'],
            'codCf': list['codCf'],
            'ragSoc': list['ragSoc'],
            'indir': list['indir'],
            'cap': list['cap'],
            'local': list['local'],
            'prov': list['prov'],
            'codFisc': list['codFisc'],
            'partiva': list['partiva'],
            'tel': list['tel'],
            'tel2': list['tel2'],
            'fax': list['fax'],
            'email': list['email'],
          });
        }
        //print(suggestions);
        setState(() {
          _optionsAnagrafica = mergedList;
          _getAnagraficaSuggestions();
          //print(_options); // Limita a 4 suggerimenti
        });
      } else {
        throw Exception('Errore durante la richiesta al server');
      }
    } catch (error) {
      print(error);
    }
  }

  void getRicambi(valore) async {
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
        print(suggestions);
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
    }
  }

  void _addProduct() {
    setState(() {
      pzRicambi.add('');
      quantita.add(0);
      _prezzoController.add(TextEditingController());
      orderInfo.add(
          {'ricambiForniti': '', 'numeroPezziRicambio': 0, 'prezzo': 0.00});

      print(orderInfo);
    });
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

    setState(() {
      _submitted = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      _closeTicket(ticket);
    } else {
      setState(() => _isLoading = false);
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

  _getTech() async {
    final Response response = await TechApi().getData();
    final body = json.decode(response.body);
    Iterable ticketList = body['tecnico'];
    List<Technician> techs = List<Technician>.from(
        ticketList.map((model) => Technician.fromJson(model)));
    techs.removeWhere((item) => item.verified == "FALSE");

    setState(() {
      techList = techs;
    });
  }

  _closeTicket(Map<String, dynamic> ticket) async {
    final location = await sign();
    try {
      var data = {
        'ragioneSociale': _ragSocController.text,
        'indirizzo': _placeController.text,
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
        'costoTrasferta':
            _trasfertaController.text.replaceFirst(RegExp(','), '.'),
        'tot': _manodoperaController.text.replaceFirst(RegExp(','), '.'),
        'operatori': operatori,
        'costoChiamata':
            _costoChiamataController.text.replaceFirst(RegExp(','), '.'),
        'iva': _iva,
        'codUnivoco': _codUnivoco.text,
        'rifFurgone': _vansValue.toString()
      };

      print(data);
      int status = await TicketApi().closeTicket(data, ticket['id']);

      CircularProgressIndicator(color: secondaryColor);
      if (status == 200) {
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
        pzRicambi = [];
        quantita = [];
        orderInfo = List<Map<String, dynamic>>.empty(growable: true);
        datiMacchina = List<Map<String, dynamic>>.empty(growable: true);
        operatori = [];
      }
    } on SocketException catch (e) {
      print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nell'apertura del ticket",
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _placeController.text = widget.ticket['indirizzo'];
    return Stack(
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
                      child: Text("Indirizzo",
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
                if (_typeIntervention != 'Cantiere' &&
                    _typeIntervention != 'Garanzia')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Diritto Fisso",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention != 'Cantiere' &&
                    _typeIntervention != 'Garanzia')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: costoChiamata(),
                  ),
                if (_typeIntervention != 'Garanzia')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Kilometraggio A/R",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention != 'Garanzia')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: trasferta(),
                  ),
                if (_typeIntervention != 'Garanzia')
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: defaultPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Costi Manodopera",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            )),
                      )),
                if (_typeIntervention != 'Garanzia')
                  Padding(
                    padding: const EdgeInsets.only(bottom: defaultPadding),
                    child: manodopera(),
                  ),
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
                const SizedBox(height: defaultPadding),
                ElevatedButton.icon(
                  //onPressed: _isLoading: null ? _onSubmit,
                  onPressed: !_isLoading
                      ? () {
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
                            child: Icon(Icons.add_rounded),
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
                            return kRicambiNullError;
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
                  Flexible(
                    child: SizedBox(
                      width: 60,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        child: Icon(Icons.add_rounded),
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
            Text("Ricambio " + (index + 1).toString(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                )),
            ListTile(
              title: ricambiForm(index),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    child: TextFormField(
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(
                            r'^[0-9]{1,3}$')), // Accetta solo numeri e al massimo una virgola
                      ],
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: false),
                      decoration: InputDecoration(hintText: 'pz.'),
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
                  IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => _removeProduct(index),
                  ),
                ],
              ),
            ),
            ListTile(
              title: TextFormField(
                controller: _prezzoController[index],
                decoration: InputDecoration(
                  hintText: 'Prezzo',
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
                onChanged: (value) {
                  pzRicambi[index] = value;
                  orderInfo[index]['prezzo'] =
                      value.replaceFirst(RegExp(','), '.');
                },
                // validator: (value) {
                //   if (value!.isEmpty) {
                //     return kRicambiNullError;
                //   } else if (double.tryParse(value) == null) {
                //     return 'Inserisci un prezzo valido';
                //   }
                //   return null;
                // },
              ),
            ),
          ],
        );
      },
    );
  }

  operatore() async {
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
                        child: Icon(Icons.add_rounded),
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
                value: techList,
                onTap: () {},
                validator: (_dropdownValue) {
                  if (_dropdownValue == null) {
                    return kStateMNullError;
                  }
                  return null;
                },
                onChanged: (value) {
                  operatori[index] = value.toString();
                },
                items: techList.map((techs) {
                  return DropdownMenuItem<int>(
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

  costoChiamata() {
    return TextFormField(
      controller: _costoChiamataController,
      decoration: InputDecoration(
        hintText: "Diritto Fisso",
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

  trasferta() {
    return TextFormField(
      controller: _trasfertaController,
      decoration: InputDecoration(
        hintText: "Kilometraggio A/R",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.edit_road_rounded),
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
      validator:
          FormValidators.requiredIfSubmitted(_submitted, kAddressNullError),
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Indirizzo",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.place_rounded),
        ),
      ),
    );
  }

  ricambiForm(index) {
    return SearchChoices.single(
      items: _getRicambiSuggestions(),
      fieldDecoration: const BoxDecoration(
        color: kPrimaryLightColor,
        borderRadius: BorderRadius.all(Radius.circular(30)),
        border: Border(
            top: BorderSide(width: 3, color: kPrimaryLightColor),
            bottom: BorderSide(width: 3, color: kPrimaryLightColor),
            left: BorderSide(width: 5, color: kPrimaryLightColor),
            right: BorderSide(width: 5, color: kPrimaryLightColor)),
      ),
      value: orderInfo[index]['ricambiForniti'],
      emptyListWidget: (value, context) {
        return Column(
          children: [
            Text("Nessun risultato per $value"),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    orderInfo[index]['ricambiForniti'] = value.toString();
                    pzRicambi[index] = value.toString();
                  });
                  Navigator.pop(context);
                },
                child: Text('Usa "$value"'))
          ],
        );
      },
      menuBackgroundColor: kPrimaryLightColor,
      //dropDownDialogPadding: EdgeInsets.all(200),
      icon: const Icon(Icons.arrow_drop_down),
      displayClearIcon: false,
      onTap: () {
        setState(() {
          orderInfo[index]['ricambiForniti'] = "";
          pzRicambi[index] = "";
        });
      },
      closeButton: "Chiudi",
      onChanged: (value) {
        print(value);
        setState(() async {
          pzRicambi[index] = await value['descrizione'];
          orderInfo[index]['ricambiForniti'] = await value['descrizione'];
          orderInfo[index]['prezzo'] = await value['prezzoFornitore'];

          _prezzoController[index].text = value['prezzoFornitore'].toString();
        });
      },

      validator: (value) {
        if (!orderInfo[index]['ricambiForniti'].toString().isNotEmpty) {
          return kRicambiNullError;
        }
        return null;
      },

      hint: () {
        if (orderInfo[index]['ricambiForniti'].toString().isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              orderInfo[index]['ricambiForniti'],
              textAlign: TextAlign.left,
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "Seleziona Ricambi",
              textAlign: TextAlign.left,
            ),
          );
        }
      },
      selectedValueWidgetFn: (value) {
        //print(_ragSocController.text);
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            orderInfo[index]['ricambiForniti'],
            textAlign: TextAlign.left,
          ),
        );
      },
      dialogBox: true,
      isExpanded: true,
      //underline: const NotGiven(),
    );
  }

  List<DropdownMenuItem<Map<String, dynamic>>> _getRicambiSuggestions() {
    // Get the current text from the text controller.

    // Clear the suggestions.
    _suggestionsRicambi.clear();

    // Iterate over the data and add any maps that match the search text to the suggestions.
    for (Map<String, dynamic> map in _optionsRicambi) {
      final String name = map['descrizione'];

      _suggestionsRicambi.add(DropdownMenuItem(
        value: map,
        child: Text(name),
      ));
    }

    // Limit the suggestions to 4 items.

    return _suggestionsRicambi;
  }

  ragSocialeFormField() {
    return SearchChoices.single(
      items: _getAnagraficaSuggestions(),
      fieldDecoration: const BoxDecoration(
        color: kPrimaryLightColor,
        borderRadius: BorderRadius.all(Radius.circular(30)),
        border: Border(
            top: BorderSide(width: 3, color: kPrimaryLightColor),
            bottom: BorderSide(width: 3, color: kPrimaryLightColor),
            left: BorderSide(width: 5, color: kPrimaryLightColor),
            right: BorderSide(width: 5, color: kPrimaryLightColor)),
      ),
      value: _ragSocController.text,
      emptyListWidget: (value, context) {
        return Column(
          children: [
            Text("Nessun risultato per $value"),
            ElevatedButton(
                onPressed: () {
                  _ragSocController.text = "";
                  setState(() {
                    _ragSocController.text = value.toString();
                    _placeController.text = "";
                  });
                  Navigator.pop(context);
                },
                child: Text('Usa "$value"'))
          ],
        );
      },
      menuBackgroundColor: kPrimaryLightColor,
      //dropDownDialogPadding: EdgeInsets.all(200),
      icon: const Icon(Icons.arrow_drop_down),
      displayClearIcon: false,
      onTap: () {
        setState(() {
          _ragSocController.text = "";
          _placeController.text = "";
          _cityController.text = "";
          _pivaController.text = "";
          _numTelController.text = "";
          setState(() {
            cU = false;
          });
        });
      },
      closeButton: "Chiudi",
      onChanged: (value) {
        print(value);
        setState(() async {
          _ragSocController.text = await value['ragSoc'];
          _placeController.text = await value['indir'];
          _cityController.text = await value['local'];

          if (value['partiva'].toString().isNotEmpty) {
            _pivaController.text = await value['partiva'];
            if (partitaIvaRegExp.hasMatch(_pivaController.text)) {
              setState(() {
                cU = true;
              });
            } else {
              setState(() {
                cU = false;
              });
            }
          } else {
            _pivaController.text = await value['codFisc'];
          }
          if (value['tel'].toString().isNotEmpty) {
            _numTelController.text = await value['tel'];
          } else {
            _numTelController.text = await value['tel2'];
          }
        });
      },
      hint: TextFormField(
        controller: _ragSocController,
        decoration: const InputDecoration(hintText: 'Seleziona Anagrafica'),
      ),
      selectedValueWidgetFn: (value) {
        //print(_ragSocController.text);
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            _ragSocController.text,
            textAlign: TextAlign.left,
          ),
        );
      },
      dialogBox: true,
      isExpanded: true,
      //underline: const NotGiven(),
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

  pIvaFormField() {
    return TextFormField(
      controller: _pivaController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      onChanged: (value) {
        _pivaController.text = value.toUpperCase();
        if (partitaIvaRegExp.hasMatch(value)) {
          setState(() {
            cU = true;
          });
        } else {
          setState(() {
            cU = false;
          });
        }
      },
      validator: (value) {
        if (!_submitted) return null;
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

  codUFormField() {
    return TextFormField(
      controller: _codUnivoco,
      textInputAction: TextInputAction.next,
      enabled: cU,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (!_submitted) return null;
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
          _iva = null;
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
          child: Icon(Icons.flag_rounded),
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
        if (!_submitted) return null;
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

  cityFormField() {
    return TextFormField(
      controller: _cityController,
      textInputAction: TextInputAction.next,
      validator:
          FormValidators.requiredIfSubmitted(_submitted, kCittaNullError),
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
    if (_typeIntervention == 'Garanzia') {
      setState(() {
        _iva = '0';
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
}
