import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
// import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/services/company_cache_service.dart';

import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/Screens/ticket_success/ticket_success_screen.dart';
// import 'package:restalltech/components/top_rounded_container.dart';

import 'package:restalltech/constants.dart';
import 'package:intl/intl.dart';
import 'package:restalltech/helper/keyboard.dart';
// import 'package:restalltech/theme.dart';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:textfield_search/textfield_search.dart';

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
  final TextEditingController _externalTicketController =
      TextEditingController();
  String? _stateValue;
  String? _typeMValue;
  DateTime? _pickedDate;
  // String _selectedOption = '';
  var _options = [];
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestions = [];
  var _isLoading = false;
  var _isOptionsLoading = true;
  String _ragSoc = "";
  Map<String, dynamic>? _selectedCompany;
  bool _submitted = false;
  final CompanyCacheService _cacheService = CompanyCacheService();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    fetchData('');
    _loadUserData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token != null) {
        final decodedToken = Jwt.parseJwt(token);
        final ragSoc = decodedToken['nome'] + " " + decodedToken['cognome'];

        setState(() {
          _ragSoc = ragSoc;
        });
      }
    } on Error {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  void fetchData(valore) async {
    setState(() => _isOptionsLoading = true);
    try {
      // Utilizza il servizio di cache invece di chiamare direttamente l'API
      final companies = await _cacheService.getCompanies(valore);

      setState(() {
        _options = companies;
        _getSuggestions();
      });
    } catch (error) {
      print(error);
    } finally {
      if (mounted) setState(() => _isOptionsLoading = false);
    }
  }

  _sendTicket() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        //'data': _pickedDate.toString(),
        'indirizzo': _placeController.text,
        'tipo_macchina': _typeMValue.toString(),
        'stato_macchina': _stateValue.toString(),
        'descrizione':
            "Aperto da Amministratore($_ragSoc) \n${_descriptionController.text}",
        'rifEsterno': _externalTicketController.text,
        'ragSocAzienda': _ragSocController.text
      };
      // print(data);
      // print(_pickedDate);
      int status = await TicketApi().postData(data);
      if (status == 201) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return TicketSuccessScreen();
          },
        ));
      } else {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: "Errore nell'apertura del ticket",
          text:
              "Si è verificato un errore durante l'apertura del ticket. Se l'errore persiste contattare lo sviluppatore.",
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    } on SocketException catch (_) {
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
    return Form(
      key: _formKey,
      // disable automatic validation; validate only on submit
      autovalidateMode: AutovalidateMode.disabled,
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
                child: Text("Luogo Intervento",
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
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Cod. Riferimento",
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
          const SizedBox(height: defaultPadding),

          ElevatedButton.icon(
            //onPressed: _isLoading: null ? _onSubmit,
            onPressed: (!_isLoading && !_isOptionsLoading)
                ? () {
                    setState(() => _submitted = true);
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _sendTicket();
                      // if all are valid then go to success screen
                      KeyboardUtil.hideKeyboard(context);
                      _formKey.currentState?.reset();
                      _descriptionController.clear();
                      _ragSocController.clear();
                      _placeController.clear();
                      _dateController.clear();
                      setState(() => _submitted = false);
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
    return TextFormField(
      controller: _placeController,
      textInputAction: TextInputAction.search,
      validator: (value) {
        if (value!.isEmpty) {
          return kAddressNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Luogo",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.place_rounded),
        ),
      ),
    );
  }

  // placeFormField() {
  //   var key = "AIzaSyB8sBHt58zI6VSuOOuFPxI6lGO9tq3JSgk";
  //   return GooglePlacesAutoCompleteTextFormField(
  //       textEditingController: _placeController,
  // decoration: const InputDecoration(
  //       hintText: "Luogo",
  //       prefixIcon: Padding(
  //         padding: EdgeInsets.all(defaultPadding),
  //         child: Icon(Icons.place_rounded),
  //       ),
  //     ),
  //       googleAPIKey: key,
  //       debounceTime: 600, // defaults to 600 ms
  //       countries: [
  //         "it"
  //       ], // optional, by default the list is empty (no restrictions)
  //       isLatLngRequired:
  //           true, // if you require the coordinates from the place details
  //       getPlaceDetailWithLatLng: (prediction) {
  //         // this method will return latlng with place detail
  //         print("Coordinates: (${prediction.lat},${prediction.lng})");
  //       }, // this callback is called when isLatLngRequired is true
  //       itmClick: (prediction) {
  //         _placeController.text = prediction.description!;
  //         _placeController.selection = TextSelection.fromPosition(
  //             TextPosition(offset: prediction.description!.length));
  //       });
  // }

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

  ragSocialeFormField() {
    return TextFormField(
      controller: _ragSocController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Cerca Anagrafica',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.business),
        ),
        suffixIcon: _isOptionsLoading
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
      onTap: _isOptionsLoading
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildAnagraficaSearchModal(),
              );
            },
    );
  }

  List<DropdownMenuItem<Map<String, dynamic>>> _getSuggestions() {
    // Clear the suggestions.
    _suggestions.clear();

    // Iterate over the data and add any maps that match the search text to the suggestions.
    for (Map<String, dynamic> map in _options) {
      final String name = map['ragSoc'];

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
      items: kTypeMachine,
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

  Widget _buildAnagraficaSearchModal() {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> displayedCompanies = List.from(_options);
    bool isSearching = false;
    Timer? debounceTimer;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Filter function (client-side)
        void filterCompanies(String query) {
          setModalState(() {
            if (query.isEmpty) {
              displayedCompanies = List.from(_options);
            } else {
              displayedCompanies = _options
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
                final existingIds = _options.map((e) => e['id']).toSet();

                final uniqueNewResults = companies
                    .where((item) => !existingIds.contains(item['id']))
                    .toList();

                _options.addAll(uniqueNewResults);

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
                                  Navigator.pop(context);
                                  _showManualEntryDialog(searchController.text);
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
                              setState(() {
                                _selectedCompany = company;
                                _ragSocController.text = ragSoc;
                                _placeController.text =
                                    indir + (local.isNotEmpty ? ", $local" : "");
                              });
                              Navigator.pop(context);
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

  void _showManualEntryDialog(String initialRagSoc) {
    final formKey = GlobalKey<FormState>();
    final ragSocCtrl = TextEditingController(text: initialRagSoc);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.business, color: secondaryColor),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inserimento Manuale',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
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
                  _selectedCompany = null;
                  _ragSocController.text = ragSocCtrl.text;
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

// _DatePickerItem rimosso perché non utilizzato
