import 'package:flutter/material.dart';
import 'package:restall/constants.dart';

import 'components/body.dart';

class SignUpScreen extends StatelessWidget {
  static String routeName = "/sign_up";
  final String? referralCode;

  const SignUpScreen({super.key, this.referralCode});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(referralCode: referralCode),
    );
  }
}
