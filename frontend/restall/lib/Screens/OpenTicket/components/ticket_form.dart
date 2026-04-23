import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Company/company.dart';

import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/API/Warehouse/wareHouseApi.dart';
import 'package:restall/Screens/ticket_success/ticket_success_screen.dart';
import 'package:restall/components/top_rounded_container.dart';

import 'package:restall/constants.dart';
import 'package:intl/intl.dart';
import 'package:restall/helper/keyboard.dart';
import 'package:restall/theme.dart';
import 'package:search_choices/search_choices.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_search/textfield_search.dart';
import 'package:restall/Screens/OpenTicket/components/barcode_scanner_page.dart';

class TicketForm extends StatefulWidget {
  const TicketForm({super.key});

  @override
  State<TicketForm> createState() => TicketFormState();
}

class TicketFormState extends State<TicketForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _ragSocController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _stateValue;
  String? _typeMValue;
  DateTime? _pickedDate;
  String _selectedOption = '';
  var _options = [];
  var _isLoading = false;
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestions = [];
  String macchina = '';
  String infoMacchina = "";

  @override
  void initState() {
    super.initState();
    //fetchData('');
  }

  void fetchData(valore) async {
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
            'ragSoc1': list['ragSoc1'],
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
        ////print(suggestions);
        setState(() {
          _options = mergedList;
          _getSuggestions();
          ////print(_options); // Limita a 4 suggerimenti
        });
      } else {
        throw Exception('Errore durante la richiesta al server');
      }
    } catch (error) {
      //print(error);
    }
  }

  _sendTicket() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'indirizzo': _placeController.text,
        'infoMacchina': macchina,
        'tipo_macchina': _typeMValue.toString(),
        'stato_macchina': _stateValue.toString(),
        'descrizione': _descriptionController.text,
      };

      int status = await TicketApi().postData(data);
      if (status == 201) {
        setState(() => _isLoading = false);

        // Pulisci il form
        _descriptionController.clear();
        _placeController.clear();
        setState(() {
          _stateValue = null;
          _typeMValue = null;
          infoMacchina = "";
          macchina = "";
        });

        // Naviga alla schermata di successo e passa true come risultato
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketSuccessScreen(),
          ),
        );

        // Se il risultato è true, ritorna true anche qui per indicare successo
        if (result == true && context.mounted) {
          Navigator.pop(context,
              true); // Ritorna alla lista ticket con risultato positivo
        }
      } else {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: "Errore nell'apertura del ticket",
          text: "Si è verificato un problema all'apertura del ticket. Riprova.",
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    } on SocketException catch (e) {
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nell'apertura del ticket",
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nell'apertura del ticket",
        text: "Si è verificato un problema all'apertura del ticket. Riprova.",
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // const Padding(
          //     padding: EdgeInsets.symmetric(vertical: defaultPadding),
          //     child: Align(
          //       alignment: Alignment.centerLeft,
          //       child: Text("Data",
          //           textAlign: TextAlign.start,
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             fontSize: 25,
          //           )),
          //     )),
          // dateFormField(context),
          // const Padding(
          //     padding: EdgeInsets.symmetric(vertical: defaultPadding),
          //     child: Align(
          //       alignment: Alignment.centerLeft,
          //       child: Text("Anagrafica",
          //           textAlign: TextAlign.start,
          //           style: TextStyle(
          //             fontWeight: FontWeight.bold,
          //             fontSize: 25,
          //           )),
          //     )),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: defaultPadding),
          //   child: ragSocialeFormField(),
          // ),
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
                child: Text("Macchina",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding),
            child: machine(),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Tipo Macchina",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding),
            child: typeMachineFormField(),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Stato Macchina",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding),
            child: stateMachineFormField(),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Descrizione problema",
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
          const SizedBox(height: defaultPadding),

          ElevatedButton.icon(
            //onPressed: _isLoading: null ? _onSubmit,
            onPressed: !_isLoading
                ? () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _sendTicket();
                      // if all are valid then go to success screen
                      KeyboardUtil.hideKeyboard(context);
                    }
                  }
                : null,
            style:
                ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
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
                : const Icon(Icons.send_rounded),
            label: const Text('INVIA'),
          ),

          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  TextFormField description() {
    return TextFormField(
      controller: _descriptionController,
      //expands: true,
      maxLines: 5,
      maxLength: 255,
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
    return GooglePlacesAutoCompleteTextFormField(
      textEditingController: _placeController,

      // NUOVO PARAMETRO RICHIESTO: config con la configurazione
      config: const GoogleApiConfig(
        apiKey: "AIzaSyCZiS2tq8NWe-f0XO6eU7D1ZQhSnujZa-A", // ← Era googleAPIKey
        debounceTime: 600, // ← Ora dentro config
        countries: ["it"], // ← Era countries, ora dentro config
      ),

      textInputAction: TextInputAction.next,

      // Validazione migliorata
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return kAddressNullError;
        }
        return null;
      },

      // Decorazione migliorata
      decoration: const InputDecoration(
        hintText: "Inserisci l'indirizzo dell'intervento",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.place_rounded),
        ),
        suffixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),

      // Stile dei suggerimenti (probabilmente cambiato anche questo)
      predictionsStyle: const TextStyle(
        // ← Era predictionsStyle
        color: kPrimaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),

      // Container personalizzato per i suggerimenti
      overlayContainerBuilder: (child) => Material(
        elevation: 8,
        color: kPrimaryLightColor,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 200, // Limita l'altezza dei suggerimenti
          ),
          child: child,
        ),
      ),

      // Gestione del click sui suggerimenti
      onSuggestionClicked: (prediction) {
        _placeController.text = prediction.description ?? '';
        _placeController.selection = TextSelection.fromPosition(
            TextPosition(offset: _placeController.text.length));

        // Nascondi la tastiera dopo la selezione
        FocusScope.of(context).unfocus();
      },

      // Gestione degli errori (potrebbe essere cambiato)
      onError: (error) {
        print('Errore Google Places: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nella ricerca dell\'indirizzo. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
  // ragSocialeFormField() {
  //   return TextFormField(
  //     controller: _ragSocController,
  //     textInputAction: TextInputAction.next,
  //     validator: (value) {
  //       if (value!.isEmpty) {
  //         return kRSocNullError;
  //       }
  //       return null;
  //     },
  //     onChanged: (value){

  //     },
  //     cursorColor: kPrimaryColor,
  //     decoration: const InputDecoration(
  //       hintText: "Anagrafica",
  //       prefixIcon: Padding(
  //         padding: EdgeInsets.all(defaultPadding),
  //         child: Icon(Icons.person_rounded),
  //       ),
  //     ),
  //   );
  // }

  // ragSocialeFormField() {
  //   return SearchChoices.single(
  //     items: _getSuggestions(),
  //     fieldDecoration: const BoxDecoration(
  //       color: kPrimaryLightColor,
  //       borderRadius: BorderRadius.all(Radius.circular(30)),
  //       border: Border(
  //           top: BorderSide(width: 3, color: kPrimaryLightColor),
  //           bottom: BorderSide(width: 3, color: kPrimaryLightColor),
  //           left: BorderSide(width: 5, color: kPrimaryLightColor),
  //           right: BorderSide(width: 5, color: kPrimaryLightColor)),
  //     ),
  //     value: _ragSocController.text,
  //     emptyListWidget: (value, context) {
  //       return Column(
  //         children: [
  //           Text("Nessun risultato per $value"),
  //           ElevatedButton(
  //               onPressed: () {
  //                 _ragSocController.text = "";
  //                 setState(() {
  //                   _ragSocController.text = value.toString();
  //                   _placeController.text = "";
  //                 });
  //                 Navigator.pop(context);
  //               },
  //               child: Text('Usa "$value"'))
  //         ],
  //       );
  //     },
  //     menuBackgroundColor: kPrimaryLightColor,
  //     dropDownDialogPadding: EdgeInsets.all(200),
  //     icon: const Icon(Icons.arrow_drop_down),
  //     displayClearIcon: false,
  //     onTap: () {
  //       setState(() {
  //         _ragSocController.text = "";
  //         _placeController.text = "";
  //       });
  //     },
  //     closeButton: "Chiudi",
  //     onChanged: (value) {
  //       //print(value);
  //       setState(() async {
  //         _ragSocController.text = await value['ragSoc'] + value['ragSoc1'];
  //         _placeController.text = await value['indir'] + ", " + value['local'];
  //       });
  //     },
  //     hint: TextFormField(
  //       controller: _ragSocController,
  //       decoration: const InputDecoration(hintText: 'Seleziona Anagrafica'),
  //     ),
  //     selectedValueWidgetFn: (value) {
  //       ////print(_ragSocController.text);
  //       return Padding(
  //         padding: const EdgeInsets.all(12.0),
  //         child: Text(
  //           _ragSocController.text,
  //           textAlign: TextAlign.left,
  //         ),
  //       );
  //     },
  //     dialogBox: true,
  //     isExpanded: true,
  //     //underline: const NotGiven(),
  //   );
  // }

  List<DropdownMenuItem<Map<String, dynamic>>> _getSuggestions() {
    // Get the current text from the text controller.
    final String text = _ragSocController.text;

    // Clear the suggestions.
    _suggestions.clear();

    // Iterate over the data and add any maps that match the search text to the suggestions.
    for (Map<String, dynamic> map in _options) {
      final String name = map['ragSoc'] + map['ragSoc1'];

      _suggestions.add(DropdownMenuItem(
        value: map,
        child: Text(name),
      ));
    }

    // Limit the suggestions to 4 items.

    return _suggestions;
  }

  DropdownButtonFormField<String> typeMachineFormField() {
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
          _typeMValue = newValue!;
        });
      },
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kTypeMNullError;
        }
        return null;
      },
      items: <String>[
        'Caldo',
        'Freddo',
        'Climatizzazione',
        'Aspirazione',
        'Altro'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
          ),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField<String> stateMachineFormField() {
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

  getInfoMachine(code) async {
    try {
      var response = await WareHouseApi().getMachine(code);
      if (response.statusCode == 200) {
        final body = await json.decode(response.body);
        //print("body: ${body}");
        if (body.isEmpty) {
          FlutterPlatformAlert.showAlert(
            windowTitle: "Errore nella scansione della macchina",
            text: "Macchina non trovata. Riprova.",
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.error,
          );
        } else {
          setState(() {
            macchina = code;
            infoMacchina = body[0]['descrizione'];
          });
        }
      }
    } on Exception catch (e) {
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nella scansione della macchina",
        text: "Si è verificato un problema durante la scansione. Riprova.",
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  machine() {
    return Builder(builder: (context) {
      if (macchina.isEmpty) {
        return ElevatedButton(
          onPressed: () async {
            String code = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerPage(),
                ));
            if (code != (-1).toString()) {
              getInfoMachine(code);
            }

            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Macchina: $macchina'),
            //   ),
            // );
          },
          child: const Text('Scansiona QR'),
        );
      } else {
        return Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.precision_manufacturing_rounded,
                        size: 50, color: kPrimaryColor),
                    SizedBox(height: 10),
                    Text(
                      'Descrizione:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(infoMacchina, textAlign: TextAlign.center),
                    SizedBox(height: 10),
                    Text(
                      'Codice:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(macchina,
                        style: TextStyle(color: kPrimaryColor, fontSize: 18)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    macchina = "";
                  });
                },
                child: Text("Rimuovi macchina"))
          ],
        );
      }
    });
  }
}

class _DatePickerItem extends StatelessWidget {
  const _DatePickerItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
          bottom: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }
}
