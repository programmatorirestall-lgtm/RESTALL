import 'dart:convert';
import 'dart:io';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/TicketTech/tickeTech.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/Technician.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:restalltech/responsive.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class FilterPreset {
  final String name;
  final String searchQuery;
  final String statusFilter;
  final String typeFilter;
  final List<String> technicianFilter;
  final String dateFilter;
  final String sortOption;

  FilterPreset({
    required this.name,
    required this.searchQuery,
    required this.statusFilter,
    required this.typeFilter,
    required this.technicianFilter,
    required this.dateFilter,
    required this.sortOption,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'searchQuery': searchQuery,
        'statusFilter': statusFilter,
        'typeFilter': typeFilter,
        'technicianFilter': technicianFilter,
        'dateFilter': dateFilter,
        'sortOption': sortOption,
      };

  factory FilterPreset.fromJson(Map<String, dynamic> json) => FilterPreset(
        name: json['name'],
        searchQuery: json['searchQuery'],
        statusFilter: json['statusFilter'],
        typeFilter: json['typeFilter'],
        technicianFilter: List<String>.from(json['technicianFilter']),
        dateFilter: json['dateFilter'],
        sortOption: json['sortOption'],
      );
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String filter;

  _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.filter,
  });
}

class _HomeAdminState extends State<HomeAdmin> {
  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetKeys =
        prefs.getKeys().where((key) => key.startsWith('filter_preset_'));
    Map<String, FilterPreset> loadedPresets = {};
    for (final key in presetKeys) {
      final presetJson = prefs.getString(key);
      if (presetJson != null) {
        try {
          final preset = FilterPreset.fromJson(jsonDecode(presetJson));
          loadedPresets[preset.name] = preset;
        } catch (e) {
          print('Failed to load preset $key: $e');
          // Optionally, remove the corrupted preset
          // await prefs.remove(key);
        }
      }
    }
    if (mounted) {
      setState(() {
        _savedPresets = loadedPresets;
      });
    }
  }

  Future<void> _savePreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final preset = FilterPreset(
      name: name,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      typeFilter: _typeFilter,
      technicianFilter: _technicianFilter,
      dateFilter: _dateFilter,
      sortOption: _sortOption,
    );
    await prefs.setString('filter_preset_$name', jsonEncode(preset.toJson()));
    if (mounted) {
      _loadPresets(); // Reload to update the UI
    }
  }

  void _applyPreset(String name) {
    final preset = _savedPresets[name];
    if (preset == null) return;

    _searchController.text = preset.searchQuery;
    setState(() {
      _selectedPreset = name;
      _searchQuery = preset.searchQuery;
      _statusFilter = preset.statusFilter;
      _typeFilter = preset.typeFilter;
      _technicianFilter = preset.technicianFilter;
      _dateFilter = preset.dateFilter;
      _sortOption = preset.sortOption;
      _applyFilters();
    });
  }

  Future<void> _deletePreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('filter_preset_$name');
    if (_selectedPreset == name) {
      _selectedPreset = null;
    }
    if (mounted) {
      _loadPresets(); // Reload to update the UI
    }
  }

  void _showDeletePresetConfirmDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Preset'),
        content: Text('Sei sicuro di voler eliminare il preset "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              _deletePreset(name);
              Navigator.pop(context);
            },
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

// 3. CONFERMA ELIMINAZIONE
  void _showDeleteConfirmDialog(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Conferma Eliminazione'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sei sicuro di voler eliminare il ticket?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${ticket['id']} - ${ticket['ragSoc']}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(ticket['indirizzo'],
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Questa azione non può essere annullata.',
              style: TextStyle(
                  color: Colors.red[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTicket(ticket['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Salva Preset Filtri'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: 'Nome del preset'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _savePreset(nameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  // State variables
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  List<Technician> _technicians = [];
  Map<int, int> _technicianWorkloads = {};
  Map<String, FilterPreset> _savedPresets = {};
  String? _selectedPreset;

  // Filters and search
  String _searchQuery = '';
  String _statusFilter = 'Tutti';
  String _typeFilter = 'Tutti';
  List<String> _technicianFilter = [];
  String _dateFilter = 'Tutte';
  String _sortOption = 'Predefinito';
  bool _showOnlyAssigned = false;
  bool _showOnlyExpired = false;

  // UI state
  bool _isLoading = true;
  bool _isKanbanView = false;
  int _currentPage = 1;
  int _itemsPerPage = 50;
  int? _expandedTicketId;
  bool _showFilters = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadPresets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data fetching methods
  Future<void> _initializeData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadTechnicians(),
        _loadTickets(),
      ]);
      _calculateAndSetWorkloads();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) _showErrorAlert('Errore nel caricamento dati');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTechnicians() async {
    final Response response = await TechApi().getData();
    final body = json.decode(response.body);
    Iterable techList = body['tecnico'];
    List<Technician> techs = List<Technician>.from(
        techList.map((model) => Technician.fromJson(model)));
    techs.removeWhere((item) => item.verified == "FALSE");

    if (mounted) {
      setState(() {
        _technicians = techs;
      });
    }
  }

  Future<void> _loadTickets() async {
    final Response response = await TicketApi().getData();
    final body = json.decode(response.body);
    var ticketList = body['tickets'];

    List<Map<String, dynamic>> list = ticketList.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> processedTickets = list.map((item) {
      Map<String, dynamic> user = item['utente'];
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

      return {
        'id': item['id'],
        'tipo_macchina': item['tipo_macchina'],
        'stato_macchina': item['stato_macchina'],
        'stato': item['stato'],
        'data': item['data'],
        'indirizzo': item['indirizzo'],
        'nome': user['nome'],
        'cognome': user['cognome'],
        'email': user['email'],
        'numTel': user['numTel'],
        'id_tecnico': item['id_tecnico'],
        'oraPrevista': item['oraPrevista'],
        'ragSoc': ragSoc,
        'ragSocAzienda': item['ragSocAzienda'] != null && item['ragSocAzienda'].toString().isNotEmpty
            ? item['ragSocAzienda']
            : ragSoc,
        'descrizione': item['descrizione'] ?? '',
      };
    }).toList();

    setState(() {
      _tickets = processedTickets;
      _applyFilters();
    });
  }

  void _filterByStat(String stat) {
    _searchController.clear();
    _searchQuery = '';
    _dateFilter = 'Tutte';
    _typeFilter = 'Tutti';
    _showOnlyAssigned = false; // Reset by default

    switch (stat) {
      case 'Non Assegnati':
        _technicianFilter = ['Non assegnato'];
        _statusFilter = 'Tutti';
        break;
      case 'Assegnati':
        _technicianFilter = [];
        _statusFilter = 'Tutti';
        _showOnlyAssigned = true; // Set the flag here
        break;
      case 'In Corso':
        _statusFilter = 'In corso';
        _technicianFilter = [];
        break;
      case 'Totale Attivi':
      default:
        _statusFilter = 'Tutti';
        _technicianFilter = [];
        break;
    }

    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _tickets;

    // FILTRO PRINCIPALE: Escludi ticket chiusi
    filtered = filtered.where((ticket) => ticket['stato'] != 'Chiuso').toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ticket) {
        return ticket['id']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            ticket['ragSoc']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            ticket['indirizzo']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Stat-based filter for assigned
    if (_showOnlyAssigned) {
      filtered =
          filtered.where((ticket) => ticket['id_tecnico'] != null).toList();
    }

    // Status filter
    if (_statusFilter != 'Tutti') {
      filtered =
          filtered.where((ticket) => ticket['stato'] == _statusFilter).toList();
    }

    // Type filter
    if (_typeFilter != 'Tutti') {
      filtered = filtered
          .where((ticket) => ticket['tipo_macchina'] == _typeFilter)
          .toList();
    }

    // Date filter
    if (_dateFilter != 'Tutte') {
      DateTime now = DateTime.now();
      DateTime filterDate;

      switch (_dateFilter) {
        case 'Oggi':
          filterDate = DateTime(now.year, now.month, now.day);
          filtered = filtered.where((ticket) {
            try {
              DateTime ticketDate = DateTime.parse(ticket['data']);
              return ticketDate.isAfter(filterDate.subtract(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          break;
        case 'Questa settimana':
          filterDate = now.subtract(Duration(days: now.weekday - 1));
          filterDate =
              DateTime(filterDate.year, filterDate.month, filterDate.day);
          filtered = filtered.where((ticket) {
            try {
              DateTime ticketDate = DateTime.parse(ticket['data']);
              return ticketDate.isAfter(filterDate.subtract(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          break;
        case 'Questo mese':
          filterDate = DateTime(now.year, now.month, 1);
          filtered = filtered.where((ticket) {
            try {
              DateTime ticketDate = DateTime.parse(ticket['data']);
              return ticketDate.isAfter(filterDate.subtract(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
          break;
        case 'Ultimi 7 giorni':
          filterDate = now.subtract(Duration(days: 7));
          filtered = filtered.where((ticket) {
            try {
              DateTime ticketDate = DateTime.parse(ticket['data']);
              return ticketDate.isAfter(filterDate);
            } catch (e) {
              return false;
            }
          }).toList();
          break;
      }
    }
    // Technician filter
    if (_technicianFilter.isNotEmpty) {
      if (_technicianFilter.contains('Non assegnato')) {
        filtered =
            filtered.where((ticket) => ticket['id_tecnico'] == null).toList();
      } else {
        final selectedTechIds = _technicians
            .where((tech) =>
                _technicianFilter.contains('${tech.nome} ${tech.cognome}'))
            .map((tech) => tech.id)
            .toSet();

        filtered = filtered
            .where((ticket) => selectedTechIds.contains(ticket['id_tecnico']))
            .toList();
      }
    }

    // Sorting logic
    switch (_sortOption) {
      case 'Data apertura':
        filtered.sort((a, b) {
          try {
            final aDate = DateTime.parse(a['data']);
            final bDate = DateTime.parse(b['data']);
            return bDate.compareTo(aDate); // Sort descending
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Data prevista':
        filtered.sort((a, b) {
          try {
            final aDate = a['oraPrevista'] != null
                ? DateTime.parse(a['oraPrevista'])
                : null;
            final bDate = b['oraPrevista'] != null
                ? DateTime.parse(b['oraPrevista'])
                : null;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1; // Put nulls at the end
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Stato':
        filtered.sort((a, b) => a['stato'].compareTo(b['stato']));
        break;
      case 'Predefinito':
      default:
        // Ordina per data di creazione, più recenti prima
        filtered.sort((a, b) {
          try {
            final aDate = DateTime.parse(a['data']);
            final bDate = DateTime.parse(b['data']);
            return bDate.compareTo(aDate); // Più recenti prima
          } catch (e) {
            return 0;
          }
        });
        break;
    }

    // Smart filter for expired tickets
    if (_showOnlyExpired) {
      final now = DateTime.now();
      filtered = filtered.where((ticket) {
        if (ticket['oraPrevista'] == null) return false;
        if (ticket['stato'] == 'In corso' || ticket['stato'] == 'Chiuso') {
          return false;
        }

        try {
          final scheduledTime = DateTime.parse(ticket['oraPrevista']);
          return scheduledTime.isBefore(now);
        } catch (e) {
          // Se il formato della data non è valido, ignora questo ticket
          return false;
        }
      }).toList();
    }

    setState(() {
      _filteredTickets = filtered;
      _currentPage = 1;
    });
  }

  // UI Helper methods
  Widget _buildMachineTypeIcon(String type) {
    switch (type) {
      case "Altro":
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.precision_manufacturing_rounded,
                  color: Color(0xFF6C63FF), size: 16),
              SizedBox(width: 4),
              Text('ALTRO',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
      case "Climatizzazione":
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thermostat, color: Color(0xFF00BCD4), size: 16),
              SizedBox(width: 4),
              Text('CLIMA',
                  style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
      case "Aspirazione":
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF607D8B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, color: Color(0xFF607D8B), size: 16),
              SizedBox(width: 4),
              Text('ASPIRA',
                  style: TextStyle(
                      color: Color(0xFF607D8B),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
      case "Caldo":
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFFF5722).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department,
                  color: Color(0xFFFF5722), size: 16),
              SizedBox(width: 4),
              Text('CALDO',
                  style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
      case "Freddo":
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ac_unit, color: Color(0xFF2196F3), size: 16),
              SizedBox(width: 4),
              Text('FREDDO',
                  style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
      default:
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, color: Colors.grey[600], size: 16),
              SizedBox(width: 4),
              Text('N/D',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            ],
          ),
        );
    }
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case "Chiuso":
        color = Color(0xFF4CAF50);
        bgColor = Color(0xFFE8F5E8);
        break;
      case "In corso":
        color = Color(0xFFFF9800);
        bgColor = Color(0xFFFFF3E0);
        break;
      case "Aperto":
        color = Color(0xFF2196F3);
        bgColor = Color(0xFFE3F2FD);
        break;
      case "Sospeso":
        color = Color(0xFFF44336);
        bgColor = Color(0xFFFFEBEE);
        break;
      default:
        color = Colors.grey[600]!;
        bgColor = Colors.grey[100]!;
    }

    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getTechnicianName(int? techId) {
    if (techId == null) return "Non assegnato";
    try {
      final tech = _technicians.firstWhere((t) => t.id == techId);
      return "${tech.nome} ${tech.cognome}";
    } catch (e) {
      return "Tecnico non trovato";
    }
  }

  void _calculateAndSetWorkloads() {
    final Map<int, int> workloads = {};
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    // Initialize map for all technicians
    for (final tech in _technicians) {
      workloads[tech.id] = 0;
    }
    // Count tickets scheduled for today for each technician
    for (final ticket in _tickets) {
      if (ticket['stato'] != 'Chiuso') {
        final techId = ticket['id_tecnico'];
        final oraPrevista = ticket['oraPrevista'];

        // Count only if ticket has a scheduled time for today
        if (techId != null &&
            oraPrevista != null &&
            workloads.containsKey(techId)) {
          try {
            final scheduledTime = DateTime.parse(oraPrevista);
            if (scheduledTime.isAfter(todayStart) &&
                scheduledTime.isBefore(todayEnd)) {
              workloads[techId] = workloads[techId]! + 1;
            }
          } catch (e) {
            // Ignore invalid dates
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _technicianWorkloads = workloads;
      });
    }
  }

  List<Technician> _getTechnicianSuggestions(Map<String, dynamic> ticket) {
    // Create a copy of the technicians list to avoid modifying the original
    List<Technician> sortedTechs = List<Technician>.from(_technicians);

    // Sort the technicians. The primary sorting key is workload (ascending).
    // A secondary key (name) is used for stable sorting.
    sortedTechs.sort((a, b) {
      final workloadA = _technicianWorkloads[a.id] ?? 999;
      final workloadB = _technicianWorkloads[b.id] ?? 999;

      // Compare workloads
      int workloadCompare = workloadA.compareTo(workloadB);
      if (workloadCompare != 0) {
        return workloadCompare;
      }

      // If workloads are equal, sort by name
      return ('${a.cognome} ${a.nome}').compareTo('${b.cognome} ${b.nome}');
    });

    return sortedTechs;
  }

  // Assignment methods
  Future<void> _assignTechnician(int ticketId, int technicianId) async {
    try {
      final data = {
        'id_ticket': ticketId,
        'id_tecnico': technicianId,
      };

      int status = await TTApi().postData(data);
      if (status == 200 || status == 201) {
        // Aggiorna lo stato locale invece di ricaricare tutto
        setState(() {
          final ticketIndex = _tickets.indexWhere((t) => t['id'] == ticketId);
          if (ticketIndex != -1) {
            _tickets[ticketIndex]['id_tecnico'] = technicianId;
          }
          _applyFilters();
        });
        _showSuccessAlert('Tecnico assegnato con successo');
      } else {
        _showErrorAlert('Errore nell\'assegnazione del tecnico');
      }
    } catch (e) {
      _showErrorAlert('Errore di connessione');
    }
  }

// 1. METODO PER CANCELLAZIONE TICKET
  Future<void> _deleteTicket(int ticketId) async {
    try {
      int status = await TicketApi().deleteTicket(ticketId);
      if (status == 200) {
        // Aggiorna lo stato locale rimuovendo il ticket
        setState(() {
          _tickets.removeWhere((t) => t['id'] == ticketId);
          _applyFilters();
        });
        _showSuccessAlert('Ticket eliminato con successo');
      } else {
        _showErrorAlert('Errore nell\'eliminazione del ticket');
      }
    } catch (e) {
      _showErrorAlert('Errore di connessione');
    }
  }

  Future<void> _setScheduledTime(int ticketId, DateTime dateTime) async {
    try {
      final data = {
        'oraPrevista': dateTime.toIso8601String(),
      };

      int status = await TicketApi().setTime(data, ticketId);
      if (status == 200) {
        // Aggiorna lo stato locale invece di ricaricare tutto
        setState(() {
          final ticketIndex = _tickets.indexWhere((t) => t['id'] == ticketId);
          if (ticketIndex != -1) {
            _tickets[ticketIndex]['oraPrevista'] = dateTime.toIso8601String();
          }
          _applyFilters();
        });
        _showSuccessAlert('Orario programmato con successo');
      } else {
        _showErrorAlert('Errore nella programmazione');
      }
    } catch (e) {
      _showErrorAlert('Errore di connessione');
    }
  }

  // Quick schedule method
  void _showQuickScheduleDialog(Map<String, dynamic> ticket) {
    // Blocca la programmazione per ticket in corso
    if (ticket['stato'] == 'In corso') {
      _showErrorAlert('I ticket in corso non possono essere modificati');
      return;
    }

    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.schedule, color: secondaryColor),
              SizedBox(width: 8),
              Text('Programma Visita'),
            ],
          ),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket info compatta
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      _buildMachineTypeIcon(ticket['tipo_macchina']),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${ticket['id']} - ${ticket['ragSoc']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              ticket['indirizzo'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Data/ora selection
                Text(
                  'Seleziona Data e Ora:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                DateTimeField(
                  format: DateFormat("dd/MM/yyyy HH:mm"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'Tocca per selezionare',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onShowPicker: (context, currentValue) async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            currentValue ?? DateTime.now()),
                      );
                      if (time != null) {
                        return DateTimeField.combine(date, time);
                      }
                    }
                    return currentValue;
                  },
                  onChanged: (value) {
                    selectedDateTime = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: secondaryColor,
              ),
              child: Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: selectedDateTime == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _setScheduledTime(ticket['id'], selectedDateTime!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Programma'),
            ),
          ],
        );
      },
    );
  }

// 7. DIALOG ASSEGNAZIONE MIGLIORATO CON RICERCA TECNICI
  void _showTechnicianRoutePreview(int technicianId) {
    final tech = _technicians.firstWhere((t) => t.id == technicianId);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    // Get all tickets for this technician scheduled for today
    final todayTickets = _tickets.where((ticket) {
      if (ticket['id_tecnico'] != technicianId || ticket['stato'] == 'Chiuso') {
        return false;
      }
      final oraPrevista = ticket['oraPrevista'];
      if (oraPrevista == null) return false;

      try {
        final scheduledTime = DateTime.parse(oraPrevista);
        return scheduledTime.isAfter(todayStart) &&
            scheduledTime.isBefore(todayEnd);
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort by scheduled time
    todayTickets.sort((a, b) {
      try {
        final timeA = DateTime.parse(a['oraPrevista']);
        final timeB = DateTime.parse(b['oraPrevista']);
        return timeA.compareTo(timeB);
      } catch (e) {
        return 0;
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.map_outlined, color: Colors.blue[700], size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Giro di oggi',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${tech.nome} ${tech.cognome}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: Responsive.isMobile(context) ? double.maxFinite : 500,
            height: Responsive.isMobile(context)
                ? MediaQuery.of(context).size.height * 0.6
                : 500,
            child: todayTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Nessun ticket programmato per oggi',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: todayTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = todayTickets[index];
                      final scheduledTime =
                          DateTime.parse(ticket['oraPrevista']);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      DateFormat('HH:mm').format(scheduledTime),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '#${ticket['id']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                ticket['ragSoc'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ticket['indirizzo'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  // STEP 1: Selezione del tecnico
  void _showImprovedAssignmentDialog(Map<String, dynamic> ticket) {
    if (ticket['stato'] == 'In corso') {
      _showErrorAlert('I ticket in corso non possono essere riassegnati');
      return;
    }

    final suggestions = _getTechnicianSuggestions(ticket).take(3).toList();
    int? selectedTechId;
    String technicianSearchQuery = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<Technician> filteredTechs = _technicians.where((tech) {
              final name = '${tech.nome} ${tech.cognome}'.toLowerCase();
              return name.contains(technicianSearchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.assignment_ind,
                        color: secondaryColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Seleziona Tecnico',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Ticket #${ticket['id']} - Step 1/2',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: Responsive.isMobile(context) ? double.maxFinite : 700,
                height: Responsive.isMobile(context)
                    ? MediaQuery.of(context).size.height * 0.75
                    : 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: secondaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            _buildMachineTypeIcon(ticket['tipo_macchina']),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket['ragSoc'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    ticket['indirizzo'],
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                      if (suggestions.isNotEmpty) ...[
                        Text('Suggerimenti:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: suggestions.map((tech) {
                            final workload = _technicianWorkloads[tech.id] ?? 0;
                            final isSelected = selectedTechId == tech.id;
                            return ActionChip(
                              avatar: CircleAvatar(
                                backgroundColor: secondaryColor,
                                child: Text(
                                  '${tech.nome[0]}${tech.cognome[0]}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white),
                                ),
                              ),
                              label: Text('${tech.nome} ${tech.cognome}',
                                  style: TextStyle(fontSize: 13)),
                              tooltip: '$workload ticket oggi',
                              backgroundColor: isSelected
                                  ? secondaryColor.withValues(alpha: 0.2)
                                  : null,
                              onPressed: () {
                                setDialogState(() {
                                  selectedTechId = tech.id;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 12),
                        Divider(thickness: 1),
                        SizedBox(height: 12),
                      ],
                      Text('Lista Tecnici:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cerca per nome...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            technicianSearchQuery = value;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 350,
                          minHeight: 250,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredTechs.length,
                          itemBuilder: (context, index) {
                            final tech = filteredTechs[index];
                            final workload = _technicianWorkloads[tech.id] ?? 0;
                            final isSelected = selectedTechId == tech.id;

                            return Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? secondaryColor.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? secondaryColor.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    setDialogState(() {
                                      selectedTechId = tech.id;
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? secondaryColor
                                                : secondaryColor.withValues(
                                                    alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${tech.nome[0]}${tech.cognome[0]}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : secondaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${tech.nome} ${tech.cognome}',
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                  color: appBarColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.assignment,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$workload ticket oggi',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (workload > 0)
                                          IconButton(
                                            icon: Icon(Icons.map_outlined,
                                                size: 18),
                                            onPressed: () {
                                              _showTechnicianRoutePreview(
                                                  tech.id);
                                            },
                                            tooltip: 'Vedi giro',
                                            style: IconButton.styleFrom(
                                              foregroundColor: Colors.blue[700],
                                              padding: EdgeInsets.all(4),
                                            ),
                                          ),
                                        if (isSelected)
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: secondaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Annulla', style: TextStyle(fontSize: 15)),
                ),
                ElevatedButton(
                  onPressed: selectedTechId == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          // Passa allo step 2: selezione orario
                          _showScheduleSelectionDialog(ticket, selectedTechId!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Continua', style: TextStyle(fontSize: 15)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // STEP 2: Selezione dell'orario
  void _showScheduleSelectionDialog(Map<String, dynamic> ticket, int techId) {
    DateTime? selectedDateTime;

    // Trova il tecnico selezionato
    final selectedTech = _technicians.firstWhere((tech) => tech.id == techId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today,
                        color: secondaryColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Programma Visita',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Ticket #${ticket['id']} - Step 2/2',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: Responsive.isMobile(context) ? double.maxFinite : 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info ticket
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: secondaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            _buildMachineTypeIcon(ticket['tipo_macchina']),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket['ragSoc'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    ticket['indirizzo'],
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Info tecnico selezionato
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${selectedTech.nome[0]}${selectedTech.cognome[0]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tecnico Selezionato',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '${selectedTech.nome} ${selectedTech.cognome}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: appBarColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(thickness: 1),
                      SizedBox(height: 20),
                      Text('Seleziona Data e Ora:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 12),
                      DateTimeField(
                        format: DateFormat("dd/MM/yyyy HH:mm"),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          hintText: 'Seleziona data e ora',
                          prefixIcon: Icon(Icons.calendar_today, size: 22),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onShowPicker: (context, currentValue) async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            initialDate: currentValue ?? DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                  currentValue ?? DateTime.now()),
                            );
                            if (time != null) {
                              return DateTimeField.combine(date, time);
                            }
                          }
                          return currentValue;
                        },
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDateTime = value;
                          });
                        },
                      ),
                      if (selectedDateTime != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Visita programmata per: ${DateFormat("EEEE d MMMM yyyy 'alle' HH:mm", 'it').format(selectedDateTime!)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Torna indietro allo step 1
                    _showImprovedAssignmentDialog(ticket);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Indietro', style: TextStyle(fontSize: 15)),
                ),
                ElevatedButton(
                  onPressed: selectedDateTime == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _assignTechnician(ticket['id'], techId);
                          await _setScheduledTime(
                              ticket['id'], selectedDateTime!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Conferma Assegnazione',
                      style: TextStyle(fontSize: 15)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorAlert(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore',
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  void _showSuccessAlert(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Successo',
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.information,
    );
  }

// 8. SOSTITUZIONE DEL METODO BUILD PER SUPPORTARE IL RESPONSIVE
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: secondaryColor));
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredTickets.length);
    final paginatedTickets = _filteredTickets.sublist(startIndex, endIndex);
    final totalPages = (_filteredTickets.length / _itemsPerPage)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Responsive.isMobile(context)
                ? _buildMobileScrollableView(paginatedTickets, totalPages)
                : Column(
                    children: [
                      // Header compatto e pulito
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            // Stats essenziali compatte
                            _buildCompactStatsRow(),

                            SizedBox(height: 16),

                            // Barra di ricerca prominente + azioni
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSearchField(),
                                ),
                                SizedBox(width: 12),
                                _buildActionButtons(),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Filtri avanzati collapsabili
                            _buildCollapsibleFilters(),

                            SizedBox(height: 12),

                            // Info risultati e paginazione
                            _buildResultsInfo(paginatedTickets, totalPages),
                          ],
                        ),
                      ),

                      // Tickets list con card separate
                      Expanded(
                        child: _isKanbanView
                            ? _buildKanbanView()
                            : _buildSeparateCardsList(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Mobile view con collapsible header
  Widget _buildMobileScrollableView(
      List<Map<String, dynamic>> paginatedTickets, int totalPages) {
    return CustomScrollView(
      slivers: [
        // SliverAppBar espandibile con filtri e statistiche
        SliverAppBar(
          backgroundColor: secondaryColor,
          pinned: true,
          floating: false,
          expandedHeight: 140,
          collapsedHeight: 60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          flexibleSpace: LayoutBuilder(
            builder: (layoutContext, constraints) {
              // Calcola se è collassato
              final isCollapsed = constraints.maxHeight <= 60 + 56;

              return FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  padding:
                      EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stats compatte
                        _buildCompactStatsRow(),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                title: isCollapsed
                    ? Builder(
                        builder: (titleContext) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tickets',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Pulsante filtri compatto
                            IconButton(
                              icon:
                                  Icon(Icons.filter_list, color: Colors.white),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: titleContext,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (sheetContext) =>
                                      _buildFiltersBottomSheet(),
                                );
                              },
                            ),
                            // Paginazione compatta
                            _buildCompactPagination(totalPages),
                          ],
                        ),
                      )
                    : null,
                titlePadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              );
            },
          ),
        ),

        // Lista tickets
        SliverPadding(
          padding: EdgeInsets.all(8),
          sliver: _isKanbanView
              ? SliverToBoxAdapter(child: _buildKanbanView())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= paginatedTickets.length) return null;
                      final ticket = paginatedTickets[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildSeparateTicketCard(
                          ticket,
                          ticket['stato'] != 'In corso',
                        ),
                      );
                    },
                    childCount: paginatedTickets.length,
                  ),
                ),
        ),

        // Paginazione in fondo
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _buildResultsInfo(paginatedTickets, totalPages),
          ),
        ),
      ],
    );
  }

  // Paginazione compatta per barra collassata
  Widget _buildCompactPagination(int totalPages) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: Icon(
              Icons.chevron_left,
              size: 20,
              color: _currentPage > 1 ? secondaryColor : Colors.grey[400],
            ),
          ),
          SizedBox(width: 4),
          Text(
            '$_currentPage/$totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          SizedBox(width: 4),
          InkWell(
            onTap: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color:
                  _currentPage < totalPages ? secondaryColor : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom sheet per filtri su mobile
  Widget _buildFiltersBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titolo
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Filtri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              // Filtri
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24),
                  children: [
                    Text(
                      'Ricerca',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildSearchField(),
                    SizedBox(height: 24),
                    Text(
                      'Filtri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStatusFilterDropdown(),
                    SizedBox(height: 12),
                    _buildTypeFilterDropdown(),
                    SizedBox(height: 12),
                    _buildDateFilterDropdown(),
                    SizedBox(height: 12),
                    _buildSortDropdown(),
                    SizedBox(height: 12),
                    _buildTechnicianFilterChip(),
                    SizedBox(height: 12),
                    _buildSmartFilterChip(),
                    if (_savedPresets.isNotEmpty) ...[
                      SizedBox(height: 12),
                      _buildPresetSelector(),
                    ],
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _statusFilter = 'Tutti';
                            _typeFilter = 'Tutti';
                            _dateFilter = 'Tutte';
                            _sortOption = 'Predefinito';
                            _technicianFilter = [];
                            _showOnlyExpired = false;
                            _showOnlyAssigned = false;
                            _searchQuery = '';
                            _searchController.clear();
                            _selectedPreset = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.clear_all, size: 18),
                        label: Text('Cancella Filtri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Applica'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sostituisci completamente il metodo _buildListView() esistente con questo:

  Widget _buildListView() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredTickets.length);
    final paginatedTickets = _filteredTickets.sublist(startIndex, endIndex);

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          itemCount: paginatedTickets.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: Colors.grey[100],
            margin: EdgeInsets.symmetric(horizontal: 16),
          ),
          itemBuilder: (context, index) {
            final ticket = paginatedTickets[index];
            final canModify = ticket['stato'] != 'In corso';

            // Usa il nuovo metodo _buildEnhancedTicketCard
            Widget ticketCard = InkWell(
              onTap: () => _showTicketDetails(ticket),
              child: _buildEnhancedTicketCard(ticket, false, canModify),
            );

            // Gestione mobile con swipe
            if (Responsive.isMobile(context)) {
              return Dismissible(
                key: ValueKey(ticket['id']),
                confirmDismiss: (direction) async {
                  if (!canModify) {
                    _showErrorAlert(
                        'I ticket in corso non possono essere modificati');
                    return false;
                  }
                  if (direction == DismissDirection.startToEnd) {
                    _showImprovedAssignmentDialog(ticket);
                  } else if (direction == DismissDirection.endToStart) {
                    _showQuickScheduleDialog(ticket);
                  }
                  return false;
                },
                background: Container(
                  color: secondaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.assignment_ind, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Assegna',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Programma',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.schedule, color: Colors.white),
                    ],
                  ),
                ),
                child: ticketCard,
              );
            } else {
              return ticketCard;
            }
          },
        ),
      ),
    );
  }

// Sostituisci la sezione del ticket card in _buildListView() con questo codice migliorato

  Widget _buildEnhancedTicketCard(
      Map<String, dynamic> ticket, bool isSelected, bool canModify) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isSelected ? secondaryColor.withOpacity(0.05) : Colors.transparent,
      ),
      child: Row(
        children: [
          // Status indicator con colori originali
          _buildOriginalStatusIndicator(ticket['stato']),
          SizedBox(width: 16),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Ticket ID
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${ticket['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Urgency badge
                    _buildUrgencyBadge(ticket['data']),

                    Spacer(),

                    // Status badge con colori originali
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getOriginalStatusColor(ticket['stato'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getOriginalStatusColor(ticket['stato'])
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(ticket['stato']),
                            size: 16,
                            color: _getOriginalStatusColor(ticket['stato']),
                          ),
                          SizedBox(width: 4),
                          Text(
                            ticket['stato'].toUpperCase(),
                            style: TextStyle(
                              color: _getOriginalStatusColor(ticket['stato']),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Customer name prominente
                Text(
                  ticket['ragSoc'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket['indirizzo'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // DESCRIZIONE - SEMPRE VISIBILE se presente
                if (ticket['descrizione'] != null &&
                    ticket['descrizione'].toString().trim().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined,
                                size: 14, color: Colors.grey[700]),
                            SizedBox(width: 6),
                            Text(
                              'DESCRIZIONE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        ReadMoreText(
                          ticket['descrizione'].toString(),
                          trimLines: 3,
                          trimCollapsedText: ' Mostra tutto',
                          trimExpandedText: ' Mostra meno',
                          colorClickableText: secondaryColor,
                          trimMode: TrimMode.Line,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 12),

                // Tipo macchina - SINGOLO E PROMINENTE
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getMachineTypeColor(ticket['tipo_macchina']),
                        _getMachineTypeColor(ticket['tipo_macchina'])
                            .withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getMachineTypeColor(ticket['tipo_macchina'])
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMachineTypeIcon(ticket['tipo_macchina']),
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        ticket['tipo_macchina'].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Date section con distinzione chiara
                Row(
                  children: [
                    // Data Richiesta
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event_note,
                                    size: 14, color: Colors.blue[700]),
                                SizedBox(width: 4),
                                Text(
                                  'RICHIESTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(DateTime.parse(ticket['data'])),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_calculateDaysAgo(ticket['data'])} giorni fa',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Data Programmata (se presente)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ticket['oraPrevista'] != null
                              ? Colors.green[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ticket['oraPrevista'] != null
                                ? Colors.green[200]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: ticket['oraPrevista'] != null
                                      ? Colors.green[700]
                                      : Colors.grey[500],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PROGRAMMATO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ticket['oraPrevista'] != null
                                        ? Colors.green[700]
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            if (ticket['oraPrevista'] != null) ...[
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(ticket['oraPrevista'])),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _getScheduledTimeStatus(ticket['oraPrevista']),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isOverdue(ticket['oraPrevista'])
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                  fontWeight: _isOverdue(ticket['oraPrevista'])
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ] else
                              Text(
                                'Non programmato',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Technician info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ticket['id_tecnico'] != null
                        ? Colors.blue[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ticket['id_tecnico'] != null
                          ? Colors.blue[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ticket['id_tecnico'] != null
                            ? Icons.person
                            : Icons.person_off,
                        size: 16,
                        color: ticket['id_tecnico'] != null
                            ? Colors.blue[700]
                            : Colors.red[700],
                      ),
                      SizedBox(width: 6),
                      Text(
                        'TECNICO: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: ticket['id_tecnico'] != null
                              ? Colors.blue[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _getTechnicianName(ticket['id_tecnico']) +
                              (ticket['id_tecnico'] != null
                                  ? ' (${_technicianWorkloads[ticket['id_tecnico']] ?? 0} oggi)'
                                  : ''),
                          style: TextStyle(
                            fontSize: 12,
                            color: ticket['id_tecnico'] != null
                                ? Colors.blue[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          SizedBox(width: 16),
          Column(
            children: [
              IconButton(
                onPressed: () => _showTicketDetails(ticket),
                icon: Icon(Icons.info_outline, size: 20),
                tooltip: 'Dettagli',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 4),
              if (canModify)
                IconButton(
                  onPressed: () => _showImprovedAssignmentDialog(ticket),
                  icon: Icon(Icons.assignment_ind_outlined, size: 20),
                  tooltip: 'Assegna',
                  style: IconButton.styleFrom(
                    backgroundColor: secondaryColor.withOpacity(0.1),
                    foregroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outlined,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

// Helper functions da aggiungere alla classe

  Widget _buildOriginalStatusIndicator(String status) {
    Color color = _getOriginalStatusColor(status);

    return Container(
      width: 4,
      height: 120, // Più alto per accomodare più contenuto
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            offset: Offset(1, 0),
          ),
        ],
      ),
    );
  }

  Color _getOriginalStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return Colors.green; // Verde come originale
      case "In corso":
        return Colors.grey; // Grigio come originale
      case "Aperto":
        return Colors.yellow[700]!; // Giallo come originale
      case "Sospeso":
        return Colors.red; // Rosso come originale
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Chiuso":
        return Icons.check_circle_rounded;
      case "In corso":
        return Icons.settings_rounded;
      case "Aperto":
        return Icons.access_time_filled_rounded;
      case "Sospeso":
        return Icons.pause_circle_filled_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getMachineTypeColor(String type) {
    switch (type) {
      case "Climatizzazione":
        return Color(0xFF00BCD4);
      case "Aspirazione":
        return Color(0xFF607D8B);
      case "Caldo":
        return Color(0xFFFF5722);
      case "Freddo":
        return Color(0xFF2196F3);
      case "Altro":
        return Color(0xFF6C63FF);
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getMachineTypeIcon(String type) {
    switch (type) {
      case "Climatizzazione":
        return Icons.thermostat;
      case "Aspirazione":
        return Icons.air;
      case "Caldo":
        return Icons.local_fire_department;
      case "Freddo":
        return Icons.ac_unit;
      case "Altro":
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.help_outline;
    }
  }

  int _calculateDaysAgo(String dateString) {
    final date = DateTime.parse(dateString);
    return DateTime.now().difference(date).inDays;
  }

  String _getScheduledTimeStatus(String scheduledTime) {
    final scheduled = DateTime.parse(scheduledTime);
    final now = DateTime.now();

    if (scheduled.isBefore(now)) {
      final overdueDays = now.difference(scheduled).inDays;
      final overdueHours = now.difference(scheduled).inHours % 24;

      if (overdueDays > 0) {
        return 'SCADUTO da $overdueDays giorni';
      } else if (overdueHours > 0) {
        return 'SCADUTO da $overdueHours ore';
      } else {
        return 'SCADUTO';
      }
    } else {
      final daysUntil = scheduled.difference(now).inDays;
      final hoursUntil = scheduled.difference(now).inHours % 24;

      if (daysUntil > 0) {
        return 'tra $daysUntil giorni';
      } else if (hoursUntil > 0) {
        return 'tra $hoursUntil ore';
      } else {
        return 'tra poco';
      }
    }
  }

  bool _isOverdue(String? scheduledTime) {
    if (scheduledTime == null) return false;
    try {
      return DateTime.parse(scheduledTime).isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

// 2. FINESTRA DETTAGLI MIGLIORATA CON CANCELLAZIONE
  void _showTicketDetails(Map<String, dynamic> ticket) async {
    // Chiamata API per ottenere dettagli completi
    Map<String, dynamic> detailedTicket = ticket;
    final response = await TicketApi().getDetails(ticket['id']);
    if (response != null) {
      final body = json.decode(response.body);
      print('=== DETTAGLI TICKET COMPLETI ===');
      print(json.encode(body));
      print('=== FINE DETTAGLI ===');

      // Merge dei dati dal getDetails con quelli già presenti
      if (body['ticket'] != null) {
        detailedTicket = {
          ...ticket,
          'descrizione': body['ticket']['descrizione'] ?? '',
          'rifEsterno': body['ticket']['rifEsterno'] ?? '',
          'summary': body['ticket']['summary'] ?? [],
          'fogli': body['ticket']['fogli'] ?? [],
          'partiva': body['ticket']['partiva'] ?? '',
          'codFisc': body['ticket']['codFisc'] ?? '',
          'codsdi': body['ticket']['codsdi'] ?? '',
          'citta': body['ticket']['citta'] ?? '',
          'indirizzoFatturazione': body['ticket']['indirizzoFatturazione'] ?? '',
          'rifFurgone': body['ticket']['rifFurgone'],
        };
      }
    }

    final isOverdue =
        detailedTicket['oraPrevista'] != null && _isOverdue(detailedTicket['oraPrevista']);

    // Colore header in base allo stato
    final headerColor = _getHeaderColorByStatus(detailedTicket['stato']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: Responsive.isMobile(context)
              ? MediaQuery.of(context).size.width * 0.95
              : MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: Responsive.isMobile(context) ? double.infinity : 1400,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente basato sullo stato
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColor, headerColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.confirmation_number,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ticket #${detailedTicket['id']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${detailedTicket['nome'] ?? ''} ${detailedTicket['cognome'] ?? ''}'
                                        .trim()
                                        .isEmpty
                                    ? 'Aperto il ${DateFormat('dd/MM/yyyy').format(DateTime.parse(detailedTicket['data']))}'
                                    : 'Aperto da ${detailedTicket['nome']} ${detailedTicket['cognome']} il ${DateFormat('dd/MM/yyyy').format(DateTime.parse(detailedTicket['data']))}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Badges stato e tipo
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildHeaderBadge(
                          detailedTicket['stato'],
                          _getStatusIconData(detailedTicket['stato']),
                          Colors.white,
                        ),
                        _buildHeaderBadge(
                          detailedTicket['tipo_macchina'],
                          _getMachineTypeIcon(detailedTicket['tipo_macchina']),
                          _getMachineTypeColor(detailedTicket['tipo_macchina']),
                        ),
                        if (isOverdue)
                          _buildHeaderBadge(
                              'SCADUTO', Icons.warning_amber, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),

              // Content scrollabile
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Responsive.isMobile(context)
                      ? _buildMobileLayout(detailedTicket)
                      : _buildDesktopLayout(detailedTicket),
                ),
              ),

              // Footer con azioni principali
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // Elimina
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmDialog(detailedTicket);
                        },
                        icon: Icon(Icons.delete_forever, size: 18),
                        label: Text(
                          'Elimina',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Assegna
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: ticket['stato'] == 'In corso'
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showImprovedAssignmentDialog(ticket);
                              },
                        icon: Icon(Icons.assignment_ind, size: 18),
                        label: Text(
                          'Assegna',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedTicketDetails(Map<String, dynamic> ticket) {
    final canModify = ticket['stato'] != 'In corso';
    final hasPhone =
        ticket['numTel'] != null && ticket['numTel'].toString().isNotEmpty;
    final hasEmail =
        ticket['email'] != null && ticket['email'].toString().isNotEmpty;
    final hasAddress = ticket['indirizzo'] != null &&
        ticket['indirizzo'].toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      color: Colors.blueGrey[50]!.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (ticket['descrizione'] != null &&
              ticket['descrizione'].toString().trim().isNotEmpty) ...[
            Text(
              'DESCRIZIONE',
              style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            SizedBox(height: 8),
            Text(
              ticket['descrizione'].toString(),
              style:
                  TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
            ),
            Divider(height: 32),
          ],

          Text(
            'AZIONI',
            style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              // Assign
              FilledButton.icon(
                onPressed: canModify
                    ? () => _showImprovedAssignmentDialog(ticket)
                    : null,
                icon: Icon(Icons.assignment_ind_outlined, size: 18),
                label: Text('Assegna'),
                style: FilledButton.styleFrom(
                  backgroundColor: secondaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
              // Call
              FilledButton.icon(
                onPressed: hasPhone
                    ? () async {
                        final Uri telUri =
                            Uri(scheme: 'tel', path: ticket['numTel']);
                        try {
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          } else {
                            _showErrorAlert(
                                'Impossibile effettuare la chiamata');
                          }
                        } catch (e) {
                          _showErrorAlert('Errore: ${e.toString()}');
                        }
                      }
                    : null,
                icon: Icon(Icons.call_outlined, size: 18),
                label: Text('Chiama'),
              ),
              // Email
              FilledButton.icon(
                onPressed: hasEmail
                    ? () async {
                        final Uri mailUri =
                            Uri(scheme: 'mailto', path: ticket['email']);
                        try {
                          if (await canLaunchUrl(mailUri)) {
                            await launchUrl(mailUri);
                          } else {
                            _showErrorAlert('Impossibile inviare l\'email');
                          }
                        } catch (e) {
                          _showErrorAlert('Errore: ${e.toString()}');
                        }
                      }
                    : null,
                icon: Icon(Icons.email_outlined, size: 18),
                label: Text('Email'),
              ),
              // Map
              FilledButton.icon(
                onPressed: hasAddress
                    ? () async {
                        final query = Uri.encodeComponent(ticket['indirizzo']);
                        final Uri mapUri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$query');
                        try {
                          if (await canLaunchUrl(mapUri)) {
                            await launchUrl(mapUri);
                          } else {
                            _showErrorAlert('Impossibile aprire la mappa');
                          }
                        } catch (e) {
                          _showErrorAlert('Errore: ${e.toString()}');
                        }
                      }
                    : null,
                icon: Icon(Icons.map_outlined, size: 18),
                label: Text('Mappa'),
              ),
              // Add Note
              FilledButton.icon(
                onPressed: null, // Disabled for now
                icon: Icon(Icons.note_add_outlined, size: 18),
                label: Text('Aggiungi Nota'),
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKanbanView() {
    final List<Map<String, dynamic>> nonAssegnati = [];
    final List<Map<String, dynamic>> assegnati = [];
    final List<Map<String, dynamic>> programmati = [];
    final List<Map<String, dynamic>> inCorso = [];

    for (final ticket in _filteredTickets) {
      if (ticket['stato'] == 'In corso') {
        inCorso.add(ticket);
      } else if (ticket['id_tecnico'] == null) {
        nonAssegnati.add(ticket);
      } else if (ticket['oraPrevista'] != null) {
        programmati.add(ticket);
      } else {
        assegnati.add(ticket);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
              title: 'Non Assegnati (${nonAssegnati.length})',
              children: nonAssegnati.map((t) => _buildKanbanCard(t)).toList()),
          _buildKanbanColumn(
              title: 'Assegnati (${assegnati.length})',
              children: assegnati.map((t) => _buildKanbanCard(t)).toList()),
          _buildKanbanColumn(
              title: 'Programmati (${programmati.length})',
              children: programmati.map((t) => _buildKanbanCard(t)).toList()),
          _buildKanbanColumn(
              title: 'In Corso (${inCorso.length})',
              children: inCorso.map((t) => _buildKanbanCard(t)).toList()),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(Map<String, dynamic> ticket) {
    final canModify = ticket['stato'] != 'In corso';
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: canModify ? () => _showImprovedAssignmentDialog(ticket) : null,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Urgency and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUrgencyBadge(ticket['data']),
                  if (canModify)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'assign') {
                          _showImprovedAssignmentDialog(ticket);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'assign',
                          child: ListTile(
                            leading: Icon(Icons.assignment_ind_outlined),
                            title: Text('Assegna'),
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      tooltip: 'Azioni rapide',
                    ),
                ],
              ),
              if (_buildUrgencyBadge(ticket['data'])
                  is SizedBox) // Add space only if badge is not shown
                SizedBox(height: 28),
              SizedBox(height: 8),

              // Body: Title and ID
              Text(
                ticket['ragSoc'],
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '#${ticket['id']}',
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
              SizedBox(height: 12),

              // Footer: Machine type and Technician
              Row(
                children: [
                  _buildMachineTypeIcon(ticket['tipo_macchina']),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTechnicianName(ticket['id_tecnico']) +
                          (ticket['id_tecnico'] != null
                              ? ' (${_technicianWorkloads[ticket['id_tecnico']] ?? 0})'
                              : ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: ticket['id_tecnico'] != null
                            ? Colors.blue[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(
      {required String title, required List<Widget> children}) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height *
          0.7, // Give columns a defined height
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Title
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey[300]),
          // List of tickets
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: children.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun ticket',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      children: children,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(String dateString) {
    if (dateString.isEmpty) {
      return SizedBox.shrink();
    }
    final creationDate = DateTime.parse(dateString);
    final age = DateTime.now().difference(creationDate);
    String label;
    Color color;
    Color textColor;
    IconData icon;

    if (age.inDays > 7) {
      label = 'CRITICO';
      color = Color(0xFFFEEBEE); // red[50]
      textColor = Color(0xFFC62828); // red[800]
      icon = Icons.error_outline;
    } else if (age.inDays > 3) {
      label = 'ALTO';
      color = Color(0xFFFFF3E0); // orange[50]
      textColor = Color(0xFFEF6C00); // orange[800]
      icon = Icons.warning_amber_outlined;
    } else if (age.inDays > 1) {
      label = 'MEDIO';
      color = Color(0xFFFFFDE7); // yellow[50]
      textColor = Color(0xFFF9A825); // yellow[800]
      icon = Icons.info_outline;
    } else {
      return SizedBox.shrink(); // No badge for recent tickets
    }

    return Tooltip(
      message:
          'Aperto da ${age.inDays} ${age.inDays == 1 ? "giorno" : "giorni"}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 12),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return Color(0xFF4CAF50);
      case "In corso":
        return Color(0xFFFF9800);
      case "Aperto":
        return Color(0xFF2196F3);
      case "Sospeso":
        return Color(0xFFF44336);
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildPresetSelector() {
    return PopupMenuButton<String>(
      onSelected: (String name) {
        _applyPreset(name);
      },
      itemBuilder: (BuildContext context) {
        if (_savedPresets.isEmpty) {
          return [
            PopupMenuItem(
              child: Text('Nessun preset salvato'),
              enabled: false,
            ),
          ];
        }
        return _savedPresets.keys.map((String name) {
          return PopupMenuItem<String>(
            value: name,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red[700], size: 22),
                  onPressed: () {
                    Navigator.pop(
                        context); // Close the menu before showing dialog
                    _showDeletePresetConfirmDialog(name);
                  },
                  tooltip: 'Elimina preset',
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.bookmark_border, size: 20, color: Colors.grey[700]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedPreset ?? 'Carica Preset',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianFilterChip() {
    String label = 'Tutti i Tecnici';
    if (_technicianFilter.isNotEmpty) {
      if (_technicianFilter.length == 1) {
        label = _technicianFilter.first;
      } else {
        label = '${_technicianFilter.length} tecnici selezionati';
      }
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _showTechnicianMultiSelectDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_search_outlined,
                      size: 20, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        InkWell(
          onTap: _showTechnicianAnalytics,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.analytics, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showTechnicianMultiSelectDialog() {
    List<String> tempSelections = List<String>.from(_technicianFilter);
    bool unassignedSelected = tempSelections.contains('Non assegnato');
    if (unassignedSelected) {
      tempSelections.remove('Non assegnato');
    }

    String searchQuery = '';

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            // Separa tecnici attivi e non attivi
            final activeTechs =
                _technicians.where((tech) => tech.verified == '1').toList();
            final inactiveTechs =
                _technicians.where((tech) => tech.verified != '1').toList();

            // Filtra per ricerca
            final filteredActive = activeTechs.where((tech) {
              final name = '${tech.nome} ${tech.cognome}'.toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            final filteredInactive = inactiveTechs.where((tech) {
              final name = '${tech.nome} ${tech.cognome}'.toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              title: Row(
                children: [
                  Icon(Icons.people_rounded, color: secondaryColor),
                  SizedBox(width: 8),
                  Text('Seleziona Tecnici'),
                ],
              ),
              content: Container(
                width: 400,
                height: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra di ricerca
                    TextFormField(
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
                        setDialogState(() => searchQuery = value);
                      },
                    ),
                    SizedBox(height: 16),

                    // Opzione "Non assegnato"
                    CheckboxListTile(
                      title: const Text('Non assegnato',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      value: unassignedSelected,
                      tileColor: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (isSelected) {
                        setDialogState(() {
                          unassignedSelected = isSelected ?? false;
                          if (unassignedSelected) {
                            tempSelections.clear();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 8),

                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Tecnici Attivi
                          if (filteredActive.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tecnici Attivi (${filteredActive.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...filteredActive.map((tech) {
                              final techName = '${tech.nome} ${tech.cognome}';
                              final workload =
                                  _technicianWorkloads[tech.id] ?? 0;
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: CheckboxListTile(
                                  title: Text(techName),
                                  subtitle: Text('$workload ticket oggi'),
                                  secondary: CircleAvatar(
                                    backgroundColor: secondaryColor,
                                    child: Text(
                                      '${tech.nome[0]}${tech.cognome[0]}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  value: tempSelections.contains(techName),
                                  onChanged: (isSelected) {
                                    setDialogState(() {
                                      if (isSelected == true) {
                                        tempSelections.add(techName);
                                      } else {
                                        tempSelections.remove(techName);
                                      }
                                      if (tempSelections.isNotEmpty) {
                                        unassignedSelected = false;
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],

                          // Tecnici Non Attivi
                          if (filteredInactive.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.cancel,
                                      color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tecnici Non Attivi (${filteredInactive.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...filteredInactive.map((tech) {
                              final techName = '${tech.nome} ${tech.cognome}';
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                color: Colors.grey[50],
                                child: CheckboxListTile(
                                  title: Text(
                                    techName,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  subtitle: Text('Non attivo',
                                      style: TextStyle(color: Colors.grey)),
                                  secondary: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Text(
                                      '${tech.nome[0]}${tech.cognome[0]}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  value: tempSelections.contains(techName),
                                  onChanged: (isSelected) {
                                    setDialogState(() {
                                      if (isSelected == true) {
                                        tempSelections.add(techName);
                                      } else {
                                        tempSelections.remove(techName);
                                      }
                                      if (tempSelections.isNotEmpty) {
                                        unassignedSelected = false;
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryColor,
                    padding: EdgeInsets.symmetric(
                        horizontal: largePadding, vertical: defaultPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                    ),
                  ),
                  child: Text('Annulla',
                      style: TextStyle(
                          color: secondaryColor, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 8,
                  height: 8,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    List<String> finalSelections = [];
                    if (unassignedSelected) {
                      finalSelections.add('Non assegnato');
                    } else {
                      finalSelections.addAll(tempSelections);
                    }
                    setState(() {
                      _technicianFilter = finalSelections;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.check_rounded),
                  label: Text('Conferma'),
                ),
              ],
            );
          });
        });
  }

// 4. FILTRI RESPONSIVE PER MOBILE
  Widget _buildMobileFilters() {
    return ElevatedButton.icon(
      onPressed: _showMobileFiltersDialog,
      icon: Icon(Icons.filter_list),
      label: Text('Filtri'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _hasActiveFilters() ? secondaryColor : Colors.grey[100],
        foregroundColor: _hasActiveFilters() ? Colors.white : Colors.grey[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _statusFilter != 'Tutti' ||
        _typeFilter != 'Tutti' ||
        _technicianFilter.isNotEmpty ||
        _dateFilter != 'Tutte' ||
        _showOnlyExpired ||
        _sortOption != 'Predefinito';
  }

  void _showMobileFiltersDialog() {
    // Stati temporanei per il dialog
    String tempSearchQuery = _searchQuery;
    String tempStatusFilter = _statusFilter;
    String tempTypeFilter = _typeFilter;
    List<String> tempTechnicianFilter = List.from(_technicianFilter);
    String tempDateFilter = _dateFilter;
    String tempSortOption = _sortOption;
    bool tempShowOnlyExpired = _showOnlyExpired;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.filter_list, color: secondaryColor),
                    SizedBox(width: 8),
                    Text('Filtri Avanzati',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ricerca
                        Text('Ricerca:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Cerca ticket, cliente, indirizzo...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (value) =>
                              setDialogState(() => tempSearchQuery = value),
                          controller:
                              TextEditingController(text: tempSearchQuery),
                        ),
                        SizedBox(height: 20),

                        // Stato
                        Text('Stato:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        _buildFilterDropdown(
                          label: 'Stato',
                          value: tempStatusFilter,
                          items: ['Tutti', 'Aperto', 'In corso', 'Sospeso'],
                          onChanged: (value) =>
                              setDialogState(() => tempStatusFilter = value!),
                        ),
                        SizedBox(height: 20),

                        // Tipo Macchina
                        Text('Tipo Macchina:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        _buildFilterDropdown(
                          label: 'Tipo Macchina',
                          value: tempTypeFilter,
                          items: [
                            'Tutti',
                            'Climatizzazione',
                            'Aspirazione',
                            'Caldo',
                            'Freddo',
                            'Altro'
                          ],
                          onChanged: (value) =>
                              setDialogState(() => tempTypeFilter = value!),
                        ),
                        SizedBox(height: 20),

                        // Tecnici
                        Text('Tecnici:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showMobileTechnicianSelector(
                              tempTechnicianFilter, setDialogState),
                          child: Text(tempTechnicianFilter.isEmpty
                              ? 'Tutti i Tecnici'
                              : '${tempTechnicianFilter.length} selezionati'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Data
                        Text('Periodo:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        _buildFilterDropdown(
                          label: 'Periodo',
                          value: tempDateFilter,
                          items: [
                            'Tutte',
                            'Oggi',
                            'Ultimi 7 giorni',
                            'Questa settimana',
                            'Questo mese'
                          ],
                          onChanged: (value) =>
                              setDialogState(() => tempDateFilter = value!),
                        ),
                        SizedBox(height: 20),

                        // Ordinamento
                        Text('Ordinamento:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        _buildFilterDropdown(
                          label: 'Ordinamento',
                          value: tempSortOption,
                          items: [
                            'Predefinito',
                            'Data apertura',
                            'Data prevista',
                            'Stato'
                          ],
                          onChanged: (value) =>
                              setDialogState(() => tempSortOption = value!),
                        ),
                        SizedBox(height: 20),

                        // Filtri avanzati
                        Text('Opzioni Avanzate:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        CheckboxListTile(
                          title: Text('Solo Scaduti'),
                          value: tempShowOnlyExpired,
                          onChanged: (value) => setDialogState(
                              () => tempShowOnlyExpired = value ?? false),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // Reset filtri
                          setDialogState(() {
                            tempSearchQuery = '';
                            tempStatusFilter = 'Tutti';
                            tempTypeFilter = 'Tutti';
                            tempTechnicianFilter.clear();
                            tempDateFilter = 'Tutte';
                            tempSortOption = 'Predefinito';
                            tempShowOnlyExpired = false;
                          });
                        },
                        child: Text('Reset'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          // Applica filtri
                          setState(() {
                            _searchQuery = tempSearchQuery;
                            _statusFilter = tempStatusFilter;
                            _typeFilter = tempTypeFilter;
                            _technicianFilter = List.from(tempTechnicianFilter);
                            _dateFilter = tempDateFilter;
                            _sortOption = tempSortOption;
                            _showOnlyExpired = tempShowOnlyExpired;
                            _showOnlyAssigned = false;
                            _searchController.text = tempSearchQuery;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Applica Filtri'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// 5. SELETTORE TECNICI MOBILE CON RICERCA
  void _showMobileTechnicianSelector(
      List<String> currentSelection, Function setDialogState) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerState) {
          String searchQuery = '';

          // Separa tecnici attivi e non attivi
          final activeTechs =
              _technicians.where((tech) => tech.verified == '1').toList();
          final inactiveTechs =
              _technicians.where((tech) => tech.verified != '1').toList();

          // Filtra per ricerca
          final filteredActive = activeTechs.where((tech) {
            final name = '${tech.nome} ${tech.cognome}'.toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          final filteredInactive = inactiveTechs.where((tech) {
            final name = '${tech.nome} ${tech.cognome}'.toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: secondaryColor),
                      SizedBox(width: 8),
                      Text('Seleziona Tecnici',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Barra di ricerca
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca tecnico...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setInnerState(() => searchQuery = value);
                    },
                  ),
                  SizedBox(height: 16),

                  // Opzione "Non assegnato"
                  CheckboxListTile(
                    title: Text('Non assegnato',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: currentSelection.contains('Non assegnato'),
                    tileColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (isSelected) {
                      setInnerState(() {
                        if (isSelected == true) {
                          currentSelection.clear();
                          currentSelection.add('Non assegnato');
                        } else {
                          currentSelection.remove('Non assegnato');
                        }
                      });
                      setDialogState(() {});
                    },
                  ),
                  SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: [
                        // Tecnici Attivi
                        if (filteredActive.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tecnici Attivi (${filteredActive.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...filteredActive.map((tech) {
                            final techName = '${tech.nome} ${tech.cognome}';
                            final workload = _technicianWorkloads[tech.id] ?? 0;
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: CheckboxListTile(
                                title: Text(techName),
                                subtitle: Text('$workload ticket oggi'),
                                secondary: CircleAvatar(
                                  backgroundColor: secondaryColor,
                                  child: Text(
                                    '${tech.nome[0]}${tech.cognome[0]}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                value: currentSelection.contains(techName),
                                onChanged: (isSelected) {
                                  setInnerState(() {
                                    currentSelection.remove('Non assegnato');
                                    if (isSelected == true) {
                                      currentSelection.add(techName);
                                    } else {
                                      currentSelection.remove(techName);
                                    }
                                  });
                                  setDialogState(() {});
                                },
                              ),
                            );
                          }),
                        ],

                        // Tecnici Non Attivi
                        if (filteredInactive.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.cancel,
                                    color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tecnici Non Attivi (${filteredInactive.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...filteredInactive.map((tech) {
                            final techName = '${tech.nome} ${tech.cognome}';
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              color: Colors.grey[50],
                              child: CheckboxListTile(
                                title: Text(
                                  techName,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                subtitle: Text('Non attivo',
                                    style: TextStyle(color: Colors.grey)),
                                secondary: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Text(
                                    '${tech.nome[0]}${tech.cognome[0]}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                value: currentSelection.contains(techName),
                                onChanged: (isSelected) {
                                  setInnerState(() {
                                    currentSelection.remove('Non assegnato');
                                    if (isSelected == true) {
                                      currentSelection.add(techName);
                                    } else {
                                      currentSelection.remove(techName);
                                    }
                                  });
                                  setDialogState(() {});
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Conferma Selezione'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// 6. ANALITICHE TECNICI
  void _showTechnicianAnalytics() {
    showDialog(
      context: context,
      builder: (context) {
        // Calcola statistiche per ogni tecnico
        Map<int, Map<String, dynamic>> techStats = {};

        for (final tech in _technicians) {
          final techTickets = _tickets
              .where((ticket) => ticket['id_tecnico'] == tech.id)
              .toList();
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final todayEnd = todayStart.add(Duration(days: 1));

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

          final activeTickets = techTickets
              .where((ticket) => ticket['stato'] != 'Chiuso')
              .toList();
          final completedTickets = techTickets
              .where((ticket) => ticket['stato'] == 'Chiuso')
              .toList();
          final inProgressTickets = techTickets
              .where((ticket) => ticket['stato'] == 'In corso')
              .toList();

          techStats[tech.id] = {
            'name': '${tech.nome} ${tech.cognome}',
            'verified': tech.verified,
            'todayCount': todayTickets.length,
            'activeCount': activeTickets.length,
            'completedCount': completedTickets.length,
            'inProgressCount': inProgressTickets.length,
            'totalAssigned': techTickets.length,
          };
        }

        // Ordina tecnici: attivi prima, poi per numero ticket oggi
        final sortedTechs = _technicians.toList()
          ..sort((a, b) {
            if (a.verified != b.verified) {
              return b.verified.compareTo(a.verified);
            }
            final aToday = techStats[a.id]?['todayCount'] ?? 0;
            final bToday = techStats[b.id]?['todayCount'] ?? 0;
            return bToday.compareTo(aToday);
          });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: secondaryColor, size: 28),
                    SizedBox(width: 12),
                    Text('Analitiche Tecnici',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Divider(),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedTechs.length,
                    itemBuilder: (context, index) {
                      final tech = sortedTechs[index];
                      final stats = techStats[tech.id]!;
                      final isActive = tech.verified == '1';
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: isActive ? Colors.white : Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive
                                ? secondaryColor.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        isActive ? secondaryColor : Colors.grey,
                                    radius: 24,
                                    child: Text(
                                        '${tech.nome[0]}${tech.cognome[0]}',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(stats['name'],
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isActive
                                                    ? Colors.black
                                                    : Colors.grey[600])),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                                isActive
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                size: 16,
                                                color: isActive
                                                    ? Colors.green
                                                    : Colors.grey),
                                            SizedBox(width: 4),
                                            Text(
                                                isActive
                                                    ? 'Attivo'
                                                    : 'Non Attivo',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: isActive
                                                        ? Colors.green
                                                        : Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: [
                                  _buildAnalyticStatCard(
                                      'Oggi',
                                      stats['todayCount'].toString(),
                                      Icons.today,
                                      Colors.blue),
                                  _buildAnalyticStatCard(
                                      'Attivi',
                                      stats['activeCount'].toString(),
                                      Icons.pending_actions,
                                      Colors.orange),
                                  _buildAnalyticStatCard(
                                      'In Corso',
                                      stats['inProgressCount'].toString(),
                                      Icons.refresh,
                                      Colors.purple),
                                  _buildAnalyticStatCard(
                                      'Completati',
                                      stats['completedCount'].toString(),
                                      Icons.check_circle,
                                      Colors.green),
                                  _buildAnalyticStatCard(
                                      'Totali',
                                      stats['totalAssigned'].toString(),
                                      Icons.assignment,
                                      secondaryColor),
                                  if (stats['todayCount'] > 0)
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showTechnicianRoutePreview(tech.id);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.teal
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.teal
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.map,
                                                color: Colors.teal, size: 24),
                                            SizedBox(height: 4),
                                            Text('Giro',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

// Helper for creating dropdowns
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

// Specific filter dropdown builders
  Widget _buildDateFilterDropdown() {
    return _buildFilterDropdown(
      label: 'Data',
      value: _dateFilter,
      items: [
        'Tutte',
        'Oggi',
        'Ultimi 7 giorni',
        'Questa settimana',
        'Questo mese'
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _showOnlyAssigned = false;
          _dateFilter = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildStatusFilterDropdown() {
    return _buildFilterDropdown(
      label: 'Stato',
      value: _statusFilter,
      items: ['Tutti', 'Aperto', 'In corso', 'Sospeso'],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _showOnlyAssigned = false;
          _statusFilter = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildTypeFilterDropdown() {
    return _buildFilterDropdown(
      label: 'Tipo',
      value: _typeFilter,
      items: [
        'Tutti',
        'Climatizzazione',
        'Aspirazione',
        'Caldo',
        'Freddo',
        'Altro'
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _showOnlyAssigned = false;
          _typeFilter = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildSortDropdown() {
    return _buildFilterDropdown(
      label: 'Ordina per',
      value: _sortOption,
      items: [
        'Predefinito',
        'Data (Crescente)',
        'Data (Decrescente)',
        'Cliente (A-Z)',
        'Cliente (Z-A)'
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _sortOption = value;
          _applyFilters();
        });
      },
    );
  }

// Other control widgets
  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      cursorColor: kPrimaryColor,
      decoration: InputDecoration(
        hintText: 'Cerca ticket...',
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.search_rounded),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _showOnlyAssigned = false;
          _searchQuery = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildSmartFilterChip() {
    return FilterChip(
      label: Text('Solo Scaduti'),
      selected: _showOnlyExpired,
      onSelected: (bool selected) {
        setState(() {
          _showOnlyExpired = selected;
          _applyFilters();
        });
      },
      selectedColor: Colors.red[100],
      checkmarkColor: Colors.red[800],
      labelStyle: TextStyle(
        color: _showOnlyExpired ? Colors.red[800] : Colors.black,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _isKanbanView = !_isKanbanView;
            });
          },
          icon: Icon(_isKanbanView ? Icons.view_list : Icons.view_kanban),
          tooltip: _isKanbanView ? 'Vista Lista' : 'Vista Kanban',
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
          onPressed: _initializeData,
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
      ],
    );
  }

// 6. CONTROLS ROW RESPONSIVE
  Widget _buildControlsRow() {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              SizedBox(width: 12),
              _buildMobileFilters(),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildSmartFilterChip(),
              Spacer(),
              _buildActionButtons(),
            ],
          ),
        ],
      );
    }

    // Desktop layout
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchField()),
        SizedBox(width: 16),
        Expanded(child: _buildTechnicianFilterChip()),
        SizedBox(width: 12),
        Expanded(child: _buildDateFilterDropdown()),
        SizedBox(width: 12),
        Expanded(child: _buildStatusFilterDropdown()),
        SizedBox(width: 12),
        Expanded(child: _buildTypeFilterDropdown()),
        SizedBox(width: 12),
        Expanded(child: _buildSortDropdown()),
        SizedBox(width: 16),
        _buildSmartFilterChip(),
        SizedBox(width: 16),
        _buildActionButtons(),
      ],
    );
  }

// 9. STATS ROW RESPONSIVE
  Widget _buildStatsRow() {
    final stats = [
      _StatCardData(
        label: 'Non Assegnati',
        value: _tickets
            .where((t) => t['stato'] != 'Chiuso' && t['id_tecnico'] == null)
            .length
            .toString(),
        icon: Icons.person_off_outlined,
        color: Color(0xFFF44336),
        filter: 'Non Assegnati',
      ),
      _StatCardData(
        label: 'Assegnati',
        value: _tickets
            .where((t) => t['stato'] != 'Chiuso' && t['id_tecnico'] != null)
            .length
            .toString(),
        icon: Icons.person_outlined,
        color: Color(0xFF2196F3),
        filter: 'Assegnati',
      ),
      _StatCardData(
        label: 'In Corso',
        value:
            _tickets.where((t) => t['stato'] == 'In corso').length.toString(),
        icon: Icons.settings_outlined,
        color: Color(0xFFFF9800),
        filter: 'In corso',
      ),
      _StatCardData(
        label: 'Totale Attivi',
        value: _tickets.where((t) => t['stato'] != 'Chiuso').length.toString(),
        icon: Icons.assignment_outlined,
        color: secondaryColor,
        filter: 'Totale Attivi',
      ),
    ];

    if (Responsive.isMobile(context)) {
      // Layout mobile: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTechStatCard(stats[0])),
              SizedBox(width: 12),
              Expanded(child: _buildTechStatCard(stats[1])),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTechStatCard(stats[2])),
              SizedBox(width: 12),
              Expanded(child: _buildTechStatCard(stats[3])),
            ],
          ),
          SizedBox(height: 12),
          // Pulsante salva preset su mobile
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _showSavePresetDialog,
              icon: Icon(Icons.save_alt),
              tooltip: 'Salva Filtri Correnti',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // Layout desktop originale
    return Row(
      children: [
        ...stats.map((stat) => Expanded(child: _buildTechStatCard(stat))),
        SizedBox(width: 8),
        IconButton(
          onPressed: _showSavePresetDialog,
          icon: Icon(Icons.save_alt),
          tooltip: 'Salva Filtri Correnti',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[700],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]
          .expand((widget) => [widget, SizedBox(width: 16)])
          .take(stats.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildTechStatCard(_StatCardData stat) {
    return InkWell(
      onTap: () => _filterByStat(stat.filter),
      child: Container(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 16),
        decoration: BoxDecoration(
          color: stat.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stat.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(stat.icon,
                    color: stat.color,
                    size: Responsive.isMobile(context) ? 20 : 24),
                Spacer(),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: Responsive.isMobile(context) ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: stat.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: Responsive.isMobile(context) ? 10 : 12,
                color: stat.color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 10. RESULTS INFO RESPONSIVE
  Widget _buildResultsInfo(
      List<Map<String, dynamic>> paginatedTickets, int totalPages) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          Text(
            'Mostrando ${paginatedTickets.length} di ${_filteredTickets.length} ticket',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (totalPages > 1) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: Icon(Icons.chevron_left),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Pagina $_currentPage di $totalPages',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                IconButton(
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: Icon(Icons.chevron_right),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    // Layout desktop originale
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mostrando ${paginatedTickets.length} di ${_filteredTickets.length} ticket',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (totalPages > 1)
          Row(
            children: [
              Text(
                'Pagina $_currentPage di $totalPages',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: Icon(Icons.chevron_left),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(width: 4),
                  IconButton(
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: Icon(Icons.chevron_right),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // NUOVI METODI PER LAYOUT RIORGANIZZATO

  Widget _buildCompactStatsRow() {
    final stats = [
      _StatCardData(
        label: 'Aperti',
        value: _tickets.where((t) => t['stato'] == 'Aperto').length.toString(),
        icon: Icons.inbox_outlined,
        color: Colors.orange,
        filter: 'Aperto',
      ),
      _StatCardData(
        label: 'In Corso',
        value:
            _tickets.where((t) => t['stato'] == 'In corso').length.toString(),
        icon: Icons.settings_outlined,
        color: Colors.blue,
        filter: 'In corso',
      ),
      _StatCardData(
        label: 'Sospesi',
        value: _tickets.where((t) => t['stato'] == 'Sospeso').length.toString(),
        icon: Icons.pause_circle_outlined,
        color: Colors.red,
        filter: 'Sospeso',
      ),
      _StatCardData(
        label: 'Totale',
        value: _tickets.where((t) => t['stato'] != 'Chiuso').length.toString(),
        icon: Icons.assignment_outlined,
        color: secondaryColor,
        filter: 'Tutti',
      ),
    ];

    return Column(
      children: [
        Row(
          children: stats
              .map((stat) => Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _statusFilter = stat.filter;
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.isMobile(context) ? 6 : 12,
                          vertical: Responsive.isMobile(context) ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              stat.color.withValues(alpha: 0.1),
                              stat.color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stat.color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              stat.value,
                              style: TextStyle(
                                fontSize:
                                    Responsive.isMobile(context) ? 18 : 24,
                                fontWeight: FontWeight.bold,
                                color: stat.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              stat.label,
                              style: TextStyle(
                                fontSize: Responsive.isMobile(context) ? 9 : 11,
                                color: stat.color.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList()
              .expand((widget) => [
                    widget,
                    SizedBox(width: Responsive.isMobile(context) ? 6 : 12)
                  ])
              .take(stats.length * 2 - 1)
              .toList(),
        ),
        if (Responsive.isMobile(context)) ...[
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMobileFilterChip(
                  label: 'Tecnico',
                  value: _technicianFilter.isEmpty
                      ? 'Tutti'
                      : '${_technicianFilter.length}',
                  onTap: () =>
                      _showMobileTechnicianSelector(_technicianFilter, (fn) {
                    setState(fn);
                    _applyFilters();
                  }),
                ),
                SizedBox(width: 8),
                _buildMobileFilterChip(
                  label: 'Data',
                  value: _dateFilter,
                  onTap: () => _showMobileDateFilterDialog(),
                ),
                SizedBox(width: 8),
                _buildMobileFilterChip(
                  label: 'Ordina',
                  value: _sortOption == 'Predefinito'
                      ? 'Def.'
                      : _sortOption.substring(0, 3),
                  onTap: () => _showMobileSortDialog(),
                ),
                SizedBox(width: 8),
                // Chip per mostrare se il filtro scaduti è attivo
                InkWell(
                  onTap: () {
                    setState(() {
                      _showOnlyExpired = !_showOnlyExpired;
                      _applyFilters();
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showOnlyExpired ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showOnlyExpired
                            ? Colors.red
                            : secondaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: _showOnlyExpired ? Colors.white : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Scaduti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showOnlyExpired
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilterChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
            Text(
              ': ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtra per Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Tutte', 'Oggi', 'Questa settimana', 'Questo mese']
              .map((date) => RadioListTile<String>(
                    title: Text(date),
                    value: date,
                    groupValue: _dateFilter,
                    onChanged: (value) {
                      setState(() {
                        _dateFilter = value!;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showMobileSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ordina per'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Predefinito',
            'Data (Crescente)',
            'Data (Decrescente)',
            'Cliente (A-Z)',
            'Cliente (Z-A)'
          ]
              .map((sort) => RadioListTile<String>(
                    title: Text(sort),
                    value: sort,
                    groupValue: _sortOption,
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value!;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

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
                  'Filtri Avanzati',
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
              SizedBox(
                width: 200,
                child: _buildStatusFilterDropdown(),
              ),
              SizedBox(
                width: 200,
                child: _buildTypeFilterDropdown(),
              ),
              SizedBox(
                width: 200,
                child: _buildDateFilterDropdown(),
              ),
              SizedBox(
                width: 200,
                child: _buildSortDropdown(),
              ),
              SizedBox(
                width: 250,
                child: _buildTechnicianFilterChip(),
              ),
              _buildSmartFilterChip(),
              if (_savedPresets.isNotEmpty)
                SizedBox(
                  width: 250,
                  child: _buildPresetSelector(),
                ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _statusFilter = 'Tutti';
                    _typeFilter = 'Tutti';
                    _dateFilter = 'Tutte';
                    _sortOption = 'Predefinito';
                    _technicianFilter = [];
                    _showOnlyExpired = false;
                    _showOnlyAssigned = false;
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedPreset = null;
                    _applyFilters();
                  });
                },
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

  Widget _buildSeparateCardsList() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredTickets.length);
    final paginatedTickets = _filteredTickets.sublist(startIndex, endIndex);

    if (paginatedTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Nessun ticket trovato',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: paginatedTickets.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ticket = paginatedTickets[index];
        final canModify = ticket['stato'] != 'In corso';

        Widget card = _buildSeparateTicketCard(ticket, canModify);

        // Gestione mobile con swipe
        if (Responsive.isMobile(context)) {
          return Dismissible(
            key: ValueKey(ticket['id']),
            confirmDismiss: (direction) async {
              if (!canModify) {
                _showErrorAlert(
                    'I ticket in corso non possono essere modificati');
                return false;
              }
              if (direction == DismissDirection.startToEnd) {
                _showImprovedAssignmentDialog(ticket);
              } else if (direction == DismissDirection.endToStart) {
                _showQuickScheduleDialog(ticket);
              }
              return false;
            },
            background: Container(
              color: secondaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Icon(Icons.person_add, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              child: Icon(Icons.schedule, color: Colors.white),
            ),
            child: card,
          );
        }

        return card;
      },
    );
  }

  Widget _buildSeparateTicketCard(Map<String, dynamic> ticket, bool canModify) {
    final status = ticket['stato'] ?? '';
    final isOverdue = _isOverdue(ticket['oraPrevista']);
    final isDesktop = !Responsive.isMobile(context);

    return InkWell(
      onTap: () => _showTicketDetails(ticket),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getOriginalStatusColor(status).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header con status - più compatto su desktop
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getOriginalStatusColor(status).withValues(alpha: 0.15),
                    _getOriginalStatusColor(status).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 8 : 10),
                    decoration: BoxDecoration(
                      color: _getOriginalStatusColor(status)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getOriginalStatusColor(status),
                      size: isDesktop ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome cliente prominente
                        Text(
                          ticket['ragSoc'] ?? 'Cliente N/D',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isDesktop ? 2 : 4),
                        // Numero ticket e stato più piccoli
                        Row(
                          children: [
                            Text(
                              'Ticket #${ticket['id']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getOriginalStatusColor(status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'SCADUTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Contenuto
            Padding(
              padding: EdgeInsets.all(isDesktop ? 12 : 16),
              child: Responsive.isMobile(context)
                  ? _buildMobileCardContent(ticket)
                  : _buildDesktopCardContent(ticket),
            ),

            // Footer con azioni
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 16,
                  vertical: isDesktop ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showTicketDetails(ticket),
                    icon: Icon(Icons.info_outline, size: 16),
                    label: Text('Dettagli'),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (canModify) ...[
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showImprovedAssignmentDialog(ticket),
                      icon: Icon(Icons.person_add, size: 16),
                      label: Text('Assegna'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: secondaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for improved ticket details dialog

  Color _getHeaderColorByStatus(String? status) {
    switch (status) {
      case 'Aperto':
        return Colors.orange[700]!;
      case 'In corso':
        return Colors.blue[700]!;
      case 'Sospeso':
        return Colors.red[700]!;
      case 'Chiuso':
        return Colors.green[700]!;
      default:
        return secondaryColor;
    }
  }

  Widget _buildHeaderBadge(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case 'Aperto':
        return Icons.inbox;
      case 'In corso':
        return Icons.build;
      case 'Sospeso':
        return Icons.pause_circle;
      case 'Chiuso':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Widget _buildDetailSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> ticket) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            secondaryColor.withValues(alpha: 0.1),
            secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: secondaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tecnico Assegnato',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _getTechnicianName(ticket['id_tecnico']),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ticket['oraPrevista'] != null) ...[
            SizedBox(height: 12),
            Divider(color: secondaryColor.withValues(alpha: 0.2)),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.schedule, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intervento Programmato',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.parse(ticket['oraPrevista'])),
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
          ],
        ],
      ),
    );
  }

  Widget _buildNotAssignedCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off, size: 32, color: Colors.orange[700]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket Non Assegnato',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                Text(
                  'Assegna un tecnico per procedere',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layout Mobile (singola colonna)
  Widget _buildMobileLayout(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descrizione per prima (priorità)
        if (ticket['descrizione'] != null &&
            ticket['descrizione'].toString().trim().isNotEmpty) ...[
          _buildDetailSection(
            'Descrizione',
            Icons.description,
            secondaryColor,
            [
              SelectableText(
                ticket['descrizione'].toString(),
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],

        // Info Cliente
        _buildDetailSection(
          'Informazioni Cliente',
          Icons.person,
          Colors.blue,
          _buildClienteInfo(ticket),
        ),
        SizedBox(height: 20),

        // Info Tecnica
        _buildDetailSection(
          'Informazioni Tecniche',
          Icons.build,
          Colors.orange,
          _buildTecnicaInfo(ticket),
        ),
        SizedBox(height: 20),

        // Info Assegnazione
        if (ticket['id_tecnico'] != null) ...[
          _buildAssignmentCard(ticket),
          SizedBox(height: 20),
        ] else ...[
          _buildNotAssignedCard(),
          SizedBox(height: 20),
        ],

        // Cronologia eventi (Summary)
        if (ticket['summary'] != null &&
            ticket['summary'] is List &&
            (ticket['summary'] as List).isNotEmpty) ...[
          _buildDetailSection(
            'Cronologia Eventi',
            Icons.timeline,
            Colors.purple,
            _buildSummaryItems(ticket['summary']),
          ),
          SizedBox(height: 20),
        ],

        // Allegati PDF (Fogli)
        if (ticket['fogli'] != null &&
            ticket['fogli'] is List &&
            (ticket['fogli'] as List).isNotEmpty) ...[
          _buildDetailSection(
            'Allegati',
            Icons.attach_file,
            Colors.green,
            _buildAttachmentItems(ticket['fogli']),
          ),
          SizedBox(height: 20),
        ],

        // Azioni rapide
        _buildQuickActions(ticket),
      ],
    );
  }

  // Layout Desktop (due colonne)
  Widget _buildDesktopLayout(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descrizione per prima (priorità, larghezza piena)
        if (ticket['descrizione'] != null &&
            ticket['descrizione'].toString().trim().isNotEmpty) ...[
          _buildDetailSection(
            'Descrizione',
            Icons.description,
            secondaryColor,
            [
              SelectableText(
                ticket['descrizione'].toString(),
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],

        // Due colonne per info cliente e tecniche
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonna sinistra
            Expanded(
              child: Column(
                children: [
                  // Info Cliente
                  _buildDetailSection(
                    'Informazioni Cliente',
                    Icons.person,
                    Colors.blue,
                    _buildClienteInfo(ticket),
                  ),
                  SizedBox(height: 20),

                  // Cronologia eventi (Summary)
                  if (ticket['summary'] != null &&
                      ticket['summary'] is List &&
                      (ticket['summary'] as List).isNotEmpty) ...[
                    _buildDetailSection(
                      'Cronologia Eventi',
                      Icons.timeline,
                      Colors.purple,
                      _buildSummaryItems(ticket['summary']),
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            SizedBox(width: 20),

            // Colonna destra
            Expanded(
              child: Column(
                children: [
                  // Info Tecnica
                  _buildDetailSection(
                    'Informazioni Tecniche',
                    Icons.build,
                    Colors.orange,
                    _buildTecnicaInfo(ticket),
                  ),
                  SizedBox(height: 20),

                  // Info Assegnazione
                  if (ticket['id_tecnico'] != null) ...[
                    _buildAssignmentCard(ticket),
                    SizedBox(height: 20),
                  ] else ...[
                    _buildNotAssignedCard(),
                    SizedBox(height: 20),
                  ],

                  // Allegati PDF (Fogli)
                  if (ticket['fogli'] != null &&
                      ticket['fogli'] is List &&
                      (ticket['fogli'] as List).isNotEmpty) ...[
                    _buildDetailSection(
                      'Allegati',
                      Icons.attach_file,
                      Colors.green,
                      _buildAttachmentItems(ticket['fogli']),
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),

        // Azioni rapide (larghezza piena)
        _buildQuickActions(ticket),
      ],
    );
  }

  // Helper per costruire le info cliente
  List<Widget> _buildClienteInfo(Map<String, dynamic> ticket) {
    final partiva = ticket['partiva']?.toString() ?? '';
    final codFisc = ticket['codFisc']?.toString() ?? '';
    final hasPiva = partiva.isNotEmpty && partiva != 'null';
    final hasCodFisc = codFisc.isNotEmpty && codFisc != 'null';
    final areEqual = hasPiva && hasCodFisc && partiva == codFisc;

    return [
      if (ticket['ragSocAzienda'] != null &&
          ticket['ragSocAzienda'].toString().isNotEmpty)
        _buildDetailRow('Azienda', ticket['ragSocAzienda']),
      _buildDetailRow('Telefono', ticket['numTel'] ?? 'N/D'),
      _buildDetailRow('Email', ticket['email'] ?? 'N/D'),
      _buildDetailRow('Indirizzo', ticket['indirizzo']),
      if (ticket['citta'] != null && ticket['citta'].toString().isNotEmpty)
        _buildDetailRow('Città', ticket['citta']),
      if (ticket['indirizzoFatturazione'] != null &&
          ticket['indirizzoFatturazione'].toString().isNotEmpty)
        _buildDetailRow('Indirizzo Fatturazione', ticket['indirizzoFatturazione']),

      // Se P.IVA e CF sono uguali, mostra solo "P.IVA / CF"
      if (areEqual)
        _buildDetailRow('P.IVA / CF', partiva)
      else ...[
        // Altrimenti mostra separatamente
        if (hasPiva)
          _buildDetailRow('P.IVA', partiva),
        if (hasCodFisc)
          _buildDetailRow('Codice Fiscale', codFisc),
      ],

      if (ticket['codsdi'] != null &&
          ticket['codsdi'].toString().isNotEmpty &&
          ticket['codsdi'].toString() != 'null')
        _buildDetailRow('Codice SDI', ticket['codsdi']),
    ];
  }

  // Helper per costruire le info tecniche
  List<Widget> _buildTecnicaInfo(Map<String, dynamic> ticket) {
    return [
      _buildDetailRow('Stato Macchina', ticket['stato_macchina'] ?? 'N/D'),
      if (ticket['rifEsterno'] != null &&
          ticket['rifEsterno'].toString().isNotEmpty)
        _buildDetailRow('Rif. Esterno', ticket['rifEsterno']),
      if (ticket['rifFurgone'] != null &&
          ticket['rifFurgone'].toString().isNotEmpty)
        _buildDetailRow('Rif. Furgone', ticket['rifFurgone']),
    ];
  }

  List<Widget> _buildSummaryItems(List<dynamic> summary) {
    return summary.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      final isLast = index == summary.length - 1;
      final eventColor = _getEventColor(event['evento']);
      final shouldShowCurrentState = isLast &&
          summary.length > 1 &&
          event['evento']?.toLowerCase() != 'chiuso' &&
          (event['dataFine'] == null || event['dataFine'].toString().isEmpty);

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEventIcon(event['evento']),
                  size: 18,
                  color: eventColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['evento'] ?? 'N/D',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    if (event['dataInizio'] != null)
                      Text(
                        'Inizio: ${_formatDateTime(event['dataInizio'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (event['dataFine'] != null && event['dataFine'].toString().isNotEmpty)
                      Text(
                        'Fine: ${_formatDateTime(event['dataFine'])}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (shouldShowCurrentState)
                      Text(
                        'Stato attuale',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
          ],
        ],
      );
    }).toList();
  }

  List<Widget> _buildAttachmentItems(List<dynamic> fogli) {
    return fogli.asMap().entries.map((entry) {
      final index = entry.key;
      final foglio = entry.value;
      final isLast = index == fogli.length - 1;

      return Column(
        children: [
          InkWell(
            onTap: () {
              if (foglio['location'] != null) {
                _openUrl(foglio['location']);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foglio['fileKey'] ?? 'Documento.pdf',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Clicca per aprire',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (!isLast) ...[
            SizedBox(height: 4),
            Divider(height: 1),
            SizedBox(height: 4),
          ],
        ],
      );
    }).toList();
  }

  IconData _getEventIcon(String? evento) {
    switch (evento?.toLowerCase()) {
      case 'aperto':
        return Icons.new_releases;
      case 'in corso':
        return Icons.play_arrow;
      case 'sospeso':
        return Icons.pause;
      case 'chiuso':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String? evento) {
    switch (evento?.toLowerCase()) {
      case 'aperto':
        return Colors.blue;
      case 'in corso':
        return Colors.green;
      case 'sospeso':
        return Colors.orange;
      case 'chiuso':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/D';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatTicketDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/D';
    try {
      final dt = DateTime.parse(dateTime);
      // Se l'ora è 00:00, mostra solo la data
      if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
        return DateFormat('dd/MM/yyyy').format(dt);
      }
      // Altrimenti mostra data e ora
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  void _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Errore apertura URL: $e');
    }
  }

  Widget _buildQuickActions(Map<String, dynamic> ticket) {
    final isMobile = Responsive.isMobile(context);
    final buttonPadding = isMobile
        ? EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final iconSize = isMobile ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, size: 20, color: secondaryColor),
            SizedBox(width: 8),
            Text(
              'Azioni Rapide',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: isMobile ? 8 : 10,
          runSpacing: isMobile ? 8 : 10,
          children: [
            // Bottone "Chiama" solo su mobile
            if (isMobile &&
                ticket['numTel'] != null &&
                ticket['numTel'].toString().isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri telUri = Uri(scheme: 'tel', path: ticket['numTel']);
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  }
                },
                icon: Icon(Icons.call, size: iconSize),
                label: Text('Chiama'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                ),
              ),
            // Bottone Email
            if (ticket['email'] != null &&
                ticket['email'].toString().isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri mailUri =
                      Uri(scheme: 'mailto', path: ticket['email']);
                  if (await canLaunchUrl(mailUri)) {
                    await launchUrl(mailUri);
                  }
                },
                icon: Icon(Icons.email, size: iconSize),
                label: Text('Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                ),
              ),
            // Bottone Mappa
            ElevatedButton.icon(
              onPressed: () async {
                final query = Uri.encodeComponent(ticket['indirizzo']);
                final Uri mapUri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$query');
                if (await canLaunchUrl(mapUri)) {
                  await launchUrl(mapUri);
                }
              },
              icon: Icon(Icons.map, size: iconSize),
              label: Text('Mappa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: buttonPadding,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Mobile card content - single column layout
  Widget _buildMobileCardContent(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indirizzo
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                ticket['indirizzo'] ?? 'N/D',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Tipo macchina
        Row(
          children: [
            Icon(_getMachineTypeIcon(ticket['tipo_macchina']),
                size: 16, color: _getMachineTypeColor(ticket['tipo_macchina'])),
            SizedBox(width: 8),
            Text(
              ticket['tipo_macchina']?.toUpperCase() ?? 'N/D',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _getMachineTypeColor(ticket['tipo_macchina']),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Descrizione
        if (ticket['descrizione'] != null &&
            ticket['descrizione'].toString().trim().isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket['descrizione'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],

        // Data apertura
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
            SizedBox(width: 8),
            Text(
              'Aperto: ${_formatTicketDate(ticket['data'])}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey[300]),
        SizedBox(height: 12),

        // Assignment info
        if (ticket['id_tecnico'] != null) ...[
          Row(
            children: [
              Icon(Icons.person_pin, size: 18, color: secondaryColor),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    children: [
                      TextSpan(text: 'Tecnico: '),
                      TextSpan(
                        text: _getTechnicianName(ticket['id_tecnico']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Data e ora programmata
          if (ticket['oraPrevista'] != null &&
              ticket['oraPrevista'].toString().isNotEmpty &&
              ticket['oraPrevista'].toString() != 'null') ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.blue[700]),
                SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      children: [
                        TextSpan(text: 'Programmato: '),
                        TextSpan(
                          text: DateFormat('dd/MM/yyyy HH:mm')
                              .format(DateTime.parse(ticket['oraPrevista'])),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          // Non assegnato
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[500]),
              SizedBox(width: 8),
              Text(
                'Non assegnato',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Desktop card content - two column layout
  Widget _buildDesktopCardContent(Map<String, dynamic> ticket) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonna sinistra - Info principali
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indirizzo
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket['indirizzo'] ?? 'N/D',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Descrizione
              if (ticket['descrizione'] != null &&
                  ticket['descrizione'].toString().trim().isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description,
                          size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket['descrizione'],
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Data apertura
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Text(
                    'Aperto: ${_formatTicketDate(ticket['data'])}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Divider verticale
        Container(
          width: 1,
          height: 80,
          margin: EdgeInsets.symmetric(horizontal: 12),
          color: Colors.grey[300],
        ),

        // Colonna destra - Tipo macchina e assegnazione
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo macchina
              Row(
                children: [
                  Icon(_getMachineTypeIcon(ticket['tipo_macchina']),
                      size: 16,
                      color: _getMachineTypeColor(ticket['tipo_macchina'])),
                  SizedBox(width: 8),
                  Text(
                    ticket['tipo_macchina']?.toUpperCase() ?? 'N/D',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getMachineTypeColor(ticket['tipo_macchina']),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Assignment info
              if (ticket['id_tecnico'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.person_pin, size: 18, color: secondaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                          children: [
                            TextSpan(text: 'Tecnico: '),
                            TextSpan(
                              text: _getTechnicianName(ticket['id_tecnico']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Data e ora programmata
                if (ticket['oraPrevista'] != null &&
                    ticket['oraPrevista'].toString().isNotEmpty &&
                    ticket['oraPrevista'].toString() != 'null') ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                            children: [
                              TextSpan(text: 'Programmato: '),
                              TextSpan(
                                text: DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(ticket['oraPrevista'])),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Non assegnato
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 18, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Non assegnato',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
