import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restall/Screens/Login/components/login_screen_top_image.dart';
import 'package:restall/Screens/Login/components/social_login.dart';
import 'package:restall/Screens/Signup/components/signup_form.dart';
import 'package:restall/Screens/Signup/signup_screen.dart';
import 'package:restall/Screens/otp/components/otp_form.dart';
import 'package:restall/components/background.dart';

import 'package:restall/components/background_start.dart';
import 'package:restall/constants.dart';
import 'package:restall/responsive.dart';
import 'package:restall/widgets/keyboard_dismissible.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black),
              onPressed: () =>
                  Navigator.pushNamed(context, SignUpScreen.routeName)),
          centerTitle: true,
        ),
        body: KeyboardDismissible(
          child: Background(
            child: SingleChildScrollView(
              child: Responsive(
                mobile: const MobileLoginScreen(),
                desktop: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Verifica OPT'.toUpperCase(),
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
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                                "Abbiamo inviato il codice a (+39) 392 149 5567"),
                            buildTimer(),
                            const SizedBox(height: 10),
                          ],
                        ),
                        const SizedBox(
                          width: 450,
                          child: OtpForm(),
                        ),
                        const SizedBox(height: defaultPadding / 2),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: [
            Text(
              'Verifica OPT'.toUpperCase(),
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
        ),
        Column(
          children: [
            const SizedBox(height: 10),
            const Text("Abbiamo inviato il codice a (+39) 392 149 5567"),
            buildTimer(),
            const SizedBox(height: 10),
          ],
        ),
        const Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: OtpForm(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}

Row buildTimer() {
  DateTime date;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Il codice scade fra "),
      TweenAnimationBuilder(
        tween: Tween(begin: 300.0, end: 0.0),
        duration: const Duration(seconds: 300),
        builder: (_, dynamic value, child) => Text(
          "${DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000))}",
          style: const TextStyle(color: kPrimaryColor),
        ),
      ),
    ],
  );
}
