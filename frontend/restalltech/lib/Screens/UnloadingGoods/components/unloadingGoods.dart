import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/WareHouse/wareHouseApi.dart';
import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';

import 'package:restalltech/helper/barcodescanner.dart';

class UnloadingGoods extends StatefulWidget {
  const UnloadingGoods({super.key});

  @override
  _UnloadingGoodsState createState() => _UnloadingGoodsState();
}

class _UnloadingGoodsState extends State<UnloadingGoods> {
  String scannedCode = '';
  var _isLoading = false;
  List<Map<String, dynamic>> summaryList = [];

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
            'name': articolo['descrizione'].toString()
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
      "scarichi": summaryList.map((item) {
        return {
          "codiceArticolo": item["code"],
          "quantita": item["quantity"],
        };
      }).toList()
    };

    int status = await WareHouseApi().scarichi(filteredData);
    if (status == 201) {
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Prelievo Completato',
        text: 'Lo scarico è stato effettuato.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.exclamation,
      );
      summaryList = [];
    } else {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Riprova.\nLo scarico non è stato effettuato.',
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
      return article[0];
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reso Merci"),
        ),
        backgroundColor: Colors.transparent,
            body: ListView.builder(
              itemCount: summaryList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      'Art. ${summaryList[index]['code']}\n${summaryList[index]['name']}'),
                  subtitle: Text('Quantità: ${summaryList[index]['quantity']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              int quantity = summaryList[index]['quantity'];
                              return AlertDialog(
                                backgroundColor: kPrimaryColor,
                                title: Text(
                                  'Quantità',
                                  style: const TextStyle(
                                      color: white, fontSize: 36),
                                ),
                                content: TextFormField(
                                  initialValue: quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    quantity = int.tryParse(value) ?? 0;
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      updateQuantity(
                                          summaryList[index]['code'], quantity);
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Salva',
                                      style: const TextStyle(color: white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_rounded),
                        onPressed: () {
                          removeFromSummary(summaryList[index]['code']);
                        },
                      ),
                    ],
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
                      if (scannedCode.isNotEmpty && scannedCode != '-1')
                        addToSummary(code); // Aggiunge il codice al riepilogo
                      // // Torna alla schermata di riepilogo
                    }
                  : null,
              child: Icon(Icons.qr_code_scanner_rounded),
            ),
            bottomNavigationBar: BottomAppBar(
              surfaceTintColor: white,
              child: ElevatedButton.icon(
                //onPressed: _isLoading: null ? _onSubmit,
                onPressed: isSendButtonEnabled()
                    ? () {
                        sendData();
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
                label: const Text('Invia'),
              ),
            ),
      ),
    );
  }
}
