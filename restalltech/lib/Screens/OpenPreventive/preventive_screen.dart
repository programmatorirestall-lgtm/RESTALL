import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class PreventiveScreen extends StatelessWidget {
  static String routeName = "/preventivi";

  const PreventiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apri Preventivo',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            color: primaryColor,
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          backgroundColor: appBarColor,
          title: Text(
            "Richiedi Preventivo",
            style: TextStyle(color: white),
          ),
        ),
        body: Body(),
      ),
    );
  }
}
