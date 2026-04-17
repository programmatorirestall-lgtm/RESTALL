import 'package:flutter/widgets.dart';
import 'package:restalltech/Screens/details/details_screen.dart';
import 'package:restalltech/Screens/myTickets/my_ticket_screen.dart';

// We use name route
// All our routes will be available here
final Map<String, WidgetBuilder> routes = {
  MyTicketScreen.routeName: (context) => const MyTicketScreen(),
};
