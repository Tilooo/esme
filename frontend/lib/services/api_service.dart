import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';
import '../models/category.dart' as app_models;
import '../models/point_of_interest.dart';

class ApiService {
  // Get the appropriate base URL based on platform and environment
  String get baseUrl {
    // For web
    if (kIsWeb) return 'http://localhost:8000/api';
    
    // For Android emulator
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    
    // For iOS simulator
    if (Platform.isIOS) return 'http://localhost:8000/api';
    
    // For physical devices, used computer's actual IP address
    // return 'http://192.168.1.X:8000/api';
    
    // Default fallback
    return 'http://localhost:8000/api';
  }

  Future<List<PointOfInterest>> getPointsOfInterest() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/points/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => PointOfInterest.fromJson(json)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch, uri=$baseUrl/points/ - Error: $e');
    }
  }

  Future<List<app_models.Category>> getCategories() async { // Use the alias here
    final response = await http.get(Uri.parse('$baseUrl/categories/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => app_models.Category.fromJson(json)).toList(); // Use the alias here
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  Future<List<Location>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/locations/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load locations: ${response.statusCode}');
    }
  }
  
  // Added method to get nearby points using the backend API
  Future<List<Map<String, dynamic>>> getNearbyPoints(double lat, double lng, double radius) async {
    final response = await http.get(
      Uri.parse('$baseUrl/nearby/?lat=$lat&lng=$lng&radius=$radius'),
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load nearby points: ${response.statusCode}');
    }
  }
}
