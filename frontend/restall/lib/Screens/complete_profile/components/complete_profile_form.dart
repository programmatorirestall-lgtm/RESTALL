import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import 'package:restall/API/SignUpRequest/signup.dart';
import 'package:restall/Screens/Login/login_screen.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/Screens/otp/otp_screen.dart';
import 'package:restall/components/form_error.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/keyboard.dart';
import 'package:restall/helper/keyboardoverlay.dart';
import 'package:restall/helper/sc.dart';
import 'package:restall/widget/date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

class CompleteProfileForm extends StatefulWidget {
  final String? referralCode;

  const CompleteProfileForm({super.key, this.referralCode});

  @override
  _CompleteProfileFormState createState() => _CompleteProfileFormState();
}

class _CompleteProfileFormState extends State<CompleteProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String?> errors = [];
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cfController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  String? firstName;
  String? lastName;
  String? ref;
  String? phoneNumber;
  String? address;
  String? cf;
  DateTime? date;
  FocusNode numberFocusNode = FocusNode();
  bool isEnabled = true;
  var _isLoading = false;
  bool cU = false;
  bool _isSeller = false; // Flag per diventare venditore

  void addError({String? error}) {
    if (!errors.contains(error))
      setState(() {
        errors.add(error);
      });
  }

  void removeError({String? error}) {
    if (errors.contains(error))
      setState(() {
        errors.remove(error);
      });
  }

  void _loadReferral() async {
    try {
      final uri = await AppLinks().getInitialLink();
      if (uri != null && uri.path == '/invite') {
        final refCode = uri.queryParameters['ref'];
        if (refCode != null) {
          setState(() {
            _refController.text = refCode;
          });
        }
      }
    } catch (_) {}
  }

  _signup() async {
    setState(() => _isLoading = true);
    try {
      final _prefs = await SharedPreferences.getInstance();
      var _jwt;
      if (_prefs.getString('jwt') != null) {
        _jwt = Jwt.parseJwt(_prefs.getString('jwt') as String);
      } else {
        return null;
      }
      final tok = context.read<MySensitiveDataProvider>();

      //print(tok.sensitiveData);
      //print(_jwt['password']);
      var data = {
        'type': "user",
        'email': _jwt['email'],
        'password': tok.sensitiveData,
        'nome': _firstNameController.text,
        'cognome': _lastNameController.text,
        'dataNascita': _dateController.text,
        'codFiscale': _cfController.text,
        'numTel': _phoneNumberController.text,
        'parentReferral': _refController.text,
        'isSeller': _isSeller
      };
      //print(jsonEncode(data));
      int status = await SignupApi().patchDataSecond(data);
      if (status == 201) {
        // ignore: use_build_context_synchronously
        setState(() => _isLoading = false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt');
        await prefs.remove('cookie');
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return LoginScreen();
          },
        ), (route) => false);
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Account Registrato',
          text: 'Per accedere verifica la tua mail',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
      } else {
        setState(() => _isLoading = false);
        // await _prefs.setString('jwt', "");
        // await _prefs.setString('cookie', "");
        //await _prefs.clear();
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
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      numberFocusNode.addListener(() {
        bool hasFocus = numberFocusNode.hasFocus;
        if (hasFocus) {
          KeyboardOverlay.showOverlay(context);
        } else {
          KeyboardOverlay.removeOverlay();
        }
      });
    }
    if (widget.referralCode != null) {
      _refController.text = widget.referralCode!;
    } else {
      _loadReferral();
    }
    if (widget.referralCode != null) {
      _refController.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    // Clean up the focus node
    numberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildFirstNameFormField(),
          const SizedBox(height: 30),
          buildLastNameFormField(),
          const SizedBox(height: 30),
          pIvaFormField(),
          const SizedBox(height: 30),
          buildDateFormField(),
          const SizedBox(height: 30),
          buildPhoneNumberFormField(),
          const SizedBox(height: 30),
          buildRefFormField(),
          const SizedBox(height: 20),
          buildSellerCheckbox(),
          FormError(errors: errors),
          const SizedBox(height: 30),
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
        ],
      ),
    );
  }

  TextFormField buildAddressFormField() {
    return TextFormField(
      controller: _addressController,
      textInputAction: TextInputAction.next,
      onSaved: (newValue) => address = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kAddressNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Indirizzo",
        hintText: "Inserisci il tuo indirizzo",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.location_city_rounded),
      ),
    );
  }

  TextFormField buildPhoneNumberFormField() {
    return TextFormField(
      controller: _phoneNumberController,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.phone,
      onSaved: (newValue) => phoneNumber = newValue,
      focusNode: numberFocusNode,
      onChanged: (value) {
        if (value.isNotEmpty) {
          removeError(error: kPhoneNumberNullError);
        }
        return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kPhoneNumberNullError;
        } else if (value.length < 10 ||
            (value.length > 13 && value.startsWith("+"))) {
          return kShortPassError;
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Cellulare",
        hintText: "Inserisci il tuo numero",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.phone_iphone_rounded),
      ),
    );
  }

  Column buildRefFormField() {
    return Column(
      children: [
        TextFormField(
          controller: _refController,
          textInputAction: TextInputAction.next,
          onSaved: (newValue) => ref = newValue,
          onChanged: (value) {
            if (value.isNotEmpty) return null;
          },
          decoration: const InputDecoration(
            labelText: "Referral",
            hintText: "Inserisci il codice referral",
            // If  you are using latest version of flutter then lable text and hint text shown like this
            // if you r using flutter less then 1.20.* then maybe this is not working properly
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(Icons.person_rounded),
          ),
        ),
        Text(
          "Sei stato invitato da un amico? Inserisci il suo codice referral, rispettando le maiuscole e le minuscole.",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  TextFormField buildLastNameFormField() {
    return TextFormField(
      controller: _lastNameController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      onSaved: (newValue) => lastName = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kLNameNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Cognome",
        hintText: "Inserisci il tuo cognome",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.person_rounded),
      ),
    );
  }

  TextFormField buildCFFormField() {
    return TextFormField(
      controller: _cfController,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      onSaved: (newValue) => cf = newValue,
      onChanged: (value) {
        _cfController.text = value.toUpperCase();
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        // if (value!.isEmpty) {
        //   return kCFNullError;
        // } else
        if (value == null) {
          setState(() {
            _cfController.text = " ";
          });
        }
        if (value!.isNotEmpty) {
          if (!cFRegExp.hasMatch(value)) {
            return kCheckCF;
          }
        }

        //return null;
      },
      decoration: const InputDecoration(
        labelText: "Codice Fiscale",
        hintText: "Inserisci il tuo CF",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.grid_3x3_rounded),
      ),
    );
  }

  pIvaFormField() {
    return TextFormField(
      controller: _cfController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      onSaved: (newValue) => cf = newValue,
      onChanged: (value) {
        _cfController.text = value.toUpperCase();
        if (partitaIvaRegExp.hasMatch(value)) {
          setState(() {
            cU = true;
          });
        } else {
          setState(() {
            cU = false;
          });
        }
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kPIVANullError;
        } else if (!partitaIvaRegExp.hasMatch(value) &&
            !cFRegExp.hasMatch(value)) {
          return kInvalidPIvaError;
        }
        return null;
      },
      cursorColor: kPrimaryColor,
      decoration: const InputDecoration(
        hintText: "Inserisci il Codice Fiscale o Partita IVA",
        labelText: "P. IVA/CF",
        prefixIcon: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Icon(Icons.numbers_rounded),
        ),
      ),
    );
  }

  TextFormField buildDateFormField() {
    return TextFormField(
      controller: _dateController,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      readOnly: true,
      onSaved: (newValue) => cf = newValue,
      onTap: () async {
        final DateTime? pickedDate = await datePickBirthDate(context);
        if (pickedDate != null) {
          String formattedDate =
              DateFormat('dd/MM/yyyy', 'it_IT').format(pickedDate);
          setState(() {
            _dateController.text = formattedDate;
          });
        }
      },
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return kDateNullError;
        }
        try {
          final birthDate = DateFormat('dd/MM/yyyy').parse(value);
          final today = DateTime.now();
          final age = today.year -
              birthDate.year -
              ((today.month > birthDate.month ||
                      (today.month == birthDate.month &&
                          today.day >= birthDate.day))
                  ? 0
                  : 1);
          if (age < 18) {
            return kAgeNullError;
          }
        } catch (e) {
          return "Formato data non valido (DD/MM/YYYY)";
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Data di nascita",
        hintText: "Inserisci la tua data di nascita",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.calendar_month_rounded),
      ),
    );
  }

  TextFormField buildFirstNameFormField() {
    return TextFormField(
      controller: _firstNameController,
      textInputAction: TextInputAction.next,
      onSaved: (newValue) => firstName = newValue,
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kFNameNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Nome",
        hintText: "Inserisci il tuo nome",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.person),
      ),
    );
  }

  Widget buildSellerCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CheckboxListTile(
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: kPrimaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Voglio diventare venditore',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 28.0),
          child: Text(
            'Potrai vendere i tuoi prodotti su RestAll dopo la verifica',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        value: _isSeller,
        onChanged: (value) {
          setState(() {
            _isSeller = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
