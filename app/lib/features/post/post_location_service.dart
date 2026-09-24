import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/lat_lng.dart';

/// What we could read out of a photo's EXIF metadata.
class PhotoExif {
  const PhotoExif({this.location, this.takenAt});

  /// GPS position stamped in the photo, or null if absent.
  final LatLng? location;

  /// When the photo was taken (DateTimeOriginal), or null if absent.
  final DateTime? takenAt;
}

/// Resolves where a post pin should start: EXIF GPS first, the device's current
/// location as the fallback (per DESIGN.md). Reads are best-effort — any failure
/// returns null and the caller falls back to the next source.
class PostLocationService {
  const PostLocationService();

  /// Reads GPS + capture time from a photo's EXIF. Never throws; returns an
  /// empty [PhotoExif] if the file can't be parsed.
  Future<PhotoExif> readExif(File photo) async {
    try {
      final Uint8List bytes = await photo.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return const PhotoExif();

      final location = _gpsLocation(tags);
      final takenAt = _parseExifDate(
        tags['EXIF DateTimeOriginal']?.printable ??
            tags['Image DateTime']?.printable,
      );
      return PhotoExif(location: location, takenAt: takenAt);
    } catch (_) {
      return const PhotoExif();
    }
  }

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

  // --- EXIF parsing helpers -------------------------------------------------

  LatLng? _gpsLocation(Map<String, IfdTag> tags) {
    final lat = _dms(tags['GPS GPSLatitude'], tags['GPS GPSLatitudeRef']);
    final lng = _dms(tags['GPS GPSLongitude'], tags['GPS GPSLongitudeRef']);
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null; // missing/garbage stamp
    return LatLng(lat, lng);
  }

  /// Converts a GPS coordinate (degrees/minutes/seconds as rationals) plus its
  /// N/S/E/W reference into a signed decimal degree.
  double? _dms(IfdTag? value, IfdTag? ref) {
    if (value == null || ref == null) return null;
    final parts = value.values.toList();
    if (parts.length < 3) return null;

    double asDouble(dynamic r) {
      final ratio = r as Ratio;
      if (ratio.denominator == 0) return 0;
      return ratio.numerator / ratio.denominator;
    }

    final degrees =
        asDouble(parts[0]) +
        asDouble(parts[1]) / 60 +
        asDouble(parts[2]) / 3600;

    final hemisphere = ref.printable.trim().toUpperCase();
    final negative = hemisphere.startsWith('S') || hemisphere.startsWith('W');
    return negative ? -degrees : degrees;
  }

  /// Parses the EXIF datetime format "yyyy:MM:dd HH:mm:ss" (no timezone -> local).
  DateTime? _parseExifDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(
      r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(raw);
    if (m == null) return null;
    return DateTime(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
  }
}
