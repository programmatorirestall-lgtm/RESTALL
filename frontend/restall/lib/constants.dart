import 'package:flutter/material.dart';

// Colori principali migliorati
const kPrimaryColor = secondaryColor;
const kPrimaryLightColor = Color.fromARGB(255, 240, 245, 255);
const kBackgroundColor = Colors.white;

// Padding e dimensioni
const double defaultPadding = 16.0;
const double largePadding = 24.0;
const double smallPadding = 8.0;

// Palette colori moderna e accattivante
const primaryColor = Color.fromARGB(255, 255, 215, 0); // Oro vibrante
const secondaryColor = Color.fromARGB(255, 30, 41, 82); // Blu navy profondo
const selectedItemColor = Color.fromARGB(255, 20, 20, 20);
const canvasColor = Color.fromARGB(255, 255, 255, 255);
const scaffoldBackgroundColor = kPrimaryLightColor;
const accentCanvasColor = Color.fromARGB(255, 255, 193, 7);
const white = Colors.white;
const black = Colors.black;

// Colori di stato
const successColor = Color.fromARGB(255, 76, 175, 80);
const warningColor = Color.fromARGB(255, 255, 152, 0);
const errorColor = Color.fromARGB(255, 244, 67, 54);
const infoColor = Color.fromARGB(255, 33, 150, 243);

// Gradients
const primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryColor, accentCanvasColor],
);

const secondaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.fromARGB(255, 30, 41, 82),
    Color.fromARGB(255, 48, 63, 159),
  ],
);

const backgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryLightColor, Colors.white],
);

// Colori derivati
final appBarColor = secondaryColor.withOpacity(0.9);
final actionColor = primaryColor;
const kTextColor = Colors.black;
const kSecondaryTextColor = Color(0xFF4A4A4A); // miglior contrasto
const kLightTextColor = Color(0xFF6B6B6B); // miglior contrasto
const buttonTextColor = Colors.black; // contrasto su oro

// Timing delle animazioni
const defaultDuration = Duration(milliseconds: 300);
const fastDuration = Duration(milliseconds: 200);
const slowDuration = Duration(milliseconds: 500);

// Dimensioni
const double kToolbarHeight = 70.0;
const double kBottomNavigationBarHeight = 80.0;
const double kBorderRadius = 20.0;
const double kSmallBorderRadius = 10.0;
const double kLargeBorderRadius = 30.0;

// Shadows
const List<BoxShadow> kElevationToShadow = [
  BoxShadow(
    color: Color.fromARGB(25, 0, 0, 0),
    blurRadius: 8,
    offset: Offset(0, 4),
  ),
];

const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color.fromARGB(15, 0, 0, 0),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
];

const List<BoxShadow> kButtonShadow = [
  BoxShadow(
    color: Color.fromARGB(30, 0, 0, 0),
    blurRadius: 15,
    offset: Offset(0, 5),
  ),
];

final RegExp emailValidatorRegExp =
    RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

final RegExp cellRegExp =
    RegExp(r'^(?:\+39|0039)?(?:(?:0|1)\d{1})?(?:\d{9}|\d{10})$');
final RegExp partitaIvaRegExp = RegExp(r'^[0-9]{11}$');
final RegExp cFRegExp = RegExp(
    r'[A-Z]{6}[0-9LMNPQRSTUV]{2}[ABCDEHLMPRST]{1}[0-7LMNPQRST]{1}[0-9LMNPQRSTUV]{1}[A-Z]{1}[0-9LMNPQRSTUV]{3}[A-Z]{1}');
final RegExp passwordValidatorRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
//const String kInvalidPasswordError = "La password deve contenere almeno 8 caratteri, una maiuscola, una minuscola, un numero e un carattere speciale.";
const String kAgeNullError = "Devi avere almeno 18 anni per registrarti.";
const String kEmailNullError = "Inserisci una email valida";
const String kInvalidCellError = "Inserisci un numero valido";
const String kInvalidEmailError = "Inserisci una email valida";
const String kInvalidPIvaError = "Inserisci una P.IVA/CF valida";

const String kCodUniNullError = "Inserisci il codice univoco";
const String kPassNullError = "Inserisci la password";
const String kShortPassError = "Password troppo corta";
const String kCheckCF = "Verifica il tuo CF";
const String kMatchPassError = "Le password non corrispondono";
const String kCFNullError = "Inserisci il tuo CF";
const String kDateNullError = "Inserisci la data";
const String kFNameNullError = "Inserisci il nome";
const String kLNameNullError = "Inserisci il cognome";
const String kPhoneNumberNullError = "Inserisci il numero di telefono";
const String kPhoneNumberShortError = "Controlla il numero di telefono";
const String kAddressNullError = "Inserisci l'indirizzo";
const String kPIVANullError = "Inserisci la P. IVA/CF";
const String kCittaNullError = "Inserisci la Città";
const String kRSocNullError = "Inserisci la Rag. Sociale";
const String kRicambiNullError = "Inserisci il ricambio";
const String kOperatoreNullError = "Inserisci il nome dell'operatore";
const String kpzNullError = "Pz.";
const String kStateMNullError = "Seleziona lo stato della macchina";
const String kTypeMNullError = "Seleziona il tipo della macchina";
const String kTypeUserNullError = "Seleziona il tipo di utente";
const String kPaymentNullError = "Seleziona il tipo di pagamento";
const String kIvaNullError = "Seleziona la percentuale";
const String kAnagrafNullError = "Seleziona l'anagrafica";

const String gKey = "AIzaSyA2mOnCoT6Bu_lLqMiADHtf7bM7VNwlLEk";
