import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:responsive_table/responsive_table.dart';

import 'package:restalltech/API/WareHouse/wareHouseApi.dart';

import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Technician.dart';

class LList extends StatefulWidget {
  const LList({Key? key}) : super(key: key);
  @override
  _LListState createState() => _LListState();
}

class _LListState extends State<LList> {
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
  bool _showSelect = true;

  static Future<List<Map<String, dynamic>>> _getProducts() async {
    final Response response = await WareHouseApi().getRientri();
    final body = json.decode(response.body);
    var productList = body['response'];
    print(productList);

    List<Map<String, dynamic>> mergedList = [];
    for (var articolo in productList) {
      mergedList.add({
        'codArticolo': articolo['codArticolo'],
        'giacenza': articolo['giacenza'],
        'prezzoFornitore': articolo['prezzoFornitore'],
        'descrizione': articolo['descrizione'],
        'codeAn': articolo['codeAn'],
      });
    }

    return mergedList;
  }

  _initializeData() async {
    // _currentPerPage = 10;
    _currentPage = 1;

    _mockPullData();
  }

  _mockPullData() async {
    List<Map<String, dynamic>> article = await _getProducts();
    print(article);
    if (article.isEmpty) {
      _currentPerPage = article.length;
      _perPages = [article.length];

      print("OKK");
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Non ci sono carichi.',
        text: 'In caso di problemi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
    } else if (article.length < _currentPerPage! && article.isNotEmpty) {
      _currentPerPage = article.length;

      _perPages = [article.length, 10, 50, 75, 100];

      _total = article.length;
      _expanded = List.generate(article.length, (index) => false);
    } else {
      _total = article.length;
      _expanded = List.generate(_currentPerPage!, (index) => false);
    }
    setState(() => _isLoading = true);
    Future.delayed(Duration(seconds: 2)).then((value) {
      _sourceOriginal.clear();
      _sourceOriginal.addAll(article);
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
          text: "codeAn",
          value: "codeAn",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
    ];

    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Prelievo"),
          backgroundColor: kPrimaryLightColor,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
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
                      _sourceFiltered.sort((a, b) =>
                          b["$_sortColumn"].compareTo(a["$_sortColumn"]));
                    } else {
                      _sourceFiltered.sort((a, b) =>
                          a["$_sortColumn"].compareTo(b["$_sortColumn"]));
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
                    setState(
                        () => _selecteds.removeAt(_selecteds.indexOf(item)));
                  }
                },
                onSelectAll: (value) {
                  if (value!) {
                    setState(() => _selecteds =
                        _source.map((entry) => entry).toList().cast());
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
        ));
  }
}
