import 'package:flutter/material.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/TicketList.dart';

import 'components/body.dart';

class DetailsScreen extends StatelessWidget {
  static String routeName = "/details";
  const DetailsScreen({super.key, required this.ticket});
  final Ticket ticket;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryLightColor,
      body: Body(ticket: ticket),
    );
  }
}
