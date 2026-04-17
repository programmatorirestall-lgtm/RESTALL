import 'dart:convert';
import 'dart:io';

import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:responsive_table/responsive_table.dart';

import 'package:restalltech/API/WareHouse/wareHouseApi.dart';
import 'package:restalltech/Screens/WareHouse/components/loadingGoodsList.dart';
import 'package:restalltech/Screens/WareHouse/components/unloadingGoodsList.dart';
import 'package:restalltech/components/top_rounded_container.dart';

import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:file_picker/file_picker.dart';

class WareHouse extends StatefulWidget {
  const WareHouse({Key? key}) : super(key: key);
  @override
  _WareHouseState createState() => _WareHouseState();
}

class _WareHouseState extends State<WareHouse> {
  late List<DatatableHeader> _headers;

  List<int> _perPages = [5, 10, 20, 50, 100];
  int _total = 0;
  int? _currentPerPage = 50;
  final int _defCurrentPerPage = 50;
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
  bool _showSelect = true;

  List<Technician> _tech = [];

  static Future<List<Map<String, dynamic>>> _getProducts() async {
    final Response response = await WareHouseApi().getData();
    final body = json.decode(response.body);
    var productList = body['prodotto'];
    print(productList);
    //List<Ticket> products = List<Ticket>.from(productList.map((model) => Ticket.fromJson(model)));
    //List<Map<String, dynamic>> list = ticketList.cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> mergedList = [];
    for (var articolo in productList) {
      mergedList.add({
        'codArticolo': articolo['codArticolo'],
        'giacenza': articolo['giacenza'],
        'prezzoFornitore': articolo['prezzoFornitore'],
        'descrizione': articolo['descrizione'],
        'sconto1': articolo['sconto1'],
        'sconto2': articolo['sconto2'],
        'sconto3': articolo['sconto3'],
        'codeAn': articolo['codeAn'],
      });
    }

    return mergedList;
  }

  _initializeData() async {
    // _total = 0;
    _currentPage = 1;
    //_currentPerPage = 0;
    _perPages = [5, 10, 20, 50, 100];

    _mockPullData();
  }

  _mockPullData() async {
    List<Map<String, dynamic>> articles = await _getProducts();
    print(articles.length);
    if (articles.isEmpty) {
      _currentPerPage = 0;
      _perPages = [0];
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Non ci sono articoli.',
        text: 'In caso di problemi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
    } else if (articles.length < _defCurrentPerPage) {
      _currentPerPage = articles.length;

      _total = articles.length;
      _expanded = List.generate(articles.length, (index) => false);
    } else {
      _total = articles.length;
      _currentPerPage = _defCurrentPerPage;

      _expanded = List.generate(_currentPerPage!, (index) => false);
    }
    setState(() => _isLoading = true);
    Future.delayed(Duration(seconds: 2)).then((value) {
      _sourceOriginal.clear();
      _sourceOriginal.addAll(articles);
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
          text: "ID",
          value: "codArticolo",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Giacenza",
          value: "giacenza",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Prez. Forn.",
          value: "prezzoFornitore",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Descrizione",
          value: "descrizione",
          show: true,
          flex: 3,
          sortable: true,
          textAlign: TextAlign.left),
      DatatableHeader(
          text: "Sconto 1",
          value: "sconto1",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Sconto 2",
          value: "sconto2",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Sconto 3",
          value: "sconto3",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "codeAn",
          value: "codeAn",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
    ];

    _initializeData();
  }

  _selectTime(id) {
    final format = DateFormat("MM/dd HH:mm");
    // final TimeOfDay? newTime = await showTimePicker(
    //   context: context,
    //   initialTime: selectedTime,
    // );
    print("IN");
    return DateTimeField(
        format: format,
        onShowPicker: (context, currentValue) async {
          return await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            initialDate: currentValue ?? DateTime.now(),
            lastDate: DateTime(2100),
          ).then((DateTime? date) async {
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
              );
              //_setTime(DateTimeField.combine(date, time), id);
              print(DateTimeField.combine(date, time));
            } else {
              return currentValue;
            }
          });
        });
    // if (newTime != null) {
    //   setState(() {
    //     selectedTime = newTime;
    //     _timeController.text = selectedTime.format(context);
    //   });
    //   _setTime(selectedTime, id);
    // }
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
                  onPressed: _initializeData,
                  tooltip: 'Ricarica',
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: appBarColor,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var result = await FlutterPlatformAlert.showCustomAlert(
                      windowTitle: 'Sei sicuro di voler eliminare tutto?',
                      text: "L'operazone sarà irreversibile",
                      positiveButtonTitle: 'Si',
                      negativeButtonTitle: 'No',
                      iconStyle: IconStyle.exclamation,
                    );
                    if (result == CustomButton.positiveButton) {
                      final Response response =
                          await WareHouseApi().deleteWarehouse();
                      _initializeData();
                    }
                  },
                  tooltip: 'Elimina Magazzino',
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: appBarColor,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xls', 'xlsx']);

                    if (result != null) {
                      PlatformFile file = result.files.first;
                      print('Path: ${file.path}');
                      print('Nome: ${file.name}');
                      print('Estensione: ${file.extension}');
                      print('Dimensione: ${file.size}');

                      var response = await WareHouseApi().updateWareHouse(file);
                      if (response.statusCode == 200) {
                        FlutterPlatformAlert.showAlert(
                          windowTitle: 'Successo',
                          text: 'Il file è stato caricato.',
                          alertStyle: AlertButtonStyle.ok,
                          iconStyle: IconStyle.information,
                        );
                        _initializeData();
                      } else {
                        FlutterPlatformAlert.showAlert(
                          windowTitle:
                              'Il file non è stato caricato corrttamente.',
                          text: 'In caso di problemi contatta lo sviluppatore.',
                          alertStyle: AlertButtonStyle.ok,
                          iconStyle: IconStyle.error,
                        );
                      }
                    }
                  },
                  tooltip: 'Upload file XLS',
                  icon: Icon(
                    Icons.upload_file_rounded,
                    color: appBarColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Prelievi',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return LList();
                      },
                    ));
                  },
                  icon: Icon(
                    Icons.download,
                    color: appBarColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Resi',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return UlList();
                      },
                    ));
                  },
                  icon: Icon(
                    Icons.upload_rounded,
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
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _isSearch = false;
                            });
                            _initializeData();
                          }),
                      suffixIcon: IconButton(
                          icon: Icon(Icons.search), onPressed: () {})),
                  onSubmitted: (value) {
                    _filterData(value);
                  },
                )),
              if (!_isSearch)
                IconButton(
                    icon: Icon(Icons.search_rounded),
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
              print("$value  $item ");
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
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text("Elementi"),
              ),
              if (_perPages.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
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
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                    "$_currentPage - ${_currentPerPage! + _currentPage - 1} di $_total"),
              ),
              IconButton(
                icon: Icon(
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
                padding: EdgeInsets.symmetric(horizontal: 15),
              ),
              IconButton(
                icon: Icon(
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
                padding: EdgeInsets.symmetric(horizontal: 15),
              )
            ],
            headerDecoration: BoxDecoration(
              color: appBarColor,
              border: Border.all(
                color: appBarColor,
                width: 1,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            selectedDecoration: BoxDecoration(
                color: appBarColor,
                border: Border.all(
                  color: appBarColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            headerTextStyle: TextStyle(color: Colors.white),
            rowTextStyle: TextStyle(color: Colors.black),
            selectedTextStyle:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
