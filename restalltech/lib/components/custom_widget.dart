// custom_widgets.dart - Componenti UI riusabili per home_admin

import 'package:flutter/material.dart';
import 'package:restalltech/constants.dart';
import 'package:intl/intl.dart';

// MIGLIORAMENTO 16: Widget per filtri avanzati
class AdvancedFiltersPanel extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final List<String> availableStatuses;
  final List<String> availableTechnicians;

  const AdvancedFiltersPanel({
    Key? key,
    required this.onFiltersChanged,
    required this.availableStatuses,
    required this.availableTechnicians,
  }) : super(key: key);

  @override
  _AdvancedFiltersPanelState createState() => _AdvancedFiltersPanelState();
}

class _AdvancedFiltersPanelState extends State<AdvancedFiltersPanel> {
  String? selectedStatus;
  String? selectedTechnician;
  DateTimeRange? selectedDateRange;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(16),
      child: ExpansionTile(
        leading: Icon(Icons.filter_list, color: secondaryColor),
        title: Text(
          'Filtri Avanzati',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildActiveFiltersIndicator(),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtro per stato
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Stato Ticket',
                          prefixIcon: Icon(Icons.flag, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        value: selectedStatus,
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text('Tutti gli stati')),
                          ...widget.availableStatuses.map((status) =>
                              DropdownMenuItem(
                                  value: status, child: Text(status))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                          _updateFilters();
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tecnico Assegnato',
                          prefixIcon: Icon(Icons.person, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        value: selectedTechnician,
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text('Tutti i tecnici')),
                          DropdownMenuItem(
                              value: 'unassigned',
                              child: Text('Non assegnati')),
                          ...widget.availableTechnicians.map((tech) =>
                              DropdownMenuItem(value: tech, child: Text(tech))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedTechnician = value;
                          });
                          _updateFilters();
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Filtro per data
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.date_range),
                        label: Text(selectedDateRange != null
                            ? '${DateFormat('dd/MM').format(selectedDateRange!.start)} - ${DateFormat('dd/MM').format(selectedDateRange!.end)}'
                            : 'Seleziona periodo'),
                        onPressed: _selectDateRange,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.clear),
                      label: Text('Reset'),
                      onPressed: _clearFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    List<String> activeFilters = [];
    if (selectedStatus != null) activeFilters.add('Stato');
    if (selectedTechnician != null) activeFilters.add('Tecnico');
    if (selectedDateRange != null) activeFilters.add('Data');

    if (activeFilters.isEmpty) {
      return Text('Nessun filtro attivo',
          style: TextStyle(color: Colors.grey[600]));
    }

    return Text(
      '${activeFilters.length} filtri attivi: ${activeFilters.join(', ')}',
      style: TextStyle(color: secondaryColor, fontSize: 12),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: selectedDateRange,
      locale: Locale('it'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: secondaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      _updateFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedStatus = null;
      selectedTechnician = null;
      selectedDateRange = null;
    });
    _updateFilters();
  }

  void _updateFilters() {
    widget.onFiltersChanged({
      'status': selectedStatus,
      'technician': selectedTechnician,
      'dateRange': selectedDateRange,
    });
  }
}

// MIGLIORAMENTO 17: Widget per statistiche in tempo reale
class RealTimeStatsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tickets;

  const RealTimeStatsWidget({
    Key? key,
    required this.tickets,
  }) : super(key: key);

  @override
  _RealTimeStatsWidgetState createState() => _RealTimeStatsWidgetState();
}

class _RealTimeStatsWidgetState extends State<RealTimeStatsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryLightColor, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: secondaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Panoramica Ticket',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  Spacer(),
                  _buildLastUpdateIndicator(),
                ],
              ),
              SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard(
                    'Totali',
                    stats['total']!,
                    Icons.assignment,
                    Colors.blue,
                    _animation.value,
                  ),
                  _buildStatCard(
                    'Aperti',
                    stats['open']!,
                    Icons.schedule,
                    Colors.orange,
                    _animation.value,
                  ),
                  _buildStatCard(
                    'In Corso',
                    stats['inProgress']!,
                    Icons.engineering,
                    Colors.green,
                    _animation.value,
                  ),
                  _buildStatCard(
                    'Urgenti',
                    stats['urgent']!,
                    Icons.priority_high,
                    Colors.red,
                    _animation.value,
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildProgressIndicator(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color,
      double animationValue) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                child: Text((count * animationValue).round().toString()),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Map<String, int> stats) {
    final total = stats['total']!;
    final completed = total - stats['open']! - stats['inProgress']!;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completamento',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          child: LinearProgressIndicator(
            value: progress * _animation.value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.7
                  ? Colors.green
                  : progress > 0.4
                      ? Colors.orange
                      : Colors.red,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdateIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 4),
          Text(
            'Aggiornato ora',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    final total = widget.tickets.length;
    final open = widget.tickets.where((t) => t['stato'] == 'Aperto').length;
    final inProgress =
        widget.tickets.where((t) => t['stato'] == 'In corso').length;

    // Calcola urgenti (ticket aperti da più di 7 giorni)
    final urgent = widget.tickets.where((t) {
      if (t['stato'] == 'Completato') return false;
      try {
        final ticketDate = DateTime.parse(t['data']);
        return DateTime.now().difference(ticketDate).inDays > 7;
      } catch (e) {
        return false;
      }
    }).length;

    return {
      'total': total,
      'open': open,
      'inProgress': inProgress,
      'urgent': urgent,
    };
  }
}

// MIGLIORAMENTO 18: Widget per azioni rapide
class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onExportData;
  final VoidCallback? onAddTicket;
  final VoidCallback? onBulkAssign;
  final bool hasSelection;

  const QuickActionsBar({
    Key? key,
    this.onRefresh,
    this.onExportData,
    this.onAddTicket,
    this.onBulkAssign,
    this.hasSelection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Aggiorna',
            onPressed: onRefresh,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.file_download,
            label: 'Esporta',
            onPressed: onExportData,
            color: Colors.green,
          ),
          SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.add_circle,
            label: 'Nuovo',
            onPressed: onAddTicket,
            color: secondaryColor,
          ),
          if (hasSelection) ...[
            SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.assignment_ind,
              label: 'Assegna',
              onPressed: onBulkAssign,
              color: Colors.orange,
            ),
          ],
          Spacer(),
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notification_important, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            '3 urgenti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// MIGLIORAMENTO 19: Modal per dettagli ticket avanzato
class TicketDetailsModal extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final Function(Map<String, dynamic>)? onUpdate;

  const TicketDetailsModal({
    Key? key,
    required this.ticket,
    this.onUpdate,
  }) : super(key: key);

  @override
  _TicketDetailsModalState createState() => _TicketDetailsModalState();
}

class _TicketDetailsModalState extends State<TicketDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ticket #${widget.ticket['id']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: secondaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: secondaryColor,
              tabs: [
                Tab(text: 'Dettagli', icon: Icon(Icons.info)),
                Tab(text: 'Timeline', icon: Icon(Icons.timeline)),
                Tab(text: 'Azioni', icon: Icon(Icons.settings)),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildTimelineTab(),
                  _buildActionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          SizedBox(height: 16),
          _buildInfoSection('Informazioni Cliente', [
            _buildInfoRow('Ragione Sociale', widget.ticket['ragSoc']),
            _buildInfoRow('Email', widget.ticket['email']),
            _buildInfoRow('Telefono', widget.ticket['numTel']),
            _buildInfoRow('Indirizzo', widget.ticket['indirizzo']),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Informazioni Macchina', [
            _buildInfoRow('Tipo', widget.ticket['tipo_macchina']),
            _buildInfoRow('Stato', widget.ticket['stato_macchina']),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Gestione Ticket', [
            _buildInfoRow('Data Apertura', _formatDate(widget.ticket['data'])),
            _buildInfoRow(
                'Visita Programmata',
                widget.ticket['oraPrevista'] != null
                    ? _formatDate(widget.ticket['oraPrevista'])
                    : 'Non programmata'),
            _buildInfoRow(
                'Tecnico Assegnato',
                widget.ticket['id_tecnico'] != null
                    ? 'Tecnico ID: ${widget.ticket['id_tecnico']}'
                    : 'Non assegnato'),
          ]),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimelineItem(
            'Ticket Aperto',
            _formatDate(widget.ticket['data']),
            Icons.add_circle,
            Colors.blue,
            isFirst: true,
          ),
          if (widget.ticket['id_tecnico'] != null)
            _buildTimelineItem(
              'Tecnico Assegnato',
              'Oggi', // Placeholder
              Icons.person_add,
              Colors.green,
            ),
          if (widget.ticket['oraPrevista'] != null)
            _buildTimelineItem(
              'Visita Programmata',
              _formatDate(widget.ticket['oraPrevista']),
              Icons.schedule,
              Colors.orange,
            ),
          _buildTimelineItem(
            'In Attesa',
            'Stato corrente',
            Icons.schedule,
            Colors.grey,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azioni Rapide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          SizedBox(height: 16),

          // Azioni di comunicazione
          _buildActionSection('Comunicazione', [
            _buildActionTile(
              'Chiama Cliente',
              'Effettua una chiamata diretta',
              Icons.phone,
              Colors.green,
              () => _callCustomer(),
            ),
            _buildActionTile(
              'Invia Email',
              'Componi e invia email',
              Icons.email,
              Colors.blue,
              () => _sendEmail(),
            ),
            _buildActionTile(
              'Invia SMS',
              'Messaggio di testo rapido',
              Icons.sms,
              Colors.orange,
              () => _sendSMS(),
            ),
          ]),

          SizedBox(height: 16),

          // Azioni di gestione
          _buildActionSection('Gestione', [
            _buildActionTile(
              'Modifica Ticket',
              'Aggiorna informazioni',
              Icons.edit,
              secondaryColor,
              () => _editTicket(),
            ),
            _buildActionTile(
              'Cambia Stato',
              'Aggiorna stato ticket',
              Icons.flag,
              Colors.purple,
              () => _changeStatus(),
            ),
            _buildActionTile(
              'Genera Report',
              'Crea report PDF',
              Icons.picture_as_pdf,
              Colors.red,
              () => _generateReport(),
            ),
          ]),

          SizedBox(height: 16),

          // Azioni di navigazione
          _buildActionSection('Navigazione', [
            _buildActionTile(
              'Apri in Maps',
              'Visualizza indirizzo',
              Icons.map,
              Colors.teal,
              () => _openMaps(),
            ),
            _buildActionTile(
              'Storico Cliente',
              'Vedi altri ticket',
              Icons.history,
              Colors.indigo,
              () => _viewHistory(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color statusColor;
    IconData statusIcon;
    String statusText = widget.ticket['stato'];

    switch (statusText.toLowerCase()) {
      case 'aperto':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'in corso':
        statusColor = Colors.blue;
        statusIcon = Icons.engineering;
        break;
      case 'completato':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stato Attuale',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          if (widget.ticket['oraPrevista'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Visita Programmata',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd/MM - HH:mm')
                      .format(DateTime.parse(widget.ticket['oraPrevista'])),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Action methods
  void _callCustomer() {
    // Implementa chiamata
    Navigator.pop(context);
    // Esempio: launch("tel:${widget.ticket['numTel']}");
  }

  void _sendEmail() {
    // Implementa invio email
    Navigator.pop(context);
    // Esempio: launch("mailto:${widget.ticket['email']}");
  }

  void _sendSMS() {
    // Implementa invio SMS
    Navigator.pop(context);
    // Esempio: launch("sms:${widget.ticket['numTel']}");
  }

  void _editTicket() {
    Navigator.pop(context);
    // Naviga a schermata di modifica
  }

  void _changeStatus() {
    Navigator.pop(context);
    // Mostra dialog per cambio stato
  }

  void _generateReport() {
    Navigator.pop(context);
    // Genera PDF report
  }

  void _openMaps() {
    Navigator.pop(context);
    // Apri Google Maps
  }

  void _viewHistory() {
    Navigator.pop(context);
    // Mostra storico cliente
  }
}

// MIGLIORAMENTO 20: Loading states avanzati
class SmartLoadingIndicator extends StatefulWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const SmartLoadingIndicator({
    Key? key,
    required this.isLoading,
    this.message,
    required this.child,
  }) : super(key: key);

  @override
  _SmartLoadingIndicatorState createState() => _SmartLoadingIndicatorState();
}

class _SmartLoadingIndicatorState extends State<SmartLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SmartLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(secondaryColor),
                            ),
                            if (widget.message != null) ...[
                              SizedBox(height: 16),
                              Text(
                                widget.message!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
