import 'package:flutter/material.dart';

import 'package:restall/constants.dart';

import 'top_rounded_container.dart';

class BackgroundForm extends StatelessWidget {
  final Widget child;
  const BackgroundForm({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: TopRoundedContainer(
          color: white,
          child: Stack(
            //alignment: Alignment.center,
            children: <Widget>[
              TopRoundedContainer(color: white, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
