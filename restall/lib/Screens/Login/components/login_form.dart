import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restall/API/FireBase/firebase.dart';
import 'package:restall/API/LoginRequest/login.dart';
import 'package:restall/API/Logout/logout.dart';
import 'package:restall/Screens/ForgotPassword/forgot_password.dart';
import 'package:restall/Screens/Login/login_screen.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/components/form_error.dart';
import 'package:restall/helper/keyboard.dart';
import 'package:restall/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Signup/signup_screen.dart';
import 'package:mailto/mailto.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<StatefulWidget> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? email;
  String? password;
  bool _passwordVisible = false;
  bool remember = false;
  final List<String?> errors = [];
  String? _stateValue;
  bool isEnabled = true;
  var _isLoading = false;

  void addError({String? error}) {
    if (!errors.contains(error)) {
      setState(() {
        errors.add(error);
      });
    }
  }

  void removeError({String? error}) {
    if (errors.contains(error)) {
      setState(() {
        errors.remove(error);
      });
    }
  }
// Sostituisci il metodo _login in login_form.dart

  _login() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'type': "user",
        'email': emailController.text,
        'password': passController.text,
      };

      Response response = await LoginApi().postData(data);

      if (response.statusCode == 200) {
        var body = await json.decode(response.body);
        var user = body['user'];

        if (user['verified'] == true) {
          // 🔥 INIZIALIZZAZIONE FIREBASE CON GESTIONE ERRORI ROBUSTA
          if (Platform.isAndroid || Platform.isIOS) {
            try {
              print("🔥 Inizializzazione Firebase Messaging...");
              await FireBaseApi().initNotifications();
              print("✅ Firebase Messaging configurato");
            } catch (firebaseError) {
              // ⚠️ NON BLOCCARE IL LOGIN per errori Firebase
              print("⚠️ Errore Firebase (continuo il login): $firebaseError");

              // Log più dettagliato per debug
              if (firebaseError.toString().contains('APNS')) {
                print("🔧 Errore APNS rilevato - probabilmente emulatore iOS");
              }

              // 📊 TRACKING: Potresti volere inviare questo errore ad analytics
              // Analytics.logEvent('firebase_init_error', {'error': firebaseError.toString()});
            }
          }

          TextInput.finishAutofillContext(shouldSave: true);
          setState(() => _isLoading = false);

          print('✅ Login completato con successo, navigazione a SideBar...');

          // NAVIGAZIONE OTTIMIZZATA: usa transizione fluida e pulisci lo stack
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const SideBar();
                },
                transitionDuration: const Duration(milliseconds: 700),
                reverseTransitionDuration: const Duration(milliseconds: 400),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Combinazione di fade e slide per transizione fluida
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve:
                          const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.2, 1.0,
                            curve: Curves.easeOutCubic),
                      )),
                      child: child,
                    ),
                  );
                },
                settings: const RouteSettings(name: '/sidebar'),
              ),
              (route) => false, // Rimuovi tutto lo stack precedente
            );
          }
        } else {
          // Utente non verificato
          setState(() => _isLoading = false);
          TextInput.finishAutofillContext(shouldSave: false);
          LogoutApi().logout();
          FlutterPlatformAlert.showAlert(
            windowTitle: 'Verifica la tua email',
            text: 'Per accedere verifica la tua email',
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.information,
          );
        }
      } else {
        // Credenziali errate
        setState(() => _isLoading = false);
        addError(error: "Credenziali errate");
      }
    } on SocketException catch (e) {
      // Errore di connessione
      print("❌ Errore di connessione: ${e.toString()}");
      setState(() => _isLoading = false);
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Errore di connessione',
        text:
            'Connessione al server non riuscita. Controlla la connessione Internet e riprova.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    } catch (e) {
      // Altri errori generici
      print("❌ Errore generico login: $e");
      setState(() => _isLoading = false);

      // 🔥 NON MOSTRARE errori Firebase all'utente - sono tecnici
      if (!e.toString().toLowerCase().contains('firebase') &&
          !e.toString().toLowerCase().contains('apns')) {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Errore',
          text: 'Si è verificato un errore durante il login. Riprova.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.error,
        );
      } else {
        // Per errori Firebase, silenzioso log ma procedi
        print("🔥 Errore Firebase ignorato nell'UI: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            buildEmailFormField(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: buildPasswordFromField(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: FormError(errors: errors),
            ),
            const SizedBox(height: defaultPadding),
            Hero(
              tag: "login_btn",
              child: ElevatedButton.icon(
                //onPressed: _isLoading: null ? _onSubmit,
                onPressed: !_isLoading
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // if all are valid then go to success screen
                          KeyboardUtil.hideKeyboard(context);
                          _login();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0)),
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('ACCEDI'),
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Password Dimenticata? ",
                  style: const TextStyle(color: kPrimaryColor),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, ForgotPasswordScreen.routeName),
                  child: Text(
                    "Recuperala",
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            AlreadyHaveAnAccountCheck(
              press: () => Navigator.pushNamed(context, SignUpScreen.routeName),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Hai bisogno di assistenza? Contattaci via ",
                  style: const TextStyle(color: kPrimaryColor),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final mailtoLink = Mailto(
                          to: ['customer-service@restall.it'],
                          subject: 'Richiesta di assistenza',
                        );

                        await launchUrlString('$mailtoLink');
                      },
                      child: Text(
                        "Mail ",
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "o ",
                      style: const TextStyle(color: kPrimaryColor),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await launchUrlString("https://wa.me/+393515134500");
                      },
                      child: Text(
                        "WhatsApp",
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextFormField buildPasswordFromField() {
    return TextFormField(
      controller: passController,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      obscureText: !_passwordVisible,
      cursorColor: kPrimaryColor,
      onEditingComplete: () {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          // if all are valid then go to success screen

          _login();
        }
        KeyboardUtil.hideKeyboard(context);
      },
      onTap: () => removeError(error: "Credenziali errate"),
      onSaved: (newValue) => password = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kPassNullError;
        } else if (value.length < 8) {
          return kShortPassError;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: const Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.lock),
        ),
        suffixIcon: IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          icon: Icon(
            // Based on passwordVisible state choose the icon
            !_passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).primaryColorDark,
          ),
          onPressed: () {
            // Update the state i.e. toogle the state of passwordVisible variable
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
    );
  }

  TextFormField buildEmailFormField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r"\s\b|\b\s"))],
      textInputAction: TextInputAction.next,
      autofillHints: [AutofillHints.email],
      cursorColor: kPrimaryColor,
      onTap: () => removeError(error: "Credenziali errate"),
      onSaved: (newValue) => email = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kEmailNullError;
        } else if (!emailValidatorRegExp.hasMatch(value)) {
          return kEmailNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Email",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.person),
        ),
      ),
    );
  }
}
