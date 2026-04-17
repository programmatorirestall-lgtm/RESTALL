import 'package:flutter/material.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/TicketList.dart';
import 'package:restalltech/responsive.dart';
import 'suspend_ticket_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key, required this.ticket}) : super(key: key);
  final Map<String, dynamic> ticket;

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileCloseTicketScreen(ticket: ticket),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: SuspendTicketForm(
                        ticket: ticket,
                      ),
                    ),
                    SizedBox(height: defaultPadding / 2),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MobileCloseTicketScreen extends StatelessWidget {
  const MobileCloseTicketScreen({
    Key? key,
    required this.ticket,
  }) : super(key: key);
  final Map<String, dynamic> ticket;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: SuspendTicketForm(
                ticket: ticket,
              ),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
