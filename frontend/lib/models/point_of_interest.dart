import 'category.dart';

class PointOfInterest {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final Category? category;
  final String? address;
  final DateTime createdAt;
  final int? createdById;

  PointOfInterest({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.category,
    this.address,
    required this.createdAt,
    this.createdById,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      // Handle both cases: when category is an ID (int) or a full object (Map)
      category: json['category'] != null ? 
        (json['category'] is Map<String, dynamic> ? 
          Category.fromJson(json['category']) : 
          Category(id: json['category'], name: json['category_name'] ?? 'Unknown', icon: null)) : 
        null,
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
      createdById: json['created_by'] is Map ? json['created_by']['id'] : json['created_by'],
    );
  }
}