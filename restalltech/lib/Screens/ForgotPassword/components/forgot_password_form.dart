import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/User/user.dart';

import 'package:restalltech/components/form_error.dart';
import 'package:restalltech/helper/keyboard.dart';

import '../../../constants.dart';

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
        'type': _stateValue,
        'email': emailController.text,
      };

      Response response = await UserApi().restorePassword(data);
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
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
      print("ci ho provato");
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

  void _onSubmit() {
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      _restore_password();
    } else {
      setState(() => _isLoading = false);
    }
  }

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
              child: FormError(errors: errors),
            ),
            const SizedBox(height: defaultPadding),
            Hero(
              tag: "login_btn",
              child: ElevatedButton.icon(
                //onPressed: _isLoading: null ? _onSubmit,
                onPressed: !_isLoading
                    ? () {
                        _onSubmit();
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
                    : const Icon(Icons.check_rounded),
                label: const Text('Recupera Password'),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     if (_formKey.currentState!.validate()) {
              //       _formKey.currentState!.save();
              //       // if all are valid then go to success screen
              //       KeyboardUtil.hideKeyboard(context);
              //       _restore_password();
              //     }
              //   }, //keep this configuration. This denies to turn back to login
              //   child: Text(
              //     "Recupera Password".toUpperCase(),
              //   ),
              // ),
            ),
            const SizedBox(height: defaultPadding),
          ],
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
