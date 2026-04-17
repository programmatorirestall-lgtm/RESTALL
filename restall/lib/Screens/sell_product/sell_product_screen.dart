import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:provider/provider.dart';
import 'package:restall/components/seller_verification_dialog.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Product/product_provider.dart';
import 'package:restall/providers/Profile/profile_provider.dart';

class SellProductScreen extends StatefulWidget {
  static String routeName = "/sell-product";

  const SellProductScreen({Key? key}) : super(key: key);

  @override
  _SellProductScreenState createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Categoria fissa per marketplace
  final String _selectedCategory = 'marketplace';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Verifica se l'utente può vendere
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSellerStatus();
    });
  }

  void _checkSellerStatus() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    print('🔍 DEBUG SellProductScreen: Controllo stato venditore');
    print('⏳ DEBUG SellProductScreen: ProfileState = ${profileProvider.state}');

    // Aspetta che il ProfileProvider completi il loading
    if (profileProvider.state == ProfileState.loading) {
      print('⏳ DEBUG SellProductScreen: Aspetto completamento fetchProfile...');
      // Aspetta che lo stato cambi da loading
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return profileProvider.state == ProfileState.loading;
      });
      print('✅ DEBUG SellProductScreen: fetchProfile completato');
    }

    print(
        '👤 DEBUG SellProductScreen: userProfile = ${profileProvider.userProfile?.toJson()}');
    print(
        '🏪 DEBUG SellProductScreen: isSeller = ${profileProvider.userProfile?.isSeller}');
    print(
        '📊 DEBUG SellProductScreen: sellerStatus = ${profileProvider.userProfile?.sellerStatus}');
    print(
        '✅ DEBUG SellProductScreen: isSellerVerified = ${profileProvider.isSellerVerified}');

    if (!profileProvider.isSellerVerified) {
      print('❌ DEBUG SellProductScreen: Utente NON verificato, mostro dialog');
      if (mounted) showSellerVerificationDialog(context);
      if (mounted) Navigator.pop(context);
    } else {
      print('✅ DEBUG SellProductScreen: Utente verificato, può vendere');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella selezione delle immagini: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'acquisizione della foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      final success = await productProvider.createProduct(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        category: _selectedCategory,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (!mounted) return;

      if (success) {
        // Mostra messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prodotto creato con successo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Torna indietro dopo un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nella creazione del prodotto'),
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
          'Vendi Prodotto',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.drafts_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bozza',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                colors: [
                  kPrimaryLightColor,
                  Colors.white,
                ],
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
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildProductDetailsCard(),
                    const SizedBox(height: 16),
                    _buildImagesCard(),
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

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: secondaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Il tuo prodotto sarà creato in bozza e potrà essere pubblicato dopo la revisione.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
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
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrizione*',
                  hintText: 'Descrivi il tuo prodotto in dettaglio...',
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  if (value.trim().length < 10) {
                    return 'La descrizione deve essere di almeno 10 caratteri';
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
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
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

  Widget _buildImagesCard() {
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
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
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
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Immagini Prodotto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aggiungi fino a 10 foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedImages.length >= 10
                          ? Colors.red.withOpacity(0.1)
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedImages.length}/10',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedImages.length >= 10
                            ? Colors.red
                            : secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePickerButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galleria',
                      onTap: _selectedImages.length < 10 ? _pickImages : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImagePickerButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Fotocamera',
                      onTap: _selectedImages.length < 10
                          ? _pickImageFromCamera
                          : null,
                    ),
                  ),
                ],
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? secondaryColor.withOpacity(0.3)
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? secondaryColor : Colors.grey[400],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? secondaryColor : Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
          onTap: _isSubmitting ? null : _submitProduct,
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
                  _isSubmitting ? 'Creazione in corso...' : 'Crea Prodotto',
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
