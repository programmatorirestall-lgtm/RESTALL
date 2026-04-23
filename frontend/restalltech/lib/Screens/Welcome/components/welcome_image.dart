import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';

class WelcomeImage extends StatelessWidget {
  const WelcomeImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: defaultPadding * 3),
        const Text(
          "RestAll",
          style: TextStyle(
            fontSize: 46,
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "Benvenuto Su RestAll!",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: defaultPadding * 3),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: Image.asset(
                "assets/images/logo.png",
                height: 250,
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
