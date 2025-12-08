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
    String name,
    String resType,
    String phone,
    String contact,
  ) async {
    try {
      final loc = await LocationService.getLocationDetails();

      final res = await http.post(
        Uri.parse("$baseUrl/restaurants"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "res_type": resType,
          "phone": phone,
          "contact": contact,
          "location": loc["address"],
          "latitude": loc["latitude"],
          "longitude": loc["longitude"],
        }),
      );

      return res.statusCode == 201;
    } catch (e) {
      print("ERROR → addRestaurant(): $e");
      return false;
    }
  }

  // restaurant_service.dart

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
