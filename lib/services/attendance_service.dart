import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl =
      "https://leads.efficient-works.com"; // update if needed

  /// CHECK-IN
  static Future<bool> checkIn(int userId, String username) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "username": username,
          "type": "in",
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Check-In Error → $e");
      return false;
    }
  }

  /// CHECK-OUT
  static Future<bool> checkOut(int userId, String username) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "username": username,
          "type": "out",
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Check-Out Error → $e");
      return false;
    }
  }
}
