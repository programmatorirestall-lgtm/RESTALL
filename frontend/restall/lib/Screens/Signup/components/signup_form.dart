import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';
import 'package:restall/API/SignUpRequest/signup.dart';
import 'package:restall/Screens/Login/login_screen.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/Screens/complete_profile/complete_profile_screen.dart';
import 'package:restall/components/PasswordStrengthSlider.dart';
import 'package:restall/components/already_have_an_account_acheck.dart';
import 'package:restall/components/form_error.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/keyboard.dart';
import 'package:restall/helper/sc.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpForm extends StatefulWidget {
  final String? referralCode;

  const SignUpForm({super.key, this.referralCode});

  @override
  State<StatefulWidget> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController passConfController = TextEditingController();
  PasswordStrengthSlider? _passwordStrengthSlider;

  final _formKey = GlobalKey<FormState>();
  String? email;
  String? password;
  String? confPassword;
  bool _passwordVisible = false;
  bool remember = false;
  final List<String?> errors = [];
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

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  _signup() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'type': "user",
        'email': emailController.text,
        'password': passController.text,
      };

      int status = await SignupApi().postDataFirst(data);
      if (status == 201) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        final tok =
            Provider.of<MySensitiveDataProvider>(context, listen: false);
        tok.setSensitiveData(passController.text);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return CompleteProfileScreen(referralCode: widget.referralCode);
          },
        ), (route) => false);
      } else {
        setState(() => _isLoading = false);
        addError(error: "Impossibile creare l'account");
      }
    } on SocketException catch (e) {
      //print("ci ho provato");
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text:
            'Conessione al server non riuscita, controlla la connessione ad Internet.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildEmailFormField(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: buildPasswordFromField(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: buildConfirmPasswordFromField(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: FormError(errors: errors),
          ),
          const SizedBox(height: defaultPadding / 2),
          Hero(
            tag: "sign_up",
            child: ElevatedButton.icon(
              //onPressed: _isLoading: null ? _onSubmit,
              onPressed: !_isLoading
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // if all are valid then go to success screen
                        KeyboardUtil.hideKeyboard(context);
                        _signup();
                      }
                    }
                  : null,
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
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
              label: const Text('CONTINUA'),
            ),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () => Navigator.pushNamed(context, LoginScreen.routeName),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Registrandoti accetti ",
                style: const TextStyle(color: kPrimaryColor),
              ),
              GestureDetector(
                onTap: () async => await launchUrl(
                    Uri.parse("https://restall.it/termini-condizioni-restall/"),
                    mode: LaunchMode.inAppBrowserView),
                child: Text(
                  "Termini e Condizioni",
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Info sulla ",
                style: const TextStyle(color: kPrimaryColor),
              ),
              GestureDetector(
                onTap: () async => await launchUrl(
                    Uri.parse("https://restall.it/info-privacy-restall/"),
                    mode: LaunchMode.inAppBrowserView),
                child: Text(
                  "Privacy",
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextFormField buildConfirmPasswordFromField() {
    return TextFormField(
      controller: passConfController,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      obscureText: !_passwordVisible,
      cursorColor: kPrimaryColor,
      onTap: () {
        removeError(error: "Credenziali errate");
      },
      onSaved: (newValue) => password = newValue,
      onEditingComplete: () {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          // if all are valid then go to success screen
        }
        KeyboardUtil.hideKeyboard(context);
      },
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value.toString().compareTo(passController.text) != 0) {
          return kMatchPassError;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: "Conferma Password",
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

  buildPasswordFromField() {
    return Column(
      children: [
        TextFormField(
          controller: passController,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          obscureText: !_passwordVisible,
          cursorColor: kPrimaryColor,
          onTap: () => removeError(error: "Credenziali errate"),
          onSaved: (newValue) => confPassword = newValue,
          onChanged: (value) {
            // Aggiorna lo stato per ridisegnare lo slider
            setState(() {
              _passwordStrengthSlider = PasswordStrengthSlider(
                password: value,
                showLabel: true,
              );
            });
            if (value.isNotEmpty) return null;
          },
          validator: (value) {
            if (value!.isEmpty) {
              return kPassNullError;
            }

            // Usa il validator specifico del widget slider
            final slider =
                PasswordStrengthSlider(password: value, showLabel: false);
            final specificError = slider.getValidationError();

            if (specificError != null) {
              return specificError;
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
                !_passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).primaryColorDark,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
        ),

        // Slider di forza password
        _passwordStrengthSlider ??
            PasswordStrengthSlider(
              password: passController.text,
              showLabel: true,
            ),
      ],
    );
  }

  TextFormField buildEmailFormField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r"\s\b|\b\s"))],
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
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
