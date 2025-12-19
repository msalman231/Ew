import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:efficient_works/config/constants.dart';

class LocationService {
  static Future<void> trackLocation({
    required int userId,
    required String email,
    required String latitude,
    required String longitude,
    required String address,
  }) async {
    final res = await http.post(
      Uri.parse("${AppConfig.baseUrl}/track-location"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId, // ✅ FINAL & CORRECT
        "email": email,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
      }),
    );

    print("TRACK LOCATION STATUS : ${res.statusCode}");
    print("TRACK LOCATION BODY   : ${res.body}");
  }

  static Future<Map<String, String>> getLocationDetails() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      throw Exception("Location permission denied forever");
    }

    Position pos = await Geolocator.getCurrentPosition();
    List<Placemark> place = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    String addr =
        "${place.first.street}, ${place.first.locality}, ${place.first.administrativeArea}, ${place.first.country}";

    return {
      "latitude": pos.latitude.toString(),
      "longitude": pos.longitude.toString(),
      "address": addr,
    };
  }
}
