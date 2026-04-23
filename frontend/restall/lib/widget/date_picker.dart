import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:intl/intl.dart';
import 'package:restall/constants.dart';

// 📅 VERSIONE UNIFICATA E MIGLIORATA DEL DATE PICKER

Future<DateTime?> datePick(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    locale: const Locale('it', 'IT'),
    initialDate: DateTime.now(),
    firstDate: DateTime.now(), // Per date future (ticket/aziende)
    // firstDate: DateTime(1900), // Per date nascita - cambia secondo il caso
    lastDate: DateTime(2101),
    initialEntryMode: DatePickerEntryMode.calendarOnly,

    // 🇮🇹 TESTI ITALIANI PERSONALIZZATI
    helpText: "Seleziona la data",
    confirmText: "CONFERMA",
    cancelText: "ANNULLA",
    fieldLabelText: "Data",
    fieldHintText: "dd/MM/yyyy",
    errorFormatText: "Formato non valido",
    errorInvalidText: "Data non valida",

    // 🎨 PERSONALIZZAZIONE COLORI (FINALMENTE CORRETTA!)
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                // 🟡 PRIMARY COLOR per il picker dei giorni (oro)
                primary: primaryColor,
                onPrimary: buttonTextColor, // testo nero su oro

                // Sfondo dialog
                surface: Colors.white,
                onSurface: kTextColor,
              ),

          // 🔵 SECONDARY COLOR per i pulsanti Conferma/Annulla
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: secondaryColor, // blu navy
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          // Stile dialog arrotondato
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
          ),

          // Header del date picker con colori corretti
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor, // oro per l'header
            foregroundColor: buttonTextColor, // testo nero
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: buttonTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  return pickedDate;
}

// 📅 VERSIONE SPECIFICA PER DATE DI NASCITA (con controllo età)
Future<DateTime?> datePickBirthDate(BuildContext context) async {
  try {
    // 📅 CALCOLO DATA LIMITE: 18 anni fa da oggi
    final DateTime now = DateTime.now();
    final DateTime maxBirthDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime initialDate = DateTime(now.year - 25, now.month, now.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      locale: const Locale('it', 'IT'),
      initialDate: initialDate, // Data iniziale più realistica
      firstDate: DateTime(1900),
      lastDate: maxBirthDate, // LIMITE: massimo 18 anni fa
      initialEntryMode: DatePickerEntryMode.calendarOnly,

      // 🇮🇹 TESTI ITALIANI PERSONALIZZATI
      helpText: "Seleziona la tua data di nascita",
      confirmText: "CONFERMA",
      cancelText: "ANNULLA",
      fieldLabelText: "Data di nascita",
      fieldHintText: "dd/MM/yyyy",
      errorFormatText: "Formato non valido",
      errorInvalidText: "Data non valida",

      // 🎨 PERSONALIZZAZIONE COLORI
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  // 🟡 PRIMARY COLOR per il picker dei giorni (oro)
                  primary: primaryColor,
                  onPrimary: buttonTextColor, // testo nero su oro
                  surface: Colors.white,
                  onSurface: kTextColor,
                ),

            // 🔵 SECONDARY COLOR per i pulsanti Conferma/Annulla
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: secondaryColor, // blu navy
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
            ),

            appBarTheme: AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: buttonTextColor,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: buttonTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // ✅ DOPPIO CONTROLLO: verifica che sia davvero maggiorenne
      final age = now.year -
          pickedDate.year -
          ((now.month > pickedDate.month ||
                  (now.month == pickedDate.month && now.day >= pickedDate.day))
              ? 0
              : 1);

      if (age < 18) {
        // 🚫 BLOCCA se sotto i 18 anni
        await FlutterPlatformAlert.showAlert(
          windowTitle: 'Età non valida',
          text: 'Devi avere almeno 18 anni per utilizzare il servizio.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.warning,
        );
        return null;
      }
      return pickedDate;
    }
  } catch (e) {
    print("❌ Errore selezione data: $e");
    await FlutterPlatformAlert.showAlert(
      windowTitle: 'Errore',
      text: 'Si è verificato un errore nella selezione della data.',
      alertStyle: AlertButtonStyle.ok,
      iconStyle: IconStyle.error,
    );
  }
  return null;
}

// 📅 VERSIONE PER PROFILO (con formato backend yyyy-MM-dd)
Future<DateTime?> datePickProfile(
    BuildContext context, String currentDateValue) async {
  DateTime? currentDate;

  // Prova a parsare la data esistente
  if (currentDateValue.isNotEmpty) {
    try {
      currentDate = DateFormat('dd/MM/yyyy').parse(currentDateValue);
    } catch (e) {
      try {
        currentDate = DateFormat('yyyy-MM-dd').parse(currentDateValue);
      } catch (e) {
        currentDate =
            DateTime.now().subtract(const Duration(days: 6570)); // ~18 anni
      }
    }
  } else {
    currentDate = DateTime.now().subtract(const Duration(days: 6570));
  }

  // 📅 CALCOLO DATA LIMITE: 18 anni fa da oggi
  final DateTime now = DateTime.now();
  final DateTime maxBirthDate = DateTime(now.year - 18, now.month, now.day);

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: currentDate.isAfter(maxBirthDate) ? maxBirthDate : currentDate,
    firstDate: DateTime(1900),
    lastDate: maxBirthDate,
    locale: const Locale('it', 'IT'),

    // 🇮🇹 TESTI PERSONALIZZATI
    helpText: "Seleziona la tua data di nascita",
    confirmText: "CONFERMA",
    cancelText: "ANNULLA",
    fieldLabelText: "Data di nascita",
    fieldHintText: "dd/MM/yyyy",

    // 🎨 PERSONALIZZAZIONE COLORI
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: primaryColor, // oro per giorni
                onPrimary: buttonTextColor, // testo nero
                surface: Colors.white,
                onSurface: kTextColor,
              ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: secondaryColor, // blu navy per pulsanti
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: buttonTextColor,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    // ✅ CONTROLLO ETÀ
    final age = now.year -
        picked.year -
        ((now.month > picked.month ||
                (now.month == picked.month && now.day >= picked.day))
            ? 0
            : 1);

    if (age < 18) {
      // 🚫 MOSTRA ERRORE
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Devi avere almeno 18 anni per utilizzare il servizio.'),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return null;
    }
    return picked;
  }
  return null;
}
