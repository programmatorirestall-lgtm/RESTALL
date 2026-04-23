import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import 'package:restalltech/API/Settings/settings.dart';
import 'package:restalltech/API/SignUpRequest/signup.dart';
import 'package:restalltech/Screens/AddTech/add_tech_screen.dart';
import 'package:restalltech/Screens/SideBar/sidebar.dart';
import 'package:restalltech/components/form_error.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/keyboard.dart';
import 'package:restalltech/helper/keyboardoverlay.dart';
import 'package:restalltech/models/Settings.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String?> errors = [];
  final TextEditingController _dirittoFissoController = TextEditingController();
  final TextEditingController _priceForKilometerController =
      TextEditingController();
  final TextEditingController _noTaxAreaController = TextEditingController();
  Set<Map<int, dynamic>> tt = {};

  FocusNode numberFocusNode = FocusNode();

  void addError({String? error}) {
    if (!errors.contains(error))
      setState(() {
        errors.add(error);
      });
  }

  void removeError({String? error}) {
    if (errors.contains(error))
      setState(() {
        errors.remove(error);
      });
  }

  var _isLoading = false;

  Future<void> _onSubmit() async {
    bool ok = true;
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      for (int i = 0; i < tt.length; i++) {
        if (!await _saveSettings(
            tt.elementAt(i).keys.first, tt.elementAt(i).values.first)) {
          ok = false;
        }
        print(tt.elementAt(i).values.first);
      }
      if (ok == true) {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Impostazioni Salvate',
          text: "Il salvataggio delle impostazioni è avventuo con successo.",
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.exclamation,
        );
      } else {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Impossibile salvare impostazioni',
          text: "C'è stato un problema con il salvataggio delle impostazioni.",
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  _getSettings() async {
    final Response response = await SettingsApi().getData();
    final body = json.decode(response.body);

    var settingsList = body['setting'];
    List<Settings> settings = List<Settings>.from(
        settingsList.map((model) => Settings.fromJson(model)));
    _priceForKilometerController.text =
        settings.firstWhere((element) => element.id == 1).value;
    _dirittoFissoController.text =
        settings.firstWhere((element) => element.id == 2).value;
    _noTaxAreaController.text =
        settings.firstWhere((element) => element.id == 3).value;

    return settings;
  }

  _saveSettings(id, value) async {
    print("ID: $id VALUE: $value");
    try {
      var data = {
        'value': value.toString(),
      };
      //print(data);
      Response response = await SettingsApi().setData(id, data);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (e) {
      //print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text:
            'Conessione al server non riuscita, controlla la connessione ad Internet.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  void initState() {
    _getSettings();
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      numberFocusNode.addListener(() {
        bool hasFocus = numberFocusNode.hasFocus;
        if (hasFocus) {
          KeyboardOverlay.showOverlay(context);
        } else {
          KeyboardOverlay.removeOverlay();
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up the focus node
    numberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Costo a kilometro",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          priceForKilometerFormField(),
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
          dirittoFissoFormField(),
          FormError(errors: errors),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("KM Esenzione costo chiamata",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          noTaxAreaFormField(),
          FormError(errors: errors),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _onSubmit,
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
                : const Icon(Icons.save_rounded),
            label: const Text('Salva'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  TextFormField priceForKilometerFormField() {
    return TextFormField(
      controller: _priceForKilometerController,
      onChanged: (value) {
        tt.removeWhere((item) => item.containsKey(1));

        tt.add({1: value});
      },
      decoration: const InputDecoration(
        hintText: "Costo per Kilometro",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.euro_rounded),
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(
            r'^\d+[\.]?\d{0,2}')), // Accetta solo numeri e al massimo una virgola
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

  TextFormField dirittoFissoFormField() {
    return TextFormField(
      controller: _dirittoFissoController,
      onChanged: (value) {
        tt.removeWhere((item) => item.containsKey(2));

        tt.add({2: value});
      },
      decoration: const InputDecoration(
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

  TextFormField noTaxAreaFormField() {
    return TextFormField(
      controller: _noTaxAreaController,
      onChanged: (value) {
        tt.removeWhere((item) => item.containsKey(3));

        tt.add({3: value});
      },
      decoration: const InputDecoration(
        hintText: "Raggio No Tax Area",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Text(
            "KM",
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          ),
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
}
