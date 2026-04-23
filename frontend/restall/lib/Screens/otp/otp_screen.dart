import 'package:flutter/material.dart';
import 'package:restall/theme.dart';
import 'components/body.dart';

class OtpScreen extends StatelessWidget {
  static String routeName = "/otp";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Verifica OTP",
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const Body(),
    );
  }
}
