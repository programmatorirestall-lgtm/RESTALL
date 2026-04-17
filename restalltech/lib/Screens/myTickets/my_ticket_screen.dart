import 'package:flutter/material.dart';
import 'package:restalltech/Screens/MyTickets/components/body.dart';
import 'package:restalltech/Screens/myTickets/components/my_ticket.dart';
import 'package:restalltech/constants.dart';

import 'package:restalltech/theme.dart';

class MyTicketScreen extends StatelessWidget {
  static String routeName = "/tickets";

  const MyTicketScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPrimaryLightColor,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        body: MaterialApp(
          home: Body(),
          debugShowCheckedModeBanner: false,
          theme: theme(),
        ));
  }
}
