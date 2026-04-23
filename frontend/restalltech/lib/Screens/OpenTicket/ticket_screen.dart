import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class TicketScreen extends StatelessWidget {
  static String routeName = "/new_ticket";

  const TicketScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apri Ticket',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Here !
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      theme: theme(),
      home: const Body(),
    );
  }
}
