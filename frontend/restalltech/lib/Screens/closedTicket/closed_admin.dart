import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_table/responsive_table.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/TicketTech/tickeTech.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/downloader.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:restalltech/models/TicketList.dart';

class ClosedTicket extends StatefulWidget {
  const ClosedTicket({Key? key}) : super(key: key);
  @override
  _ClosedTicketState createState() => _ClosedTicketState();
}

class _ClosedTicketState extends State<ClosedTicket> {
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

  String? _sortColumn;
  bool _sortAscending = true;
  bool _isLoading = true;
  bool _showSelect = false;

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

  Technician _getTechById(int id) {
    return _tech.firstWhere((element) => element.id == id);
  }

  static Future<List<Technician>> _getTech() async {
    final Response response = await TechApi().getData();
    final body = json.decode(response.body);
    Iterable ticketList = body['tecnico'];
    List<Technician> tickets = List<Technician>.from(
        ticketList.map((model) => Technician.fromJson(model)));

    return tickets;
  }

  _getTickets({int offset = 0, int limit = 50}) async {
    print("Richiesta API con offset: $offset, limit: $limit");
    final Response response =
        await TicketApi().getClosedT(offset: offset, limit: limit);
    final body = json.decode(response.body);
    var ticketList = body['tickets'];
    final totalCount = body['totalCount'];
    var ragsoc;

    //List<Ticket> tickets = List<Ticket>.from(ticketList.map((model) => Ticket.fromJson(model)));
    List<Map<String, dynamic>> list = ticketList.cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> mergedList = list.map((item) {
      Map<String, dynamic> user = item['utente'];
      if (user['cognome'].toString().isEmpty &&
          user['nome'].toString().isEmpty) {
        ragsoc = "UTENTE ELIMINATO";
      } else if (item['ragSocAzienda'] != null) {
        ragsoc = item['ragSocAzienda'].toString();
      } else {
        ragsoc = user['cognome'] + ' ' + user['nome'];
      }
      Map<String, dynamic> tickets = {
        'id': item['id'],
        'tipo_macchina': item['tipo_macchina'],
        'stato_Macchina': item['stato_macchina'],
        'stato': item['stato'],
        'data': item['data'],
        'indirizzo': item['indirizzo'],
        'nome': user['nome'],
        'cognome': user['cognome'],
        'email': user['email'],
        'id_tecnico': item['id_tecnico'],
        'ragSoc': ragsoc,
      };

      return tickets;
    }).toList();

    return {
      'tickets': mergedList,
      'totalCount': totalCount,
    };
  }

  _initializeData() async {
    _currentPerPage = 50;
    _currentPage = 1;
    _getTech().then((value) {
      setState(() {
        _tech = value;
      });
    });
    _mockPullData();
  }

  _mockPullData({int offset = 0, int? limit}) async {
    limit ??= _currentPerPage!; // Usa il limite scelto dall'utente
    print("MockPullData con offset: $offset, limit: $limit"); // Log del limite

    final result = await _getTickets(offset: offset, limit: limit);

    final tickets = result['tickets'];
    final totalCount = result['totalCount'];

    print(
        "Ticket ricevuti: ${tickets.length}, Totale: $totalCount"); // Verifica il numero di ticket

    setState(() {
      _sourceOriginal = tickets;
      _sourceFiltered = tickets;
      _total = totalCount; // Totale dal server

      // Sincronizza _expanded e _source
      _expanded = List.generate(tickets.length, (_) => false);
      _source = tickets;
      _isLoading = false;
    });
  }

  _resetData({int offset = 0}) async {
    final limit = _currentPerPage!;
    print(
        "Reset data con offset: $offset, limit: $limit"); // Verifica il limite usato

    final result = await _getTickets(offset: offset, limit: limit);

    final tickets = result['tickets'];

    setState(() {
      _source = tickets;
      _expanded = List.generate(tickets.length, (_) => false);
      _isLoading = false;
    });
  }

  _filterData(String value) {
    setState(() => _isLoading = true);

    try {
      if (value.isEmpty) {
        _sourceFiltered = _sourceOriginal;
      } else {
        _sourceFiltered = _sourceOriginal
            .where((data) => data[_searchKey!]
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase()))
            .toList();
      }

      _total = _sourceFiltered.length;
      if (_perPages.isEmpty || !_perPages.contains(_total)) {
        _perPages = [_total, 10, 20, 50, 100];
      }
      final rangeEnd = _currentPage * _currentPerPage! > _total
          ? _total
          : _currentPage * _currentPerPage!;
      final rangeStart = (_currentPage - 1) * _currentPerPage!;

      _expanded = List.generate(rangeEnd - rangeStart, (_) => false);
      _source = _sourceFiltered.sublist(rangeStart, rangeEnd);
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
          text: "Tipo",
          value: "tipo_macchina",
          show: true,
          sortable: true,
          sourceBuilder: (value, row) {
            //print(value);
            return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (value.compareTo("Altro") == 0 && value != null)
                    const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: Color.fromARGB(255, 170, 0, 255),
                      size: 35,
                    ),
                  if (value.compareTo("Climatizzazione") == 0)
                    IconButton(
                      icon: SvgPicture.asset("assets/icons/mode_dual.svg",
                          height: 30, semanticsLabel: 'Label'),
                      onPressed: () {},
                    ),
                  if (value.compareTo("Aspirazione") == 0)
                    const Icon(
                      Icons.factory_rounded,
                      color: Colors.blueGrey,
                      size: 35,
                    ),
                  if (value.compareTo("Caldo") == 0)
                    const Icon(
                      Icons.local_fire_department_outlined,
                      color: Colors.red,
                      size: 35,
                    ),
                  if (value.compareTo("Freddo") == 0)
                    const Icon(
                      Icons.ac_unit_rounded,
                      color: Colors.blue,
                      size: 35,
                    )
                ]);
          },
          textAlign: TextAlign.center),
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (value.compareTo("Chiuso") == 0)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 35,
                    ),
                  if (value.compareTo("Annullato") == 0)
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 35,
                    ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(value)
                ]);
          },
          textAlign: TextAlign.start),
      DatatableHeader(
          text: "Rag.Soc",
          value: "ragSoc",
          show: true,
          sortable: true,
          textAlign: TextAlign.center),
      DatatableHeader(
          text: "Indirizzo",
          value: "indirizzo",
          show: true,
          sortable: true,
          flex: 3,
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
          sortable: false,
          sourceBuilder: (value, row) {
            List temp = [];
            temp.add(row);
            //print("ROOO;  " + row.toString());
            if (value != null) {
              var tech = _getTechById(value);

              return Text(tech.nome + " " + tech.cognome);
            }
            return Text("Tecnico non assegnato");
          },
          textAlign: TextAlign.start)
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
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ResponsiveDatatable(
            title: Row(
              children: [
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
              //print(data['id']);

              return DropDownContainer(data: data);
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
                              value: e,
                              child: Text("$e"),
                            ))
                        .toList(),
                    onChanged: (dynamic value) {
                      setState(() {
                        _currentPerPage =
                            value; // Cambia il limite dinamicamente
                        _currentPage = 1; // Torna alla prima pagina
                        _resetData(
                            offset: 0); // Ricarica i dati con il nuovo limite
                      });
                    },
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                    "${_currentPage * _currentPerPage! - _currentPerPage! + 1} - ${_currentPage * _currentPerPage!} di $_total"),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: _currentPage == 1
                    ? null
                    : () {
                        setState(() {
                          _currentPage--;
                          int offset = (_currentPage - 1) * _currentPerPage!;
                          _resetData(
                              offset: offset); // Usa il limite aggiornato
                        });
                      },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: _currentPage * _currentPerPage! >= _total
                    ? null
                    : () {
                        setState(() {
                          _currentPage++;
                          int offset = (_currentPage - 1) * _currentPerPage!;
                          _resetData(
                              offset: offset); // Usa il limite aggiornato
                        });
                      },
              ),
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

class DropDownContainer extends StatefulWidget {
  final Map<String, dynamic> data;
  const DropDownContainer({Key? key, required this.data}) : super(key: key);

  @override
  _DropDownContainerState createState() => _DropDownContainerState();
}

class _DropDownContainerState extends State<DropDownContainer> {
  static Future<List<dynamic>> _getDetails(t) async {
    final Response response = await TicketApi().getDetails(t);
    final body = json.decode(response.body);
    var item = body['ticket'];
    //print("ITEM" + body['fogli'].toString());
    var ticket = item;
    item = ticket['fogli'];
    //ticket = item['location'];
    print(item);
    return item;
  }

  Future<void> _downloadFile(url) async {
    DownloadService downloadService;
    if (kIsWeb) {
      downloadService = WebDownloadService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      downloadService = MobileDownloadService();
    } else {
      downloadService = DesktopDownloadService();
    }
    await downloadService.download(url: url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
        future: _getDetails(widget.data['id']),
        builder: (context, snapshot) {
          print(snapshot);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Align(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: secondaryColor));
          } else if (snapshot.hasData && snapshot.data!.length > 0) {
            final ticket = snapshot.data!;
            print(ticket.length);
            return SizedBox(
              height: 50,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: ticket.length,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            child: Text(
                              ticket[index]['fileKey'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () {
                              _downloadFile(ticket[index]['location']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Text("Non ci sono dettagli");
          }
        });
  }
}
