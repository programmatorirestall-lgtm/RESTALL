import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:restall/API/Cart/cart.dart';
import 'package:restall/API/Order/order_api.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Cart/cart_provider.dart';
import 'package:restall/providers/Profile/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckOutScreen extends StatefulWidget {
  final bool isMarketplace;
  final Product? marketplaceProduct;
  final int? marketplaceQuantity;

  const CheckOutScreen({
    super.key,
    this.isMarketplace = false,
    this.marketplaceProduct,
    this.marketplaceQuantity,
  });

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

// Tipo cliente
enum CustomerType { private, business }

CustomerType _customerType = CustomerType.private;

class _CheckOutScreenState extends State<CheckOutScreen>
    with TickerProviderStateMixin {
  int currentStep = 0;
  bool _isLoading = false;

  // Form keys per validazione
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _shippingFormKey = GlobalKey<FormState>();

  // Controllers per i campi del form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _companyController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  // Variabili per modalità acquisto
  bool _isBusiness = false;
  bool _needInvoice = false;
  bool _isValidPIva = false;
  bool _requireCodUnivoco = false;

  // Business/Partita IVA controllers
  final _businessNameController = TextEditingController();
  final _partitaIvaController = TextEditingController();
  final _codiceUnivocaController = TextEditingController();
  final _pecController = TextEditingController();
  final _sdiController = TextEditingController();

// Billing controllers separati (se diversi da shipping)
  final _billingNameController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingCompanyController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPostalCodeController = TextEditingController();
  final _billingCountryController = TextEditingController();

  // FocusNode per i campi numerici (per keyboard_actions su iOS)
  final _phoneFocusNode = FocusNode();
  final _postalCodeFocusNode = FocusNode();

  // Variabili per le opzioni
  String _selectedShippingMethod = 'standard';
  bool _acceptTerms = false;
  List<Map<String, dynamic>> _savedAddresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _useAsBilling = true;
  bool _saveThisAddress = false;
  String _addressNickname = '';
  bool _isProgressBarExpanded = false;

  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;
  String? _orderStatus;
  String? _orderMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _animationController.forward();
    _progressController.forward();
    _loadSavedAddresses();
    _countryController.text = 'IT'; // Default Italy
    _billingCountryController.text = 'IT';

    // Precompila email e telefono dall'account utente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.userProfile != null) {
        _emailController.text = profileProvider.userProfile!.email;
        if (profileProvider.userProfile!.numTel != null) {
          _phoneController.text = profileProvider.userProfile!.numTel!;
        }
        // Precompila nome e cognome se disponibili
        if (profileProvider.userProfile!.nome.isNotEmpty &&
            profileProvider.userProfile!.cognome.isNotEmpty) {
          _nameController.text =
              '${profileProvider.userProfile!.nome} ${profileProvider.userProfile!.cognome}';
        }
      }
    });
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = prefs.getString('saved_addresses') ?? '[]';
    final List<dynamic> addressesList = json.decode(addressesJson);

    setState(() {
      _savedAddresses = List<Map<String, dynamic>>.from(addressesList);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    _companyController.dispose();
    _address2Controller.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _billingNameController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _billingCompanyController.dispose();
    _billingAddressController.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPostalCodeController.dispose();
    _billingCountryController.dispose();
    _businessNameController.dispose();
    _partitaIvaController.dispose();
    _codiceUnivocaController.dispose();

    // Dispose FocusNode
    _phoneFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _pecController.dispose();
    _sdiController.dispose();
    super.dispose();
  }

  /// Configurazione KeyboardActions per iOS - aggiunge il tasto "Fatto" sui campi numerici
  KeyboardActionsConfig _buildKeyboardActionsConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
      keyboardBarColor: Colors.grey[200],
      nextFocus: false,
      actions: [
        KeyboardActionsItem(
          focusNode: _phoneFocusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Fatto',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ],
        ),
        KeyboardActionsItem(
          focusNode: _postalCodeFocusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Fatto',
                    style: TextStyle(
                      color: primaryColor,
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

  Future<void> _saveAddress(Map<String, dynamic> address) async {
    final prefs = await SharedPreferences.getInstance();

    address['saved_date'] = DateTime.now().toIso8601String();
    address['nickname'] = _addressNickname.isEmpty
        ? '${address['city']}, ${address['address1']}'
        : _addressNickname;

    _savedAddresses.add(address);

    if (_savedAddresses.length > 5) {
      _savedAddresses = _savedAddresses.sublist(_savedAddresses.length - 5);
    }

    final addressesJson = json.encode(_savedAddresses);
    await prefs.setString('saved_addresses', addressesJson);

    setState(() {});
  }

  Future<void> _deleteAddress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _savedAddresses.removeAt(index);

    final addressesJson = json.encode(_savedAddresses);
    await prefs.setString('saved_addresses', addressesJson);

    setState(() {});
  }

  void _selectSavedAddress(Map<String, dynamic> address) {
    setState(() {
      _selectedAddress = address;
      _addressController.text = address['address1'] ?? '';
      _address2Controller.text = address['address2'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _postalCodeController.text = address['postalCode'] ?? '';
      _countryController.text = address['country'] ?? 'IT';
      _companyController.text = address['company'] ?? '';
    });
  }

  Map<String, dynamic> _getCurrentShippingAddress() {
    return {
      'company': _companyController.text,
      'address1': _addressController.text,
      'address2': _address2Controller.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'postalCode': _postalCodeController.text,
      'country': _countryController.text,
    };
  }

  Future<void> _geocodeAddress(String address) async {
    debugPrint('📍 _geocodeAddress chiamato con: $address');

    if (address.trim().isEmpty || address.length < 10) {
      debugPrint('❌ Indirizzo troppo corto o vuoto');
      return;
    }

    try {
      final encodedAddress = Uri.encodeComponent(address);
      const workingApiKey = "AIzaSyCZiS2tq8NWe-f0XO6eU7D1ZQhSnujZa-A"; // Stessa chiave di Places
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&components=country:IT&key=$workingApiKey',
      );

      debugPrint('🌐 Chiamando Geocoding API: $url');
      final response = await http.get(url);
      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📦 Geocoding response: ${data['status']}');
        debugPrint('📦 Results count: ${data['results']?.length ?? 0}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final components = data['results'][0]['address_components'] as List;
          debugPrint('🔧 Address components trovati: ${components.length}');

          String? city;
          String? province;
          String? postalCode;

          for (var component in components) {
            final types = component['types'] as List;
            debugPrint('  Component: ${component['long_name']} - Types: $types');

            if (types.contains('locality')) {
              city = component['long_name'];
              debugPrint('  ✅ Città trovata: $city');
            } else if (types.contains('administrative_area_level_2')) {
              province = component['short_name'];
              debugPrint('  ✅ Provincia trovata: $province');
            } else if (types.contains('postal_code')) {
              postalCode = component['long_name'];
              debugPrint('  ✅ CAP trovato: $postalCode');
            }
          }

          debugPrint('📝 Risultati finali - Città: $city, Provincia: $province, CAP: $postalCode');

          if (mounted) {
            setState(() {
              // Compila città (non sovrascrivere indirizzo già inserito)
              if (city != null && city.isNotEmpty) {
                _cityController.text = city;
                debugPrint('✏️ Compilato campo Città: $city');
              }

              // Compila provincia
              if (province != null && province.isNotEmpty) {
                _stateController.text = province;
                debugPrint('✏️ Compilato campo Provincia: $province');
              }

              // Compila CAP
              if (postalCode != null && postalCode.isNotEmpty) {
                _postalCodeController.text = postalCode;
                debugPrint('✏️ Compilato campo CAP: $postalCode');
              }

              // Italia di default
              _countryController.text = 'IT';
            });

            // Feedback visivo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Città, CAP e provincia compilati!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Errore geocodifica indirizzo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isLoading) {
          return _buildLoadingState();
        }

        // Per marketplace, non controllare il carrello ma usa il prodotto passato
        if (!widget.isMarketplace && cartProvider.isEmpty) {
          return _buildEmptyCartState();
        }

        // Calcola il totale: per marketplace usa il prezzo del prodotto, altrimenti usa il carrello
        final total = widget.isMarketplace && widget.marketplaceProduct != null
            ? widget.marketplaceProduct!.price * (widget.marketplaceQuantity ?? 1)
            : cartProvider.totalAmount;
        final shippingCost = _getShippingCost();
        final finalTotal = total + shippingCost;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: kBackgroundColor,
          extendBodyBehindAppBar: true,
          appBar: _buildEnhancedAppBar(),
          body: KeyboardActions(
            config: _buildKeyboardActionsConfig(context),
            child: GestureDetector(
              onTap: () {
                // Chiude la tastiera quando si fa tap fuori dai campi
                FocusScope.of(context).unfocus();
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Container(
                decoration: const BoxDecoration(
                  gradient: backgroundGradient,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      children: [
                        const SizedBox(height: 120),
                        _buildEnhancedProgressIndicator(),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: isKeyboardVisible ? keyboardHeight * 0.1 : 0,
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom:
                                    isKeyboardVisible ? keyboardHeight + 20 : 20,
                              ),
                              physics: const BouncingScrollPhysics(),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isLoading
                                    ? _buildLoadingState()
                                    : _buildStepContent(cartProvider, total,
                                        shippingCost, finalTotal),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(
                0, isKeyboardVisible && keyboardHeight > 300 ? 150 : 0, 0),
            child: _buildEnhancedBottomActionBar(finalTotal),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              secondaryColor.withAlpha((255 * 0.9).round()),
              secondaryColor.withAlpha((255 * 0.7).round()),
            ],
          ),
        ),
      ),
      title: const Text(
        "Checkout",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryColor, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: primaryColor.withAlpha((255 * 0.3).round())),
          ),
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCartState() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildEnhancedAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Carrello Vuoto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi prodotti per procedere al checkout',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Inizia lo Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: buttonTextColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    int maxLines = 1,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    bool enabled = true,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction ?? TextInputAction.next,
      enabled: enabled,
      focusNode: focusNode,
      onTap: () {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
          }
        });
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildEnhancedBottomActionBar(double finalTotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Totale:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    Text(
                      '€${finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (currentStep > 0)
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _goToPreviousStep,
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              size: 18),
                          label: const SizedBox.shrink(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 12),
                  Flexible(
                    flex: 4,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                _handleNextStep();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: buttonTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                currentStep == 3
                                    ? 'Completa Ordine'
                                    : 'Continua',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPersonalInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        defaultPadding,
        defaultPadding,
        defaultPadding,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? defaultPadding + 20
            : defaultPadding,
      ),
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerTypeSelector(),
            const SizedBox(height: 24),
            if (_customerType == CustomerType.private)
              _buildPrivateCustomerForm()
            else
              _buildBusinessCustomerForm(),
            SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom > 0 ? 100 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTypeSelector() {
    return _buildFormCard([
      const Row(
        children: [
          Icon(Icons.account_circle_outlined, color: primaryColor, size: 24),
          SizedBox(width: 12),
          Text(
            'Tipo di acquisto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _customerType = CustomerType.private;
                    _isBusiness = false;
                    _needInvoice = false;
                    _clearBusinessFields();
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _customerType == CustomerType.private
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: _customerType == CustomerType.private
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Privato',
                        style: TextStyle(
                          color: _customerType == CustomerType.private
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: _customerType == CustomerType.private
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _customerType = CustomerType.business;
                    _isBusiness = true;
                    _needInvoice = true;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _customerType == CustomerType.business
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: _customerType == CustomerType.business
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Azienda',
                        style: TextStyle(
                          color: _customerType == CustomerType.business
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: _customerType == CustomerType.business
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _customerType == CustomerType.private
            ? 'Acquisto come persona fisica'
            : 'Acquisto aziendale con fattura e partita IVA',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Widget _buildPrivateCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedSectionHeader('Dati Personali', Icons.person),
        const SizedBox(height: defaultPadding),
        _buildFormCard([
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _firstNameController,
                  label: 'Nome',
                  icon: Icons.person_outline,
                  onChanged: (value) => _updateFullName(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il nome';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _lastNameController,
                  label: 'Cognome',
                  icon: Icons.person_outline,
                  onChanged: (value) => _updateFullName(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci cognome';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Email nascosta - viene presa automaticamente dal profilo utente
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _phoneController,
            label: 'Telefono',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocusNode,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci telefono';
              }
              if (!cellRegExp.hasMatch(value)) {
                return 'Numero non valido';
              }
              return null;
            },
          ),
        ]),
        const SizedBox(height: 20),
        _buildInvoiceOptionForPrivate(),
      ],
    );
  }

  Widget _buildBusinessCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedSectionHeader('Dati Aziendali', Icons.business),
        const SizedBox(height: defaultPadding),
        _buildFormCard([
          _buildEnhancedTextField(
            controller: _businessNameController,
            label: 'Ragione Sociale *',
            icon: Icons.business_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return kRSocNullError;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _partitaIvaController,
            label: 'Partita IVA / Codice Fiscale *',
            icon: Icons.numbers,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              final upperValue = value.toUpperCase();
              _partitaIvaController.text = upperValue;
              _partitaIvaController.selection = TextSelection.fromPosition(
                  TextPosition(offset: upperValue.length));
              setState(() {
                _isValidPIva = partitaIvaRegExp.hasMatch(value) ||
                    cFRegExp.hasMatch(value);
                _requireCodUnivoco = partitaIvaRegExp.hasMatch(value);
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return kPIVANullError;
              }
              if (!partitaIvaRegExp.hasMatch(value) &&
                  !cFRegExp.hasMatch(value)) {
                return kInvalidPIvaError;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_partitaIvaController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isValidPIva ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isValidPIva
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isValidPIva ? Icons.check_circle : Icons.info,
                    color: _isValidPIva ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isValidPIva
                          ? (partitaIvaRegExp
                                  .hasMatch(_partitaIvaController.text)
                              ? 'Partita IVA valida - Richiesto codice univoco'
                              : 'Codice fiscale valido')
                          : 'Formato non riconosciuto come P.IVA o C.F.',
                      style: TextStyle(
                        color: _isValidPIva
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_requireCodUnivoco) ...[
            _buildEnhancedTextField(
              controller: _codiceUnivocaController,
              label: 'Codice Univoco (SDI) *',
              icon: Icons.qr_code,
              textCapitalization: TextCapitalization.characters,
              hintText: 'es: 0000000, XXXXXXX',
              onChanged: (value) {
                _codiceUnivocaController.text = value.toUpperCase();
              },
              validator: (value) {
                if (_requireCodUnivoco &&
                    (value == null || value.trim().isEmpty)) {
                  return kCodUniNullError;
                }
                if (value != null && value.isNotEmpty) {
                  if (value.length != 7) {
                    return 'Codice univoco deve essere di 7 caratteri';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _firstNameController,
                  label: 'Referente Nome *',
                  icon: Icons.person_outline,
                  onChanged: (value) => _updateFullName(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci nome referente';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _lastNameController,
                  label: 'Cognome *',
                  icon: Icons.person_outline,
                  onChanged: (value) => _updateFullName(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci cognome';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Email aziendale nascosta - viene presa automaticamente dal profilo utente
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _phoneController,
                  label: 'Telefono *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci telefono';
                    }
                    if (!cellRegExp.hasMatch(value)) {
                      return 'Numero non valido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _pecController,
                  label: 'PEC (opzionale)',
                  icon: Icons.mark_email_read_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'azienda@pec.it',
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'PEC non valida';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 20),
        _buildBusinessInvoiceInfo(),
      ],
    );
  }

  Widget _buildInvoiceOptionForPrivate() {
    return _buildFormCard([
      CheckboxListTile(
        value: _needInvoice,
        onChanged: (bool? value) {
          setState(() {
            _needInvoice = value ?? false;
          });
        },
        title: const Text('Richiedi fattura'),
        subtitle:
            const Text('Per acquisti detraibili come spese professionali'),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: primaryColor,
      ),
      if (_needInvoice) ...[
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildEnhancedTextField(
          controller: _partitaIvaController,
          label: 'Partita IVA / Codice Fiscale *',
          icon: Icons.numbers,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            final upperValue = value.toUpperCase();
            _partitaIvaController.text = upperValue;
            setState(() {
              _isValidPIva =
                  partitaIvaRegExp.hasMatch(value) || cFRegExp.hasMatch(value);
            });
          },
          validator: (value) {
            if (_needInvoice && (value == null || value.trim().isEmpty)) {
              return kPIVANullError;
            }
            if (value != null && value.isNotEmpty) {
              if (!partitaIvaRegExp.hasMatch(value) &&
                  !cFRegExp.hasMatch(value)) {
                return kInvalidPIvaError;
              }
            }
            return null;
          },
        ),
        if (_needInvoice &&
            partitaIvaRegExp.hasMatch(_partitaIvaController.text)) ...[
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _codiceUnivocaController,
            label: 'Codice Univoco SDI',
            icon: Icons.qr_code,
            textCapitalization: TextCapitalization.characters,
            hintText: '0000000 (se non hai uno specifico)',
            validator: (value) {
              if (_needInvoice &&
                  partitaIvaRegExp.hasMatch(_partitaIvaController.text)) {
                if (value == null || value.trim().isEmpty) {
                  return 'Codice univoco richiesto per P.IVA';
                }
              }
              return null;
            },
          ),
        ],
      ],
    ]);
  }

  Widget _buildBusinessInvoiceInfo() {
    return _buildFormCard([
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informazioni Fatturazione',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• La fattura elettronica verrà emessa entro 24 ore\n'
              '• Riceverai una copia via email\n'
              '• Se hai una PEC, la fattura sarà inviata anche lì\n'
              '• I prezzi mostrati sono IVA esclusa per aziende',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  void _updateFullName() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    _nameController.text = '$firstName $lastName'.trim();
  }

  void _clearBusinessFields() {
    _businessNameController.clear();
    _partitaIvaController.clear();
    _codiceUnivocaController.clear();
    _pecController.clear();
    _sdiController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _nameController.clear();
    _isValidPIva = false;
    _requireCodUnivoco = false;
  }

  Widget _buildEnhancedOrderSummary(CartProvider cartProvider, double total,
      double shippingCost, double finalTotal) {
    final double ivaRate = 0.22;
    final double totalNoIva = _isBusiness ? total / (1 + ivaRate) : total;
    final double ivaAmount = _isBusiness ? total - totalNoIva : 0;
    final double finalTotalNoIva =
        _isBusiness ? finalTotal / (1 + ivaRate) : finalTotal;
    final double finalIvaAmount =
        _isBusiness ? finalTotal - finalTotalNoIva : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedSectionHeader('Riepilogo Ordine', Icons.receipt_long),
          const SizedBox(height: defaultPadding),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isBusiness ? Colors.blue.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isBusiness ? Colors.blue.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isBusiness ? Icons.business : Icons.person,
                  color: _isBusiness
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBusiness ? 'Acquisto Aziendale' : 'Acquisto Privato',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isBusiness
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        _isBusiness
                            ? 'Prezzi mostrati IVA esclusa'
                            : (_needInvoice
                                ? 'Con richiesta fattura'
                                : 'Senza fattura'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isBusiness
                              ? Colors.blue.shade600
                              : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.06).round()),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Per marketplace usa il prodotto passato, altrimenti usa il carrello
                if (widget.isMarketplace && widget.marketplaceProduct != null)
                  _buildOrderItem(
                    widget.marketplaceProduct!.name,
                    widget.marketplaceQuantity ?? 1,
                    widget.marketplaceProduct!.price,
                  )
                else
                  ...cartProvider.items.values.map((item) =>
                      _buildOrderItem(item.title, item.quantity, item.price)),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_isBusiness) ...[
                        _buildPriceRow('Subtotale (IVA escl.)', totalNoIva),
                        _buildPriceRow('Spedizione (IVA escl.)',
                            shippingCost / (1 + ivaRate)),
                        const Divider(height: 20),
                        _buildPriceRow('Totale (IVA escl.)', finalTotalNoIva),
                        _buildPriceRow('IVA 22%', finalIvaAmount),
                        const Divider(height: 20),
                        _buildPriceRow('Totale (IVA incl.)', finalTotal,
                            isTotal: true),
                      ] else ...[
                        _buildPriceRow('Subtotale', total),
                        _buildPriceRow('Spedizione', shippingCost),
                        if (_needInvoice) ...[
                          const Divider(height: 20),
                          _buildPriceRow(
                              'IVA inclusa',
                              ivaAmount > 0
                                  ? ivaAmount
                                  : finalTotal * 0.22 / 1.22),
                        ],
                        const Divider(height: 20),
                        _buildPriceRow('Totale', finalTotal, isTotal: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String title, int quantity, double price) {
    final double displayPrice = _isBusiness ? price / 1.22 : price;
    final double totalItemPrice = displayPrice * quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qtà: $quantity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (_isBusiness) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'IVA escl.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '€${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '€${totalItemPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? secondaryColor : kTextColor,
            ),
          ),
          Container(
            padding: isTotal
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : null,
            decoration: isTotal
                ? BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Text(
              '€${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? buttonTextColor : secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSaveOptions() {
    return _buildFormCard([
      CheckboxListTile(
        value: _saveThisAddress,
        onChanged: (bool? value) {
          setState(() {
            _saveThisAddress = value ?? false;
          });
        },
        title: const Text('Salva questo indirizzo'),
        subtitle: const Text('Per riutilizzarlo nei prossimi ordini'),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: primaryColor,
      ),
      if (_saveThisAddress) ...[
        const SizedBox(height: 12),
        _buildEnhancedTextField(
          controller: TextEditingController()..text = _addressNickname,
          label: 'Nome per questo indirizzo (opzionale)',
          icon: Icons.label_outlined,
          onChanged: (value) => _addressNickname = value,
          hintText: 'es: Casa, Ufficio, Lavoro',
        ),
      ],
      const Divider(height: 32),
      CheckboxListTile(
        value: _useAsBilling,
        onChanged: (bool? value) {
          setState(() {
            _useAsBilling = value ?? true;
          });
        },
        title: const Text('Usa come indirizzo di fatturazione'),
        subtitle: Text(
          _useAsBilling
              ? 'I dati di spedizione verranno usati anche per la fatturazione'
              : 'Potrai inserire un indirizzo di fatturazione diverso',
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: primaryColor,
      ),
    ]);
  }

  Widget _buildSavedAddressesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.06).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.bookmark_outlined, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Indirizzi Salvati',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_savedAddresses.length, (index) {
            final address = _savedAddresses[index];
            final isSelected = _selectedAddress == address;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                selected: isSelected,
                selectedTileColor: primaryColor.withAlpha((255 * 0.05).round()),
                leading: CircleAvatar(
                  backgroundColor:
                      isSelected ? primaryColor : Colors.grey.shade200,
                  child: Icon(
                    Icons.location_on,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                title: Text(
                  address['nickname'] ?? 'Indirizzo ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : secondaryColor,
                  ),
                ),
                subtitle: Text(
                  '${address['address1']}\n${address['city']}, ${address['postalCode']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'select') {
                      _selectSavedAddress(address);
                    } else if (value == 'delete') {
                      _deleteAddress(index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 8),
                          Text('Seleziona'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Elimina', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => _selectSavedAddress(address),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEnhancedShippingInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        defaultPadding,
        defaultPadding,
        defaultPadding,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? defaultPadding + 20
            : defaultPadding,
      ),
      child: Form(
        key: _shippingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedSectionHeader(
                'Indirizzo di Spedizione', Icons.location_on),
            const SizedBox(height: defaultPadding),
            if (_savedAddresses.isNotEmpty) ...[
              _buildSavedAddressesSection(),
              const SizedBox(height: 24),
            ],
            _buildFormCard([
              GooglePlacesAutoCompleteTextFormField(
                textEditingController: _addressController,
                config: const GoogleApiConfig(
                  apiKey: "AIzaSyCZiS2tq8NWe-f0XO6eU7D1ZQhSnujZa-A",
                  debounceTime: 600,
                  countries: ["it"],
                ),
                textInputAction: TextInputAction.next,
                onSuggestionClicked: (prediction) {
                  _addressController.text = prediction.description ?? '';
                  _addressController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _addressController.text.length),
                  );
                  // Auto-compila città, CAP e provincia dopo selezione
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _geocodeAddress(_addressController.text);
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci indirizzo';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Via e Numero Civico',
                  hintText: 'Inizia a digitare...',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
                  ),
                  suffixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: errorColor),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: errorColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                predictionsStyle: const TextStyle(
                  color: secondaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overlayContainerBuilder: (child) => Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: child,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildEnhancedTextField(
                controller: _address2Controller,
                label: 'Interno, Piano, Scala (opzionale)',
                icon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildEnhancedTextField(
                      controller: _cityController,
                      label: 'Città',
                      icon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Inserisci città';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedTextField(
                      controller: _postalCodeController,
                      label: 'CAP',
                      icon: Icons.markunread_mailbox_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      textInputAction: TextInputAction.done,
                      focusNode: _postalCodeFocusNode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'CAP richiesto';
                        }
                        if (value.length != 5) {
                          return 'CAP non valido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedTextField(
                      controller: _stateController,
                      label: 'Provincia',
                      icon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedTextField(
                      controller: _countryController,
                      label: 'Paese',
                      icon: Icons.flag_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Paese richiesto';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildEnhancedTextField(
                controller: _notesController,
                label: 'Note per la consegna',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 20),
            _buildAddressSaveOptions(),
            const SizedBox(height: 24),
            _buildShippingMethodsSection(),
            SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom > 0 ? 100 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedSectionHeader(
            'Metodo di Spedizione', Icons.local_shipping),
        const SizedBox(height: defaultPadding),
        ...['standard', 'express', 'free'].map((method) {
          final titles = {
            'standard': 'Spedizione Standard',
            'express': 'Spedizione Express',
            'free': 'Ritiro in Negozio'
          };
          final subtitles = {
            'standard': 'Consegna in 3-5 giorni lavorativi',
            'express': 'Consegna in 1-2 giorni lavorativi',
            'free': 'Disponibile dal giorno successivo'
          };
          final costs = {'standard': 5.99, 'express': 12.99, 'free': 0.0};
          final icons = {
            'standard': Icons.local_shipping,
            'express': Icons.flash_on,
            'free': Icons.store
          };

          return _buildEnhancedShippingOption(
            method,
            titles[method]!,
            subtitles[method]!,
            costs[method]!,
            icons[method]!,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.06).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(largePadding),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildEnhancedProgressIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey.shade200,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      ((currentStep + 1) / 4) * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: primaryGradient,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isProgressBarExpanded = !_isProgressBarExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Step ${currentStep + 1}/4',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isProgressBarExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isProgressBarExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildEnhancedProgressStep('1', 'Riepilogo',
                              Icons.receipt_long, currentStep >= 0),
                          Expanded(child: Container()),
                          _buildEnhancedProgressStep(
                              '2', 'Dati', Icons.person, currentStep >= 1),
                          Expanded(child: Container()),
                          _buildEnhancedProgressStep('3', 'Spedizione',
                              Icons.local_shipping, currentStep >= 2),
                          Expanded(child: Container()),
                          _buildEnhancedProgressStep('4', 'Pagamento',
                              Icons.payment, currentStep >= 3),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressStep(
      String number, String label, IconData icon, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isActive ? primaryGradient : null,
              color: !isActive ? Colors.grey.shade200 : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryColor.withAlpha((255 * 0.2).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isActive
                  ? Icon(icon, color: buttonTextColor, size: 18)
                  : Text(
                      number,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? secondaryColor : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    if (_orderStatus != null) {
      return _buildOrderStatusFeedback();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha((255 * 0.2).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Elaborazione in corso...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: secondaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendi mentre completiamo il tuo ordine',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kSecondaryTextColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusFeedback() {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    switch (_orderStatus) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusTitle = 'Ordine completato!';
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusTitle = 'Errore';
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_outlined;
        statusTitle = 'Attenzione';
        break;
      case 'refreshing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusTitle = 'Sincronizzazione';
        break;
      case 'completing':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        statusTitle = 'Finalizzazione';
        break;
      default:
        statusColor = secondaryColor;
        statusIcon = Icons.info_outline;
        statusTitle = 'Stato ordine';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withAlpha((255 * 0.2).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            statusTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 8),
          if (_orderMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _orderMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kSecondaryTextColor,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(CartProvider cartProvider, double total,
      double shippingCost, double finalTotal) {
    switch (currentStep) {
      case 0:
        return _buildEnhancedOrderSummary(
            cartProvider, total, shippingCost, finalTotal);
      case 1:
        return _buildEnhancedPersonalInfo();
      case 2:
        return _buildEnhancedShippingInfo();
      case 3:
        return _buildEnhancedPaymentMethod(finalTotal);
      default:
        return Container();
    }
  }

  Widget _buildEnhancedShippingOption(
      String value, String title, String subtitle, double cost, IconData icon) {
    final isSelected = _selectedShippingMethod == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withAlpha((255 * 0.1).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedShippingMethod,
        onChanged: (String? newValue) {
          setState(() {
            _selectedShippingMethod = newValue!;
          });
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withAlpha((255 * 0.1).round())
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? primaryColor : Colors.grey.shade600,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primaryColor : secondaryColor,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 52, top: 4),
          child: Text(
            cost == 0.0 ? 'Gratuito' : '€${cost.toStringAsFixed(2)}',
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEnhancedPaymentMethod(double finalTotal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedSectionHeader('Metodo di Pagamento', Icons.payment),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.06).round()),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF635BFF).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Stripe_Logo%2C_revised_2016.svg/512px-Stripe_Logo%2C_revised_2016.svg.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.payment,
                      color: Color(0xFF635BFF),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paga con Stripe',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Carta di credito/debito, Apple Pay, Google Pay',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: Colors.green[600],
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.06).round()),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(largePadding),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _acceptTerms
                            ? primaryColor.withAlpha((255 * 0.3).round())
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                        HapticFeedback.lightImpact();
                      },
                      title: const Text(
                        'Accetto i termini e condizioni',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: GestureDetector(
                        onTap: () => _showTermsDialog(),
                        child: Text(
                          'Leggi i termini di servizio e la privacy policy',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      activeColor: primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withAlpha((255 * 0.1).round()),
                          kPrimaryLightColor.withAlpha((255 * 0.3).round()),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withAlpha((255 * 0.2).round()),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    primaryColor.withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: secondaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Riepilogo Finale',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    primaryColor.withAlpha((255 * 0.3).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '€${finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: buttonTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pagamento sicuro con SSL',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha((255 * 0.3).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: buttonTextColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.description, color: primaryColor, size: 20),
              SizedBox(width: 12),
              Text('Termini e Condizioni'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Termini di Servizio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Il pagamento viene elaborato in modo sicuro tramite Stripe\n'
                  '• I prodotti vengono preparati freschi al momento dell\'ordine\n'
                  '• Le consegne vengono effettuate negli orari specificati\n'
                  '• È possibile cancellare l\'ordine entro 10 minuti dalla conferma',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• I tuoi dati personali sono protetti e crittografati\n'
                  '• Utilizziamo i tuoi dati solo per elaborare l\'ordine\n'
                  '• Non condividiamo le tue informazioni con terze parti\n'
                  '• Puoi richiedere la cancellazione dei tuoi dati in qualsiasi momento',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _processStripePayment() async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Estrai i valori dei controller PRIMA di qualsiasi operazione async
      // per evitare errori se il widget viene disposed durante l'operazione
      final name = _nameController.text;
      final email = _emailController.text;
      final phone = _phoneController.text;
      final address = _addressController.text;
      final city = _cityController.text;
      final postalCode = _postalCodeController.text;

      // Se è un ordine marketplace, usa l'endpoint specifico
      late final http.Response response;
      if (widget.isMarketplace && widget.marketplaceProduct != null) {
        // Per marketplace, usa il prodotto passato come parametro
        final productId = widget.marketplaceProduct!.id;
        final quantity = widget.marketplaceQuantity ?? 1;

        final orderData = {
          'line_items': [
            {
              'product_id': productId,
              'quantity': quantity,
            }
          ],
          'payment_method': 'stripe',
          'payment_method_title': 'Carta di credito',
          'set_paid': false,
          'billing': {
            'first_name': name.split(' ').first,
            'last_name': name.split(' ').length > 1
                ? name.split(' ').skip(1).join(' ')
                : '',
            'address_1': address,
            'city': city,
            'postcode': postalCode,
            'country': 'IT',
            'email': email,
            'phone': phone,
          },
          'shipping': {
            'first_name': name.split(' ').first,
            'last_name': name.split(' ').length > 1
                ? name.split(' ').skip(1).join(' ')
                : '',
            'address_1': address,
            'city': city,
            'postcode': postalCode,
            'country': 'IT',
          },
        };

        final orderApi = OrderApi();
        final marketplaceResponse =
            await orderApi.createMarketplacePaymentIntent(productId, orderData);

        if (marketplaceResponse == null || marketplaceResponse.statusCode != 200) {
          throw Exception('Errore nella creazione del PaymentIntent marketplace');
        }
        response = marketplaceResponse;
      } else {
        // Ordine normale
        response = await CartApi().createOrderOnly();
        if (response.statusCode != 200) {
          throw Exception('Errore nella creazione del PaymentIntent');
        }
      }

      final paymentData = json.decode(response.body);

      final billingDetails = BillingDetails(
        name: name,
        email: email,
        phone: phone,
        address: Address(
          city: city,
          country: 'IT',
          line1: address,
          postalCode: postalCode,
          line2: '',
          state: '',
        ),
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentData['clientSecret'],
          merchantDisplayName: 'RestAll',
          customerId: paymentData['customer'],
          customerEphemeralKeySecret: paymentData['ephemeralKey'],
          style: ThemeMode.light,
          billingDetails: billingDetails,
          allowsDelayedPaymentMethods: true,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'IT',
            currencyCode: 'EUR',
            testEnv: false,
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'IT',
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Per ordini marketplace, il pagamento è completato e l'ordine è già gestito dal backend
      if (widget.isMarketplace) {
        // NON svuotare il carrello per ordini marketplace
        // perché il prodotto non è stato aggiunto al carrello persistente

        setState(() {
          _orderStatus = 'success';
          _orderMessage = 'Il tuo ordine marketplace è stato completato con successo!\n'
              'Payment Intent: ${paymentData['paymentIntent']}\n'
              'Riceverai una conferma via email.';
        });

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          await _completeOrder();
        }
      } else {
        // Ordine normale - crea l'ordine su WooCommerce
        final orderApi = OrderApi();

        final orderData = {
          'payment_method': 'stripe',
          'payment_method_title': 'Carta di credito',
          'set_paid': true,
          'billing': {
            'first_name': _nameController.text.split(' ').first,
            'last_name': _nameController.text.split(' ').skip(1).join(' '),
            'address_1': _addressController.text,
            'city': _cityController.text,
            'postcode': _postalCodeController.text,
            'country': 'IT',
            'email': _emailController.text,
            'phone': _phoneController.text,
          },
          'shipping': {
            'first_name': _nameController.text.split(' ').first,
            'last_name': _nameController.text.split(' ').skip(1).join(' '),
            'address_1': _addressController.text,
            'city': _cityController.text,
            'postcode': _postalCodeController.text,
            'country': 'IT',
          },
          'line_items': cartProvider.items.values
              .map((item) => {
                    'product_id': int.tryParse(item.id) ?? 0,
                    'quantity': item.quantity,
                    'name': item.title,
                    'price': item.price.toString(),
                  })
              .toList(),
          'shipping_lines': [
            {
              'method_id': 'flat_rate',
              'method_title': 'Spedizione standard',
              'total': '0.00',
            }
          ],
          'meta_data': [
            {
              'key': 'stripe_payment_intent_id',
              'value': _extractPaymentIntentId(paymentData['clientSecret']),
            },
            {
              'key': 'payment_processed_via',
              'value': 'restall_app',
            }
          ],
        };

        final orderResponse = await orderApi.createOrder(orderData);

        if (orderResponse?.statusCode == 201) {
          final createdOrder = json.decode(orderResponse!.body);

          await cartProvider.clearCart();

          setState(() {
            _orderStatus = 'success';
            _orderMessage = 'Il tuo ordine è stato completato con successo!\n'
                'Ordine ID: ${createdOrder['id']}\n'
                'Totale: €${createdOrder['total']} ${createdOrder['currency']?.toUpperCase() ?? 'EUR'}';
          });

          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            await _completeOrder();
          }
        } else {
          setState(() {
            _orderStatus = 'error';
            _orderMessage =
                'Pagamento completato con successo ma errore nella creazione dell\'ordine.\n'
                'Contatta il supporto con il Payment Intent: ${_extractPaymentIntentId(paymentData['clientSecret'])}';
          });
        }
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return;
      }

      setState(() {
        _orderStatus = 'error';
        _orderMessage = 'Errore nel pagamento: ${e.error.localizedMessage}';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _orderStatus = null;
            _orderMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _orderStatus = 'error';
        _orderMessage = 'Errore: $e';
      });
    }
  }

  Future<void> _processPayPalPayment() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (DateTime.now().millisecond % 10 != 0) {
        setState(() {
          _orderStatus = 'success';
          _orderMessage = 'Pagamento PayPal completato con successo!';
        });

        await Future.delayed(const Duration(seconds: 3));
        await _completeOrder();
      } else {
        throw Exception('Errore di connessione con PayPal');
      }
    } catch (e) {
      setState(() {
        _orderStatus = 'error';
        _orderMessage = 'Errore PayPal: ${e.toString()}';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _orderStatus = null;
            _orderMessage = null;
          });
        }
      });
    }
  }

  Future<void> _completeOrder() async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (mounted) {
        setState(() {
          _orderStatus = 'completing';
          _orderMessage = 'Finalizzazione ordine in corso...';
        });
      }

      bool cartCleared = false;
      try {
        await cartProvider.clearCart();
        cartCleared = true;
      } catch (e) {
        try {
          await cartProvider.clearCart();
          cartCleared = true;
        } catch (localError) {
          cartCleared = false;
        }
      }

      if (mounted) {
        setState(() {
          _orderStatus = 'success';
          _orderMessage = cartCleared
              ? 'Ordine completato con successo!'
              : 'Ordine completato! Il carrello verrà sincronizzato al prossimo accesso.';
        });
      }

      await Future.delayed(Duration(milliseconds: cartCleared ? 500 : 1000));

      if (!mounted) return;

      await Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const SideBar(initialTabIndex: 6);
          },
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          settings: const RouteSettings(name: '/sidebar_shop'),
        ),
        (route) => false,
      );

      if (!cartCleared) {
        _attemptBackgroundCartSync(cartProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orderStatus = 'warning';
          _orderMessage = 'Ordine creato correttamente!\n'
              'Potrebbe esserci un problema con la sincronizzazione del carrello.\n'
              'Verifica i tuoi ordini nella sezione Shop.';
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const SideBar(initialTabIndex: 6),
              ),
              (route) => false,
            );
          }
        });
      }
    }
  }

  void _attemptBackgroundCartSync(CartProvider cartProvider) {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await cartProvider.syncCartFromServer();
      } catch (e) {
        // Non è critico
      }
    });
  }

  void _handleNextStep() async {
    if (_isLoading) return;

    if (currentStep == 1) {
      if (!_personalInfoFormKey.currentState!.validate()) {
        _showMessage('Completa tutti i campi obbligatori',
            backgroundColor: errorColor);
        return;
      }

      if (_isBusiness) {
        if (_businessNameController.text.trim().isEmpty) {
          _showMessage('Ragione sociale richiesta per acquisti aziendali',
              backgroundColor: errorColor);
          return;
        }
        if (_requireCodUnivoco &&
            _codiceUnivocaController.text.trim().isEmpty) {
          _showMessage('Codice univoco SDI richiesto per questa P.IVA',
              backgroundColor: errorColor);
          return;
        }
      }

      if (!_isBusiness &&
          _needInvoice &&
          _partitaIvaController.text.trim().isEmpty) {
        _showMessage('P.IVA/C.F. richiesti per emettere fattura',
            backgroundColor: errorColor);
        return;
      }
    } else if (currentStep == 2) {
      if (!_shippingFormKey.currentState!.validate()) {
        _showMessage('Completa l\'indirizzo di spedizione',
            backgroundColor: errorColor);
        return;
      }

      if (_saveThisAddress) {
        final addressToSave = _getCurrentShippingAddress();
        if (_isBusiness) {
          addressToSave['business_name'] = _businessNameController.text;
          addressToSave['is_business'] = true;
        }
        await _saveAddress(addressToSave);
        _showMessage('Indirizzo salvato!', backgroundColor: Colors.green);
      }
    } else if (currentStep == 3) {
      if (!_acceptTerms) {
        _showMessage('Accetta i termini per continuare',
            backgroundColor: errorColor);
        return;
      }
    }

    if (currentStep < 3) {
      setState(() {
        currentStep++;
        _animationController.forward(from: 0);
        _progressController.forward(from: 0);
      });
    } else {
      try {
        await _processBusinessPayment();
      } catch (e) {
        _showMessage('Errore durante il pagamento: $e');
      }
    }
  }

  Future<void> _processBusinessPayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      // Estrai i valori dei controller PRIMA di qualsiasi operazione async
      // per evitare errori se il widget viene disposed durante l'operazione
      final businessName = _businessNameController.text;
      final name = _nameController.text;
      final email = _emailController.text;
      final phone = _phoneController.text;
      final address = _addressController.text;
      final address2 = _address2Controller.text;
      final city = _cityController.text;
      final postalCode = _postalCodeController.text;
      final country = _countryController.text;
      final state = _stateController.text;

      // Se è un ordine marketplace, usa l'endpoint specifico
      late final http.Response response;
      if (widget.isMarketplace && widget.marketplaceProduct != null) {
        // Per marketplace, usa il prodotto passato come parametro
        final productId = widget.marketplaceProduct!.id;
        final quantity = widget.marketplaceQuantity ?? 1;

        final orderData = {
          'line_items': [
            {
              'product_id': productId,
              'quantity': quantity,
            }
          ],
          'payment_method': 'stripe',
          'payment_method_title': 'Carta di credito',
          'set_paid': false,
          'billing': {
            'first_name': _isBusiness
                ? businessName.split(' ').first
                : name.split(' ').first,
            'last_name': _isBusiness
                ? (businessName.split(' ').length > 1
                    ? businessName.split(' ').skip(1).join(' ')
                    : '')
                : (name.split(' ').length > 1
                    ? name.split(' ').skip(1).join(' ')
                    : ''),
            'address_1': address,
            'city': city,
            'postcode': postalCode,
            'country': country,
            'email': email,
            'phone': phone,
          },
          'shipping': {
            'first_name': _isBusiness
                ? businessName.split(' ').first
                : name.split(' ').first,
            'last_name': _isBusiness
                ? (businessName.split(' ').length > 1
                    ? businessName.split(' ').skip(1).join(' ')
                    : '')
                : (name.split(' ').length > 1
                    ? name.split(' ').skip(1).join(' ')
                    : ''),
            'address_1': address,
            'city': city,
            'postcode': postalCode,
            'country': country,
          },
        };

        final orderApi = OrderApi();
        final marketplaceResponse =
            await orderApi.createMarketplacePaymentIntent(productId, orderData);

        if (marketplaceResponse == null || marketplaceResponse.statusCode != 200) {
          throw Exception('Errore nella creazione del PaymentIntent marketplace');
        }
        response = marketplaceResponse;
      } else {
        // Ordine normale
        response = await CartApi().createOrderOnly();
        if (response.statusCode != 200) {
          throw Exception('Errore nella creazione del PaymentIntent');
        }
      }

      final paymentData = json.decode(response.body);

      final billingDetails = BillingDetails(
        name: _isBusiness ? businessName : name,
        email: email,
        phone: phone,
        address: Address(
          city: city,
          country: country,
          line1: address,
          line2: address2,
          postalCode: postalCode,
          state: state,
        ),
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentData['clientSecret'],
          merchantDisplayName: 'RestAll',
          customerId: paymentData['customer'],
          customerEphemeralKeySecret: paymentData['ephemeralKey'],
          style: ThemeMode.light,
          billingDetails: billingDetails,
          allowsDelayedPaymentMethods: true,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'IT',
            currencyCode: 'EUR',
            testEnv: false,
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'IT',
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Per ordini marketplace, il pagamento è completato e l'ordine è già gestito dal backend
      if (widget.isMarketplace) {
        setState(() {
          _isLoading = false;
          _orderStatus = 'success';
          _orderMessage = 'Il tuo ordine marketplace è stato completato con successo!\n'
              'Payment Intent: ${paymentData['paymentIntent']}\n'
              'Riceverai una conferma via email.';
        });

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          await _completeOrder();
        }
      } else {
        // Ordine normale - crea l'ordine su WooCommerce
        final orderApi = OrderApi();

        final orderData = _buildBusinessOrderData(cartProvider, paymentData);

        final orderResponse = await orderApi.createOrder(orderData);

        if (orderResponse?.statusCode == 201) {
          final createdOrder = json.decode(orderResponse!.body);
          await _completeBusinessOrder(cartProvider, createdOrder);
        } else {
          throw Exception('Errore nella creazione dell\'ordine business');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _orderStatus = 'error';
        _orderMessage = 'Errore nel pagamento business: $e';
      });
    }
  }

  Map<String, dynamic> _buildBusinessOrderData(
      CartProvider cartProvider, Map<String, dynamic> paymentData) {
    final bool isBusinessOrder = _isBusiness || _needInvoice;

    final billingData = {
      'first_name': _isBusiness
          ? 'Amministratore'
          : _nameController.text.split(' ').first,
      'last_name': _isBusiness
          ? _businessNameController.text
          : _nameController.text.split(' ').skip(1).join(' '),
      'company': _isBusiness ? _businessNameController.text : '',
      'address_1': _addressController.text,
      'address_2': _address2Controller.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'postcode': _postalCodeController.text,
      'country': _countryController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
    };

    final shippingData = _useAsBilling
        ? billingData
        : {
            'first_name': _nameController.text.split(' ').first,
            'last_name': _nameController.text.split(' ').skip(1).join(' '),
            'company': _isBusiness ? _businessNameController.text : '',
            'address_1': _addressController.text,
            'address_2': _address2Controller.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'postcode': _postalCodeController.text,
            'country': _countryController.text,
          };

    final List<Map<String, dynamic>> metaData = [
      {
        'key': 'stripe_payment_intent_id',
        'value': _extractPaymentIntentId(paymentData['clientSecret']),
      },
      {
        'key': 'payment_processed_via',
        'value': 'restall_app_business',
      },
      {
        'key': 'customer_type',
        'value': _isBusiness ? 'business' : 'private',
      },
      {
        'key': 'invoice_required',
        'value': isBusinessOrder ? 'yes' : 'no',
      },
    ];

    if (_partitaIvaController.text.isNotEmpty) {
      metaData.add({
        'key': 'partita_iva',
        'value': _partitaIvaController.text,
      });

      if (partitaIvaRegExp.hasMatch(_partitaIvaController.text)) {
        metaData
            .add({'key': 'vat_number', 'value': _partitaIvaController.text});
        metaData.add({'key': 'is_vat_exempt', 'value': 'no'});
      } else {
        metaData.add({'key': 'tax_code', 'value': _partitaIvaController.text});
      }
    }

    if (_codiceUnivocaController.text.isNotEmpty) {
      metaData.add({
        'key': 'codice_univoco_sdi',
        'value': _codiceUnivocaController.text,
      });
    }

    if (_pecController.text.isNotEmpty) {
      metaData.add({
        'key': 'pec_email',
        'value': _pecController.text,
      });
    }

    if (_isBusiness) {
      metaData.add({
        'key': 'business_name',
        'value': _businessNameController.text,
      });
    }

    final lineItems = cartProvider.items.values
        .map((item) => {
              'product_id': int.tryParse(item.id) ?? 0,
              'quantity': item.quantity,
              'name': item.title,
              'price': item.price.toString(),
            })
        .toList();

    return {
      'payment_method': 'stripe',
      'payment_method_title': 'Carta di credito/debito',
      'set_paid': true,
      'billing': billingData,
      'shipping': shippingData,
      'line_items': lineItems,
      'customer_note': _buildCustomerNote(),
      'shipping_lines': [
        {
          'method_id': 'flat_rate',
          'method_title': _getShippingMethodTitle(),
          'total': _getShippingCost().toStringAsFixed(2),
        }
      ],
      'meta_data': metaData,
      'status': 'processing',
    };
  }

  String _extractPaymentIntentId(String clientSecret) {
    return clientSecret.split('_secret_').first;
  }

  String _buildCustomerNote() {
    final List<String> notes = [];

    if (_isBusiness) {
      notes.add('ORDINE AZIENDALE');
      notes.add('Ragione Sociale: ${_businessNameController.text}');
      notes.add('P.IVA: ${_partitaIvaController.text}');

      if (_codiceUnivocaController.text.isNotEmpty) {
        notes.add('Codice Univoco SDI: ${_codiceUnivocaController.text}');
      }

      if (_pecController.text.isNotEmpty) {
        notes.add('PEC: ${_pecController.text}');
      }
    } else if (_needInvoice) {
      notes.add('RICHIESTA FATTURA');
      notes.add('P.IVA/CF: ${_partitaIvaController.text}');

      if (_codiceUnivocaController.text.isNotEmpty) {
        notes.add('Codice Univoco: ${_codiceUnivocaController.text}');
      }
    }

    if (_notesController.text.isNotEmpty) {
      notes.add('Note consegna: ${_notesController.text}');
    }

    return notes.join('\n');
  }

  String _getShippingMethodTitle() {
    switch (_selectedShippingMethod) {
      case 'express':
        return 'Spedizione Express';
      case 'free':
        return 'Ritiro in Negozio';
      default:
        return 'Spedizione Standard';
    }
  }

  Future<void> _completeBusinessOrder(
      CartProvider cartProvider, Map<String, dynamic> createdOrder) async {
    try {
      setState(() {
        _orderStatus = 'success';
        _orderMessage = _buildSuccessMessage(createdOrder);
      });

      await cartProvider.clearCart();

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const SideBar(initialTabIndex: 6);
          },
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          settings: const RouteSettings(name: '/sidebar_business_orders'),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _orderStatus = 'warning';
        _orderMessage =
            'Ordine creato ma potrebbero esserci problemi con la sincronizzazione.\n'
            'Controlla i tuoi ordini nella sezione dedicata.';
      });
    }
  }

  String _buildSuccessMessage(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? 'N/A';
    final total = order['total']?.toString() ?? '0.00';
    final currency = (order['currency']?.toString() ?? 'EUR').toUpperCase();

    if (_isBusiness) {
      return '🏢 Ordine Aziendale Completato!\n\n'
          'Ordine ID: #$orderId\n'
          'Totale: €$total $currency\n'
          'Azienda: ${_businessNameController.text}\n'
          'P.IVA: ${_partitaIvaController.text}\n\n'
          '📧 La fattura elettronica sarà emessa entro 24 ore\n'
          '📋 Riceverai conferma via email';
    } else if (_needInvoice) {
      return '📄 Ordine con Fattura Completato!\n\n'
          'Ordine ID: #$orderId\n'
          'Totale: €$total $currency\n'
          'P.IVA/CF: ${_partitaIvaController.text}\n\n'
          '📧 La fattura sarà inviata via email';
    } else {
      return '✅ Ordine Completato con Successo!\n\n'
          'Ordine ID: #$orderId\n'
          'Totale: €$total $currency\n\n'
          '📦 Riceverai aggiornamenti via email';
    }
  }

  void _goToPreviousStep() {
    if (_isLoading) return;
    setState(() {
      if (currentStep > 0) {
        currentStep--;
        _animationController.forward(from: 0);
        _progressController.forward(from: 0);
      }
    });
  }

  double _getShippingCost() {
    switch (_selectedShippingMethod) {
      case 'express':
        return 12.99;
      case 'free':
        return 0.0;
      case 'standard':
      default:
        return 5.99;
    }
  }

  // Metodo per tentare refresh manuale del carrello
  void _attemptManualCartRefresh() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      _orderStatus = 'refreshing';
      _orderMessage = 'Sincronizzazione carrello...';
    });

    try {
      await cartProvider.syncCartFromServer();
      setState(() {
        _orderStatus = 'success';
        _orderMessage = 'Carrello sincronizzato con successo!';
      });

      // Attendi un attimo e vai alla sidebar
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const SideBar(initialTabIndex: 6),
            ),
            (route) => false,
          );
        }
      });
    } catch (e) {
      setState(() {
        _orderStatus = 'error';
        _orderMessage = 'Errore durante la sincronizzazione: ${e.toString()}';
      });
    }
  }
}
