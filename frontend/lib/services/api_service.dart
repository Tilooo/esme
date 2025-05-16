import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location.dart';
import '../models/category.dart';
import '../models/point_of_interest.dart';

class ApiService {
  final String baseUrl = 'http://localhost:8000/api';

  Future<List<PointOfInterest>> getPointsOfInterest() async {
    final response = await http.get(Uri.parse('$baseUrl/points/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => PointOfInterest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load points of interest');
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Location>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/locations/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }
}
