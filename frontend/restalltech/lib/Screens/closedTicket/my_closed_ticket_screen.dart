import 'package:flutter/material.dart';
import 'package:restalltech/Screens/closedTicket/components/body.dart';
import 'package:restalltech/theme.dart';

class MyClosedTicketScreen extends StatelessWidget {
  static String routeName = "/closed_tickets";

  const MyClosedTicketScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Closed Ticket',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const Body(),
    );
  }
}
