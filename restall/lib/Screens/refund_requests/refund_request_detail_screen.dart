import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/refund_request.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';

class RefundRequestDetailScreen extends StatefulWidget {
  static String routeName = "/refund-request-detail";

  @override
  _RefundRequestDetailScreenState createState() =>
      _RefundRequestDetailScreenState();
}

class _RefundRequestDetailScreenState
    extends State<RefundRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final refundRequestId = ModalRoute.of(context)?.settings.arguments as int?;
      if (refundRequestId != null) {
        context.read<RefundRequestProvider>().loadRefundRequest(refundRequestId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dettagli Richiesta Reso'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RefundRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            );
          }

          if (provider.selectedRefundRequest == null) {
            return Center(
              child: Text(
                'Richiesta non trovata',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          final refundRequest = provider.selectedRefundRequest!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(refundRequest),
                SizedBox(height: 16),
                _buildDetailsCard(refundRequest),
                SizedBox(height: 16),
                _buildLineItemsCard(refundRequest),
                SizedBox(height: 16),
                _buildTimelineCard(refundRequest),
                SizedBox(height: 24),
                _buildAdminActions(context, refundRequest, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(RefundRequest refundRequest) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Richiesta #${refundRequest.id}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ordine #${refundRequest.orderId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(refundRequest.status),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Importo Reso',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '€ ${(refundRequest.amount / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(RefundRequest refundRequest) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dettagli',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              Icons.comment_outlined,
              'Motivo',
              refundRequest.reason,
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Data Richiesta',
              DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.createdAt),
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.update_outlined,
              'Ultimo Aggiornamento',
              DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsCard(RefundRequest refundRequest) {
    if (refundRequest.lineItems.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Articoli da Restituire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            ...refundRequest.lineItems.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Articolo #${item.id}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Quantità: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(RefundRequest refundRequest) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            _buildTimelineItem(
              'Richiesta Creata',
              DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.createdAt),
              Colors.blue,
              true,
            ),
            if (refundRequest.isApproved || refundRequest.isRefunded)
              _buildTimelineItem(
                'Richiesta Approvata',
                DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.updatedAt),
                Colors.green,
                true,
              ),
            if (refundRequest.isDeclined)
              _buildTimelineItem(
                'Richiesta Rifiutata',
                DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.updatedAt),
                Colors.red,
                true,
              ),
            if (refundRequest.isRefunded)
              _buildTimelineItem(
                'Rimborso Completato',
                DateFormat('dd/MM/yyyy HH:mm').format(refundRequest.updatedAt),
                Colors.purple,
                false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    Color color,
    bool showLine,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: color.withOpacity(0.3),
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (showLine) SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActions(
    BuildContext context,
    RefundRequest refundRequest,
    RefundRequestProvider provider,
  ) {
    // TODO: Controlla se l'utente è admin
    // Per ora mostriamo sempre i pulsanti (dovrai aggiungere il controllo dei ruoli)

    if (refundRequest.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Approva Richiesta',
                        'Sei sicuro di voler approvare questa richiesta di reso?',
                      );
                      if (confirmed == true) {
                        final success = await provider.approveRefundRequest(refundRequest.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Richiesta approvata con successo'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(Icons.check_circle),
              label: Text('Approva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Rifiuta Richiesta',
                        'Sei sicuro di voler rifiutare questa richiesta di reso?',
                      );
                      if (confirmed == true) {
                        final success = await provider.declineRefundRequest(refundRequest.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Richiesta rifiutata'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(Icons.cancel),
              label: Text('Rifiuta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (refundRequest.isApproved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () async {
                  final confirmed = await _showConfirmDialog(
                    context,
                    'Esegui Rimborso',
                    'Sei sicuro di voler procedere con il rimborso? Questa azione eseguirà il rimborso su Stripe e WooCommerce.',
                  );
                  if (confirmed == true) {
                    final result = await provider.executeRefund(refundRequest.id);
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rimborso completato con successo!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  }
                },
          icon: Icon(Icons.payment),
          label: Text('Esegui Rimborso'),
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.hourglass_top;
        break;
      case 'approved':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        break;
      case 'declined':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        break;
      case 'refunded':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.payment;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'In Attesa';
      case 'approved':
        return 'Approvato';
      case 'declined':
        return 'Rifiutato';
      case 'refunded':
        return 'Rimborsato';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
