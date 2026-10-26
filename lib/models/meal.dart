/// A meal the student buys regularly (primary SQLite record).
class Meal {
  static const categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  final int? id;
  final String name;
  final String location;
  final String category;
  final double typicalPrice;
  final DateTime createdAt;

  const Meal({
    this.id,
    required this.name,
    this.location = '',
    required this.category,
    required this.typicalPrice,
    required this.createdAt,
  });

  Meal copyWith({
    int? id,
    String? name,
    String? location,
    String? category,
    double? typicalPrice,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      category: category ?? this.category,
      typicalPrice: typicalPrice ?? this.typicalPrice,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'category': category,
        'typical_price': typicalPrice,
        'created_at': createdAt.toIso8601String(),
      };

  factory Meal.fromMap(Map<String, Object?> m) => Meal(
        id: m['id'] as int?,
        name: m['name'] as String,
        location: (m['location'] as String?) ?? '',
        category: m['category'] as String,
        typicalPrice: (m['typical_price'] as num).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
