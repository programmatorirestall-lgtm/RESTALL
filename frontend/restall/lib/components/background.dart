import 'package:flutter/material.dart';
import 'package:restall/constants.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        color: kPrimaryLightColor,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          //alignment: Alignment.center,
          children: <Widget>[
            Container(child: child),
          ],
        ),
      ),
    );
  }
}
