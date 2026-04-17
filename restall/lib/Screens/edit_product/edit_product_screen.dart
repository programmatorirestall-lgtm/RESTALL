import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/UserProducts.dart';
import 'package:restall/providers/Product/product_provider.dart';

class EditProductScreen extends StatefulWidget {
  final ProductBase product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  final _priceFocusNode = FocusNode();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
      keyboardBarColor: Colors.grey[200],
      actions: [
        KeyboardActionsItem(
          focusNode: _priceFocusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ],
        ),
      ],
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      final success = await productProvider.updateProduct(
        productId: widget.product.id,
        name: _titleController.text.trim(),
        price: _priceController.text.trim(),
        regularPrice: _priceController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prodotto aggiornato con successo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nell\'aggiornamento del prodotto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLightColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withOpacity(0.95),
                secondaryColor.withOpacity(0.85),
              ],
            ),
          ),
        ),
        title: const Text(
          'Modifica Prodotto',
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
      body: KeyboardActions(
        config: _buildKeyboardActionsConfig(context),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kPrimaryLightColor, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.images.isNotEmpty)
                      _buildImagesPreview(),
                    const SizedBox(height: 16),
                    _buildProductDetailsCard(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesPreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.product.images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.product.images[index].src,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dettagli Prodotto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Titolo*',
                  hintText: 'Es. iPhone 13 Pro Max',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  if (value.trim().length < 3) {
                    return 'Il titolo deve essere di almeno 3 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                focusNode: _priceFocusNode,
                textInputAction: TextInputAction.done,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Prezzo*',
                  hintText: 'Es. 599.99',
                  prefixIcon: Icon(Icons.euro_rounded),
                  suffixText: '€',
                ),
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un prezzo';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Inserisci un prezzo valido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isSubmitting
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : [secondaryColor, secondaryColor.withOpacity(0.85)],
        ),
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: secondaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitUpdate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isSubmitting ? 'Salvataggio in corso...' : 'Salva Modifiche',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
