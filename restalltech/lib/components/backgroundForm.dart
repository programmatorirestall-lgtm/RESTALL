import 'package:flutter/material.dart';
import 'package:restalltech/components/top_rounded_container.dart';
import 'package:restalltech/constants.dart';

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
        body: Stack(
          children: <Widget>[
            TopRoundedContainer(color: white, child: child),
          ],
        ),
      ),
    );
  }
}
