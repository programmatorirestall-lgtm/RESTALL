import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InputDoneView extends StatelessWidget {
  const InputDoneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        color: CupertinoColors.extraLightBackgroundGray,
        child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.5, bottom: 0.5),
              child: CupertinoButton(
                padding:
                    const EdgeInsets.only(right: 24.0, top: 2.0, bottom: 2.0),
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: const Text("Fatto",
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                    )),
              ),
            )));
  }
}
