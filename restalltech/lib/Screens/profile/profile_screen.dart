import 'package:flutter/material.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'components/body.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = "/pofile";
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: new Text(
          'Profilo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appBarColor,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      backgroundColor: kPrimaryLightColor,
      body: MaterialApp(
        home: const Body(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate, // Here !
          DefaultWidgetsLocalizations.delegate,
        ],
        theme: theme(),
      ),
    );
  }
}
