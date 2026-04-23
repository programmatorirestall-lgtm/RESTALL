import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/theme.dart';

import 'components/body.dart';

class CloseTicketScreen extends StatelessWidget {
  static String routeName = "/close_ticket";
  const CloseTicketScreen({super.key, required this.ticket});

  final Map<String, dynamic> ticket;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "#" + ticket['id'].toString(),
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: kPrimaryLightColor,
      body: Body(
        ticket: ticket,
      ),
    );
  }
}
