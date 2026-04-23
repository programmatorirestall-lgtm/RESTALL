import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
// import 'package:file_previewer/file_previewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/Preventivi/preventiviApi.dart';

import 'package:restalltech/constants.dart';

import 'package:restalltech/helper/keyboard.dart';

class PreventiveForm extends StatefulWidget {
  const PreventiveForm({super.key});

  @override
  State<PreventiveForm> createState() => PreventiveFormState();
}

class PreventiveFormState extends State<PreventiveForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ragSocController = TextEditingController();
  final TextEditingController _cellPhoneController = TextEditingController();
  var _isLoading = false;
  var image;
  @override
  void initState() {
    super.initState();
  }

  _sendPreventive() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'descrizione': _descriptionController.text,
        'ragSocialeAzienda': _ragSocController.text,
        'numCellulare': _cellPhoneController.text
      };
      ////print(jsonEncode(data));
      // //print(_pickedDate);
      Response response = await PreventiviApi().postData(data);
      //print(response.statusCode);
      //print(response.body);
      if (response.statusCode == 201) {
        try {
          if (_selectedFile != null) {
            Map<String, dynamic> jsonResponse = json.decode(response.body);

            // Estrai l'ID
            int id = jsonResponse['result']['id'];
            StreamedResponse r2 = await PreventiviApi()
                .uploadOpenPreventivo(file: _selectedFile, id: id);
            //print(r2.statusCode);
            if (r2.statusCode == 200) {
              setState(() => _isLoading = false);
              clearAfterSubmit();
              success();
            } else {
              setState(() => _isLoading = false);
              clearAfterSubmit();
              FlutterPlatformAlert.showAlert(
                windowTitle: "Preventivo Preso in Carico senza documento",
                text:
                    'Il preventivo è stato creato con successo, un operatore lo elaborerà il prima possibile.Purtroppo non è stato possibile caricare il documento',
                alertStyle: AlertButtonStyle.ok,
                iconStyle: IconStyle.error,
              );
            }
          } else {
            setState(() => _isLoading = false);
            clearAfterSubmit();
            success();
          }
        } on Exception catch (e) {
          setState(() => _isLoading = false);
          clearAfterSubmit();
          FlutterPlatformAlert.showAlert(
            windowTitle: "Preventivo Preso in Carico senza documento",
            text:
                'Il preventivo è stato creato con successo, un operatore lo elaborerà il prima possibile.Purtroppo non è stato possibile caricare il documento',
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.error,
          );
        }

        //Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: "Errore nell'apertura del preventivo",
          text:
              "Si è verificato un problema all'apertura del preventivo. Riprova.",
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    } on SocketException catch (e) {
      //print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: "Errore nell'apertura del preventivo",
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  void clearAfterSubmit() {
    _descriptionController.clear();
    _cellPhoneController.clear();
    _ragSocController.clear();
    _removeFile();
  }

  success() {
    return FlutterPlatformAlert.showAlert(
      windowTitle: "Preventivo Preso in Carico",
      text:
          'Il preventivo è stato creato con successo, un operatore lo elaborerà il prima possibile.',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.information,
    );
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
                child: Text("Rag.Sociale/Anagarfica",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding),
            child: ragSoc(),
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
            child: cellphone(),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Documenti",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          Padding(
            padding: const EdgeInsets.only(bottom: defaultPadding),
            child: SizedBox(child: caricaFile()),
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
                      _sendPreventive();
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

  File? _selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });

      // if (_selectedFile!.path.endsWith(".pdf")) {
      //   try {
      //     final thumbnail = await FilePreview.getThumbnail(_selectedFile!.path);
      //     setState(() {
      //       image = thumbnail;
      //     });
      //   } catch (e) {
      //     image = Image.asset("");
      //   }
      // }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  caricaFile() {
    return Column(
      children: [
        if (_selectedFile == null)
          ElevatedButton(
            onPressed: _pickFile,
            child: Text("Seleziona File"),
          ),
        if (_selectedFile != null) ...[
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryLightColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPrimaryLightColor),
            ),
            child: Column(
              children: [
                // if (_selectedFile!.path.endsWith(".pdf"))
                //   image != null
                //       ? Container(
                //           height: 200,
                //           padding: const EdgeInsets.all(8.0),
                //           color: Colors.white,
                //           child: image,
                //         )
                //       : Container()

                // else
                if (_selectedFile!.path.endsWith(".jpg") ||
                    _selectedFile!.path.endsWith(".png"))
                  Image.file(
                    _selectedFile!,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                else
                  Text("Anteprima non disponibile per questo tipo di file"),
                SizedBox(height: 10),
                Text("${_selectedFile!.path.split('/').last}",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: _removeFile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: Text("Rimuovi",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ]
      ],
    );
  }

  TextFormField ragSoc() {
    return TextFormField(
      controller: _ragSocController,
      textInputAction: TextInputAction.search,
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Rag.Sociale/Anagarfica",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.person_rounded),
        ),
      ),
    );
  }

  cellNumberFormField() {
    return TextFormField(
      controller: _cellPhoneController,
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

  TextFormField cellphone() {
    return TextFormField(
      controller: _cellPhoneController,
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
}
