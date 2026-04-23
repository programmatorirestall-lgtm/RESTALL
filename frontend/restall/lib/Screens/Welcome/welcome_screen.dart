import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restall/API/LoginRequest/login.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/theme.dart';

import 'components/body.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static String routeName = "/welcome";

  @override
  State<StatefulWidget> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _checkAuthOnResume();
  }

  /// Controlla lo stato di autenticazione quando il WelcomeScreen viene mostrato
  /// Se l'utente è già loggato, reindirizza automaticamente alla SideBar
  Future<void> _checkAuthOnResume() async {
    if (_isCheckingAuth) return;

    setState(() {
      _isCheckingAuth = true;
    });

    try {
      final loginApi = LoginApi();
      final sessionState = await loginApi.sessionState();

      print('🔐 WelcomeScreen: Session state = $sessionState');

      if (sessionState == true && mounted) {
        // Utente già loggato, reindirizza alla SideBar
        print('✅ Utente già autenticato, reindirizzamento a SideBar...');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const SideBar(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
        return;
      }
    } catch (e) {
      print('❌ Errore controllo auth in WelcomeScreen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Previeni il back gesture se l'utente è in fase di controllo auth
      canPop: !_isCheckingAuth,
      onPopInvoked: (didPop) {
        if (didPop) {
          print('🔙 Back gesture su WelcomeScreen');
        }
      },
      child: Scaffold(
        body: _isCheckingAuth ? _buildAuthCheckingWidget() : const Body(),
      ),
    );
  }

  Widget _buildAuthCheckingWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Controllo autenticazione...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
