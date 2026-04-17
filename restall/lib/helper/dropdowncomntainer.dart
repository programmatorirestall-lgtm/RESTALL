import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/constants.dart';
import 'package:restall/helper/downloader.dart';

class DropDownContainer extends StatefulWidget {
  final Map<String, dynamic> data;
  const DropDownContainer({Key? key, required this.data}) : super(key: key);

  @override
  _DropDownContainerState createState() => _DropDownContainerState();
}

class _DropDownContainerState extends State<DropDownContainer> {
  static Future<List<dynamic>> _getDetails(t) async {
    final Response response = await TicketApi().getDetails(t);
    final body = json.decode(response.body);
    var item = body['ticket'];
    ////print("ITEM" + body['fogli'].toString());
    var ticket = item;
    item = ticket['fogli'];
    //ticket = item['location'];
    //print(item);
    return item;
  }

  Future<void> _downloadFile(url) async {
    DownloadService downloadService;
    if (kIsWeb) {
      downloadService = WebDownloadService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      downloadService = MobileDownloadService();
    } else {
      downloadService = DesktopDownloadService();
    }
    await downloadService.download(url: url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
        future: _getDetails(widget.data['id']),
        builder: (context, snapshot) {
          //print(snapshot);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Align(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: secondaryColor));
          } else if (snapshot.hasData && snapshot.data!.length > 0) {
            final ticket = snapshot.data!;
            //print(ticket.length);
            return SizedBox(
              height: 50,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: ticket.length,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            child: Text(
                              ticket[index]['fileKey'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () {
                              _downloadFile(ticket[index]['location']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Text("Non ci sono dettagli");
          }
        });
  }
}
