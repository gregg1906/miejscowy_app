class Kategoria {
  final String id;
  final String nazwa;

  Kategoria({
    required this.id,
    required this.nazwa,
  });

  factory Kategoria.fromJson(Map<String, dynamic> json) {
    return Kategoria(
      id: json['id'] as String,
      nazwa: json['nazwa'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nazwa': nazwa,
    };
  }
}
