import 'package:flutter/material.dart';

import 'package:restall/components/backgroundForm.dart';
import 'package:restall/constants.dart';
import 'package:restall/responsive.dart';
import 'add_company_form.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileAddCompanyScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 450,
                      child: AddCompanyForm(),
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

class MobileAddCompanyScreen extends StatelessWidget {
  const MobileAddCompanyScreen({
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
              child: AddCompanyForm(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
