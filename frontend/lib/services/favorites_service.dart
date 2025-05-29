import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/point_of_interest.dart';
import 'auth_service.dart';

class FavoritesService {
  final String baseUrl;
  final AuthService authService;
  
  FavoritesService({required this.baseUrl, required this.authService});
  
  // Gets user's favorite points
  Future<List<PointOfInterest>> getFavorites() async {
    final token = await authService.getToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PointOfInterest.fromJson(json['point'])).toList();
      } else {
        print('Failed to get favorites: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Favorites error: $e');
      return [];
    }
  }
  
  // Adds a point to favorites
  Future<bool> addFavorite(int pointId) async {
    final token = await authService.getToken();
    if (token == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'point_id': pointId,
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Add favorite error: $e');
      return false;
    }
  }
  
  // Removes a point from favorites
  Future<bool> removeFavorite(int pointId) async {
    final token = await authService.getToken();
    if (token == null) return false;
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$pointId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 204;
    } catch (e) {
      print('Remove favorite error: $e');
      return false;
    }
  }
  
  // Checks if a point is in favorites
  Future<bool> isFavorite(int pointId) async {
    final favorites = await getFavorites();
    return favorites.any((point) => point.id == pointId);
  }
}