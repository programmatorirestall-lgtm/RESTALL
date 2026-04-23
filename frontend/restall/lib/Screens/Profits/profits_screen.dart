import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/API/api_exceptions.dart';
import 'package:restall/constants.dart';
import 'package:restall/core/performance/connection_manager.dart';
import 'package:restall/models/UserProfile.dart';

class ProfitsScreen extends StatefulWidget {
  static String routeName = "/profits";

  @override
  _ProfitsScreenState createState() => _ProfitsScreenState();
}

class _ProfitsScreenState extends State<ProfitsScreen>
    with TickerProviderStateMixin {
  // Dati profitti dall'utente
  Map<String, dynamic>? userData;
  bool isLoadingUserData = false;
  String? errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void fetchUserData() async {
    setState(() {
      isLoadingUserData = true;
      errorMessage = null;
    });

    try {
      // Usa il nuovo metodo che restituisce i dati grezzi con profitti
      Map<String, dynamic> userDataResponse =
          await UserApi().getUserDataWithProfits();

      setState(() {
        userData = userDataResponse;
        isLoadingUserData = false;
      });
      _startAnimations();
    } on ApiException catch (e) {
      setState(() {
        isLoadingUserData = false;
        errorMessage = 'Errore API: ${e.message}';
      });
    } on NetworkException catch (e) {
      setState(() {
        isLoadingUserData = false;
        errorMessage = 'Errore di connessione: ${e.message}';
      });
    } catch (e) {
      setState(() {
        isLoadingUserData = false;
        errorMessage = 'Errore inaspettato: $e';
      });
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withOpacity(0.9),
                secondaryColor.withOpacity(0.7),
              ],
            ),
          ),
        ),
        title: const Text(
          'Portafoglio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => fetchUserData(),
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _buildBody(colorScheme),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (isLoadingUserData) {
      return _buildLoadingState(colorScheme);
    }

    if (errorMessage != null) {
      return _buildErrorState(colorScheme);
    }

    if (userData == null) {
      return _buildEmptyState(colorScheme);
    }

    return _buildProfitsContent(colorScheme);
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Caricamento profitti...',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Errore nel caricamento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32),
              FilledButton.icon(
                onPressed: fetchUserData,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Riprova'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Nessun dato disponibile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'I dati sui profitti non sono ancora disponibili.\nInizia a guadagnare seguendo la guida qui sotto!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitsContent(ColorScheme colorScheme) {
    double profitFromTicket = (userData!['profitFromTicket'] ?? 0).toDouble();
    double profitFromShop = (userData!['profitFromShop'] ?? 0).toDouble();
    double totalProfit = (userData!['totalProfit'] ?? 0).toDouble();

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalProfitCard(totalProfit, colorScheme),
                  SizedBox(height: 24),
                  _buildProfitBreakdown(
                      profitFromTicket, profitFromShop, colorScheme),
                  SizedBox(height: 32),
                  _buildEarningsGuideCard(colorScheme),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalProfitCard(double totalProfit, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Totale Guadagni',
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '€${totalProfit.toStringAsFixed(2)}',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitBreakdown(
      double profitFromTicket, double profitFromShop, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildProfitCard(
            'Da Ticket',
            profitFromTicket,
            Icons.confirmation_number_outlined,
            colorScheme,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildProfitCard(
            'Da Shop',
            profitFromShop,
            Icons.shopping_cart_outlined,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitCard(
      String title, double amount, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsGuideCard(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Come Guadagnare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildEarningMethod(
            'Ticket dalla tua rete',
            'Guadagna per ogni ticket aperto dagli utenti che hai portato nell\'app',
            Icons.people_outline_rounded,
            colorScheme,
            isHighValue: false,
          ),
          SizedBox(height: 16),
          _buildEarningMethod(
            'I tuoi ticket',
            'Guadagna di più per ogni ticket che apri tu direttamente',
            Icons.person_outline_rounded,
            colorScheme,
            isHighValue: true,
          ),
          SizedBox(height: 16),
          _buildEarningMethod(
            'Commissioni shop (2%)',
            'Ricevi il 2% di commissione su tutti gli ordini effettuati',
            Icons.shopping_bag_outlined,
            colorScheme,
            isHighValue: false,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Più utenti porti nella tua rete, più guadagni! Condividi l\'app con i tuoi amici.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningMethod(
    String title,
    String description,
    IconData icon,
    ColorScheme colorScheme, {
    bool isHighValue = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isHighValue
            ? Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighValue ? colorScheme.primary : colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isHighValue) ...[
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
