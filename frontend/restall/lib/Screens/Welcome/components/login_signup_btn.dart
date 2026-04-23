import 'package:flutter/material.dart';
import 'package:restall/Screens/Login/login_screen.dart';
import 'package:restall/Screens/Signup/signup_screen.dart';
import 'package:restall/constants.dart';

class LoginAndSignupBtn extends StatelessWidget {
  const LoginAndSignupBtn({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: "login_btn",
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName,
                  (Route<dynamic> route) => false);
            },
            child: Text(
              "Accedi".toUpperCase(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Hero(
          tag: "sign_up",
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, SignUpScreen.routeName,
                  (Route<dynamic> route) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryLightColor, elevation: 0),
            child: Text(
              "Registrati".toUpperCase(),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
