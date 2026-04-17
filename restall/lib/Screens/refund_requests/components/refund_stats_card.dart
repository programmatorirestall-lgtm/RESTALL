import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';

class RefundStatsCard extends StatelessWidget {
  const RefundStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RefundRequestProvider>(
      builder: (context, provider, child) {
        if (!provider.hasRefundRequests) {
          return SizedBox.shrink();
        }

        final totalRefundAmount = _calculateTotalAmount(provider);
        final averageAmount = provider.refundRequestCount > 0
            ? totalRefundAmount / provider.refundRequestCount
            : 0.0;

        return Card(
          margin: EdgeInsets.all(16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: secondaryColor,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Statistiche Resi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Totale Richieste',
                        provider.refundRequestCount.toString(),
                        Icons.receipt_long_outlined,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'In Attesa',
                        provider.pendingRequests.length.toString(),
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Approvate',
                        provider.approvedRequests.length.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Rimborsate',
                        provider.refundedRequests.length.toString(),
                        Icons.payments_outlined,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountStat(
                      'Importo Totale',
                      totalRefundAmount,
                      secondaryColor,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    _buildAmountStat(
                      'Media per Reso',
                      averageAmount,
                      Colors.blue[700]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '€ ${(amount / 100).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateTotalAmount(RefundRequestProvider provider) {
    return provider.refundRequests.fold(
      0.0,
      (sum, request) => sum + request.amount,
    );
  }
}
