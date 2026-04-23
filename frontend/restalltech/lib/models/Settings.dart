import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Settings {
  final int id;
  final String descr, value;

  const Settings({
    required this.id,
    required this.descr,
    required this.value,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
        id: json['id'], descr: json['descr'], value: json['value'].toString());
  }
}
