import 'package:flutter/material.dart';
import 'package:restall/Screens/Login/components/login_screen_top_image.dart';
import 'package:restall/Screens/Login/components/social_login.dart';

import 'package:restall/components/background_start.dart';
import 'package:restall/constants.dart';
import 'package:restall/responsive.dart';

import 'login_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundStart(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileLoginScreen(),
          desktop: Row(
            children: [
              const Expanded(
                child: LoginScreenTopImage(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: LoginForm(),
                    ),
                    SizedBox(height: defaultPadding / 2),
                    //SocialLogin()
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
              child: LoginForm(),
            ),
            Spacer(),
          ],
        ),
        //const SocialLogin()
      ],
    );
  }
}
