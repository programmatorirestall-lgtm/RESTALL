import 'package:flutter/material.dart';
import 'package:restalltech/Screens/Home/components/home_admin.dart';
import 'package:restalltech/components/background.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/responsive.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: const MobileHomeScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: double.maxFinite,
                      height: 800, // Altezza fissa per la nuova dashboard
                      child: HomeAdmin(), // Sostituisce Home()
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

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({
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
              child: HomeAdmin(), // Sostituisce Home()
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
