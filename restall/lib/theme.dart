import 'package:flutter/material.dart';
import 'constants.dart';

ThemeData theme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    canvasColor: canvasColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: kBackgroundColor,
      error: errorColor,
      onPrimary: buttonTextColor,
      onSecondary: Colors.white,
      onSurface: kTextColor,
      onBackground: kTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      iconTheme: const IconThemeData(color: secondaryColor),
      titleTextStyle: const TextStyle(
        color: secondaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    scaffoldBackgroundColor: kBackgroundColor,
    textTheme: textTheme(),
    iconTheme: const IconThemeData(color: secondaryColor),
    primaryIconTheme: const IconThemeData(color: white),
    textSelectionTheme: textSelectionThemeData(),
    elevatedButtonTheme: elevatedButtonThemeData(),
    floatingActionButtonTheme: floatingActionButtonThemeData(),
    cardTheme: cardTheme(),
    inputDecorationTheme: inputDecorationTheme(),
    bottomNavigationBarTheme: bottomNavigationBarTheme(),
    dialogTheme: dialogTheme(),
  );
}

ThemeData appBartheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    canvasColor: canvasColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    textTheme: textTheme(),
    elevatedButtonTheme: elevatedButtonThemeData(),
    inputDecorationTheme: inputDecorationTheme(),
    cardTheme: cardTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      iconTheme: const IconThemeData(color: white),
      titleTextStyle: const TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

TextTheme textTheme() {
  return const TextTheme(
    headlineLarge: TextStyle(
        color: secondaryColor, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(
        color: secondaryColor, fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(
        color: secondaryColor, fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(
        color: secondaryColor, fontSize: 20, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(
        color: secondaryColor, fontSize: 18, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(
        color: secondaryColor, fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(
        color: kTextColor, fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(
        color: kTextColor, fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(
        color: kSecondaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.normal),
    labelLarge:
        TextStyle(color: kTextColor, fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(
        color: kSecondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(
        color: kSecondaryTextColor, fontSize: 10, fontWeight: FontWeight.w600),
  );
}

TextSelectionThemeData textSelectionThemeData() {
  return TextSelectionThemeData(
    cursorColor: primaryColor,
    selectionColor: primaryColor.withOpacity(0.2),
    selectionHandleColor: primaryColor,
  );
}

ElevatedButtonThemeData elevatedButtonThemeData() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: buttonTextColor,
      backgroundColor: primaryColor,
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius)),
      padding: const EdgeInsets.symmetric(
          horizontal: largePadding, vertical: defaultPadding),
      minimumSize: const Size(double.infinity, 56),
      maximumSize: const Size(double.infinity, 56),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed))
          return primaryColor.withOpacity(0.8);
        if (states.contains(MaterialState.hovered))
          return primaryColor.withOpacity(0.9);
        return primaryColor;
      }),
      elevation: MaterialStateProperty.resolveWith<double>((states) {
        if (states.contains(MaterialState.pressed)) return 2;
        if (states.contains(MaterialState.hovered)) return 8;
        return 4;
      }),
    ),
  );
}

FloatingActionButtonThemeData floatingActionButtonThemeData() {
  return FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: buttonTextColor,
    elevation: 8,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius)),
  );
}

CardThemeData cardTheme() {
  return CardThemeData(
    color: Colors.white,
    shadowColor: Colors.black.withOpacity(0.1),
    elevation: 4,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius)),
    margin: const EdgeInsets.all(defaultPadding),
  );
}

InputDecorationTheme inputDecorationTheme() {
  return InputDecorationTheme(
    filled: true,
    fillColor: kPrimaryLightColor,
    iconColor: primaryColor,
    prefixIconColor: secondaryColor,
    suffixIconColor: primaryColor,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: defaultPadding, vertical: defaultPadding),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: const BorderSide(color: errorColor, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    labelStyle: const TextStyle(
      color: kSecondaryTextColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: TextStyle(
      color: secondaryColor,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(
      color: kSecondaryTextColor,
      fontSize: 14,
    ),
    errorStyle: const TextStyle(
      color: errorColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

BottomNavigationBarThemeData bottomNavigationBarTheme() {
  return BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryColor,
    unselectedItemColor: Color(0xFF6B6B6B),
    selectedIconTheme: const IconThemeData(size: 28),
    unselectedIconTheme: const IconThemeData(size: 24),
    selectedLabelStyle:
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle:
        const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );
}

DialogThemeData dialogTheme() {
  return DialogThemeData(
    backgroundColor: Colors.white,
    elevation: 16,
    shadowColor: Colors.black.withOpacity(0.2),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius)),
    titleTextStyle: const TextStyle(
      color: secondaryColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: kTextColor,
      fontSize: 16,
    ),
  );
}
