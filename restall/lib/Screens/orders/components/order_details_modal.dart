import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Order.dart';
import 'package:restall/models/refund_request.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';
import 'package:restall/providers/Order/order_provider.dart';
import 'package:restall/Screens/refund_requests/refund_requests_screen.dart';

class OrderDetailsModal extends StatelessWidget {
  final Order order;

  const OrderDetailsModal({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfo(),
                  SizedBox(height: 24),
                  _buildProductsSection(),
                  SizedBox(height: 24),
                  _buildAddressSection(),
                  SizedBox(height: 24),
                  _buildPaymentSection(),
                  if (order.status == 'completed') ...[
                    SizedBox(height: 32),
                    _buildActionsSection(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordine #${order.number}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                order.formattedDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final returnRequest = orderProvider.getReturnRequestByOrderId(order.id);
        final hasReturn = returnRequest != null;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informazioni Ordine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                _buildInfoRow('Status', order.statusLabel,
                    color: order.statusColor),
                if (hasReturn)
                  _buildInfoRow('Reso', returnRequest.status.toUpperCase(),
                      color: Colors.orange[700]!),
                _buildInfoRow('Totale', order.formattedTotal),
                _buildInfoRow('Valuta', order.currency),
                _buildInfoRow('Metodo Pagamento', order.paymentMethodTitle),
                if (order.customerNote.isNotEmpty)
                  _buildInfoRow('Note', order.customerNote),
                if (hasReturn && returnRequest.reason.isNotEmpty)
                  _buildInfoRow('Motivo Reso', returnRequest.reason),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prodotti (${order.totalItems})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...order.lineItems.map((item) => Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: item.image?.src.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.image!.src,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image,
                                          color: Colors.grey[400]),
                                ),
                              )
                            : Icon(Icons.shopping_bag, color: Colors.grey[400]),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SKU: ${item.sku} • Qty: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.formattedPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.formattedTotal,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indirizzi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fatturazione',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        order.billing.fullName,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (order.billing.company.isNotEmpty)
                        Text(order.billing.company),
                      Text(order.billing.fullAddress),
                      if (order.billing.phone.isNotEmpty)
                        Text('Tel: ${order.billing.phone}'),
                      Text(order.billing.email),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spedizione',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        order.shipping.fullName,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (order.shipping.company.isNotEmpty)
                        Text(order.shipping.company),
                      Text(
                          '${order.shipping.address1}, ${order.shipping.address2}'),
                      Text('${order.shipping.postcode} ${order.shipping.city}'),
                      Text(order.shipping.country),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento e Spedizione',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Metodo Pagamento', order.paymentMethodTitle),
            ...order.shippingLines.map((shipping) =>
                _buildInfoRow('Spedizione', shipping.methodTitle)),
            Divider(height: 24),
            _buildInfoRow('Totale Ordine', order.formattedTotal,
                color: secondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Azioni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (order.status == 'processing' || order.status == 'completed') ...[
              // Pulsante per rimborso Stripe Marketplace
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRefundMarketplaceDialog(context),
                  icon: Icon(Icons.credit_card),
                  label: Text('Rimborso Marketplace (Stripe)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF635BFF), // Stripe purple
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Pulsante per reso tradizionale
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestReturn(context),
                  icon: Icon(Icons.keyboard_return),
                  label: Text('Richiedi Reso'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRefundMarketplaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card, color: Color(0xFF635BFF)),
            SizedBox(width: 12),
            Text('Rimborso Marketplace'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleziona il prodotto da rimborsare:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            ...order.lineItems.map((item) => Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.image?.src.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image!.src,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image, color: Colors.grey[400]),
                              ),
                            )
                          : Icon(Icons.shopping_bag, color: Colors.grey[400]),
                    ),
                    title: Text(item.name, style: TextStyle(fontSize: 13)),
                    subtitle: Text(item.formattedPrice, style: TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: Icon(Icons.undo, color: Color(0xFF635BFF)),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _processMarketplaceRefund(context, item.productId.toString());
                      },
                    ),
                  ),
                )),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stripe gestirà automaticamente il reverse transfer al venditore',
                      style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annulla'),
          ),
        ],
      ),
    );
  }

  Future<void> _processMarketplaceRefund(BuildContext context, String productId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF635BFF)),
                SizedBox(height: 16),
                Text('Elaborazione rimborso...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Esegui il rimborso
    final refund = await orderProvider.refundMarketplaceProduct(productId);

    // Chiudi loading
    if (context.mounted) Navigator.pop(context);

    // Chiudi il modale dettagli ordine se il rimborso è andato a buon fine
    if (refund != null && context.mounted) {
      Navigator.pop(context);
    }
  }

  void _requestReturn(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _RefundRequestDialog(order: order),
    );
  }
}

// StatefulWidget separato per il dialog del reso
class _RefundRequestDialog extends StatefulWidget {
  final Order order;

  const _RefundRequestDialog({required this.order});

  @override
  _RefundRequestDialogState createState() => _RefundRequestDialogState();
}

class _RefundRequestDialogState extends State<_RefundRequestDialog> {
  String? selectedPredefinedReason;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> predefinedReasons = [
    'Componente non compatibile con il modello',
    'Prodotto difettoso o non funzionante',
    'Parte mancante o errata nella confezione',
    'Danni durante il trasporto',
    'Prestazioni non conformi alle specifiche',
    'Errore nell’ordine (articolo sbagliato)',
    'Quantità errata ricevuta',
    'Cambio modello o specifiche richieste',
    'Consegna in ritardo',
    'Altro (specifica nel campo)',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Richiedi Reso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Vuoi richiedere il reso per l\'ordine #${widget.order.number}?'),
            SizedBox(height: 8),
            Text(
              'Importo: ${widget.order.formattedTotal}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Seleziona il motivo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: predefinedReasons.map((reason) {
                final isSelected = selectedPredefinedReason == reason;
                return FilterChip(
                  label: Text(
                    reason,
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedPredefinedReason = selected ? reason : null;
                    });
                  },
                  selectedColor: secondaryColor.withOpacity(0.2),
                  checkmarkColor: secondaryColor,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: isSelected ? secondaryColor : Colors.grey[700],
                  ),
                  side: BorderSide(
                    color: isSelected ? secondaryColor : Colors.grey[300]!,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: selectedPredefinedReason == 'Altro (specifica sotto)'
                    ? 'Specifica il motivo *'
                    : 'Dettagli aggiuntivi (opzionale)',
                hintText: 'Aggiungi ulteriori dettagli...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => _submitRefundRequest(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('Conferma Reso'),
        ),
      ],
    );
  }

  Future<void> _submitRefundRequest(BuildContext dialogContext) async {
    // Salva il context prima di operazioni async
    final scaffoldContext = context;

    if (selectedPredefinedReason == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Seleziona un motivo dal menu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalReason = selectedPredefinedReason!;
    if (selectedPredefinedReason == 'Altro (specifica sotto)') {
      if (_reasonController.text.isEmpty ||
          _reasonController.text.length < 10) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Specifica il motivo (almeno 10 caratteri)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      finalReason = _reasonController.text;
    } else if (_reasonController.text.isNotEmpty) {
      finalReason = '$finalReason - ${_reasonController.text}';
    }

    // Ottieni il provider PRIMA di chiudere il dialog
    final refundProvider =
        Provider.of<RefundRequestProvider>(scaffoldContext, listen: false);

    // Calcola l'importo in centesimi
    final totalAmount = (double.parse(widget.order.total) * 100).toInt();

    // Crea lista line items dall'ordine
    final lineItems = widget.order.lineItems
        .map((item) => RefundLineItem(
              id: item.productId,
              quantity: item.quantity,
            ))
        .toList();

    final dto = CreateRefundRequestDto(
      orderId: widget.order.id,
      amount: totalAmount.toDouble(),
      reason: finalReason,
      lineItems: lineItems,
    );

    // Chiudi i dialog
    Navigator.pop(dialogContext); // Chiudi dialog reso
    Navigator.pop(scaffoldContext); // Chiudi modal ordine

    // Esegui la richiesta DOPO aver chiuso
    final success = await refundProvider.createRefundRequest(dto);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Richiesta di reso creata con successo!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Visualizza',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(scaffoldContext)
                  .pushNamed(RefundRequestsScreen.routeName);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
              refundProvider.errorMessage ?? 'Errore nella creazione del reso'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
