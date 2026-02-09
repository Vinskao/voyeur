class Person {
  final String name;

  Person({required this.name});

  String get id => name;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
  };
}
