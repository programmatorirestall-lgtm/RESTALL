import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class SettingsScreen extends StatelessWidget {
  static String routeName = "/settings";
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLightColor,
      body: MaterialApp(
        title: 'Impostazioni',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        theme: theme(),
        home: Body(),
      ),
    );
  }
}
