import 'package:flutter/material.dart';

import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';

import 'package:restalltech/responsive.dart';
import 'add_tech_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileAddTechScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: AddTechForm(),
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

class MobileAddTechScreen extends StatelessWidget {
  const MobileAddTechScreen({
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
              child: AddTechForm(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
