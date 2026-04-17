import 'package:flutter/material.dart';
import 'package:restalltech/Screens/ticket_success/components/body.dart';
import 'package:restalltech/components/background_start.dart';
import 'package:restalltech/responsive.dart';

class TicketSuccess extends StatefulWidget {
  const TicketSuccess({super.key});

  _TicketSuccessState createState() => _TicketSuccessState();
}

class _TicketSuccessState extends State<TicketSuccess> {
  @override
  Widget build(BuildContext context) {
    //SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return BackgroundStart(
      child: SingleChildScrollView(
        child: SafeArea(
          child: Responsive(
            desktop: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Expanded(
                  child: Body(),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 450,
                        child: BackhomeBtn(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            mobile: const MobileTicketSuccessScreen(),
          ),
        ),
      ),
    );
  }
}

class MobileTicketSuccessScreen extends StatelessWidget {
  const MobileTicketSuccessScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Body(),
        Row(
          children: const [
            Spacer(),
            Expanded(
              flex: 8,
              child: BackhomeBtn(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}

class BackhomeBtn extends StatelessWidget {
  const BackhomeBtn({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            "Continua".toUpperCase(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
