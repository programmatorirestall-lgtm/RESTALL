import 'package:flutter/material.dart';
import 'package:restalltech/Screens/Home/components/body.dart';
import 'package:restalltech/theme.dart';

class HomeScreen extends StatelessWidget {
  static String routeName = "/home";

  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: const Body(),
    );
  }
}
