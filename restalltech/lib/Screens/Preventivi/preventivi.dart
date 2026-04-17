import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/Preventivi/preventiviApi.dart';
import 'package:restalltech/Screens/OpenPreventive/preventive_screen.dart';
import 'package:restalltech/Screens/Preventivi/preventivoListTile.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';

class PreventiviManager extends StatefulWidget {
  const PreventiviManager({Key? key}) : super(key: key);

  @override
  State<PreventiviManager> createState() => _PreventiviManagerState();
}

class _PreventiviManagerState extends State<PreventiviManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> preventivi = [];
  bool isLoading = true;
  String? errorMessage;

  // Costanti per gli stati
  static const String statusAperto = "APERTO";
  static const String statusInLavorazione = "IN LAVORAZIONE";
  static const String statusConsegnato = "CONSEGNATO";
  static const String statusRifiutato = "RIFIUTATO";

  // GlobalKey per RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshKeyAperto =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshKeyLavorazione =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshKeyConsegnato =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshKeyRifiutato =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchPreventivi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchPreventivi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Carica tutti i preventivi con paginazione
      List<dynamic> allPreventivi = [];
      int currentOffset = 0;
      const int pageLimit = 50;
      bool hasMore = true;

      while (hasMore) {
        final Response response = await PreventiviApi().getAll(
          offset: currentOffset,
          limit: pageLimit,
        );

        if (response.statusCode == 200) {
          final body = json.decode(response.body);
          final List<dynamic> pagePreventivi = body['preventivi'] ?? [];
          allPreventivi.addAll(pagePreventivi);

          // Se riceviamo meno elementi del limite, abbiamo finito
          hasMore = pagePreventivi.length == pageLimit;
          currentOffset += pagePreventivi.length;
        } else {
          throw Exception('Errore nel caricamento: ${response.statusCode}');
        }
      }

      setState(() {
        preventivi = allPreventivi;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Errore durante il caricamento dei preventivi: $e';
      });
    }
  }

  Future<void> _refreshPreventivi() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 1));
    await fetchPreventivi();
  }

  Future<void> _navigateToNewPreventivo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreventiveScreen()),
    );

    // Ricarica i dati se è stato creato un nuovo preventivo
    if (result == true) {
      fetchPreventivi();
    }
  }

  List<dynamic> filterByStatus(String status) {
    return preventivi
        .where((p) => (p['stato'] ?? '').toString().toUpperCase() == status)
        .toList();
  }

  Widget buildList(List<dynamic> filteredPreventivi) {
    if (filteredPreventivi.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun preventivo trovato',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: filteredPreventivi.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PreventivoListTile(preventivo: filteredPreventivi[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TopRoundedContainer(
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      secondaryColor.withOpacity(0.95),
                      secondaryColor.withOpacity(0.85),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
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
                        fontSize: 10.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      tabs: const [
                        Tab(text: "APERTI"),
                        Tab(text: "LAVORAZIONE"),
                        Tab(text: "CONSEGNATI"),
                        Tab(text: "RESPINTI"),
                      ],
                    ),
                  ),
                ),
              ),
              toolbarHeight: 72,
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: _navigateToNewPreventivo,
                backgroundColor: primaryColor,
                elevation: 6,
                icon: const Icon(Icons.add_rounded,
                    color: secondaryColor, size: 22),
                foregroundColor: secondaryColor,
                label: const Text(
                  'Nuovo Preventivo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: _buildTabBarView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Caricamento Preventivi...',
              style: TextStyle(
                color: kTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRefreshableList(statusAperto, _refreshKeyAperto),
        _buildRefreshableList(statusInLavorazione, _refreshKeyLavorazione),
        _buildRefreshableList(statusConsegnato, _refreshKeyConsegnato),
        _buildRefreshableList(statusRifiutato, _refreshKeyRifiutato),
      ],
    );
  }

  Widget _buildRefreshableList(
      String status, GlobalKey<RefreshIndicatorState> key) {
    return RefreshIndicator(
      key: key,
      onRefresh: _refreshPreventivi,
      color: kPrimaryColor,
      child: buildList(filterByStatus(status)),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchPreventivi,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
            ),
            child: const Text('Riprova', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
