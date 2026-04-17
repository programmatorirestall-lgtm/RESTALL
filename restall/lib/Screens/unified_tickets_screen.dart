import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/components/ticket_card.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/TicketList.dart';
import 'package:restall/Screens/OpenTicket/ticket_screen.dart';

class UnifiedTicketsScreen extends StatefulWidget {
  final int initialTabIndex;
  static String routeName = "/unified_tickets";

  const UnifiedTicketsScreen({Key? key, this.initialTabIndex = 0})
      : super(key: key);

  @override
  _UnifiedTicketsScreenState createState() => _UnifiedTicketsScreenState();
}

class _UnifiedTicketsScreenState extends State<UnifiedTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Future per ogni tab
  Future<List<Ticket>>? _openTickets;
  Future<List<Ticket>>? _allMyTickets;
  Future<List<Ticket>>? _closedTickets;

  // GlobalKey per RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshKeyOpen =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshKeyAll =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshKeyClosed =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadAllTickets();
  }

  void refreshTicketsFromExternal() {
    _loadAllTickets();
  }

  void _loadAllTickets() {
    _openTickets = _getOpenTickets();
    _allMyTickets = _getAllMyTickets();
    _closedTickets = _getClosedTickets();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Verifica se siamo tornati da un'altra schermata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Questo metodo viene chiamato ogni volta che si torna a questa schermata
      if (mounted) {
        _loadAllTickets();
      }
    });
  }

  Future<List<Ticket>> _refreshOpenTickets() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 1));
    final tickets = await _getOpenTickets();
    setState(() {
      _openTickets = Future.value(tickets);
    });
    return tickets;
  }

  Future<List<Ticket>> _refreshAllMyTickets() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 1));
    final tickets = await _getAllMyTickets();
    setState(() {
      _allMyTickets = Future.value(tickets);
    });
    return tickets;
  }

  Future<List<Ticket>> _refreshClosedTickets() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 1));
    final tickets = await _getClosedTickets();
    setState(() {
      _closedTickets = Future.value(tickets);
    });
    return tickets;
  }

  static Future<List<Ticket>> _getOpenTickets() async {
    try {
      final Response response = await TicketApi().getData();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          Iterable ticketList = body['tickets'];
          List<Ticket> tickets = List.from(ticketList)
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
          return tickets.where((ticket) => ticket.stateT == 'Aperto').toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore caricamento ticket aperti: $e');
      return [];
    }
  }

  static Future<List<Ticket>> _getAllMyTickets() async {
    try {
      final Response response = await TicketApi().getData();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          Iterable ticketList = body['tickets'];
          return List.from(ticketList)
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore caricamento tutti i miei ticket: $e');
      return [];
    }
  }

  static Future<List<Ticket>> _getClosedTickets() async {
    try {
      final Response response = await TicketApi().getClosed();
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body != null && body['tickets'] != null) {
          Iterable ticketList = body['tickets'];
          return List.from(ticketList)
              .map((model) => Ticket.fromJson(Map.from(model)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore caricamento ticket chiusi: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withOpacity(0.89),
                secondaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: secondaryColor,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(text: "APERTI"),
                  Tab(text: "TUTTI"),
                  Tab(text: "CHIUSI"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TicketListView(
            future: _openTickets,
            onRefresh: _refreshOpenTickets,
            refreshKey: _refreshKeyOpen,
            noTicketsMessage: 'Nessun Ticket Aperto',
            noTicketsSubtitle: 'Tutti i tuoi ticket aperti appariranno qui',
            emptyIcon: Icons.schedule_rounded,
          ),
          TicketListView(
            future: _allMyTickets,
            onRefresh: _refreshAllMyTickets,
            refreshKey: _refreshKeyAll,
            noTicketsMessage: 'Nessun Ticket Trovato',
            noTicketsSubtitle: 'I tuoi ticket appariranno qui una volta creati',
            emptyIcon: Icons.assignment_outlined,
          ),
          TicketListView(
            future: _closedTickets,
            onRefresh: _refreshClosedTickets,
            refreshKey: _refreshKeyClosed,
            noTicketsMessage: 'Nessun Ticket Chiuso',
            noTicketsSubtitle: 'I ticket completati appariranno qui',
            emptyIcon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.lightImpact();

          // Naviga alla creazione ticket e aspetta il risultato
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TicketScreen()),
          );

          // Se è stato creato un ticket con successo, aggiorna le liste
          if (result == true) {
            print('🔄 Ticket creato con successo, aggiornamento liste...');
            _loadAllTickets(); // Ricarica tutti i dati

            // Feedback visivo opzionale
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket creato con successo!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuovo Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
        ),
      ),
    );
  }
}

class TicketListView extends StatelessWidget {
  final Future<List<Ticket>>? future;
  final Future<List<Ticket>> Function() onRefresh;
  final GlobalKey<RefreshIndicatorState> refreshKey;
  final String noTicketsMessage;
  final String noTicketsSubtitle;
  final IconData emptyIcon;

  const TicketListView({
    Key? key,
    required this.future,
    required this.onRefresh,
    required this.refreshKey,
    required this.noTicketsMessage,
    required this.noTicketsSubtitle,
    required this.emptyIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ticket>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Caricamento Ticket...',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: RefreshIndicator(
              key: refreshKey,
              onRefresh: onRefresh,
              color: secondaryColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Errore di connessione',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Trascina verso il basso per riprovare',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final tickets = snapshot.data!;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: RefreshIndicator(
              key: refreshKey,
              onRefresh: onRefresh,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TicketCard(ticket: tickets[index]),
                  );
                },
              ),
            ),
          );
        }

        // Empty state
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: RefreshIndicator(
            key: refreshKey,
            onRefresh: onRefresh,
            color: primaryColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              emptyIcon,
                              size: 64,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            noTicketsMessage,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            noTicketsSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Trascina verso il basso per aggiornare',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
