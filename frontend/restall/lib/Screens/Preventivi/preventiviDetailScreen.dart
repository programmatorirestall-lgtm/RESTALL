import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:restall/API/Preventivi/preventiviApi.dart';
import 'package:restall/components/top_rounded_container.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/downloader.dart';
import 'package:url_launcher/url_launcher.dart';

class PreventivoDetailScreen extends StatefulWidget {
  final int idPreventivo;

  const PreventivoDetailScreen({Key? key, required this.idPreventivo})
      : super(key: key);

  @override
  State<PreventivoDetailScreen> createState() => _PreventivoDetailScreenState();
}

class _PreventivoDetailScreenState extends State<PreventivoDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? preventivo;
  bool _isLoading = true;

  late AnimationController _animationController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final double collapsedHeight = 70.0; // Altezza AppBar collassata
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchDettaglio();
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

  Future<void> fetchDettaglio() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final response = await PreventiviApi().getDetails(widget.idPreventivo);
      var body = jsonDecode(response.body);

      setState(() {
        preventivo = body;
        _isLoading = false;
      });

      _animationController.forward();
      _cardController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stato = (preventivo?['stato'] ?? '').toUpperCase();
    final statoColor = _getStatoColor(stato);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar che cambia dinamicamente
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            collapsedHeight: collapsedHeight,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isAppBarCollapsed
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.3),
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
                final double appBarHeight = constraints.biggest.height;
                final double statusBarHeight =
                    MediaQuery.of(context).padding.top;
                final bool isCollapsed =
                    appBarHeight <= (collapsedHeight + statusBarHeight);

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
                    color: isCollapsed ? statoColor : Colors.transparent,
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
                                  _getStatoIconData(stato),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Preventivo #${preventivo?['id'] ?? '---'}",
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
                      background: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 0.0 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statoColor.withOpacity(0.3), // più visibile
                                statoColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                                            statoColor,
                                            statoColor.withOpacity(0.8)
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: statoColor.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _getStatoIconData(stato),
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Info preventivo
                                    Text(
                                      "Preventivo",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "#${preventivo?['id'] ?? '---'}",
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
                                        color: statoColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: statoColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatoIconData(stato),
                                            color: statoColor,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            stato,
                                            style: TextStyle(
                                              color: statoColor,
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
                      )),
                );
              },
            ),
          ),

          // Content
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (preventivo == null)
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
            "Caricamento dettagli...",
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
    final stato = (preventivo?['stato'] ?? '').toUpperCase();
    final allegati =
        List<Map<String, dynamic>>.from(preventivo?['allegati'] ?? []);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Card data richiesta
              _buildDateCard(stato),
              const SizedBox(height: 20),

              // Card informazioni dettagliate
              _buildInfoCard(),
              const SizedBox(height: 20),

              // Card dati cliente
              _buildClientCard(),

              // Card allegati (solo se consegnato)
              if (stato == "CONSEGNATO") ...[
                const SizedBox(height: 20),
                _buildAllegatiCard(allegati),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(String stato) {
    final statoColor = _getStatoColor(stato);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [statoColor, statoColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: statoColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              _formatDataString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCard(
      title: "Informazioni Dettagliate",
      icon: Icons.info_outline_rounded,
      iconColor: infoColor,
      children: [
        if (preventivo?['descrizione'] != null)
          _buildInfoRow(
            icon: Icons.description_outlined,
            label: "Descrizione",
            value: preventivo?['descrizione'] ?? "N/D",
          ),
        if (preventivo?['urlDoc'] != null &&
            preventivo!['urlDoc'].toString().isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildDownloadButton(),
        ],
      ],
    );
  }

  Widget _buildClientCard() {
    return _buildCard(
      title: "Dati Cliente",
      icon: Icons.person_outline_rounded,
      iconColor: successColor,
      children: [
        _buildInfoRow(
          icon: Icons.business_outlined,
          label: "Ragione Sociale",
          value: preventivo?['ragSocialeAzienda'] ?? "N/D",
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: "Numero Cellulare",
          value: preventivo?['numCellulare'] ?? "N/D",
        ),
      ],
    );
  }

  Widget _buildAllegatiCard(List<Map<String, dynamic>> allegati) {
    return _buildCard(
      title: "Allegati Disponibili",
      icon: Icons.attach_file_rounded,
      iconColor: warningColor,
      children: [
        if (allegati.isEmpty)
          _buildEmptyAllegati()
        else
          ...allegati.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key < allegati.length - 1 ? 12 : 0),
                  child: _buildAllegatoTile(entry.value, entry.key),
                ),
              ),
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
                Text(
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

  Widget _buildDownloadButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [infoColor, Color.fromARGB(255, 21, 101, 192)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: infoColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _downloadFile(preventivo?['urlDoc']),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  "Scarica Documento",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllegatoTile(Map<String, dynamic> allegato, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrl(Uri.parse(allegato['url'])),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Allegato #${index + 1}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ID: ${allegato['id']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: warningColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAllegati() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Nessun allegato disponibile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDataString() {
    try {
      if (preventivo?['data'] != null && preventivo?['data'].isNotEmpty) {
        final DateTime date = DateTime.parse(preventivo?['data']);
        return "Richiesto il ${DateFormat('dd/MM/yyyy').format(date)}";
      }
    } catch (e) {
      print('Errore nel parsing della data: $e');
    }

    if (preventivo?['data_creazione'] != null &&
        preventivo?['data_creazione'].isNotEmpty) {
      try {
        final DateTime date = DateTime.parse(preventivo?['data_creazione']);
        return "Richiesto il ${DateFormat('dd/MM/yyyy').format(date)}";
      } catch (e) {
        print('Errore nel parsing data_creazione: $e');
      }
    }

    return 'Data non disponibile';
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

  IconData _getStatoIconData(String? stato) {
    switch (stato?.toUpperCase()) {
      case "APERTO":
        return Icons.schedule_rounded;
      case "IN LAVORAZIONE":
        return Icons.build_circle_rounded;
      case "CONSEGNATO":
        return Icons.check_circle_rounded;
      case "RIFIUTATO":
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatoColor(String stato) {
    switch (stato.toUpperCase()) {
      case "APERTO":
        return warningColor;
      case "IN LAVORAZIONE":
        return infoColor;
      case "CONSEGNATO":
        return successColor;
      case "RIFIUTATO":
        return errorColor;
      default:
        return Colors.grey[600]!;
    }
  }
}
