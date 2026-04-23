import 'package:flutter/material.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';
import 'ticket_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileTicketScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: TicketForm(),
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
            Spacer(),
            Expanded(
              flex: 8,
              child: TicketForm(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
