import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../services/location_service.dart';

import 'package:efficient_works/config/constants.dart';

class RestaurantService {
  static Future<List<dynamic>> getRestaurants() async {
    final res = await http.get(Uri.parse(" ${AppConfig.baseUrl}/restaurants"));
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
    String? email,
    String? product,
    String? posMulti,
    String? cost,
    String? discount,
    String? balance,
    String? paymentMethod,
    String? comment,
    String? closedReason,
  ) async {
    final res = await http.post(
      Uri.parse("${AppConfig.baseUrl}/restaurants"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "name": name,
        "res_type": resType,
        "phone": phone,
        "contact": contact,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,

        "email": email,
        "product": product,
        "pos_multi": posMulti,
        "cost": cost,
        "discount": discount,
        "balance": balance, // ✔ correct position
        "payment_method": paymentMethod, // ✔ correct position
        "comment": comment,
        "closed_reason": closedReason,
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
    String longitude, {
    String? email,
    String? product,
    String? posMulti,
    String? cost,
    String? discount,
    String? balance,
    String? paymentMethod,
    String? comment,
    String? closedReason,
    String? savedDate, // NEW FIELD
  }) async {
    try {
      final res = await http.put(
        Uri.parse("${AppConfig.baseUrl}/restaurants/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "res_type": resType,
          "phone": phone,
          "contact": contact,
          "location": location,
          "latitude": latitude,
          "longitude": longitude,

          // ADD THESE FIELDS (same as addRestaurant)
          "email": email,
          "product": product,
          "pos_multi": posMulti,
          "cost": cost,
          "discount": discount,
          "balance": balance,
          "payment_method": paymentMethod,
          "comment": comment,
          "closed_reason": closedReason,

          // NEW FIELD
          "saved_date": savedDate,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("ERROR → updateRestaurant(): $e");
      return false;
    }
  }

  static Future<List<dynamic>> getRestaurantsByUser(int userId) async {
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/restaurants/$userId"),
    );
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
      Uri.parse("${AppConfig.baseUrl}/track-location"),
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
