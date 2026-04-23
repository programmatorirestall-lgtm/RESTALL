import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class AddTechScreen extends StatelessWidget {
  static String routeName = "/add_tech";
  const AddTechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLightColor,
      appBar: AppBar(
        title: Text("Aggiungi Tecnico"),
        backgroundColor: appBarColor,
      ),
      body: MaterialApp(
        title: 'Aggiungi Tecnico',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate, // Here !
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('it')],
        theme: theme(),
        home: Body(),
      ),
    );
  }
}
