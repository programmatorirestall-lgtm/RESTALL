import 'package:flutter/material.dart';
import 'package:restall/Screens/ticket_success/components/button.dart';

class TicketSuccessScreen extends StatelessWidget {
  static String routeName = "/ticket_success";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TicketSuccess(),
    );
  }
}
