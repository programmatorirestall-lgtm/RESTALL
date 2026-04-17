import 'package:flutter/material.dart';
import 'package:restalltech/Screens/PriceProduct/components/priceProduct.dart';

import 'package:restalltech/components/backgroundForm.dart';
import 'package:restalltech/constants.dart';

import 'package:restalltech/responsive.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundForm(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileUnloadingGoodsScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: const PriceProduct(),
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

class MobileUnloadingGoodsScreen extends StatelessWidget {
  const MobileUnloadingGoodsScreen({
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
              child: const PriceProduct(),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }
}
