import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

final String baseUrl = "https://f5vfl9mt-3000.inc1.devtunnels.ms";

class RestaurantService {
  static Future<List<dynamic>> getRestaurants() async {
    final res = await http.get(Uri.parse("$baseUrl/restaurants"));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<bool> addRestaurant(
    int userId,
    String name,
    String resType,
    String phone,
    String contact,
    String location,
    String latitude,
    String longitude,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/restaurants"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId, // ⭐ send current user ID
        "name": name,
        "res_type": resType,
        "phone": phone,
        "contact": contact,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    return res.statusCode == 201;
  }

  // restaurant_service.dart

  static Future<bool> updateRestaurant(
    int id,
    String name,
    String resType,
    String phone,
    String contact,
    String location,
    String latitude,
    String longitude,
  ) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/restaurants/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "res_type": resType,
          "phone": phone,
          "contact": contact,
          "location": location,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("ERROR → updateRestaurant(): $e");
      return false;
    }
  }

  static Future<List<dynamic>> getRestaurantsByUser(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/restaurants/$userId"));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> trackLocation({
    required int userId,
    required String email,
    required String latitude,
    required String longitude,
    required String address,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/track-location"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "email": email,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
      }),
    );
  }
}
