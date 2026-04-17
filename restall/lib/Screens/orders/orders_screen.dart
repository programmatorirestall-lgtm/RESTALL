import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Order/order_provider.dart';
import 'components/order_card.dart';
import 'components/return_card.dart';
// ...existing code...

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          'I Miei Ordini',
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
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final Map<OrderStatusFilter, Map<String, dynamic>> filters = {
      OrderStatusFilter.all: {
        'label': 'Tutti',
        'icon': Icons.all_inclusive_rounded,
      },
      OrderStatusFilter.processing: {
        'label': 'In Lavorazione',
        'icon': Icons.hourglass_top_rounded,
      },
      OrderStatusFilter.completed: {
        'label': 'Completati',
        'icon': Icons.check_circle_outline_rounded,
      },
      OrderStatusFilter.cancelled: {
        'label': 'Annullati',
        'icon': Icons.cancel_outlined,
      },
      OrderStatusFilter.refunded: {
        'label': 'Rimborsati',
        'icon': Icons.keyboard_return_rounded,
      },
      OrderStatusFilter.returnsPending: {
        'label': 'Resi (In attesa)',
        'icon': Icons.pending_actions_rounded,
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
            final isSelected = orderProvider.activeFilter == filter;

            return GestureDetector(
              onTap: () => orderProvider.applyFilter(filter),
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
                      info['label'],
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

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading && !orderProvider.hasOrders) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Caricamento ordini...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (orderProvider.error != null && !orderProvider.hasOrders) {
          return _buildErrorWidget(
            orderProvider.error!,
            () => orderProvider.fetchOrders(),
          );
        }

        if (!orderProvider.hasOrders) {
          return _buildEmptyState(() => orderProvider.refreshOrders());
        }

        // Se il filtro è returnsPending, mostra le ReturnRequest
        if (orderProvider.activeFilter == OrderStatusFilter.returnsPending) {
          print('🔍 Filtro returnsPending attivo');
          print('📋 Totale returns caricati: ${orderProvider.returns.length}');

          final returnsToShow = orderProvider.returns
              .where((request) {
                print('  - Return ID: ${request.id}, Status: ${request.status}');
                return request.status.toLowerCase() == 'pending';
              })
              .toList();

          print('✅ Returns filtrati per pending: ${returnsToShow.length}');

          return RefreshIndicator(
            onRefresh: () async {
              await orderProvider.fetchReturns(status: 'pending', showLoading: true);
            },
            color: secondaryColor,
            backgroundColor: Colors.white,
            child: returnsToShow.isEmpty
                ? _buildEmptyReturnsState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: returnsToShow.length,
                    itemBuilder: (context, index) {
                      return ReturnCard(request: returnsToShow[index]);
                    },
                  ),
          );
        }

        // Filtra ordini per stato
        List ordersToShow = orderProvider.orders;
        if (orderProvider.activeFilter == OrderStatusFilter.refunded) {
          ordersToShow = orderProvider.orders
              .where((order) => order.status.toLowerCase().contains('refund'))
              .toList();
        }

        return RefreshIndicator(
          onRefresh: orderProvider.refreshOrders,
          color: secondaryColor,
          backgroundColor: Colors.white,
          child: ordersToShow.isEmpty
              ? _buildEmptyReturnsState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: ordersToShow.length,
                  itemBuilder: (context, index) {
                    return OrderCard(order: ordersToShow[index]);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyReturnsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_return_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Nessuna richiesta di reso/rimborso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Non ci sono rimborsi o richieste di reso per questo filtro.',
              textAlign: TextAlign.center,
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
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Nessun ordine trovato',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Non hai ancora effettuato alcun ordine.\nInizia a fare shopping!',
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
              'Nessun ordine per questo filtro',
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
