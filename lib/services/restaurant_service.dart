import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:efficient_works/config/constants.dart';

class RestaurantService {
  // GET all restaurants (example)
  static Future<List<dynamic>> getRestaurants() async {
    final res = await http.get(Uri.parse("${AppConfig.baseUrl}/restaurants"));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // ADD restaurant (POST)
  static Future<bool> addRestaurant(
    int userId,
    String name,
    String resType,
    String phone,
    String contact,
    String location,
    String latitude,
    String longitude, {
    String? email,
    String? visitType,
    String? posMulti,
    String? cost,
    String? discount,
    String? balance,
    String? paymentMethod,
    String? paymentDetails, // JSON or Settled
    String? toPay,
    String? amountPaid,
    String? closedReason,
    String? comment,
  }) async {
    final body = {
      "user_id": userId,
      "name": name,
      "res_type": resType,
      "phone": phone,
      "contact": contact,
      "location": location,
      "latitude": latitude,
      "longitude": longitude,

      "email": email,
      "product": visitType,
      "pos_multi": posMulti,
      "cost": cost,
      "discount": discount,

      "to_pay": toPay,
      "amount_paid": amountPaid,
      "balance": balance,

      "payment_method": paymentMethod,

      // IMPORTANT: Use exact DB column
      "payment_detials": paymentDetails,

      "closed_reason": closedReason,
      "comment": comment,
    };

    // Remove null or empty
    body.removeWhere(
      (key, value) => value == null || value.toString().trim().isEmpty,
    );

    final res = await http.post(
      Uri.parse("${AppConfig.baseUrl}/restaurants"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("SENDING JSON: ${jsonEncode(body)}");
    print("RESPONSE: ${res.body}");

    return res.statusCode == 201;
  }

  // UPDATE restaurant (PUT). Includes payment fields.
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
    String? visitType,
    String? posMulti,
    String? cost,
    String? discount,
    String? balance,
    String? toPay,
    String? amount,
    String? paymentDetails, // <-- MUST map to payment_detials
    String? closedReason,
  }) async {
    final url = "${AppConfig.baseUrl}/restaurant/$id";

    Map<String, dynamic> body;

    if (resType == "conversion") {
      body = {
        "name": name,
        "email": email,
        "product": visitType,
        "pos_multi": posMulti,
        "cost": cost,
        "discount": discount,
        "balance": balance,
        "to_pay": toPay,
        "amount_paid": amount,
        "payment_detials": paymentDetails, // <-- EXACT MATCH
        "contact": contact,
        "phone": phone,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "res_type": "conversion",
      };
    } else {
      body = {"closed_reason": closedReason, "res_type": "closed"};
    }

    final res = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  // Convenience: update payments only (optional). PUT /restaurants/:id/payments (implement backend if using)
  static Future<bool> updatePayments(
    int id,
    String paymentDetails,
    String toPay,
    String amount,
  ) async {
    final body = {"to_pay": toPay, "amount": amount};
    final res = await http.put(
      Uri.parse(
        "${AppConfig.baseUrl}/restaurants/$id",
      ), // reuse same endpoint (server must accept)
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return res.statusCode == 200;
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
