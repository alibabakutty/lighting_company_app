import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isDenied) return null;
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<String> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return "Unknown location";

      Placemark place = placemarks.first;
      return "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
    } catch (e) {
      return "Unknown location";
    }
  }

  static Future<bool> isWithinAuthorizedArea(Position position) async {
    const List<Map<String, double>> authorizedLocations = [
      {
        'lat': 12.9716,
        'lng': 77.5946,
        'radius': 100.0,
      }, // Example: Bangalore with 100m radius
    ];

    for (var loc in authorizedLocations) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        loc['lat'] ?? 0.0,
        loc['lng'] ?? 0.0,
      );

      if (distance <= (loc['radius'] ?? 0.0)) {
        return true;
      }
    }
    return false;
  }
}
