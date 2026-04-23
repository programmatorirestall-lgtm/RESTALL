import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';
import 'components/refund_request_card.dart';
import 'components/refund_stats_card.dart';
import 'create_refund_request_screen.dart';

class RefundRequestsScreen extends StatefulWidget {
  static String routeName = "/refund-requests";

  @override
  _RefundRequestsScreenState createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  String _selectedFilter = 'all';
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  @override
  void initState() {
    super.initState();
    // Carica le richieste all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefundRequestProvider>().loadRefundRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Richieste di Reso'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            tooltip: 'Ordina',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 18),
                    SizedBox(width: 8),
                    Text('Più recenti'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 18),
                    SizedBox(width: 8),
                    Text('Meno recenti'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount_desc',
                child: Row(
                  children: [
                    Icon(Icons.euro, size: 18),
                    Icon(Icons.arrow_downward, size: 14),
                    SizedBox(width: 8),
                    Text('Importo decrescente'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount_asc',
                child: Row(
                  children: [
                    Icon(Icons.euro, size: 18),
                    Icon(Icons.arrow_upward, size: 14),
                    SizedBox(width: 8),
                    Text('Importo crescente'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<RefundRequestProvider>().loadRefundRequests();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const RefundStatsCard(),
          _buildFilterBar(context),
          Expanded(child: _buildRefundRequestsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(CreateRefundRequestScreen.routeName);
        },
        backgroundColor: secondaryColor,
        icon: Icon(Icons.add),
        label: Text('Nuova Richiesta'),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final provider = Provider.of<RefundRequestProvider>(context);

    final Map<String, Map<String, dynamic>> filters = {
      'all': {
        'label': 'Tutte',
        'icon': Icons.all_inclusive_rounded,
        'count': provider.refundRequestCount,
      },
      'pending': {
        'label': 'In Attesa',
        'icon': Icons.hourglass_top_rounded,
        'count': provider.pendingRequests.length,
      },
      'approved': {
        'label': 'Approvate',
        'icon': Icons.check_circle_outline_rounded,
        'count': provider.approvedRequests.length,
      },
      'declined': {
        'label': 'Rifiutate',
        'icon': Icons.cancel_outlined,
        'count': provider.declinedRequests.length,
      },
      'refunded': {
        'label': 'Rimborsate',
        'icon': Icons.keyboard_return_rounded,
        'count': provider.refundedRequests.length,
      },
    };

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final filter = entry.key;
            final info = entry.value;
            final isSelected = _selectedFilter == filter;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? secondaryColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: secondaryColor.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      info['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${info['label']} (${info['count']})',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRefundRequestsList() {
    return Consumer<RefundRequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasRefundRequests) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Caricamento richieste...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (provider.errorMessage != null && !provider.hasRefundRequests) {
          return _buildErrorWidget(
            provider.errorMessage!,
            () => provider.loadRefundRequests(),
          );
        }

        if (!provider.hasRefundRequests) {
          return _buildEmptyState(() => provider.loadRefundRequests());
        }

        // Filtra le richieste in base al filtro selezionato
        final filteredRequests = _getFilteredRequests(provider);

        return RefreshIndicator(
          onRefresh: () => provider.loadRefundRequests(),
          color: secondaryColor,
          backgroundColor: Colors.white,
          child: filteredRequests.isEmpty
              ? _buildEmptyFilterState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    return RefundRequestCard(
                      refundRequest: filteredRequests[index],
                    );
                  },
                ),
        );
      },
    );
  }

  List<dynamic> _getFilteredRequests(RefundRequestProvider provider) {
    List<dynamic> requests;

    switch (_selectedFilter) {
      case 'pending':
        requests = provider.pendingRequests;
        break;
      case 'approved':
        requests = provider.approvedRequests;
        break;
      case 'declined':
        requests = provider.declinedRequests;
        break;
      case 'refunded':
        requests = provider.refundedRequests;
        break;
      case 'all':
      default:
        requests = provider.refundRequests;
    }

    // Applica l'ordinamento
    List<dynamic> sortedRequests = List.from(requests);

    switch (_sortBy) {
      case 'date_desc':
        sortedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        sortedRequests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_desc':
        sortedRequests.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        sortedRequests.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return sortedRequests;
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Qualcosa è andato storto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VoidCallback onRefresh) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Nessuna richiesta di reso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Non hai ancora creato richieste di reso.\nUsa il pulsante qui sotto per iniziare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Aggiorna'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Nessuna richiesta per questo filtro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Prova a selezionare un filtro diverso',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
