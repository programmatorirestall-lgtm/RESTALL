import 'package:flutter/material.dart';
import 'package:restalltech/Screens/ForgotPassword/components/forgot_password_screen_top_image.dart';
import 'package:restalltech/Screens/Login/components/login_screen_top_image.dart';

import 'package:restalltech/components/background_start.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';

import 'forgot_password_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundStart(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileForgotPasswordScreen(),
          desktop: Row(
            children: [
              const Expanded(
                child: ForgotPasswordScreenTopImage(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: ForgotPasswordForm(),
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

class MobileForgotPasswordScreen extends StatelessWidget {
  const MobileForgotPasswordScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const ForgotPasswordScreenTopImage(),
        Row(
          children: const [
            Spacer(),
            Expanded(
              flex: 8,
              child: ForgotPasswordForm(),
            ),
            Spacer(),
          ],
        ),
        //const SocialLogin()
      ],
    );
  }
}
