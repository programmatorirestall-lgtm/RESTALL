import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Ticket {
  final int id;
  final String typeM, stateM, data, stateT, indirizzo;
  final String? oraPrevista;

  const Ticket(
      {required this.id,
      required this.typeM,
      required this.stateM,
      required this.stateT,
      required this.indirizzo,
      this.oraPrevista,
      required this.data});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    var user = json['utente'];
    return Ticket(
      id: json['id'],
      typeM: json['tipo_macchina'],
      stateM: json['stato_macchina'],
      stateT: json['stato'],
      indirizzo: json['indirizzo'],
      data: DateFormat('dd/MM/yyyy').format(DateTime.parse(json['data'])),
      oraPrevista: json['oraPrevista'],
    );
  }
}
