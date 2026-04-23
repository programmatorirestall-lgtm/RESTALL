import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/Screens/CloseTicket/close_ticket_screen.dart';
import 'package:restalltech/Screens/CloseTicket/components/close_ticket_form.dart';
import 'package:restalltech/Screens/SuspendTicket/components/suspend_ticket_form.dart';
import 'package:restalltech/Screens/SuspendTicket/suspend_ticket_screen.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/models/TicketList.dart';
import 'package:restalltech/responsive.dart';

import 'ticket_description.dart';
import '../../../components/top_rounded_container.dart';

class Body extends StatefulWidget {
  final Ticket ticket;
  const Body({Key? key, required this.ticket}) : super(key: key);
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late Ticket t;
  var refreshKey = GlobalKey<RefreshIndicatorState>();
  static Future<Map<String, dynamic>> _getDetails(Ticket t) async {
    final Response response = await TicketApi().getDetails(t.id);
    final body = json.decode(response.body);
    var item = body['ticket'];
    Map<String, dynamic> ticket = item;
    ticket['nome'] = t.nome;
    ticket['cognome'] = t.cognome;
    return ticket;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<Null> refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      new Body(ticket: t);
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Future<Map<String, dynamic>> ticket = _getDetails(widget.ticket);
    setState(() {
      t = widget.ticket;
    });
    return FutureBuilder<Map<String, dynamic>>(
        future: ticket,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Align(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: secondaryColor));
          } else if (snapshot.hasData) {
            final ticket = snapshot.data!;
            return RefreshIndicator(
              onRefresh: refreshList,
              key: refreshKey,
              child: buildDetail(ticket),
            );
          } else {
            return Text("Non ci sono dettagli");
          }
        });
  }

  Widget buildDetail(ticket) => Container(
        color: Colors.grey[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TicketDescription(
                    ticket: ticket,
                  ),
                  _buildActionButtons(ticket),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons(ticket) {
    if ((ticket['stato'] ?? '').toString().toLowerCase() == "aperto") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Avvia Ticket", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              int response = await TicketApi().startTicket(ticket['id']);
              if (response == 200) {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Ticket avviato',
                  text: 'Il ticket è stato correttamente avviato',
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.exclamation,
                );
                refreshList();
              } else {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Ticket non avviato',
                  text:
                      'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.error,
                );
              }
            },
          ),
        ),
      );
    } else if ((ticket['stato'] ?? '').toString().toLowerCase() == "in corso") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text("Chiudi", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return CloseTicketScreen(
                        ticket: ticket,
                      );
                    },
                  ));
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              width: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return SuspendTicketScreen(
                        ticket: ticket,
                      );
                    },
                  ));
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      );
    } else if ((ticket['stato'] ?? '').toString().toLowerCase() == "sospeso") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Riapri Ticket", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              int response = await TicketApi().startTicket(ticket['id']);
              if (response == 200) {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Ticket riaperto',
                  text: 'Il ticket è stato correttamente riaperto',
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.exclamation,
                );
                refreshList();
              } else {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Ticket non avviato',
                  text:
                      'Connessione al server non riuscita, controlla la connessione ad Internet e riprova.',
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.error,
                );
              }
            },
          ),
        ),
      );
    } else if ((ticket['stato'] ?? '').toString().toLowerCase() == "chiuso") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                "TICKET CHIUSO",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
