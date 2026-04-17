import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/WareHouse/wareHouseApi.dart';
import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';
import 'package:search_choices/search_choices.dart';

import 'package:restalltech/helper/barcodescanner.dart';

class PriceProduct extends StatefulWidget {
  const PriceProduct({super.key});

  @override
  _PriceProductState createState() => _PriceProductState();
}

class _PriceProductState extends State<PriceProduct> {
  String scannedCode = '';
  var _isLoading = false;
  List<Map<String, dynamic>> summaryList = [];
  List<DropdownMenuItem<Map<String, dynamic>>> _suggestionsRicambi = [];
  var _optionsRicambi = [];

  void addToSummary(String code) async {
    var articolo;
    bool isAlreadyAdded = false;
    for (var item in summaryList) {
      if (item['code'] == code) {
        isAlreadyAdded = true;
        break;
      }
    }
    articolo = await getName(code);

    if (articolo != null && articolo.isNotEmpty) {
      if (!isAlreadyAdded) {
        setState(() {
          summaryList.add({
            'code': articolo['codArticolo'].toString(),
            'quantity': 1,
            'name': articolo['descrizione'].toString(),
            'price': articolo['prezzoFornitore'].toString()
          });
        });
      }
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Articolo ' + code + ' sconosciuto',
        text: 'Riprova.\n O contatta il magazziniere.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  void updateQuantity(String code, int quantity) {
    for (var item in summaryList) {
      if (item['code'] == code) {
        setState(() {
          item['quantity'] = quantity;
        });
        break;
      }
    }
  }

  sendData() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> filteredData = {
      "rientri": summaryList.map((item) {
        return {
          "codiceArticolo": item["code"],
          "quantita": item["quantity"],
        };
      }).toList()
    };

    int status = await WareHouseApi().setRientri(filteredData);
    if (status == 201) {
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Prelievo Completato',
        text: 'Il rientro è stato effettuato.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.exclamation,
      );
      summaryList = [];
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Riprova.\nIl rientro non è stato effettuato.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
      setState(() => _isLoading = false);
    }
  }

  void removeFromSummary(String code) {
    setState(() {
      summaryList.removeWhere((item) => item['code'] == code);
    });
  }

  bool isSendButtonEnabled() {
    return summaryList.isNotEmpty && !_isLoading;
  }

  getName(code) async {
    final Response response = await WareHouseApi().getArticle(code);
    final List<dynamic> article = json.decode(response.body);
    if (response.statusCode == 200 && article.isNotEmpty) {
      print(article[0]);
      return article[0];
    } else {
      return null;
    }
  }

  ricambiForm() {
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
      value: summaryList[0]['ricambiForniti'],
      emptyListWidget: (value, context) {
        return Column(
          children: [
            Text("Nessun risultato per $value"),
            ElevatedButton(
                onPressed: () {
                  bool exists = summaryList
                      .any((item) => item['ricambiForniti'] == value);

                  if (exists) {
                    FlutterPlatformAlert.showAlert(
                      windowTitle: 'Ricambio già presente',
                      text: 'Il ricambio $value è già stato aggiunto.',
                      alertStyle: AlertButtonStyle.ok,
                      iconStyle: IconStyle.warning,
                    );
                  } else {
                    summaryList[0]['ricambiForniti'] = value.toString();
                  }
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

      closeButton: "Chiudi",

      hint: () {
        if (summaryList[0]['ricambiForniti'].toString().isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              summaryList[0]['ricambiForniti'],
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

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Prezzo Merci"),
        ),
        backgroundColor: Colors.transparent,
        body: summaryList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nessun articolo scansionato',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Usa il pulsante per scansionare un codice',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: summaryList.length,
                    itemBuilder: (context, index) {
                      final item = summaryList[index];
                      final price = double.parse(item['price']);

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icona articolo
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: secondaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: secondaryColor,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Info articolo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Art. ${item['code']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    // Prezzo in evidenza
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.euro,
                                            size: 18,
                                            color: Colors.green[700],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            price.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
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
                      if (scannedCode.isNotEmpty && scannedCode != '-1') {
                        addToSummary(code);
                      }
                    }
                  : null,
              backgroundColor: secondaryColor,
          child: Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
