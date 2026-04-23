import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
// import 'package:file_previewer/file_previewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restall/API/Preventivi/preventiviApi.dart';

import 'package:restall/constants.dart';

import 'package:restall/helper/keyboard.dart';

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
                .uploadPreventivo(file: _selectedFile, id: id);
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
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? result = await _picker.pickImage(source: source);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.path);
      });
    }
  }

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

  Widget caricaFile() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _selectedFile != null ? kPrimaryColor : Colors.grey.shade300,
          width: 2,
        ),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedFile == null) ...[
            // Sezione upload quando nessun file è selezionato
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: kPrimaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "Carica un documento",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Seleziona un file o scatta una foto",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            // Bottoni per la selezione
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor,
                          kPrimaryColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      icon: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Carica File",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  icon: Icons.photo_library_outlined,
                  onTap: () => _pickImage(ImageSource.gallery),
                  tooltip: "Galleria",
                ),
                const SizedBox(width: 8),
                _buildQuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _pickImage(ImageSource.camera),
                  tooltip: "Fotocamera",
                ),
              ],
            ),
          ] else ...[
            // Sezione preview quando un file è selezionato
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kPrimaryLightColor.withOpacity(0.1),
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Anteprima del file
                  _buildFilePreview(),
                  const SizedBox(height: 16),

                  // Informazioni sul file
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFileIcon(),
                            color: kPrimaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.path.split('/').last,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getFileSize(),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Caricato",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottoni azione
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _removeFile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.red.shade200,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text(
                            "Rimuovi",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _removeFile();
                            _pickFile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor.withOpacity(0.1),
                            foregroundColor: kPrimaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: kPrimaryColor.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text(
                            "Sostituisci",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = _selectedFile!.path.toLowerCase();

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.file(
            _selectedFile!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _getFileIcon(),
                size: 32,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Anteprima non disponibile",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getFileIcon() {
    final fileName = _selectedFile!.path.toLowerCase();

    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png')) {
      return Icons.image;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileSize() {
    final bytes = _selectedFile!.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
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
