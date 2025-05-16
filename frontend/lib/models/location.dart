class Location {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final int createdById;

  Location({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.createdById,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
      createdById: json['created_by'],
    );
  }
}