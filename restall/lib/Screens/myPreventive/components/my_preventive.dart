import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:restall/API/Ticket/ticket.dart';
import 'package:restall/components/background.dart';
import 'package:restall/components/product_card.dart';
import 'package:restall/components/ticket_card.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/Product.dart';
import 'package:restall/models/TicketList.dart';

class MyPreventive extends StatefulWidget {
  const MyPreventive({super.key});
  static String routeName = "/my_ticket";

  @override
  _MyPreventiveState createState() => _MyPreventiveState();
}

class _MyPreventiveState extends State<MyPreventive> {
  Future<List<Ticket>> ticket = getTickets();
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  static Future<List<Ticket>> getTickets() async {
    final Response response = await TicketApi().getData();
    final body = json.decode(response.body);
    Iterable ticketList = body['tickets'];
    //List<Ticket> tickets = List<Ticket>.from(ticketList.map((model) => Ticket.fromJson(model)));
    List<Ticket> tickets = List.from(ticketList)
        .map((model) => Ticket.fromJson(Map.from(model)))
        .toList();
    //List<User> users = List.from(body).map((e) => User.fromJson(Map.from(e))).toList();
    return tickets;
  }

  Future<Null> refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      ticket = getTickets();
      new MyPreventive();
    });

    return null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ticket = getTickets();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ticket>>(
        future: ticket,
        builder: (context, snapshot) {
          //print(snapshot);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Align(
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: secondaryColor));
          } else if (snapshot.hasData && snapshot.data!.length > 0) {
            final tickets = snapshot.data!;

            return RefreshIndicator(
              onRefresh: refreshList,
              key: refreshKey,
              child: buildTickets(tickets),
            );
          } else {
            return RefreshIndicator(
                onRefresh: refreshList,
                key: refreshKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Nessun Ticket'),
                              Text('Trascina per ricaricare'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ));
          }
        });
  }

  Widget buildTickets(List<Ticket> tickets) => ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: tickets.length,
      itemBuilder: (context, index) => TicketCard(ticket: tickets[index]));
}
