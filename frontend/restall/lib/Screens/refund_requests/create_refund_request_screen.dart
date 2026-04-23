import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/refund_request.dart';
import 'package:restall/providers/RefundRequest/refund_request_provider.dart';
import 'package:restall/widgets/keyboard_dismissible.dart';

class CreateRefundRequestScreen extends StatefulWidget {
  static String routeName = "/create-refund-request";

  const CreateRefundRequestScreen({Key? key}) : super(key: key);

  @override
  _CreateRefundRequestScreenState createState() =>
      _CreateRefundRequestScreenState();
}

class _CreateRefundRequestScreenState extends State<CreateRefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  final List<RefundLineItem> _lineItems = [];
  final _lineItemIdController = TextEditingController();
  final _lineItemQuantityController = TextEditingController();

  // Motivi predefiniti per il reso
  final List<String> _predefinedReasons = [
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

  String? _selectedReason;

  @override
  void dispose() {
    _orderIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _lineItemIdController.dispose();
    _lineItemQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Nuova Richiesta Reso'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: KeyboardDismissible(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                SizedBox(height: 16),
                _buildOrderDetailsCard(),
                SizedBox(height: 16),
                _buildLineItemsCard(),
                SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: secondaryColor,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compila i dati per richiedere il reso di un ordine. L\'importo deve essere in centesimi (es. 1599 = €15.99)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
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
              'Dettagli Ordine',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _orderIdController,
              decoration: InputDecoration(
                labelText: 'ID Ordine',
                hintText: 'Es. 123',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci l\'ID dell\'ordine';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Importo (in centesimi)',
                hintText: 'Es. 1599 per €15.99',
                prefixIcon: Icon(Icons.euro_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci l\'importo';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Inserisci un importo valido';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Text(
              'Motivo del Reso',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            _buildReasonChips(),
            SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: _selectedReason == 'Altro (specifica nel campo)'
                    ? 'Specifica il motivo'
                    : 'Note aggiuntive (opzionale)',
                hintText: 'Aggiungi dettagli...',
                prefixIcon: Icon(Icons.comment_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              validator: (value) {
                if (_selectedReason == null) {
                  return 'Seleziona un motivo dal menu sopra';
                }
                if (_selectedReason == 'Altro (specifica nel campo)' &&
                    (value == null || value.isEmpty || value.length < 10)) {
                  return 'Specifica il motivo (almeno 10 caratteri)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsCard() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Articoli da Restituire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${_lineItems.length} articoli',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_lineItems.isNotEmpty) ...[
              ..._lineItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Articolo #${item.id}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quantità: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _lineItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lineItemIdController,
                    decoration: InputDecoration(
                      labelText: 'ID Articolo',
                      hintText: 'Es. 45',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lineItemQuantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantità',
                      hintText: 'Es. 1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle, color: secondaryColor),
                  iconSize: 32,
                  onPressed: _addLineItem,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _predefinedReasons.map((reason) {
        final isSelected = _selectedReason == reason;
        return FilterChip(
          label: Text(reason),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedReason = selected ? reason : null;
            });
          },
          selectedColor: secondaryColor.withOpacity(0.2),
          checkmarkColor: secondaryColor,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isSelected ? secondaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: Colors.grey[100],
          side: BorderSide(
            color: isSelected ? secondaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  void _addLineItem() {
    final id = int.tryParse(_lineItemIdController.text);
    final quantity = int.tryParse(_lineItemQuantityController.text);

    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inserisci un ID articolo valido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inserisci una quantità valida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _lineItems.add(RefundLineItem(id: id, quantity: quantity));
      _lineItemIdController.clear();
      _lineItemQuantityController.clear();
    });
  }

  Widget _buildSubmitButton() {
    return Consumer<RefundRequestProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.isLoading ? null : _submitRequest,
            icon: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.send),
            label: Text(
              provider.isLoading ? 'Invio in corso...' : 'Invia Richiesta',
              style: TextStyle(fontSize: 16),
            ),
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
      },
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Costruisci il motivo completo
    String finalReason = _selectedReason ?? '';
    if (_reasonController.text.isNotEmpty) {
      finalReason = _selectedReason == 'Altro (specifica nel campo)'
          ? _reasonController.text
          : '$finalReason - ${_reasonController.text}';
    }

    final dto = CreateRefundRequestDto(
      orderId: int.parse(_orderIdController.text),
      amount: double.parse(_amountController.text),
      reason: finalReason,
      lineItems: _lineItems,
    );

    final provider = context.read<RefundRequestProvider>();
    final success = await provider.createRefundRequest(dto);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Richiesta creata con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Errore durante la creazione'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
