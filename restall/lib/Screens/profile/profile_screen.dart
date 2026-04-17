import 'package:flutter/material.dart';
import 'package:restall/constants.dart';
import 'package:restall/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restall/widgets/keyboard_dismissible.dart';
import 'components/body.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = "/profile";
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: kPrimaryLightColor,
      body: KeyboardDismissible(
        child: Body(),
      ),
    );
  }
}
