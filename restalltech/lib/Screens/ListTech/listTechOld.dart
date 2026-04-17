import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:d_chart/d_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:responsive_table/responsive_table.dart';

import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/TicketTech/tickeTech.dart';
import 'package:restalltech/Screens/AddTech/add_tech_screen.dart';
import 'package:restalltech/Screens/ListTech/dropdown.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/keyboard.dart';
import 'package:restalltech/models/Technician.dart';

class ListTech extends StatefulWidget {
  const ListTech({Key? key}) : super(key: key);
  @override
  ListTechState createState() => ListTechState();
}

class ListTechState extends State<ListTech> {
  late List<DatatableHeader> _headers;

  List<int> _perPages = [5, 10, 20, 50, 100];
  int _total = 0;
  int? _currentPerPage = 50;
  List<bool>? _expanded;
  String? _searchKey = "id";

  int _currentPage = 1;
  bool _isSearch = false;
  List<Map<String, dynamic>> _sourceOriginal = [];
  List<Map<String, dynamic>> _sourceFiltered = [];
  List<Map<String, dynamic>> _source = [];
  List<Map<String, dynamic>> _selecteds = [];
  // ignore: unused_field
  String _selectableKey = "id";
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime dateTime = DateTime.now();
  final TextEditingController _timeController = TextEditingController();
  String? _sortColumn;
  bool _sortAscending = true;
  bool _isLoading = true;
  bool _showSelect = false;
  late bool verified;

  final MaterialStateProperty<Icon?> thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  List<Technician> _tech = [];
  _setTT(data) async {
    try {
      int status = await TTApi().postData(data);
      print(status);
    } on SocketException catch (e) {
      print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _getTechs() async {
    final Response response = await TechApi().getData();
    final body = json.decode(response.body);
    var techList = body['tecnico'];
    //print("LISTA TECH: $techList");
    List<Map<String, dynamic>> list = techList.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> mergedList = list.map((item) {
      Map<String, dynamic> techs = {
        'id': item['id'],
        'nome': item['nome'],
        'cognome': item['cognome'],
        'verified': item['verified'],
        'paga': item['pagamento_orario'],
      };
      return techs;
    }).toList();

    return mergedList;
  }

  initializeData() async {
    // _currentPerPage = 10;
    _currentPage = 1;

    _mockPullData();
  }

  _mockPullData() async {
    List<Map<String, dynamic>> techs = await _getTechs();
    //print(tickets);
    if (techs.isEmpty) {
      _currentPerPage = techs.length;
      _perPages = [techs.length];

      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Non ci sono tecnici.',
        text: 'In caso di problemi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
    } else if (techs.length < _currentPerPage! && techs.isNotEmpty) {
      _currentPerPage = techs.length;

      if (!_perPages.contains(techs.length))
        _perPages = [techs.length, 10, 50, 75, 100];

      _total = techs.length;
      _expanded = List.generate(techs.length, (index) => false);
    } else {
      _total = techs.length;
      _expanded = List.generate(_currentPerPage!, (index) => false);
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2)).then((value) {
      _sourceOriginal.clear();
      _sourceOriginal.addAll(techs);
      _sourceFiltered = _sourceOriginal;
      _total = _sourceFiltered.length;
      _source = _sourceFiltered.getRange(0, _currentPerPage!).toList();
      setState(() => _isLoading = false);
    });
  }

  _resetData({start = 0}) async {
    setState(() {
      _isLoading = true;
    });

    var _expandedLen =
        _total - start < _currentPerPage! ? _total - start : _currentPerPage;

    if (start >= 0 && start < _sourceFiltered.length) {
      _expanded = List.generate(_expandedLen as int, (index) => false);
      _source.clear();
      _source = _sourceFiltered.getRange(start, start + _expandedLen).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  _filterData(value) {
    setState(() => _isLoading = true);

    try {
      if (value == "" || value == null) {
        _sourceFiltered = _sourceOriginal;
      } else {
        _sourceFiltered = _sourceOriginal
            .where((data) => data[_searchKey!]
                .toString()
                .toLowerCase()
                .contains(value.toString().toLowerCase()))
            .toList();
      }

      _total = _sourceFiltered.length;
      var _rangeTop = _total < _currentPerPage! ? _total : _currentPerPage!;
      _expanded = List.generate(_rangeTop, (index) => false);
      _source = _sourceFiltered.getRange(0, _rangeTop).toList();
    } catch (e) {
      print(e);
    }
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();

    /// set headers
    _headers = [
      DatatableHeader(
        text: "Stato",
        value: "verified",
        show: true,
        editable: true,
        sortable: true,
        textAlign: TextAlign.end,
        sourceBuilder: (value, row) {
          if (value.compareTo("TRUE") == 0) {
            verified = true;
          } else {
            verified = false;
          }
          return Switch(
            thumbIcon: thumbIcon,
            value: verified,
            onChanged: (bool val) {
              if (row['verified'].toString().compareTo("TRUE") == 0) {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(
                      " ${row['cognome']} ${row['nome']}",
                      style: TextStyle(fontSize: 32, color: secondaryColor),
                    ),
                    content: const Text(
                        'Sei sicuro di voler disattivare il tecnico?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Annulla'),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          var data = {"verified": val.toString().toUpperCase()};
                          int resp =
                              await TechApi().setStatusTech(data, row['id']);
                          print(resp);
                          if (resp == 200) {
                            setState(() {
                              row['verified'] = val.toString().toUpperCase();
                            });
                          }
                        },
                        child: const Text('Disattiva Tecnico'),
                      ),
                    ],
                  ),
                );
              } else {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(
                      " ${row['cognome']} ${row['nome']}",
                      style: TextStyle(fontSize: 32, color: secondaryColor),
                    ),
                    content:
                        const Text('Sei sicuro di voler attivare il tecnico?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Annulla'),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          var data = {"verified": val.toString().toUpperCase()};
                          int resp =
                              await TechApi().setStatusTech(data, row['id']);
                          print(resp);
                          if (resp == 200) {
                            setState(() {
                              row['verified'] = val.toString().toUpperCase();
                            });
                          }
                        },
                        child: const Text('Attiva Tecnico'),
                      ),
                    ],
                  ),
                );
              }
            },
          );

          // const Icon(
          //   Icons.check_circle_rounded,
          //   color: Colors.green,
          //   size: 35,
          // ),
          // if (value.compareTo("TRUE") == 0) Text("Attivo"),
          // if (value.compareTo("FALSE") == 0)
          //   const Icon(
          //     Icons.dangerous_rounded,
          //     color: Colors.red,
          //     size: 35,
          //   ),
        },
      ),
      DatatableHeader(
          text: "Cognome",
          value: "cognome",
          show: true,
          sortable: true,
          textAlign: TextAlign.left),
      DatatableHeader(
          text: "Nome",
          value: "nome",
          show: true,
          sortable: true,
          textAlign: TextAlign.left),
      DatatableHeader(
        text: "Paga Oraria",
        value: "paga",
        show: true,
        sortable: true,
        textAlign: TextAlign.end,
      ),
    ];

    initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ResponsiveDatatable(
            title: Row(
              children: [
                // if (_selecteds.isNotEmpty)
                //   Column(
                //     children: [
                //       Container(
                //         width: 260,
                //         child: Padding(
                //             padding: const EdgeInsets.only(top: 8, bottom: 8),
                //             child: _selectTech(null, _selecteds)),
                //       ),
                //     ],
                //   ),
                IconButton(
                  onPressed: initializeData,
                  tooltip: 'Ricarica',
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: appBarColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return AddTechScreen();
                      },
                    ));
                  },
                  tooltip: 'Aggiungi Tecnico',
                  icon: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: appBarColor,
                  ),
                ),
              ],
            ),
            reponseScreenSizes: [ScreenSize.xs],
            actions: [
              if (_isSearch)
                Expanded(
                    child: TextField(
                  decoration: InputDecoration(
                      hintText: _searchKey!
                          .replaceAll(new RegExp('[\\W_]+'), ' ')
                          .toUpperCase(),
                      prefixIcon: IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _isSearch = false;
                            });
                            initializeData();
                          }),
                      suffixIcon: IconButton(
                          tooltip: 'Cerca',
                          icon: const Icon(Icons.search),
                          onPressed: () {})),
                  onSubmitted: (value) {
                    _filterData(value);
                  },
                )),
              if (!_isSearch)
                IconButton(
                    icon: const Icon(Icons.search_rounded),
                    color: appBarColor,
                    onPressed: () {
                      setState(() {
                        _isSearch = true;
                      });
                    }),
            ],
            headers: _headers,
            source: _source,
            selecteds: _selecteds,
            showSelect: _showSelect,
            autoHeight: false,
            dropContainer: (data) {
              if (data.isEmpty) {
                return const Text("no data");
              }
              return TechDropDownContainer(tech: data);
              //return const Text("no data");
            },
            onChangedRow: (value, header) {
              /// print(value);
              /// print(header);
            },
            onSubmittedRow: (value, header) {
              print(value);

              /// print(header);
            },
            onTabRow: (data) {
              //print(data);
            },
            onSort: (value) {
              setState(() => _isLoading = true);

              setState(() {
                _sortColumn = value;
                _sortAscending = !_sortAscending;
                if (_sortAscending) {
                  _sourceFiltered.sort(
                      (a, b) => b["$_sortColumn"].compareTo(a["$_sortColumn"]));
                } else {
                  _sourceFiltered.sort(
                      (a, b) => a["$_sortColumn"].compareTo(b["$_sortColumn"]));
                }
                var _rangeTop = _currentPerPage! < _sourceFiltered.length
                    ? _currentPerPage!
                    : _sourceFiltered.length;
                _source = _sourceFiltered.getRange(0, _rangeTop).toList();
                _searchKey = value;

                _isLoading = false;
              });
            },
            expanded: _expanded,
            sortAscending: _sortAscending,
            sortColumn: _sortColumn,
            isLoading: _isLoading,
            onSelect: (value, item) {
              // print("$value  $item ");
              if (value!) {
                setState(() => _selecteds.add(item));
              } else {
                setState(() => _selecteds.removeAt(_selecteds.indexOf(item)));
              }
            },
            onSelectAll: (value) {
              if (value!) {
                setState(() =>
                    _selecteds = _source.map((entry) => entry).toList().cast());
              } else {
                setState(() => _selecteds.clear());
              }
            },
            footers: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: const Text("Elementi"),
              ),
              if (_perPages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DropdownButton<int>(
                    value: _currentPerPage,
                    items: _perPages
                        .map((e) => DropdownMenuItem<int>(
                              child: Text("$e"),
                              value: e,
                            ))
                        .toList(),
                    onChanged: (dynamic value) {
                      setState(() {
                        _currentPerPage = value;
                        _currentPage = 1;
                        _resetData();
                      });
                    },
                    isExpanded: false,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                    "$_currentPage - ${_currentPerPage! + _currentPage - 1} di $_total"),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                ),
                onPressed: _currentPage == 1
                    ? null
                    : () {
                        var _nextSet = _currentPage - _currentPerPage!;
                        setState(() {
                          _currentPage = _nextSet > 1 ? _nextSet : 1;
                          _resetData(start: _currentPage - 1);
                        });
                      },
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onPressed: _currentPage + _currentPerPage! - 1 >= _total
                    ? null
                    : () {
                        var _nextSet = _currentPage + _currentPerPage!;
                        setState(() {
                          _currentPage = _nextSet < _total
                              ? _nextSet
                              : _total - _currentPerPage!;
                          _resetData(start: _nextSet - 1);
                        });
                      },
                padding: const EdgeInsets.symmetric(horizontal: 15),
              )
            ],
            headerDecoration: BoxDecoration(
              color: appBarColor,
              border: Border.all(
                color: appBarColor,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            selectedDecoration: BoxDecoration(
                color: appBarColor,
                border: Border.all(
                  color: appBarColor,
                  width: 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            headerTextStyle: const TextStyle(color: Colors.white),
            rowTextStyle: const TextStyle(color: Colors.black),
            selectedTextStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
