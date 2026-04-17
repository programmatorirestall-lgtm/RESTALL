import 'package:flutter/material.dart';
import 'package:restalltech/constants.dart';

class Body extends StatelessWidget {
  const Body({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: defaultPadding * 3),
        const Text(
          "Ticket Aperto!",
          style: TextStyle(
            fontSize: 46,
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: defaultPadding * 3),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 5000,
              child: Image.asset(
                "assets/images/success.png",
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 3),
      ],
    );
  }
}
