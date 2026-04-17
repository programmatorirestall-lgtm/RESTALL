import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Company/company.dart';

import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/Screens/ticket_success/ticket_success_screen.dart';
import 'package:restall/components/top_rounded_container.dart';

import 'package:restall/constants.dart';
import 'package:intl/intl.dart';
import 'package:restall/helper/keyboard.dart';
import 'package:restall/theme.dart';
import 'package:search_choices/search_choices.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:textfield_search/textfield_search.dart';

class AddCompanyForm extends StatefulWidget {
  const AddCompanyForm({super.key});

  @override
  State<AddCompanyForm> createState() => AddCompanyFormState();
}

class AddCompanyFormState extends State<AddCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _ragSocController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pivaController = TextEditingController();
  final TextEditingController _codUnivoco = TextEditingController();
  final TextEditingController _numTelController = TextEditingController();
  String? _stateValue;
  String? _typeMValue;
  DateTime? _pickedDate;
  String _selectedOption = '';
  var _options = [];
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestions = [];
  bool cU = false;
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

  _addCompany() async {
    try {
      var data = {
        //'data': _pickedDate.toString(),
        'indirizzo': _placeController.text,
        'tipo_macchina': _typeMValue.toString(),
        'stato_macchina': _stateValue.toString(),
        'descrizione': _descriptionController.text,
      };
      //print(jsonEncode(data));
      // //print(_pickedDate);
      int status = await TicketApi().postData(data);
      if (status == 201) {
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, TicketSuccessScreen.routeName);
      } else {
        Navigator.pushNamed(context, TicketSuccessScreen.routeName);
      }
    } on SocketException catch (e) {
      //print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nell'aggiunta dell' azienda",
        text:
            'Conessione al server non riuscita, controlla la connessione ad Internet e riprova.',
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
                child: Text("Partita IVA",
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

          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _addCompany();
                // if all are valid then go to success screen
                KeyboardUtil.hideKeyboard(context);
                _formKey.currentState?.reset();
                _descriptionController.clear();
                _ragSocController.clear();
                _placeController.clear();
                _dateController.clear();
              }
            },
            child: Text(
              "Aggiungi".toUpperCase(),
            ),
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  TextFormField dateFormField(BuildContext context) {
    return TextFormField(
      controller: _dateController,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      readOnly: true,
      cursorColor: kPrimaryColor,
      onTap: () async {
        await datePick(context);
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kDateNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Data",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.calendar_month_rounded),
        ),
      ),
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

  Column placeFormField() {
    return Column(
      children: [
        TextFormField(
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
            hintText: "Indirizzo",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.place_rounded),
            ),
          ),
        ),
      ],
    );
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
        if (value!.isEmpty) {
          return kPIVANullError;
        } else if (!partitaIvaRegExp.hasMatch(value)) {
          return kInvalidPIvaError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Partita IVA",
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

  Column cityFormField() {
    return Column(
      children: [
        TextFormField(
          controller: _cityController,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value!.isEmpty) {
              return kAddressNullError;
            }
            return null;
          },
          cursorColor: kPrimaryColor,
          decoration: const InputDecoration(
            hintText: "Città",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.place_rounded),
            ),
          ),
        ),
      ],
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

  ragSocialeFormField() {
    return TextFormField(
      controller: _ragSocController,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return kRSocNullError;
        }
        return null;
      },
      onChanged: (value) {},
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Rag. Sociale",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.person_rounded),
        ),
      ),
    );
  }

  Future<void> datePick(BuildContext context) async {
    _pickedDate = await showDatePicker(
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        context: context,
        locale: const Locale('it', 'IT'),
        initialDate: DateTime.now(),
        firstDate: DateTime
            .now(), //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));
    ThemeData(
        textTheme: const TextTheme(
            bodyLarge: TextStyle(
                fontSize: 2.0), // <-- here you can do your font smaller
            bodyMedium: TextStyle(fontSize: 6.0)));

    if (_pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(_pickedDate!);

      setState(() {
        _dateController.text =
            formattedDate; //set output date to TextField value.
      });
    } else {
      (value) {
        if (value!.isEmpty) {
          return kStateMNullError;
        }
        return null;
      };
    }
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
