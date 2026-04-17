import 'package:flutter/material.dart';
import 'package:restalltech/Screens/Login/login_screen.dart';
import 'package:restalltech/constants.dart';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginScreen();
                  },
                ),
              );
            },
            child: Text(
              "Accedi".toUpperCase(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
