import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/constants.dart' hide kToolbarHeight;
import 'package:restall/helper/downloader.dart';
import 'package:restall/helper/dropdowncomntainer.dart';
import 'package:restall/models/TicketList.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? ticketDetails;
  bool _isLoading = true;

  late AnimationController _animationController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAppBarCollapsed = false;
  final double collapsedHeight = 70.0; // Define the collapsed height

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadTicketDetails();
  }

  Widget _buildExpandedHeader(String status) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona grande centrata
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _getStatusIcon(status),
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),

            // Label ticket centrata
            Text(
              "Ticket RestAll",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Numero ticket grande centrato
            Text(
              "#${ticketDetails?['id'] ?? widget.ticket.id}",
              style: const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),

            // Data di creazione centrata
            Text(
              _formatCreationDate(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Badge stato centrato
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(String status) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 70, top: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Ticket #${ticketDetails?['id'] ?? widget.ticket.id}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final Response response = await TicketApi().getDetails(widget.ticket.id);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          ticketDetails = body['ticket'];
          _isLoading = false;
        });

        _animationController.forward();
        _cardController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ticketDetails?['stato'] ?? widget.ticket.stateT;
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar completa con calcolo corretto
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            collapsedHeight: collapsedHeight,
            elevation: 0,

            // Leading con colore adattivo
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isAppBarCollapsed
                      ? Colors.white.withOpacity(0.2) // Chiaro quando collapsed
                      : Colors.black.withOpacity(0.3), // Scuro quando espanso
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calcolo corretto dell'altezza
                final double appBarHeight = constraints.biggest.height;
                final double statusBarHeight =
                    MediaQuery.of(context).padding.top;
                final bool isCollapsed = appBarHeight <= (70 + statusBarHeight);

                // Aggiorna lo stato solo se cambia
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isAppBarCollapsed != isCollapsed) {
                    setState(() {
                      _isAppBarCollapsed = isCollapsed;
                    });
                  }
                });

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isCollapsed ? statusColor : Colors.transparent,
                    boxShadow: isCollapsed
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    centerTitle: false,

                    // Titolo che appare quando collapsed
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isCollapsed ? 1.0 : 0.0,
                      child: SizedBox(
                        height: collapsedHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Ticket #${ticketDetails?['id'] ?? widget.ticket.id}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Background che scompare quando collapsed
                    background: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isCollapsed ? 0.0 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withOpacity(0.3), // Più visibile
                              statusColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icona circolare dello stato
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withOpacity(0.8)
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getStatusIcon(status),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Info ticket
                                  Text(
                                    "Ticket",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "#${ticketDetails?['id'] ?? widget.ticket.id}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),

                                  // Badge stato
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getStatusIcon(status),
                                          color: statusColor,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (ticketDetails == null)
            SliverFillRemaining(child: _buildErrorState())
          else
            SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          SizedBox(height: 16),
          Text(
            "Caricamento dettagli ticket...",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: errorColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Errore nel caricamento",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Riprova più tardi",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final status = ticketDetails!['stato'];
    final statusColor = _getStatusColor(status);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Card data creazione
              _buildDateCard(status),
              const SizedBox(height: 20),

              // Card dettagli tecnici
              _buildTechDetailsCard(),
              const SizedBox(height: 20),

              // Card info personali
              _buildPersonalInfoCard(),
              const SizedBox(height: 20),

              // Card info macchina
              _buildMachineInfoCard(),
              const SizedBox(height: 20),

              // Card descrizione
              _buildDescriptionCard(),
              const SizedBox(height: 20),

              // Card download
              _buildDownloadCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(String status) {
    return _buildCard(
      title: "Data Creazione",
      icon: Icons.calendar_today_rounded,
      iconColor: Colors.blue,
      children: [
        _buildInfoRow(
          icon: Icons.date_range_outlined,
          label: "Data",
          value: _formatCreationDate(),
        ),
      ],
    );
  }

  Widget _buildTechDetailsCard() {
    final tech = ticketDetails?['id_tecnico'] != null
        ? "Tecnico assegnato"
        : "Tecnico non assegnato";

    return _buildCard(
      title: "Dettagli Tecnici",
      icon: Icons.engineering_rounded,
      iconColor: infoColor,
      children: [
        _buildInfoRow(
          icon: Icons.person_outline,
          label: "Tecnico",
          value: tech,
        ),
        if (ticketDetails?['id_tecnico'] != null &&
            ticketDetails?['oraPrevista'] != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: "Data Prevista",
            value: DateFormat("dd/MM/yyyy", "it_IT")
                .format(DateTime.parse(ticketDetails!['oraPrevista'])),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: "Ora Prevista",
            value: DateFormat('HH:mm')
                .format(DateTime.parse(ticketDetails!['oraPrevista'])),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      title: "Info Personali",
      icon: Icons.person_rounded,
      iconColor: successColor,
      children: [
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: "Indirizzo",
          value: ticketDetails?['indirizzo'] ?? "N/D",
          isExpandable: true,
        ),
      ],
    );
  }

  Widget _buildMachineInfoCard() {
    return _buildCard(
      title: "Info Macchina",
      icon: Icons.precision_manufacturing_rounded,
      iconColor: warningColor,
      children: [
        _buildInfoRow(
          icon: Icons.build_outlined,
          label: "Tipo",
          value: ticketDetails?['tipo_macchina'] ?? "N/D",
          isExpandable: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.settings_outlined,
          label: "Stato",
          value: ticketDetails?['stato_macchina'] ?? "N/D",
          isExpandable: true,
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      title: "Descrizione",
      icon: Icons.description_rounded,
      iconColor: Colors.purple,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ReadMoreText(
            ticketDetails?['descrizione'] ?? "Nessuna descrizione disponibile",
            trimLines: 4,
            trimCollapsedText: "\nMostra altro",
            trimExpandedText: "\nMostra meno",
            colorClickableText: Colors.purple,
            trimMode: TrimMode.Line,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadCard() {
    return _buildCard(
      title: "Download",
      icon: Icons.download_rounded,
      iconColor: Colors.indigo,
      children: [
        DropDownContainer(data: ticketDetails ?? {}),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isExpandable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                isExpandable
                    ? ReadMoreText(
                        value,
                        trimLines: 2,
                        trimCollapsedText: " Mostra altro",
                        trimExpandedText: " Mostra meno",
                        colorClickableText: secondaryColor,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreationDate() {
    try {
      // Prova prima dai dettagli del ticket
      if (ticketDetails?['data'] != null &&
          ticketDetails!['data'].toString().isNotEmpty) {
        // Se è una data già formattata (dd/MM/yyyy), la usiamo così
        if (ticketDetails!['data'].toString().contains('/')) {
          return "Creato il ${ticketDetails!['data']}";
        } else {
          // Altrimenti proviamo a parsarla
          final DateTime date =
              DateTime.parse(ticketDetails!['data'].toString());
          return "Creato il ${DateFormat('dd/MM/yyyy').format(date)}";
        }
      }

      // Fallback al ticket widget che ha già la data formattata
      if (widget.ticket.data.isNotEmpty) {
        return "Creato il ${widget.ticket.data}";
      }
    } catch (e) {
      print('Errore nel parsing della data: $e');
    }
    return 'Data non disponibile';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Chiuso":
        return successColor;
      case "Annullato":
        return errorColor;
      case "In corso":
        return infoColor;
      case "Aperto":
        return warningColor;
      case "Sospeso":
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Chiuso":
        return Icons.check_circle_rounded;
      case "Annullato":
        return Icons.cancel_rounded;
      case "In corso":
        return Icons.build_circle_rounded;
      case "Aperto":
        return Icons.schedule_rounded;
      case "Sospeso":
        return Icons.pause_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
