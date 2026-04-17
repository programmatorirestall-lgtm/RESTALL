import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import 'package:restalltech/API/SignUpRequest/signup.dart';
import 'package:restalltech/Screens/AddTech/add_tech_screen.dart';
import 'package:restalltech/Screens/SideBar/sidebar.dart';
import 'package:restalltech/components/form_error.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/helper/keyboard.dart';
import 'package:restalltech/helper/keyboardoverlay.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AddTechForm extends StatefulWidget {
  const AddTechForm({super.key});

  @override
  _AddTechFormState createState() => _AddTechFormState();
}

class _AddTechFormState extends State<AddTechForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String?> errors = [];
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cfController = TextEditingController();
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? address;
  String? cf;
  String? email;
  String? password;
  DateTime? date;
  FocusNode numberFocusNode = FocusNode();
  bool _passwordVisible = false;

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

  var _isLoading = false;

  void _onSubmit() {
    setState(() => _isLoading = true);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // if all are valid then go to success screen
      KeyboardUtil.hideKeyboard(context);
      _signup();
    } else {
      setState(() => _isLoading = false);
    }
  }

  _signup() async {
    try {
      var data = {
        'type': "tech",
        'email': _emailController.text,
        'password': _passwordController.text,
        'nome': _firstNameController.text,
        'cognome': _lastNameController.text,
        'dataNascita': _dateController.text,
        'codFiscale': _cfController.text.toUpperCase()
      };
      print(data);
      Response response = await SignupApi().addTech(data);
      if (response.statusCode == 201) {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Tecnico creato con successo',
          text: '',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.exclamation,
        );
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return new AddTechScreen();
          },
        ), ModalRoute.withName("../"));
      } else {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'impossibile creare tecnico',
          text: 'Verifica che la mail non sia stata già utilizzataa.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.warning,
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
    _passwordVisible = false;
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
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Email",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildEmailFormField(),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Password",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildPasswordFromField(),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Nome",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildFirstNameFormField(),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Cognome",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildLastNameFormField(),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Codice Fiscale",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildCFFormField(),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Data di Nascita",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    )),
              )),
          buildDateFormField(),
          FormError(errors: errors),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _onSubmit,
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
                : const Icon(Icons.add_rounded),
            label: const Text('Crea Tecnico'),
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
        hintText: "Inserisci il cognome",
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
        if (value!.isEmpty) {
          return kCFNullError;
        } else if (!cFRegExp.hasMatch(value)) {
          return kCheckCF;
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Inserisci il CF",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.grid_3x3_rounded),
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
        await datePick(context);
      },
      onChanged: (value) {
        if (value.isNotEmpty) return null;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return kDateNullError;
        }
        return null;
      },
      decoration: const InputDecoration(
        hintText: "Inserisci data di nascita",
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
        hintText: "Inserisci nome",
        // If  you are using latest version of flutter then lable text and hint text shown like this
        // if you r using flutter less then 1.20.* then maybe this is not working properly
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(Icons.person),
      ),
    );
  }

  Future<void> datePick(BuildContext context) async {
    try {
      DateTime? pickedDate = await showDatePicker(
          context: context,
          locale: const Locale('it', 'EU'),
          initialDate: DateTime.now(),
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          errorFormatText: "Formato non valido",
          errorInvalidText: "Testo non valido",
          firstDate: DateTime(
              1900), //DateTime.now() - not to allow to choose before today.
          //lastDate: DateTime(2101)); //DateTime.now() - not to allow to choose before today.
          lastDate: DateTime.now());
      ThemeData(
          textTheme: const TextTheme(
              bodyLarge: TextStyle(
                  fontSize: 2.0), // <-- here you can do your font smaller
              bodyMedium: TextStyle(fontSize: 6.0)));

      if (pickedDate != null) {
        print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
        String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
        print(
            formattedDate); //formatted date output using intl package =>  2021-03-16
        //you can implement different kind of Date Format here according to your requirement

        setState(() {
          _dateController.text =
              formattedDate; //set output date to TextField value.
        });
      } else {
        print("Date is not selected");
      }
    } on FormatException {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Data errata',
        text:
            'Insersci la data dal calendario o utilizza il segeunte layout DD/MM/YYYY',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  TextFormField buildPasswordFromField() {
    return TextFormField(
      controller: _passwordController,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      obscureText: !_passwordVisible,
      cursorColor: kPrimaryColor,
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
      controller: _emailController,
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
