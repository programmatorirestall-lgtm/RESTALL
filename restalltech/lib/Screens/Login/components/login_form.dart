import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:restalltech/API/FireBase/firebase.dart';
import 'package:restalltech/API/LoginRequest/login.dart';
import 'package:restalltech/Screens/ForgotPassword/forgot_password.dart';
import 'package:restalltech/Screens/SideBar/sidebar.dart';
import 'package:restalltech/components/form_error.dart';
import 'package:restalltech/helper/keyboard.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';

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

  _login() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'type': _stateValue,
        'email': emailController.text,
        'password': passController.text,
      };

      int status = await LoginApi().postData(data);
      print(status);
      if (status == 200) {
        setState(() => _isLoading = false);
        if (!Platform.isWindows) {
          await FireBaseApi().initNotifications();
        }
        TextInput.finishAutofillContext(shouldSave: true);
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return const SideBar();
          },
        ), ModalRoute.withName("../"));
      } else {
        setState(() => _isLoading = false);
        addError(error: "Credenziali errate");
      }
    } on SocketException catch (e) {
      print("ci ho provato" + e.toString());
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
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  // void setButton() {
  //   if (isEnabled) {
  //     isEnabled = false;
  //   } else {
  //     isEnabled = true;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            userType(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: buildEmailFormField(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ForgotPasswordScreen();
                      },
                    ),
                  ),
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
      autofillHints: [AutofillHints.password],
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
            color: secondaryColor,
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

  DropdownButtonFormField<String> userType() {
    return DropdownButtonFormField(
      hint: Text('Utente'),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.flag_rounded),
        ),
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
      dropdownColor: kPrimaryLightColor,
      value: _stateValue,
      validator: (_dropdownValue) {
        if (_dropdownValue == null) {
          return kTypeUserNullError;
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _stateValue = newValue!;
        });
      },
      onTap: () {
        return null;
      },
      items: <String>['Admin', 'Tech']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value.toLowerCase(),
          child: Text(
            value,
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
        );
      }).toList(),
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
