import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:responsive_table/responsive_table.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/TicketTech/tickeTech.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:restalltech/models/TicketList.dart';

class HomeTech extends StatefulWidget {
  const HomeTech({Key? key}) : super(key: key);
  @override
  _HomeTechState createState() => _HomeTechState();
}

class _HomeTechState extends State<HomeTech> {
  late List<DatatableHeader> _headers;

  List<int> _perPages = [10, 20, 50, 100];
  int _total = 0;
  int? _currentPerPage = 10;
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

  String? _sortColumn;
  bool _sortAscending = true;
  bool _isLoading = true;
  bool _showSelect = true;

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
            'Conessione al server non riuscita, controlla la connessione ad Internet.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  Technician _getProductById(int id) {
    return _tech.firstWhere((element) => element.id == id);
  }

  DropdownButtonFormField<int> _selectTech(val, row) {
    List<Technician> techs = _tech;

    int? _stateValue;
    return DropdownButtonFormField(
      hint: Text('Tecnico'),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      //value: temp.cognome+""+ temp.nome,
      value: val,
      onTap: () {},
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kStateMNullError;
        }
        return null;
      },
      onChanged: (int? newValue) {
        if (row.length > 1) {
          for (int i = 0; i < row.length; i++) {
            var data = {
              'id_ticket': row[i]['id'],
              'id_tecnico': newValue,
            };
            _setTT(data);
          }
          _initializeData();
        } else {
          var data = {
            'id_ticket': row[0]['id'],
            'id_tecnico': newValue,
          };
          _setTT(data);
        }
        setState(() {
          _stateValue = null;
          val = null;
        });
      },
      items: techs.map((techs) {
        return DropdownMenuItem<int>(
          value: techs.id,
          child: Text(
            techs.cognome + " " + techs.nome,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
    );
  }

  static Future<List<Technician>> _getTech() async {
    final Response response = await TechApi().getData();
    final body = json.decode(response.body);
    Iterable ticketList = body['tecnico'];
    List<Technician> tickets = List<Technician>.from(
        ticketList.map((model) => Technician.fromJson(model)));

    return tickets;
  }

  static Future<List<Map<String, dynamic>>> _getTickets() async {
    final Response response = await TicketApi().getData();
    final body = json.decode(response.body);
    var ticketList = body['tickets'];
    //List<Ticket> tickets = List<Ticket>.from(ticketList.map((model) => Ticket.fromJson(model)));
    List<Map<String, dynamic>> list = ticketList.cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> mergedList = list.map((item) {
      Map<String, dynamic> user = item['utente'];

      // Logica per ragSoc (stessa dell'admin)
      String ragSoc;
      if (item['ragSocAzienda'] != null &&
          item['ragSocAzienda'].toString().isNotEmpty) {
        ragSoc = item['ragSocAzienda'].toString();
      } else if (user['cognome'].toString().isEmpty &&
          user['nome'].toString().isEmpty) {
        ragSoc = "UTENTE ELIMINATO";
      } else {
        ragSoc = user['cognome'] + ' ' + user['nome'];
      }

      Map<String, dynamic> tickets = {
        'id': item['id'],
        'tipo': item['tipo'],
        'stato': item['stato'],
        'data': item['data'],
        'indirizzo': item['indirizzo'],
        'Cliente': ragSoc,
        'email': user['email'],
        'id_tecnico': item['id_tecnico'],
        'ragSoc': ragSoc,
        'ragSocAzienda': item['ragSocAzienda'] != null && item['ragSocAzienda'].toString().isNotEmpty
            ? item['ragSocAzienda']
            : ragSoc,
      };

      return tickets;
    }).toList();

    return mergedList;
  }

  _initializeData() async {
    _currentPerPage = 10;
    _currentPage = 1;
    _getTech().then((value) {
      setState(() {
        _tech = value;
      });
    });

    List<Map<String, dynamic>> tickets = await _getTickets();
    if (tickets.isEmpty) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Non ci sono ticket',
        text: 'Non è stato trovato nessun ticket aperto',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
    } else if (tickets.length < 10) {
      _perPages = [tickets.length];
    } else {
      _mockPullData(tickets);
    }
  }

  _mockPullData(tickets) async {
    _total = tickets.length;
    _expanded = List.generate(tickets.length, (index) => false);

    setState(() => _isLoading = true);
    Future.delayed(Duration(seconds: 2)).then((value) {
      _sourceOriginal.clear();
      _sourceOriginal.addAll(tickets);
      _sourceFiltered = _sourceOriginal;
      _total = _sourceFiltered.length;
      _source = _sourceFiltered.getRange(0, _currentPerPage!).toList();
      setState(() => _isLoading = false);
    });
  }

  _resetData({start = 0}) async {
    setState(() => _isLoading = true);
    var _expandedLen =
        _total - start < _currentPerPage! ? _total - start : _currentPerPage;
    Future.delayed(Duration(seconds: 2)).then((value) {
      _expanded = List.generate(_expandedLen as int, (index) => false);
      _source.clear();
      _source = _sourceFiltered.getRange(start, start + _expandedLen).toList();
      setState(() => _isLoading = false);
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
          value: "id",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Stato",
          value: "stato",
          show: true,
          sortable: true,
          sourceBuilder: (value, row) {
            return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (value.compareTo("Chiuso") == 0)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 35,
                    ),
                  if (value.compareTo("In corso") == 0)
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.grey,
                      size: 35,
                    ),
                  if (value.compareTo("Aperto") == 0)
                    Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.yellow,
                      size: 35,
                    ),
                  Text(value)
                ]);
          },
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Indirizzo",
          value: "indirizzo",
          show: true,
          sortable: true,
          textAlign: TextAlign.left),
      DatatableHeader(
          text: "Data desiderata",
          value: "data",
          show: true,
          sortable: true,
          sourceBuilder: (value, row) {
            return Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(value)));
          },
          textAlign: TextAlign.left),
      DatatableHeader(
          text: "Tecnico",
          value: "id_tecnico",
          show: true,
          flex: 3,
          sortable: false,
          sourceBuilder: (value, row) {
            List temp = [];
            temp.add(row);
            return Column(
              children: [
                Container(
                  width: 270,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _selectTech(value, temp)),
                ),
              ],
            );
          },
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
    return Padding(
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
          child: Background(
            child: ResponsiveDatatable(
              title: Row(
                children: [
                  if (_selecteds.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          width: 260,
                          child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: _selectTech(null, _selecteds)),
                        ),
                      ],
                    ),
                  IconButton(
                    onPressed: _initializeData,
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
              dropContainer: (data) {
                if (data.isEmpty) {
                  return Text("no data");
                }
                return _DropDownContainer(data: data);
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
                  setState(() => _selecteds.removeAt(_selecteds.indexOf(item)));
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
                  child: Text("$_currentPage - $_currentPerPage di $_total"),
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
                  icon: Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _currentPage + _currentPerPage! - 1 > _total
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
      ),
    );
  }
}

class _DropDownContainer extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DropDownContainer({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> _children = data.entries.map<Widget>((entry) {
      Widget w = Row(
        children: [
          Text(entry.key.toString()),
          Spacer(),
          Text(entry.value.toString()),
        ],
      );
      return w;
    }).toList();

    return Container(
      /// height: 100,
      child: Column(
        /// children: [
        ///   Expanded(
        ///       child: Container(
        ///     color: Colors.red,
        ///     height: 50,
        ///   )),
        /// ],
        children: _children,
      ),
    );
  }
}
