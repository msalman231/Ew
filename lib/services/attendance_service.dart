import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:efficient_works/config/constants.dart';

class AttendanceService {
  /// ---------------------------
  /// CHECK-IN
  /// ---------------------------
  static Future<bool> checkIn(int userId) async {
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.baseUrl}/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emp_id": userId, "type": "in"}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print("CHECK-IN SUCCESS : ${body["message"] ?? "OK"}");
        return true;
      }

      print("CHECK-IN FAILED : ${res.body}");
      return false;
    } catch (e) {
      print("CHECK-IN ERROR → $e");
      return false;
    }
  }

  /// ---------------------------
  /// CHECK-OUT
  /// ---------------------------
  static Future<bool> checkOut(int userId) async {
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.baseUrl}/attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emp_id": userId, "type": "out"}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final workedHours = body["data"]?["worked_hours"]?["total_hours"];
        if (workedHours != null) {
          print("TOTAL WORKED HOURS : $workedHours");
        }

        return true;
      }

      print("CHECK-OUT FAILED : ${res.body}");
      return false;
    } catch (e) {
      print("CHECK-OUT ERROR → $e");
      return false;
    }
  }
}
