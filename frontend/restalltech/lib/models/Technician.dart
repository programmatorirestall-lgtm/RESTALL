import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Technician {
  final int id;
  final String nome, cognome, verified;

  const Technician({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.verified,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
        id: json['id'],
        nome: json['nome'],
        cognome: json['cognome'],
        verified: json['verified']);
  }
}
