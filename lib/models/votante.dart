// To parse this JSON data, do
//
//     final votante = votanteFromMap(jsonString);

import 'dart:convert';

class Votante {
  Votante({
    required this.name,
  });

  String name;

  factory Votante.fromJson(String str) => Votante.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Votante.fromMap(Map<String, dynamic> json) => Votante(
        name: json["voterName"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
      };
}
