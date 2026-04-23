import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restall/API/Logout/logout.dart';
import 'package:restall/API/PhotoPic/photoPic.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/API/api_exceptions.dart';
import 'package:restall/Screens/Profits/profits_screen.dart';
import 'package:restall/Screens/Network/network.dart';
import 'package:restall/Screens/dashboard/dashboard_screen.dart';

import 'package:restall/Screens/OpenTicket/ticket_screen.dart';
import 'package:restall/Screens/Preventivi/preventivi.dart';
import 'package:restall/Screens/Welcome/welcome_screen.dart';
import 'package:restall/Screens/unified_tickets_screen.dart';
import 'package:restall/Screens/profile/profile_screen.dart';
import 'package:restall/Screens/shop/shop_screen.dart';
import 'package:restall/providers/ShopNavigation/shop_navigation_provider.dart';
import 'package:provider/provider.dart';

import 'package:restall/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key, this.initialTabIndex = 0});
  static String routeName = "/sidebar";
  final int initialTabIndex;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> with TickerProviderStateMixin {
  final _key = GlobalKey<ScaffoldState>();
  late final SidebarXController _controller;
  final RegExp cellRegExp = RegExp(r'^\+?[1-9]\d{1,14}$');

// Aggiungi questo getter pubblico
  SidebarXController get controller => _controller;
  final TextEditingController _numTelController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _title = "Apri Ticket";
  String _ragSoc = "";
  String _userType = "";
  String _userId = "";
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(
      selectedIndex: widget.initialTabIndex,
      extended: true,
    );
    _title = _getTitleByIndex(_controller.selectedIndex);
    _controller.addListener(_setTitle);

    // Aggiungi listener al ShopNavigationProvider per aggiornare il titolo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final shopNavProvider = Provider.of<ShopNavigationProvider>(context, listen: false);
          shopNavProvider.addListener(_setTitle);
        } catch (e) {
          // Provider non ancora disponibile
        }
      }
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.removeListener(_setTitle);

    // Rimuovi listener dal ShopNavigationProvider
    try {
      final shopNavProvider = Provider.of<ShopNavigationProvider>(context, listen: false);
      shopNavProvider.removeListener(_setTitle);
    } catch (e) {
      // Provider non disponibile
    }

    _numTelController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setTitle() {
    if (mounted) {
      setState(() {
        // Se siamo nella sezione Shop (index 6), usa il titolo dal provider
        if (_controller.selectedIndex == 6) {
          try {
            final shopNavProvider = Provider.of<ShopNavigationProvider>(context, listen: false);
            _title = shopNavProvider.currentShopSection;
          } catch (e) {
            // Fallback al titolo statico se il provider non è disponibile
            _title = _getTitleByIndex(_controller.selectedIndex);
          }
        } else {
          _title = _getTitleByIndex(_controller.selectedIndex);
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Carica token JWT
      await _loadTokenData();

      // Carica dati utente dall'API
      await _loadUserFromApi();

      // Controlla se serve aggiungere il numero di telefono
      _checkPhoneNumber();

      // Avvia animazione di fade in
      _fadeController.forward();
    } catch (e) {
      _showErrorAlert(
          'Si è verificato un errore durante il caricamento dei dati');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTokenData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    if (token != null && token.isNotEmpty) {
      try {
        final decodedToken = Jwt.parseJwt(token);
        final id = decodedToken['id']?.toString() ?? '';
        final tipo = decodedToken['type']?.toString() ?? '';

        if (mounted) {
          setState(() {
            _userType = tipo;
            _userId = id;
          });
        }
      } catch (e) {
        throw Exception('Errore decodifica token');
      }
    } else {
      throw Exception('Token non trovato');
    }
  }

  Future<void> _loadUserFromApi() async {
    try {
      final userProfile = await UserApi().getData();
      if (userProfile != null && mounted) {
        setState(() {
          _user = {
            'nome': userProfile.nome,
            'cognome': userProfile.cognome,
            'dataNascita': userProfile.dataNascita,
            'codFiscale': userProfile.codFiscale,
            'numTel': userProfile.numTel,
          };
          _ragSoc = userProfile.nome ?? '';
        });
      }
    } catch (e) {
      throw Exception('Errore caricamento dati utente');
    }
  }

  void _checkPhoneNumber() {
    if (_user != null &&
        (_user!['numTel'] == null || _user!['numTel'].toString().isEmpty)) {
      _showPhoneDialog();
    }
  }

  void _showPhoneDialog() {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Telefono',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Aggiungi il numero di telefono per continuare ad utilizzare l'app",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildPhoneNumberFormField(),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _updatePhoneNumber(),
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Aggiungi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _buildPhoneNumberFormField() {
    return TextFormField(
      controller: _numTelController,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return kPhoneNumberNullError;
        } else if (value.length < 10 ||
            (value.length > 13 && value.startsWith("+"))) {
          return kShortPassError;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: "Inserisci il tuo numero",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.phone_iphone_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: kPrimaryLightColor,
      ),
    );
  }

  Future<void> _updatePhoneNumber() async {
    if (_user == null) {
      _showErrorAlert('Dati utente non disponibili');
      return;
    }

    final phoneValue = _numTelController.text.trim();

    // Validazione lato client
    if (phoneValue.isEmpty) {
      _showErrorAlert(kPhoneNumberNullError);
      return;
    }

    if (!cellRegExp.hasMatch(phoneValue)) {
      _showErrorAlert(kInvalidCellError);
      return;
    }

    try {
      //print('📞 Aggiornamento numero telefono: $phoneValue per utente $_userId');

      // Usa il metodo specifico per aggiornamenti semplici
      final userApi = UserApi();
      final updatedProfile = await userApi.updateProfileData({
        'nome': _user!['nome'],
        'cognome': _user!['cognome'],
        'dataNascita': _user!['dataNascita'],
        'codFiscale': _user!['codFiscale'],
        'numTel': phoneValue,
      }, _userId);

      if (updatedProfile != null) {
        // Aggiorna i dati locali
        setState(() {
          _user!['numTel'] = phoneValue;
        });

        Navigator.of(context).pop();
        _showSuccessAlert('Numero aggiornato con successo!');
      }
    } on ApiException catch (e) {
      //print('❌ Errore API: ${e.message}');
      _showErrorAlert('Errore aggiornamento: ${e.message}');
    } catch (e) {
      //print('❌ Errore generico: $e');
      _showErrorAlert('Si è verificato un errore durante l\'aggiornamento');
    }
  }

  void _showErrorAlert(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore',
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }

  void _showSuccessAlert(String message) {
    FlutterPlatformAlert.showAlert(
      windowTitle: 'Successo',
      text: message,
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.exclamation,
    );
  }
// Sostituisci il metodo build() nella classe _SideBarState con questo:

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return PopScope(
      // Previeni il back gesture dalla SideBar per evitare di tornare al WelcomeScreen
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Invece del back normale, mostra dialog di conferma logout
          final shouldExit = await _showExitConfirmDialog(context);
          if (shouldExit == true) {
            await _performLogout(context);
          }
        }
      },
      child: Scaffold(
        key: _key,
        appBar: isSmallScreen
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
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
                title: Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                leading: IconButton(
                  color: Colors.white,
                  onPressed: () {
                    // Chiudi la tastiera prima di aprire il drawer
                    FocusScope.of(context).unfocus();
                    _key.currentState?.openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: primaryColor,
                  ),
                ),
              )
            : null,
        drawer: RestAllSidebarX(
          controller: _controller,
          ragSoc: _ragSoc,
          scaffoldKey: _key,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryLightColor,
                  Colors.white,
                ],
              ),
            ),
            child: Row(
              children: [
                if (!isSmallScreen)
                RestAllSidebarX(
                  controller: _controller,
                  ragSoc: _ragSoc,
                  scaffoldKey: _key,
                ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(isSmallScreen ? 0 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 0 : 20),
                    boxShadow: isSmallScreen
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 0 : 20),
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      child: _Screens(controller: _controller),
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: child,
                        );
                      },
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Aggiungi questi metodi helper per gestire l'exit

  Future<bool?> _showExitConfirmDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Uscire dall\'app?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        content: const Text(
          'Vuoi uscire dall\'applicazione e tornare alla schermata di login?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Esci',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Mostra loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logout in corso...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Esegui logout
      await LogoutApi().logout();

      // Chiudi loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Naviga alla WelcomeScreen con stack pulito
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const WelcomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Errore durante il logout: $e');

      // Chiudi loading dialog se ancora aperto
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostra errore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il logout. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RestAllSidebarX extends StatefulWidget {
  const RestAllSidebarX({
    Key? key,
    required this.controller,
    required this.ragSoc,
    required this.scaffoldKey,
  }) : super(key: key);

  final SidebarXController controller;
  final String ragSoc;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<RestAllSidebarX> createState() => _RestAllSidebarXState();
}

class _RestAllSidebarXState extends State<RestAllSidebarX>
    with TickerProviderStateMixin {
  String? _profileImageUrl;
  bool _isLoadingImage = false;
  late Timer _imageRefreshTimer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();

    // Carica l'immagine profilo all'avvio
    _loadProfileImage();

    // Configura un timer per aggiornare l'immagine periodicamente
    _imageRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadProfileImage();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _imageRefreshTimer.cancel();
    super.dispose();
  }

// Metodo migliorato per caricare l'immagine profilo
  Future<void> _loadProfileImage() async {
    if (mounted) {
      setState(() {
        _isLoadingImage = true;
      });
    }

    try {
      final response = await PhotoPicApi().getPhotoPic();
      if (response != null && response.statusCode == 200) {
        final body = json.decode(response.body);
        final img = body['file'];
        if (img != null && img['location'] != null) {
          final imageUrl = img['location'] as String;

          // Aggiorna la cache e forza il refresh
          final cacheManager = DefaultCacheManager();
          await cacheManager.removeFile(imageUrl);

          if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
              _isLoadingImage = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _profileImageUrl = null;
              _isLoadingImage = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _profileImageUrl = null;
            _isLoadingImage = false;
          });
        }
      }
    } catch (e) {
      print('Errore caricamento immagine sidebar: $e');
      if (mounted) {
        setState(() {
          _profileImageUrl = null;
          _isLoadingImage = false;
        });
      }
    }
  }

// Metodo pubblico per forzare l'aggiornamento dell'immagine (da chiamare dopo upload)
  void refreshProfileImage() {
    _loadProfileImage();
  }

// Avatar migliorato per la sidebar
  Widget _buildUserAvatar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.8),
                  primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              padding: const EdgeInsets.all(2),
              child: _buildAvatarContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarContent() {
    if (_isLoadingImage) {
      return _buildLoadingAvatar();
    }

    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.grey[50],
      backgroundImage: _getAvatarImageProvider(),
      child: _profileImageUrl == null ? _buildDefaultAvatarIcon() : null,
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.grey[100],
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),
          // Loading indicator
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                secondaryColor.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: secondaryColor.withOpacity(0.7),
      ),
    );
  }

  ImageProvider? _getAvatarImageProvider() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(
        _profileImageUrl!,
        headers: {
          'Cache-Control': 'no-cache',
        },
      );
    }
    return null;
  }

// Metodo per gestire gli errori di caricamento immagine
  Widget _buildErrorAvatar() {
    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.grey[100],
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

// Metodo migliorato per gestire il tap sull'avatar (opzionale)
  Widget _buildUserAvatarWithTap() {
    return GestureDetector(
      onTap: () {
        // Naviga al profilo quando si tocca l'avatar
        widget.controller.selectIndex(1); // Indice del profilo
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildUserAvatar(),
      ),
    );
  }

// Widget per l'indicatore di stato online (opzionale)
  Widget _buildOnlineIndicator() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: successColor,
          border: Border.all(
            color: white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

// Avatar completo con indicatore online
  Widget _buildCompleteUserAvatar() {
    return Stack(
      children: [
        _buildUserAvatarWithTap(),
        _buildOnlineIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: SidebarX(
          controller: widget.controller,
          showToggleButton: false,
          theme: SidebarXTheme(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color.fromARGB(255, 248, 250, 255),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            hoverColor: primaryColor.withOpacity(0.1),
            textStyle: const TextStyle(
              color: secondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            selectedTextStyle: const TextStyle(
              color: secondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            itemTextPadding: const EdgeInsets.only(left: 25),
            selectedItemTextPadding: const EdgeInsets.only(left: 25),
            itemDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.transparent),
            ),
            selectedItemDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.8),
                  primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            iconTheme: IconThemeData(
              color: secondaryColor.withOpacity(0.7),
              size: 22,
            ),
            selectedIconTheme: const IconThemeData(
              color: secondaryColor,
              size: 22,
            ),
          ),
          extendedTheme: SidebarXTheme(
            width: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color.fromARGB(255, 248, 250, 255),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          headerBuilder: (context, extended) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCompleteUserAvatar(), // Avatar migliorato
                    const SizedBox(height: 12),
                    _buildUserName(extended),
                    const SizedBox(height: 20),
                    _buildWelcomeMessage(extended),
                  ],
                ),
              ),
            );
          },
          items: _buildSidebarItems(context),
          footerBuilder: (context, extended) {
            final item = _buildLogoutItem(context);
            return Column(
              children: [
                ListTile(
                  leading: item.iconWidget,
                  title: Text(
                    item.label ?? '',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: item.onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hoverColor: Colors.red.withOpacity(0.08),
                ),
                SizedBox(
                  height: extended ? 25 : 0,
                ),
              ],
            );
          }),
    );
  }

  Widget _buildUserName(bool extended) {
    return AnimatedOpacity(
      opacity: extended ? 1.0 : 0.0,
      duration: Duration(milliseconds: extended ? 600 : 200),
      child: Text(
        widget.ragSoc,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: secondaryColor,
        ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWelcomeMessage(bool extended) {
    return AnimatedOpacity(
      opacity: extended ? 1.0 : 0.0,
      duration: Duration(milliseconds: extended ? 800 : 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimaryLightColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Text(
          'Benvenuto!',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<SidebarXItem> _buildSidebarItems(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.person_rounded, 'label': 'Profilo'},
      {'icon': Icons.confirmation_number_rounded, 'label': 'Gestione Ticket'},
      {'icon': Icons.handshake_rounded, 'label': 'Preventivi'},
      {'icon': Icons.euro_symbol_rounded, 'label': 'Profitti'},
      {'icon': Icons.diversity_3_rounded, 'label': 'Network'},
      {'icon': Icons.shopping_cart_rounded, 'label': 'Shop'},
    ];

    return [
      ...items.map((item) => SidebarXItem(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            onTap: () {
              widget.scaffoldKey.currentState?.closeDrawer();
              _showSelectionFeedback();
            },
          )),
    ];
  }

  void _showSelectionFeedback() {
    // Piccola vibrazione o animazione per feedback
    // Qui puoi aggiungere HapticFeedback se necessario
  }

  SidebarXItem _buildLogoutItem(BuildContext context) {
    return SidebarXItem(
      iconWidget: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.logout_rounded,
          color: Colors.red,
          size: 20,
        ),
      ),
      label: 'Esci',
      onTap: () => _handleLogout(context),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Mostra dialog di conferma con design migliorato
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Conferma Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
        content: const Text(
          'Sei sicuro di voler uscire dall\'applicazione?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await LogoutApi().logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        // Gestisci errore logout se necessario
      }
    }
  }
}

class _Screens extends StatelessWidget {
  const _Screens({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _getScreenByIndex(controller.selectedIndex),
        );
      },
    );
  }

  Widget _getScreenByIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ProfileScreen();
      case 2:
        return const UnifiedTicketsScreen(initialTabIndex: 0);
      case 3:
        return const PreventiviManager();
      case 4:
        return ProfitsScreen(); // NUOVA SCHERMATA PROFITTI
      case 5:
        return ReferralNetworkScreen();
      case 6:
        return ShopScreen();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _getTitleByIndex(index),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
    }
  }
}

String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Dashboard';
    case 1:
      return 'Profilo';
    case 2:
      return 'Gestione Ticket';
    case 3:
      return 'Preventivi';
    case 4:
      return 'I Miei Profitti'; // NUOVO TITOLO
    case 5:
      return 'Network';
    case 6:
      return 'Shop';
    default:
      return 'Pagina non trovata';
  }
}
