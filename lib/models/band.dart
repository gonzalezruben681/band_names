class Band {
  String id;
  String name;
  int? votes;

  Band({
    required this.id,
    required this.name,
    this.votes,
  });

// factory constructor tiene como objetivo regresar una nueva instancia de la clase band
  factory Band.fromMap(Map<String, dynamic> json) => Band(
        id: json['id'],
        name: json['name'],
        votes: json['votes'],
      );
}
