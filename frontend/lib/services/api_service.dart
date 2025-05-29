import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';
import '../models/category.dart' as app_models;
import '../models/point_of_interest.dart';

class ApiService {
  // Gets the appropriate base URL based on platform and environment
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

  Future<List<app_models.Category>> getCategories() async { // the alias
    final response = await http.get(Uri.parse('$baseUrl/categories/'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => app_models.Category.fromJson(json)).toList(); // The alias
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
  
  // Method to get nearby points using the backend API
  Future<List<PointOfInterest>> getNearbyPoints(double lat, double lng, double radius) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nearby/?lat=$lat&lng=$lng&radius=$radius'),
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // F to see the raw response
        print('Raw API response: ${response.body}');
        
        // Handles empty response gracefully
        if (data.isEmpty) {
          print('No nearby points found within ${radius}km');
          return [];
        }
        
        List<PointOfInterest> points = [];
        
        // Processes each item with better type checking
        for (var i = 0; i < data.length; i++) {
          try {
            var pointData = data[i];
            print('Processing item $i: $pointData (type: ${pointData.runtimeType})');
            
            if (pointData is Map<String, dynamic>) {
              points.add(PointOfInterest.fromJson(pointData));
            } else if (pointData is int) {
              print('Skipping integer value: $pointData');
            } else {
              print('Unexpected data type: ${pointData.runtimeType}');
            }
          } catch (e) {
            print('Error processing point at index $i: $e');
          }
        }
        
        return points;
      } else {
        throw Exception('Failed to load nearby points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch nearby points: $e');
    }
  }

  // Searches functionality
  Future<List<PointOfInterest>> searchPoints(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/points/search/?q=$query'),
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => PointOfInterest.fromJson(json)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }
}
