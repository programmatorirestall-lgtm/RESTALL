import 'package:flutter/material.dart';
import 'package:restall/Screens/Signup/components/sign_up_top_image.dart';
import 'package:restall/Screens/Signup/components/signup_form.dart';
import 'package:restall/Screens/Signup/components/social_sign_up.dart';
import 'package:restall/components/background_start.dart';
import 'package:restall/constants.dart';
import 'package:restall/responsive.dart';

class Body extends StatelessWidget {
  final String? referralCode;

  const Body({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    return BackgroundStart(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileSignupScreen(referralCode: referralCode),
          desktop: Row(
            children: [
              const Expanded(
                child: SignUpScreenTopImage(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: SignUpForm(referralCode: referralCode),
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    //SocialSignUp()
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

class MobileSignupScreen extends StatelessWidget {
  final String? referralCode;
  const MobileSignupScreen({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SignUpScreenTopImage(),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: SignUpForm(referralCode: referralCode),
            ),
            const Spacer(),
          ],
        ),
        //const SocialSignUp()
      ],
    );
  }
}
