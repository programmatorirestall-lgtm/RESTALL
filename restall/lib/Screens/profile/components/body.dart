import 'package:flutter/material.dart';
import 'package:restall/Screens/profile/components/profile.dart';

import 'package:restall/components/backgroundForm.dart';
import 'package:restall/constants.dart';

import 'package:restall/responsive.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: ProfileScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: Profile(),
                    ),
                    SizedBox(height: defaultPadding / 2),
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: Profile(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
