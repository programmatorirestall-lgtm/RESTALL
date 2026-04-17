import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/components/ticket_card.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/draft_manager.dart';
import 'package:restalltech/models/TicketList.dart';

class MyTicket extends StatefulWidget {
  const MyTicket({super.key});

  @override
  _MyTicketState createState() => _MyTicketState();
}

class _MyTicketState extends State<MyTicket> {
  Future<List<Ticket>> ticket = getTickets();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  // Filtri per stato
  String _selectedFilter = 'Tutti';
  final List<String> _filterOptions = [
    'Tutti',
    'Aperto',
    'In corso',
  ];
  List<Ticket> _allTickets = [];
  List<Ticket> _filteredTickets = [];

  // Ordinamento
  String _sortOrder = 'Data prevista';
  final List<String> _sortOptions = [
    'Data prevista',
    'Più recenti',
    'Più vecchi'
  ];

  // Stato per collassare/espandere filtri
  bool _showFilters = true;

  // Numero di bozze
  int _draftsCount = 0;

  static Future<List<Ticket>> getTickets() async {
    final Response response = await TicketApi().getData();
    final body = json.decode(response.body);
    Iterable ticketList = body['tickets'];
    List<Ticket> tickets = List.from(ticketList)
        .map((model) => Ticket.fromJson(Map.from(model)))
        .toList();
    return tickets;
  }

  Future<Null> refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      ticket = getTickets();
      _loadAndFilterTickets();
    });

    return null;
  }

  void _loadAndFilterTickets() async {
    final tickets = await ticket;
    setState(() {
      _allTickets = tickets;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedFilter == 'Tutti') {
      _filteredTickets = List.from(_allTickets);
    } else {
      _filteredTickets =
          _allTickets.where((t) => t.stateT == _selectedFilter).toList();
    }
    _applySorting();
  }

  void _applySorting() {
    if (_sortOrder == 'Data prevista') {
      _filteredTickets.sort((a, b) {
        if (a.oraPrevista != null && b.oraPrevista != null) {
          try {
            final dateA = DateTime.parse(a.oraPrevista!);
            final dateB = DateTime.parse(b.oraPrevista!);
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        }
        if (a.oraPrevista != null) return -1;
        if (b.oraPrevista != null) return 1;
        return 0;
      });
    } else if (_sortOrder == 'Più recenti') {
      _filteredTickets.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.id.compareTo(a.id);
      });
    } else if (_sortOrder == 'Più vecchi') {
      _filteredTickets.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        return a.id.compareTo(b.id);
      });
    }
  }

  bool _hasActiveFilters() {
    return _selectedFilter != 'Tutti' || _sortOrder != 'Data prevista';
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'Tutti';
      _sortOrder = 'Data prevista';
      _applyFilter();
    });
  }

  @override
  void initState() {
    super.initState();
    ticket = getTickets();
    _loadAndFilterTickets();
    _loadDraftsCount();
  }

  void _loadDraftsCount() async {
    final count = await DraftManager.getDraftsCount();
    if (mounted) {
      setState(() {
        _draftsCount = count;
      });
      // Mostra notifica se ci sono bozze
      if (count > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDraftsNotification();
        });
      }
    }
  }

  void _showDraftsNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.drafts, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hai $_draftsCount bozz${_draftsCount == 1 ? 'a' : 'e'} non completat${_draftsCount == 1 ? 'a' : 'e'}',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Visualizza',
          textColor: Colors.white,
          onPressed: _showDraftsDialog,
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _showDraftsDialog() async {
    final drafts = await DraftManager.getAllDrafts();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.drafts, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bozze salvate ($_draftsCount)'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: drafts.isEmpty
              ? Text('Nessuna bozza salvata')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  itemBuilder: (context, index) {
                    final draft = drafts[index];
                    final timestamp = DateTime.parse(draft['timestamp']);
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
                    final type = draft['type'] == 'close' ? 'Chiusura' : 'Sospensione';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          draft['type'] == 'close' ? Icons.close : Icons.pause,
                          color: draft['type'] == 'close' ? Colors.red : Colors.orange,
                        ),
                        title: Text('$type Ticket #${draft['ticketId']}'),
                        subtitle: Text('Salvata il: $formattedDate'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DraftManager.deleteDraft(draft['ticketId']);
                            Navigator.pop(context);
                            _loadDraftsCount();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (drafts.isNotEmpty) {
                await DraftManager.deleteAllDrafts();
                Navigator.pop(context);
                _loadDraftsCount();
              }
            },
            child: Text('Elimina Tutte'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Filtri collassabili (stile home_admin)
              _buildCollapsibleFilters(),

              SizedBox(height: 12),

              // Lista ticket
        Expanded(
          child: FutureBuilder<List<Ticket>>(
              future: ticket,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Align(
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                          color: secondaryColor));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // Aggiorna _allTickets quando i dati sono disponibili
                  if (_allTickets.isEmpty ||
                      _allTickets.length != snapshot.data!.length) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _allTickets = snapshot.data!;
                          _applyFilter();
                        });
                      }
                    });
                  }

                  final displayTickets =
                      _filteredTickets.isNotEmpty || _selectedFilter == 'Tutti'
                          ? _filteredTickets
                          : snapshot.data!;

                  if (displayTickets.isEmpty && _selectedFilter != 'Tutti') {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nessun ticket "$_selectedFilter"',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: refreshList,
                    key: refreshKey,
                    child: buildTickets(displayTickets),
                  );
                } else {
                  return RefreshIndicator(
                      onRefresh: refreshList,
                      key: refreshKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text('Nessun Ticket'),
                                    Text('Trascina per ricaricare'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ));
                }
              }),
        ),
            ],
          ),
        ),
      ),
    );
  }

  // Filtri collassabili (stile home_admin)
  Widget _buildCollapsibleFilters() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  size: 20,
                  color: secondaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Filtri',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
                if (_hasActiveFilters()) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Attivi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Spacer(),
                if (_draftsCount > 0) ...[
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.drafts, color: Colors.orange),
                        onPressed: _showDraftsDialog,
                        tooltip: 'Bozze salvate',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_draftsCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(Icons.refresh, color: secondaryColor),
                  onPressed: () {
                    refreshList();
                    _loadDraftsCount();
                  },
                  tooltip: 'Aggiorna',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                Icon(
                  _showFilters ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showFilters) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: _buildFilterDropdown(
                  label: 'Stato',
                  value: _selectedFilter,
                  items: _filterOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedFilter = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildFilterDropdown(
                  label: 'Ordina per',
                  value: _sortOrder,
                  items: _sortOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sortOrder = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
              if (_hasActiveFilters())
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear_all, size: 18),
                  label: Text('Cancella Filtri'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // Helper per creare dropdown (stesso stile di home_admin)
  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.filter_list_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
      dropdownColor: kPrimaryLightColor,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget buildTickets(List<Ticket> tickets) => ListView.builder(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
      itemCount: tickets.length,
      itemBuilder: (context, index) => TicketCard(ticket: tickets[index]));
}
