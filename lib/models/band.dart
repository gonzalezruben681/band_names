// To parse this JSON data, do
//
//     final band = bandFromMap(jsonString);

import 'dart:convert';

class Band {
  Band({
    required this.id,
    required this.name,
    this.votes,
  });

  String id;
  String name;
  int? votes;

  factory Band.fromJson(String str) => Band.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());
  // factory constructor tiene como objetivo regresar una nueva instancia de la clase band
  factory Band.fromMap(Map<String, dynamic> json) => Band(
        id: json["_id"],
        name: json["name"],
        votes: json["votes"],
      );

  Map<String, dynamic> toMap() => {
        "_id": id,
        "name": name,
        "votes": votes,
      };
}
