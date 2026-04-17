import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restalltech/constants.dart';
import 'package:universal_html/js.dart';
import './config.dart' show apiHost;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restalltech/API/LoginRequest/login.dart';
import 'package:restalltech/Screens/SideBar/sidebar.dart';
import 'package:restalltech/Screens/Welcome/welcome_screen.dart';
import 'package:restalltech/helper/sc.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:window_size/window_size.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

checkAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  var localVersionBuild = "${info.version}+${info.buildNumber}";
  var localVersion = info.version;
  var localBuild = info.buildNumber;
  final response = await http.get(Uri.parse("$apiHost/info"));
  var data = json.decode(response.body);
  var version = data['version'];
  print("status: ${response.statusCode}");
  print("data: $version");
  if (response.statusCode == 200) {
    if (version is String && version.contains('+')) {
      var parts = version.split('+');
      var serverVersionOnly = parts[0];
      var serverBuild = parts[1];

      List<int> parseVersion(String v) => v.split('.').map(int.parse).toList();

      List<int> localParts = parseVersion(localVersion);
      List<int> serverParts = parseVersion(serverVersionOnly);

      bool versionOutdated = false;
      for (int i = 0; i < serverParts.length; i++) {
        int localVal = i < localParts.length ? localParts[i] : 0;
        if (localVal < serverParts[i]) {
          versionOutdated = true;
          break;
        } else if (localVal > serverParts[i]) {
          break;
        }
      }

      int localBuildNum = int.tryParse(localBuild) ?? 0;
      int serverBuildNum = int.tryParse(serverBuild) ?? 0;
      var context;

      if (versionOutdated || localBuildNum < serverBuildNum) {
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Aggiornamento disponibile',
          text:
              'Aggiorna l\'app per continuare.\nControlla sul canale telegram.',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.warning,
        );
      } else {
        print("App is up to date.");
      }
    }
  }
}

void main() async {
  print(apiHost);

  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) {
    await Firebase.initializeApp();
  }
  final data = MediaQueryData.fromWindow(WidgetsBinding.instance!.window);
  if (data.size.shortestSide > 600) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  //await checkAppVersion();

  if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
    setWindowTitle('RestAll');
    setWindowMinSize(const Size(200, 200));
    setWindowMaxSize(Size.infinite);
  }

  var api = LoginApi();
  print("SESSION");
  print(api.sessionState());

  try {
    if (await api.sessionState() == null || await api.sessionState() == false) {
      runApp(
        ChangeNotifierProvider(
          create: (_) => MySensitiveDataProvider(),
          child: const WelecomeScreen(),
        ),
      );
    } else {
      runApp(ChangeNotifierProvider(
        create: (_) => MySensitiveDataProvider(),
        child: const SideBar(),
      ));
    }
  } on Exception catch (e) {
    print("NO: " + e.toString());
    // SharedPreferences preferences = await SharedPreferences.getInstance();
    // await preferences.clear();
  }
}
