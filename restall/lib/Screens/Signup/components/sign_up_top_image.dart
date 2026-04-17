import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:restall/constants.dart';

class SignUpScreenTopImage extends StatelessWidget {
  const SignUpScreenTopImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Registrati".toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: Image.asset(
                "assets/images/logo.png",
                height: 180,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
