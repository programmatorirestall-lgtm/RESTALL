import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';

import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/Screens/AddTech/add_tech_screen.dart';
import 'package:restalltech/Screens/TechDetail/tech_detail_screen.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Technician.dart';

class ListTech extends StatefulWidget {
  const ListTech({Key? key}) : super(key: key);
  @override
  ListTechState createState() => ListTechState();
}

class ListTechState extends State<ListTech> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTechs = [];
  List<Map<String, dynamic>> _activeTechs = [];
  List<Map<String, dynamic>> _inactiveTechs = [];
  Map<int, Map<String, dynamic>> _techStats = {};
  String _searchQuery = '';
  String _viewMode = 'tutti'; // 'tutti', 'attivi', 'non_attivi'

  // Cache per ridurre chiamate API
  static DateTime? _lastLoadTime;
  static List<Map<String, dynamic>>? _cachedTickets;
  static const Duration _cacheTimeout = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      // Carica tecnici con retry
      final techResponse = await _retryApiCall(() => TechApi().getData());
      if (techResponse == null) {
        setState(() => _isLoading = false);
        _showErrorMessage(
            'Impossibile caricare i tecnici. Il server potrebbe essere sovraccarico. Riprova tra qualche secondo.');
        return;
      }
      final techBody = json.decode(techResponse.body);
      final techList = (techBody['tecnico'] as List?) ?? [];

      // Usa cache per i ticket se disponibile e non scaduta
      List<Map<String, dynamic>> ticketList;
      if (!forceRefresh &&
          _cachedTickets != null &&
          _lastLoadTime != null &&
          DateTime.now().difference(_lastLoadTime!) < _cacheTimeout) {
        print('Using cached tickets data');
        ticketList = _cachedTickets!;
      } else {
        // Carica tickets con retry
        final ticketResponse = await _retryApiCall(() => TicketApi().getData());
        if (ticketResponse == null) {
          setState(() => _isLoading = false);
          _showErrorMessage(
              'Impossibile caricare i ticket. Il server potrebbe essere sovraccarico. Riprova tra qualche secondo.');
          return;
        }
        final ticketBody = json.decode(ticketResponse.body);
        ticketList = ((ticketBody['tickets'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

        // Salva in cache
        _cachedTickets = ticketList;
        _lastLoadTime = DateTime.now();
        print('Loaded fresh tickets data and cached it');
      }

      List<Map<String, dynamic>> allTechs = [];
      List<Map<String, dynamic>> activeTechs = [];
      List<Map<String, dynamic>> inactiveTechs = [];
      Map<int, Map<String, dynamic>> stats = {};

      // Verifica che ci siano tecnici
      if (techList.isEmpty) {
        setState(() {
          _allTechs = [];
          _activeTechs = [];
          _inactiveTechs = [];
          _techStats = {};
          _isLoading = false;
        });
        return;
      }

      // Calcola le statistiche per ogni tecnico solo dai ticket (più veloce)
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(Duration(days: 1));

      for (var tech in techList) {
        final techId = tech['id'] as int;
        final isActive = tech['verified'].toString().toUpperCase() == 'TRUE';

        Map<String, dynamic> techData = {
          'id': techId,
          'nome': tech['nome'],
          'cognome': tech['cognome'],
          'verified': tech['verified'],
          'paga': tech['pagamento_orario'],
        };

        // Calcola tutte le statistiche dai ticket (come in home_admin)
        final techTickets =
            ticketList.where((t) => t['id_tecnico'] == techId).toList();

        final todayTickets = techTickets.where((ticket) {
          final oraPrevista = ticket['oraPrevista'];
          if (oraPrevista != null) {
            try {
              final scheduledTime = DateTime.parse(oraPrevista);
              return scheduledTime.isAfter(todayStart) &&
                  scheduledTime.isBefore(todayEnd);
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();

        final activeTickets =
            techTickets.where((ticket) => ticket['stato'] != 'Chiuso').toList();
        final completedTickets =
            techTickets.where((ticket) => ticket['stato'] == 'Chiuso').toList();
        final inProgressTickets = techTickets
            .where((ticket) => ticket['stato'] == 'In corso')
            .toList();

        stats[techId] = {
          'todayCount': todayTickets.length,
          'activeCount': activeTickets.length,
          'completedCount': completedTickets.length,
          'inProgressCount': inProgressTickets.length,
          'totalAssigned': techTickets.length,
        };

        allTechs.add(techData);
        if (isActive) {
          activeTechs.add(techData);
        } else {
          inactiveTechs.add(techData);
        }
      }

      // Ordina per numero di ticket oggi
      activeTechs.sort((a, b) {
        final aCount = stats[a['id']]?['todayCount'] ?? 0;
        final bCount = stats[b['id']]?['todayCount'] ?? 0;
        return bCount.compareTo(aCount);
      });

      setState(() {
        _allTechs = allTechs;
        _activeTechs = activeTechs;
        _inactiveTechs = inactiveTechs;
        _techStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      _showErrorMessage('Impossibile caricare i dati. Riprova.');
    }
  }

  // Metodo per retry con backoff esponenziale
  Future<T?> _retryApiCall<T>(Future<T> Function() apiCall,
      {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final result = await apiCall();
        if (result != null) {
          return result;
        }
      } catch (e) {
        print('API call attempt ${attempt + 1} failed: $e');
      }

      attempt++;
      if (attempt < maxRetries) {
        // Backoff esponenziale: 500ms, 1000ms, 2000ms
        final delay = Duration(milliseconds: 500 * (1 << attempt));
        print('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
    return null;
  }

  void _showErrorMessage(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore',
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  List<Map<String, dynamic>> _getFilteredTechs() {
    List<Map<String, dynamic>> techs;

    switch (_viewMode) {
      case 'attivi':
        techs = _activeTechs;
        break;
      case 'non_attivi':
        techs = _inactiveTechs;
        break;
      default:
        techs = _allTechs;
    }

    if (_searchQuery.isEmpty) {
      return techs;
    }

    return techs.where((tech) {
      final name = '${tech['nome']} ${tech['cognome']}'.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildTechCard(Map<String, dynamic> tech) {
    final isActive = tech['verified'].toString().toUpperCase() == 'TRUE';
    final stats = _techStats[tech['id']] ?? {};
    final todayCount = stats['todayCount'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isActive ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TechDetailScreen(tech: tech, stats: stats),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive ? Colors.green : Colors.grey,
                radius: 24,
                child: Text(
                  '${tech['nome'][0]}${tech['cognome'][0]}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tech['cognome']} ${tech['nome']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isActive ? 'Attivo' : 'Non Attivo',
                          style: TextStyle(
                            fontSize: 14,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (todayCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today, size: 16, color: Colors.blue[700]),
                      SizedBox(width: 6),
                      Text(
                        '$todayCount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: _buildStatCard('Attivi', '${_activeTechs.length}',
                  Icons.check_circle_outlined, Colors.green)),
          SizedBox(width: 12),
          Expanded(
              child: _buildStatCard('Non Attivi', '${_inactiveTechs.length}',
                  Icons.cancel_outlined, Colors.grey)),
          SizedBox(width: 12),
          Expanded(
              child: _buildStatCard('Totali', '${_allTechs.length}',
                  Icons.people_outline, secondaryColor)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTechs = _getFilteredTechs();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // Cards riepilogo
                if (!_isLoading) _buildSummaryCards(),

                // Barra ricerca e filtri
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              textInputAction: TextInputAction.search,
                              cursorColor: kPrimaryColor,
                              decoration: InputDecoration(
                                hintText: 'Cerca tecnico...',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(defaultPadding),
                                  child: Icon(Icons.search_rounded),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            onPressed: _loadData,
                            icon: Icon(Icons.refresh),
                            tooltip: 'Aggiorna',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.person_add_alt_1),
                            tooltip: 'Aggiungi Tecnico',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddTechScreen()),
                              ).then((_) => _loadData());
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: secondaryColor,
                              foregroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: Text('Tutti'),
                                selected: _viewMode == 'tutti',
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _viewMode = 'tutti');
                                  }
                                },
                                selectedColor:
                                    secondaryColor.withValues(alpha: 0.2),
                                checkmarkColor: secondaryColor,
                              ),
                              FilterChip(
                                label: Text('Attivi'),
                                selected: _viewMode == 'attivi',
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _viewMode = 'attivi');
                                  }
                                },
                                selectedColor: Colors.green[100],
                                checkmarkColor: Colors.green[800],
                              ),
                              FilterChip(
                                label: Text('Non Attivi'),
                                selected: _viewMode == 'non_attivi',
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _viewMode = 'non_attivi');
                                  }
                                },
                                selectedColor: Colors.grey[300],
                                checkmarkColor: Colors.grey[800],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista tecnici
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : filteredTechs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nessun tecnico trovato',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filteredTechs.length,
                              itemBuilder: (context, index) {
                                return _buildTechCard(filteredTechs[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
