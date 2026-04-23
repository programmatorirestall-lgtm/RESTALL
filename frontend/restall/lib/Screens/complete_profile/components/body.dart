import 'package:flutter/material.dart';
import 'package:restall/Screens/Signup/components/sign_up_top_image.dart';
import 'package:restall/Screens/complete_profile/components/complete_profile_form.dart';
import 'package:restall/components/background_start.dart';
import 'package:restall/responsive.dart';

class Body extends StatelessWidget {
  const Body({Key? key, this.referralCode}) : super(key: key);

  final String? referralCode;

  @override
  Widget build(BuildContext context) {
    return BackgroundStart(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileSignup(referralCode: referralCode),
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
                      child: CompleteProfileForm(referralCode: referralCode),
                    ),
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

class MobileSignup extends StatelessWidget {
  const MobileSignup({Key? key, this.referralCode}) : super(key: key);

  final String? referralCode;

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
              child: CompleteProfileForm(referralCode: referralCode),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
