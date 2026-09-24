import 'package:geolocator/geolocator.dart';

import '../../core/lat_lng.dart';

/// The device-location fallback for a post pin (used when the picked photo has
/// no GPS of its own), and the home map's opening position. Best-effort — any
/// failure returns null and the caller falls back to the next source.
class PostLocationService {
  const PostLocationService();

  /// The device's current location, or null if location is off / denied / fails.
  Future<LatLng?> currentDeviceLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
