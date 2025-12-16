import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:efficient_works/config/constants.dart';

class RestaurantService {
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
    String? product,
    String? posMulti,
    String? cost,
    String? discount,
    String? balance,
    String? toPay,
    String? amountPaid,
    String? paymentDetails,
    String? closedReason,
  }) async {
    final body = {
      "user_id": userId,
      "name": name,
      "email": email,
      "product": product,
      "pos_multi": posMulti,

      "cost": cost,
      "discount": discount,
      "to_pay": toPay,
      "amount_paid": amountPaid,
      "balance": balance,

      "payment_detials": paymentDetails,
      "closed_reason": closedReason,

      "res_type": resType.toLowerCase(),
      "contact": contact,
      "phone": phone,
      "location": location,
      "latitude": latitude,
      "longitude": longitude,
    };

    // Remove null / empty values
    body.removeWhere((k, v) => v == null || v.toString().trim().isEmpty);

    final res = await http.post(
      Uri.parse("${AppConfig.baseUrl}/restaurants"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("POST PAYLOAD => ${jsonEncode(body)}");
    print("RESPONSE => ${res.body}");

    return res.statusCode == 201;
  }

  // UPDATE restaurant (PUT). Includes payment fields.
  static Future<bool> updateRestaurant(
    int id,
    String resType, {
    String? name,
    String? email,
    String? product,
    String? posMulti,
    String? cost,
    String? discount,
    String? toPay,
    String? amountPaid,
    String? balance,
    String? paymentDetails,
    String? contact,
    String? phone,
    String? location,
    String? latitude,
    String? longitude,
    String? closedReason,
  }) async {
    final url = "${AppConfig.baseUrl}/restaurant/$id";

    Map<String, dynamic> body;

    if (resType.toLowerCase() == "conversion") {
      body = {
        "name": name,
        "email": email,
        "product": product,
        "pos_multi": posMulti,

        "cost": cost,
        "discount": discount,
        "to_pay": toPay,
        "amount_paid": amountPaid,
        "balance": balance,

        "payment_detials": paymentDetails,

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

    body.removeWhere((k, v) => v == null || v.toString().trim().isEmpty);

    final res = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("UPDATE PAYLOAD => ${jsonEncode(body)}");
    print("RESPONSE => ${res.body}");

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

  static Future<List<dynamic>> getRestaurants() async {
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/restaurants_role"),
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
