import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/Ticket/ticket.dart';

import 'package:restalltech/components/ticket_card.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';

import 'package:restalltech/models/TicketList.dart';

class MyClosedTicket extends StatefulWidget {
  const MyClosedTicket({super.key});

  @override
  _MyClosedTicketState createState() => _MyClosedTicketState();
}

class _MyClosedTicketState extends State<MyClosedTicket> {
  List<Ticket> tickets = [];
  List<Ticket> filteredTickets = [];
  bool isLoading = false;
  bool hasMore = true;
  int offset = 0;
  final int limit = 20;
  final ScrollController _scrollController = ScrollController();

  // Filtri
  String _selectedFilter = 'Tutti';
  final List<String> _filterOptions = ['Tutti', 'Chiuso', 'Annullato'];

  // Stato per collassare/espandere filtri
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    loadTickets();

    // Aggiunge un listener per il caricamento quando si raggiunge la fine della lista
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLoading &&
          hasMore) {
        loadTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadTickets({bool isRefresh = false, int? loadLimit}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    if (isRefresh) {
      offset = 0;
      tickets.clear();
      hasMore = true;
    }

    try {
      final Response response =
          await TicketApi().getClosedT(offset: offset, limit: loadLimit ?? limit);
      final body = json.decode(response.body);
      Iterable ticketList = body['tickets'];
      List<Ticket> newTickets =
          List<Ticket>.from(ticketList.map((model) => Ticket.fromJson(model)));

      // Ordinamento inverso: ultimi chiusi per primi
      newTickets.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.id.compareTo(a.id);
      });

      setState(() {
        tickets.addAll(newTickets);
        offset += newTickets.length;
        hasMore = newTickets.length == (loadLimit ?? limit);
        _applyFilter();
      });
    } catch (e) {
      print("Errore durante il caricamento dei ticket: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'Tutti') {
      filteredTickets = List.from(tickets);
    } else {
      filteredTickets = tickets.where((ticket) => ticket.stateT == _selectedFilter).toList();
    }
  }

  Future<void> _reopenTicket(Ticket ticket) async {
    final confirm = await FlutterPlatformAlert.showCustomAlert(
      windowTitle: 'Riaprire ticket',
      text: 'Vuoi riaprire il ticket #${ticket.id}?',
      positiveButtonTitle: 'Sì',
      negativeButtonTitle: 'No',
    );

    if (confirm == CustomButton.positiveButton) {
      try {
        final response = await TicketApi().suspendTicket({'stato': 'Aperto'}, ticket.id);
        if (response == 200) {
          await FlutterPlatformAlert.showAlert(
            windowTitle: 'Successo',
            text: 'Ticket riaperto con successo',
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.information,
          );
          await refreshList();
        } else {
          throw Exception('Errore nella riapertura');
        }
      } catch (e) {
        await FlutterPlatformAlert.showAlert(
          windowTitle: 'Errore',
          text: 'Impossibile riaprire il ticket',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      }
    }
  }

  Future<void> refreshList() async {
    await loadTickets(isRefresh: true);
  }

  bool _hasActiveFilters() {
    return _selectedFilter != 'Tutti';
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'Tutti';
      _applyFilter();
    });
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
                child: RefreshIndicator(
              onRefresh: refreshList,
              child: filteredTickets.isEmpty && !isLoading
                  ? LayoutBuilder(
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
                                    'Nessun ticket trovato',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Trascina per ricaricare',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      padding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
                      itemCount: filteredTickets.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < filteredTickets.length) {
                          return Dismissible(
                            key: Key('ticket_${filteredTickets[index].id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return false; // Non elimina il ticket
                            },
                            onDismissed: (direction) {},
                            background: Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Riapri',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: GestureDetector(
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity! < -500) {
                                  _reopenTicket(filteredTickets[index]);
                                }
                              },
                              child: TicketCard(ticket: filteredTickets[index]),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: CircularProgressIndicator(color: secondaryColor),
                            ),
                          );
                        }
                      },
                    ),
                ),
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
              ..._filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilter();
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: appBarColor.withValues(alpha: 0.2),
                  checkmarkColor: appBarColor,
                  labelStyle: TextStyle(
                    color: isSelected ? appBarColor : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? appBarColor : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
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
}
