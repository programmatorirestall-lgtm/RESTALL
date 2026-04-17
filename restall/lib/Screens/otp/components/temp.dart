import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restall/Screens/Login/components/login_screen_top_image.dart';
import 'package:restall/Screens/Login/components/social_login.dart';
import 'package:restall/Screens/otp/components/otp_form.dart';

import 'package:restall/components/background_start.dart';
import 'package:restall/constants.dart';
import 'package:restall/responsive.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundStart(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileLoginScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      "Verifica OPT",
                      //style: headingStyle,
                    ),
                    Text("Abbiamo inviato il codice to +39 3333333333"),
                    buildTimer(),
                    OtpForm(),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        // OTP code resend
                      },
                      child: Text(
                        "Invia un nuovo codice",
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: OtpForm(),
                    ),
                    SizedBox(height: defaultPadding / 2),
                    SocialLogin()
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

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const LoginScreenTopImage(),
        Row(
          children: const [
            Spacer(),
            Expanded(
              flex: 8,
              child: OtpForm(),
            ),
            Spacer(),
          ],
        ),
        const SocialLogin()
      ],
    );
  }
}

Row buildTimer() {
  DateTime date;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("Il codice scade fra "),
      TweenAnimationBuilder(
        tween: Tween(begin: 300.0, end: 0.0),
        duration: Duration(seconds: 300),
        builder: (_, dynamic value, child) => Text(
          "${DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000))}",
          style: TextStyle(color: kPrimaryColor),
        ),
      ),
    ],
  );
}
