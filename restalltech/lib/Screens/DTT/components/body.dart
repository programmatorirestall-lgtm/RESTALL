import 'package:flutter/material.dart';
import 'package:restalltech/Screens/DTT/components/imagepicker.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';
import 'package:restalltech/test.dart';

class Body extends StatelessWidget {
  final String t;

  const Body({Key? key, required this.t}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileDTTScreen(t: t),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: ImagePickerWidget(t: t),
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

class MobileDTTScreen extends StatelessWidget {
  String t;

  MobileDTTScreen({Key? key, required this.t}) : super(key: key);

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
              child: ImagePickerWidget(t: t),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
