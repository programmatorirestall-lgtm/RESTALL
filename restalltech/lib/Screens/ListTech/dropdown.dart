import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:d_chart/commons/config_render/config_render.dart';
import 'package:d_chart/commons/data_model/data_model.dart';
import 'package:d_chart/ordinal/pie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/Screens/ListTech/listTech.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/keyboard.dart';

class TechDropDownContainer extends StatefulWidget {
  const TechDropDownContainer({super.key, required this.tech});
  final Map<String, dynamic> tech;
  @override
  State<TechDropDownContainer> createState() => TechDropDownContainerState();
}

class TechDropDownContainerState extends State<TechDropDownContainer> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;
  final TextEditingController _pagaController = TextEditingController();

  static Future<Map<String, dynamic>> _getDetails(data) async {
    final Response response = await TechApi().getTechbyID(data['id']);
    final body = json.decode(response.body);
    var item = body['analytics'];
    print(item);

    return item;
  }

  setPaga() async {
    try {
      var data = {
        'pagamento_orario': _pagaController.text,
      };
      int status = await TechApi().setPaga(data, widget.tech['id']);
      if (status == 200) {
        // ignore: use_build_context_synchronously
        setState(() => _isLoading = false);
        Navigator.pop(context);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Paga salvata',
          text: 'La paga è stata correttamente salvata',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.exclamation,
        );
      } else {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Si è verificato un errore',
          text: 'La paga non è stata correttamente salvata.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
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

  pagaFormField() {
    return TextFormField(
      controller: _pagaController,
      textInputAction: TextInputAction.done,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      validator: (value) {
        if (value!.isEmpty) {
          return kAddressNullError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Paga oraria",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.euro_rounded),
        ),
      ),
    );
  }

  void _onSubmit() {
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      setPaga();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var tech = _getDetails(widget.tech);
    _pagaController.text = widget.tech['paga'].toString();
    return FutureBuilder<Map<String, dynamic>>(
        future: tech,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: secondaryColor));
          } else if (snapshot.hasData) {
            final techData = snapshot.data!;
            // return SizedBox(
            //     child: Text("Descrizione: " + ticket['descrizione']));
            List<OrdinalData> numericDataList = [
              OrdinalData(
                  domain: 'In Corso',
                  measure: techData['incorso'],
                  color: Colors.grey),
              OrdinalData(
                  domain: 'Sospesi',
                  measure: techData['numSospesi'],
                  color: Colors.red),
              OrdinalData(
                  domain: 'Chiusi',
                  measure: techData['chiusi'],
                  color: Colors.green),
            ];

            return Container(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 50,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.grey,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  "In Corso: ",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor),
                                ),
                                Text(
                                  techData['incorso'].toString(),
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      color: appBarColor),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  "Chiusi: ",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor),
                                ),
                                Text(
                                  techData['chiusi'].toString(),
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      color: appBarColor),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.handyman_rounded,
                                  color: Colors.red,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  "Sospesi: ",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor),
                                ),
                                Text(
                                  techData['numSospesi'].toString(),
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500,
                                      color: appBarColor),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 25,
                            ),
                            //Text(ticket['descrizione']),
                            const SizedBox(
                              height: 25,
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 300,
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: DChartPieO(
                        data: numericDataList,
                        configRenderPie: const ConfigRenderPie(
                          arcWidth: 40,
                          arcLength: 7 / 5 * pi,
                          startAngle: 4 / 5 * pi,
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Paga Oraria: ",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                child: pagaFormField(),
                                width: 250,
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: ElevatedButton.icon(
                                //onPressed: _isLoading: null ? _onSubmit,
                                onPressed: !_isLoading
                                    ? () {
                                        _onSubmit();
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
                                label: const Text('Conferma'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Text("Descrizione: Nessuna");
          }
        });
  }
}
