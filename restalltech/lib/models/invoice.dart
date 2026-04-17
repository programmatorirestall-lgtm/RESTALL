import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restalltech/API/UpLoad/upload.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class Sign extends StatefulWidget {
  const Sign(BuildContext context, {Key? key}) : super(key: key);

  @override
  _SignState createState() => _SignState();
}

class _SignState extends State<Sign> {
  String _generatedHtml = '';
  final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void _handleClearButtonPressed() {
    signatureGlobalKey.currentState!.clear();
  }

  void _handleSaveButtonPressed() async {
    final data =
        await signatureGlobalKey.currentState!.toImage(pixelRatio: 3.0);
    final bytes = await data.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/firma.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    String location = await UploadApi().updateSign(file);
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(),
      body: Column(
          children: [
            Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                    child: SfSignaturePad(
                        key: signatureGlobalKey,
                        backgroundColor: Colors.white,
                        strokeColor: Colors.black,
                        minimumStrokeWidth: 1.0,
                        maximumStrokeWidth: 4.0),
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.grey)))),
            SizedBox(height: 10),
            Row(children: <Widget>[
              TextButton(
                child: Text('Conferma'),
                onPressed: _handleSaveButtonPressed,
              ),
              TextButton(
                child: Text('Pulisci'),
                onPressed: _handleClearButtonPressed,
              ),
            ], mainAxisAlignment: MainAxisAlignment.spaceEvenly)
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center),
    );
  }
}
