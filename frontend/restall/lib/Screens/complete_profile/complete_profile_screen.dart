import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/widgets/keyboard_dismissible.dart';

import 'components/body.dart';

class CompleteProfileScreen extends StatelessWidget {
  static String routeName = "/complete_profile";

  final String? referralCode;

  const CompleteProfileScreen({super.key, this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardDismissible(
        child: Body(referralCode: referralCode),
      ),
    );
  }
}
