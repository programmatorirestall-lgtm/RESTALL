import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Drop-in replacement for SimpleBarcodeScannerPage.
/// Returns the scanned barcode string via Navigator.pop, or null if cancelled.
class SimpleBarcodeScannerPage extends StatefulWidget {
  const SimpleBarcodeScannerPage({super.key});

  @override
  State<SimpleBarcodeScannerPage> createState() =>
      _SimpleBarcodeScannerPageState();
}

class _SimpleBarcodeScannerPageState extends State<SimpleBarcodeScannerPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scansione Codice')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode?.rawValue != null) {
            _scanned = true;
            Navigator.pop(context, barcode!.rawValue);
          }
        },
      ),
    );
  }
}

class ScanScreen extends StatefulWidget {
  final Function(String) addToSummary;

  ScanScreen({required this.addToSummary});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String scannedCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scansione Codice'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Codice Scansionato:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              scannedCode,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                var code = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleBarcodeScannerPage(),
                    ));
                setState(() {
                  if (code is String) {
                    scannedCode = code;
                  }
                });
                widget.addToSummary(code);
                Navigator.pop(context);
              },
              child: Text('Scansiona'),
            ),
          ],
        ),
      ),
    );
  }
}
