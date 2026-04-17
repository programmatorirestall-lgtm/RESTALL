import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/Screens/DTT/components/imagepicker.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class DDTScreen extends StatelessWidget {
  static String routeName = "/dtt";
  final String t;
  const DDTScreen({super.key, required this.t});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPrimaryLightColor,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                Navigator.pop(context);
              }),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        body: MaterialApp(
          home: Body(t: t),
          debugShowCheckedModeBanner: false,
          theme: theme(),
        ));
  }
}
