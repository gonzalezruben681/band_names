class Category {
  String name;
  String id;

  Category({required this.name, required this.id});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
      };
}
