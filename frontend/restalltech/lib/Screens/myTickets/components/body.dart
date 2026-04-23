import 'package:flutter/material.dart';

import 'package:restalltech/Screens/myTickets/components/my_ticket.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Background(child: MyTicket());
  }
}

class MobileTicketScreen extends StatelessWidget {
  const MobileTicketScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: const [
            Flexible(
              flex: 8,
              child: MyTicket(),
            ),
          ],
        ),
      ],
    );
  }
}
