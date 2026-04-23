import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restall/theme.dart';

import 'components/body.dart';

class AddCompanyScreen extends StatelessWidget {
  static String routeName = "/add_company";

  const AddCompanyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
    );
  }
}
