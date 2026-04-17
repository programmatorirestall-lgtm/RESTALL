import 'package:flutter/material.dart';
import 'package:restall/Screens/OpenPreventive/components/preventive_form.dart';
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
          mobile: const MobilePreventiveScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: PreventiveForm(),
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

class MobilePreventiveScreen extends StatelessWidget {
  const MobilePreventiveScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: const [
            Spacer(),
            Expanded(
              flex: 8,
              child: PreventiveForm(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
