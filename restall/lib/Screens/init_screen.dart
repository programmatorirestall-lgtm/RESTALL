import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restall/API/LoginRequest/login.dart';
import 'package:restall/API/Renew%20Session/renew_session.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/Screens/complete_profile/complete_profile_screen.dart';
import 'package:restall/Screens/Welcome/welcome_screen.dart';
import 'package:restall/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restall/helper/user_id_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});
  static String routeName = "/init";

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  bool _isProfileComplete = false;
  String _statusMessage = "Inizializzazione...";

  String _appVersion = "Caricamento...";
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _setupAnimations();
    _loadPackageInfo();
    _startAuthCheck();
  }

  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion =
              "Versione ${_packageInfo!.version}+${_packageInfo!.buildNumber}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = "Versione 1.0.12+13"; // Fallback
        });
      }
    }
  }

  void _setupAnimations() {
    // Controller principale per il logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Controller per il pulse del logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller per i testi
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animazioni del logo
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _logoRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    // Animazione pulse continua
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animazioni del testo
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Avvia le animazioni
    _logoController.forward();

    // Pulse continuo dopo che il logo è apparso
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  Future<void> _startAuthCheck() async {
    // Attendi che le animazioni iniziali finiscano
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _statusMessage = "Controllo autenticazione...";
      });
      _fadeController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 600));
    await _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    if (!mounted) return;

    setState(() {
      _isCheckingAuth = true;
      _statusMessage = "Controllo autenticazione...";
    });

    try {
      // ✅ STEP 1: Verifica presenza token
      final prefs = await SharedPreferences.getInstance();
      final hasTokens = prefs.containsKey('jwt') && prefs.containsKey('cookie');

      if (!hasTokens) {
        print("⚠️ Token non presenti");
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _statusMessage = "Nessuna sessione attiva...";
          });
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _navigateToAppropriateScreen();
        return;
      }

      // ✅ STEP 2: Verifica validità sessione
      final sessionValid = await LoginApi().sessionState();

      if (sessionValid != true) {
        // Token presenti ma scaduti - prova a rinnovare
        print("🔄 Token scaduti, tento rinnovo...");

        if (mounted) {
          setState(() {
            _statusMessage = "Rinnovo sessione...";
          });
        }

        final renewSuccess = await RenewSessionApi().renew();

        if (renewSuccess?.statusCode == 200) {
          print("✅ Sessione rinnovata con successo");
          // Ricontrolla dopo il rinnovo
          final recheckValid = await LoginApi().sessionState();
          if (recheckValid == true) {
            await _proceedWithValidSession();
            return;
          }
        }

        // Rinnovo fallito, pulisci e vai al login
        print("❌ Impossibile rinnovare, redirect al login");
        await prefs.clear();

        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _statusMessage = "Sessione scaduta, effettua il login...";
          });
          await Future.delayed(const Duration(milliseconds: 800));
          _navigateToAppropriateScreen();
        }
        return;
      }

      // ✅ STEP 3: Sessione valida, procedi
      await _proceedWithValidSession();
    } catch (e) {
      print("❌ Errore durante il controllo autenticazione: $e");

      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _statusMessage = "Errore di connessione...";
        });
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _navigateToAppropriateScreen();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _proceedWithValidSession() async {
    if (mounted) {
      setState(() {
        _isAuthenticated = true;
        _statusMessage = "Verifica profilo...";
      });
    }

    // Verifica completezza profilo
    final userId = await UserIdHelper.getCurrentUserId();

    if (userId != null && userId.isNotEmpty) {
      final userInfo = await UserIdHelper.getUserInfoFromJwt();

      if (userInfo != null &&
          userInfo['nome'] != null &&
          userInfo['cognome'] != null) {
        if (mounted) {
          setState(() {
            _isProfileComplete = true;
            _statusMessage = "Accesso effettuato!";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = true; // ← Token validi
            _isProfileComplete = false; // ← Ma profilo incompleto
            _statusMessage = "Completa la registrazione...";
          });
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _navigateToAppropriateScreen();
  }

  void _navigateToAppropriateScreen() {
    Widget targetScreen;
    String routeName;

    if (_isAuthenticated) {
      if (_isProfileComplete) {
        targetScreen = const SideBar();
        routeName = SideBar.routeName;
      } else {
        targetScreen = const CompleteProfileScreen();
        routeName = CompleteProfileScreen.routeName;
      }
    } else {
      targetScreen = const WelcomeScreen();
      routeName = WelcomeScreen.routeName;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => targetScreen,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: _isAuthenticated
                    ? const Offset(0.0, 0.1)
                    : const Offset(0.0, -0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              secondaryColor, // Blu navy profondo
              Color.fromARGB(255, 48, 63, 159), // Blu più chiaro
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Particelle decorative di sfondo
              _buildBackgroundParticles(),

              // Contenuto principale
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animato RestAll
                    _buildAnimatedLogo(),

                    const SizedBox(height: 32),

                    // Nome app
                    _buildAppTitle(),

                    const SizedBox(height: 12),

                    // Sottotitolo
                    _buildSubtitle(),

                    const SizedBox(height: 80),

                    // Stato e progress
                    _buildStatusSection(),
                  ],
                ),
              ),

              // Footer con versione
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlesPainter(_logoController.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value *
              (_pulseController.status == AnimationStatus.dismissed
                  ? 1.0
                  : _pulseAnimation.value),
          child: Transform.rotate(
            angle: _logoRotateAnimation.value * 0.1, // Leggera rotazione
            child: FadeTransition(
              opacity: _logoFadeAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [white, white],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: white.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 60,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    return AnimatedBuilder(
      animation: _logoFadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _logoController,
              curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
            )),
            child: const Text(
              'RestAll',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _logoFadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _logoController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
            )),
            child: const Text(
              'Il tuo assistente di fiducia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return AnimatedBuilder(
      animation: _textFadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textFadeAnimation,
          child: SlideTransition(
            position: _textSlideAnimation,
            child: Column(
              children: [
                // Progress indicator moderno
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _isCheckingAuth
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        )
                      : Icon(
                          _isAuthenticated
                              ? Icons.check_circle_rounded
                              : Icons.login_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                ),

                const SizedBox(height: 16),

                // Messaggio di stato
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _logoFadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _logoFadeAnimation,
            child: Center(
              child: Text(
                _appVersion, // Usa la variabile dinamica invece del testo hardcoded
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter per le particelle di sfondo
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Crea particelle animate
    for (int i = 0; i < 15; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x = size.width * (0.1 + (i * 0.05) % 0.8);
      final y = size.height * (0.2 + progress * 0.6);
      final radius = 2.0 + (progress * 3);

      paint.color = primaryColor.withOpacity(0.1 * (1 - progress));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Particelle più grandi e meno frequenti
    for (int i = 0; i < 8; i++) {
      final progress = (animationValue * 0.7 + i * 0.15) % 1.0;
      final x = size.width * (0.15 + (i * 0.1) % 0.7);
      final y = size.height * (0.1 + progress * 0.8);
      final radius = 1.0 + (progress * 2);

      paint.color = Colors.white.withOpacity(0.05 * (1 - progress));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
