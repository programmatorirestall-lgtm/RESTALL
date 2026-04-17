import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Ticket {
  final int id;
  final String typeM, stateM, data, stateT, indirizzo, cognome, nome;
  final String ragSoc;
  final String? oraPrevista;
  final DateTime? createdAt;

  const Ticket(
      {required this.id,
      required this.typeM,
      required this.stateM,
      required this.stateT,
      required this.nome,
      required this.cognome,
      required this.ragSoc,
      required this.indirizzo,
      this.oraPrevista,
      this.createdAt,
      required this.data});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    var user = json['utente'];

    // Logica per ragSoc (stessa dell'admin)
    String ragSoc;
    if (json['ragSocAzienda'] != null &&
        json['ragSocAzienda'].toString().isNotEmpty) {
      ragSoc = json['ragSocAzienda'].toString();
    } else if (user['cognome'].toString().isEmpty &&
        user['nome'].toString().isEmpty) {
      ragSoc = "UTENTE ELIMINATO";
    } else {
      ragSoc = user['cognome'] + ' ' + user['nome'];
    }

    return Ticket(
      id: json['id'],
      nome: user['nome'],
      cognome: user['cognome'],
      ragSoc: ragSoc,
      typeM: json['tipo_macchina'],
      stateM: json['stato_macchina'],
      stateT: json['stato'],
      indirizzo: json['indirizzo'],
      data: DateFormat('dd/MM/yyyy').format(DateTime.parse(json['data'])),
      oraPrevista: json['oraPrevista'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
