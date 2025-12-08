import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
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
