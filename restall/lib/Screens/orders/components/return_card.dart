import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/ReturnRequest.dart';
import 'package:provider/provider.dart';
import 'package:restall/providers/Order/order_provider.dart';
import 'order_details_modal.dart';

class ReturnDetailsModal extends StatelessWidget {
  final ReturnRequest request;
  const ReturnDetailsModal({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dettaglio richiesta di reso',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('ID richiesta: #${request.id}', style: TextStyle(fontSize: 15)),
          Text('Ordine associato: #${request.orderId}',
              style: TextStyle(fontSize: 15)),
          SizedBox(height: 8),
          Text('Stato: ${request.status}', style: TextStyle(fontSize: 15)),
          SizedBox(height: 8),
          Text(
              'Motivo: ${request.reason.isNotEmpty ? request.reason : "Nessun motivo"}',
              style: TextStyle(fontSize: 15)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.receipt_long),
              label: Text('Visualizza ordine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final orderProvider =
                    Provider.of<OrderProvider>(context, listen: false);
                final order = orderProvider
                    .getOrderById(int.tryParse(request.orderId) ?? 0);
                if (order != null) {
                  Navigator.pop(context); // Chiudi il modal reso
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => OrderDetailsModal(order: order),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ordine non trovato.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 8),
          Text('Importo: ${request.formattedAmount}',
              style: TextStyle(fontSize: 15)),
          SizedBox(height: 8),
          Text('Data richiesta: ${request.formattedDate}',
              style: TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class ReturnCard extends StatelessWidget {
  final ReturnRequest request;

  const ReturnCard({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showReturnDetails(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reso #${request.id}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(request.formattedDate,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('Ordine: #${request.orderId}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                  SizedBox(height: 8),
                  Text(
                      request.reason.isNotEmpty
                          ? request.reason
                          : 'Nessun motivo',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(request.formattedAmount,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor)),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey[400])
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReturnDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReturnDetailsModal(request: request),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (request.status.toLowerCase()) {
      case 'pending':
      case 'in_review':
        color = Colors.orange[600]!;
        break;
      case 'approved':
      case 'refunded':
        color = Colors.green[600]!;
        break;
      case 'rejected':
        color = Colors.red[600]!;
        break;
      default:
        color = Colors.grey[600]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        request.status.toUpperCase(),
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
