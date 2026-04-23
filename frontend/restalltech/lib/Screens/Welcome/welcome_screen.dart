import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:restalltech/theme.dart';

import 'components/body.dart';

class WelecomeScreen extends StatefulWidget {
  const WelecomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WelecomeScreenState();
}

class _WelecomeScreenState extends State<WelecomeScreen> {
  static String routeName = "/welecome_screen";

  @override
  void initState() {
    super.initState();
    setState(() {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  }

  void _updateSystemStateBar() {
    setState(() {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateSystemStateBar();
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Here !
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      title: 'RestAll',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const Body(),
    );
  }
}
