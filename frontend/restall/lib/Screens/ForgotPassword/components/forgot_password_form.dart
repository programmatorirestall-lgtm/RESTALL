import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restall/API/LoginRequest/login.dart';
import 'package:restall/API/Logout/logout.dart';
import 'package:restall/API/User/user.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/components/form_error.dart';
import 'package:restall/helper/keyboard.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Signup/signup_screen.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
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

  _restore_password() async {
    setState(() => _isLoading = true);
    try {
      var data = {
        'type': "user",
        'email': emailController.text,
      };

      Response response = await UserApi().restorePassword(data);
      if (response.statusCode == 200) {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Recupero Password',
          text:
              'È stata inviata una mail di recupero password al tuo indirizzo.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
      } else {
        setState(() => _isLoading = false);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Recupero Password',
          text: 'È stato impossibile recuperare password.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
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
                          _restore_password();
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
                    : const Icon(Icons.restore_rounded),
                label: const Text('RECUPERA PASSWORD'),
              ),
            ),
            const SizedBox(height: defaultPadding),
          ],
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
