import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

abstract class DownloadService {
  Future<void> download({required String url});
}

class WebDownloadService implements DownloadService {
  @override
  Future<void> download({required String url}) async {
    html.window.open(url, "_blank");
  }
}

class DesktopDownloadService implements DownloadService {
  @override
  Future<void> download({required String url}) async {
    //print(url);
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri);
    else
      // can't launch url, there is some error
      throw "Could not launch $url";
  }
}

class MobileDownloadService implements DownloadService {
  @override
  Future<void> download({required String url}) async {
    //print("MOBILE");
    // Richiedi il permesso per scaricare il file
    Dio dio = Dio();
    if (Platform.isAndroid) {
      bool hasPermission = await _requestWritePermission();
      //print(hasPermission);
      if (!hasPermission) return;
    }

    try {
      var dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory());
      } else if (Platform.isIOS) {
        dir = (await getApplicationDocumentsDirectory());
      }
      //print(dir);

      // Estrai il nome del file dall'URL
      String fileName = url.split('/').last;
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }
      // Scarica il file
      var path = "${dir.path}/$fileName";
      //print(path);
      await dio.download(
        url,
        path,
        onReceiveProgress: (count, total) {
          //print("Rec: $count , Total: $total");
        },
      );

      // Apri il file usando OpenFile
      OpenFile.open(path);
    } catch (e) {
      //print(e);
    }
  }

  // requests storage permission
  Future<bool> _requestWritePermission() async {
    bool isStoragePermission = true;
    bool isVideosPermission = true;
    bool isPhotosPermission = true;
    // await Permission.storage.request();
    // return await Permission.storage.request().isGranted;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      isVideosPermission = await Permission.videos.status.isGranted;
      isPhotosPermission = await Permission.photos.status.isGranted;
    } else {
      isStoragePermission = await Permission.storage.status.isGranted;
    }

    if (isStoragePermission && isVideosPermission && isPhotosPermission) {
      return true;
    } else {
      return isStoragePermission;
    }
  }

  Future download2(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        //onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      ////print("TEST" + response.data);
      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      //print(e);
    }
  }
}
