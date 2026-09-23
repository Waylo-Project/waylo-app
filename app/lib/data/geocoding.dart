import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/lat_lng.dart';
import '../core/locale_controller.dart';

/// The Mapbox geocoding `language` for the active UI language, so place /
/// country names match what the rest of the app shows. Chinese is requested as
/// `zh-Hans`: the app's Chinese strings are Simplified, while a bare `zh` makes
/// Mapbox return Traditional place names.
String _geoLanguage() {
  final code = LocaleController.instance.resolvedLanguageCode;
  return code == 'zh' ? 'zh-Hans' : code;
}

/// A short place name (city/locality) for a location, for the photo sheet
/// headline. Best-effort; null on failure. [language] overrides the resolved
/// UI language (defaults to it).
Future<String?> reversePlaceName(LatLng loc, {String? language}) async {
  try {
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${loc.longitude},${loc.latitude}.json'
      '?types=place&language=${language ?? _geoLanguage()}&limit=1'
      '&access_token=${AppConfig.mapboxPublicToken}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) return null;
    return (features.first as Map<String, dynamic>)['text'] as String?;
  } catch (_) {
    return null;
  }
}

/// A place headline plus its country, resolved in one reverse-geocode: the city
/// text, the country name, and the ISO alpha-2 code (lowercase, for the flag
/// asset). Used by the "Just in" cards (e.g. "Seoul · Korea" + 🇰🇷).
class PlaceLabel {
  const PlaceLabel({this.place, this.country, this.countryCode});
  final String? place;
  final String? country;
  final String? countryCode;
}

/// Reverse-geocode a location to a [PlaceLabel] in a single call: the `place`
/// feature carries the country in its `context`. Best-effort; blank on failure.
/// [language] overrides the resolved UI language (defaults to it).
Future<PlaceLabel> reversePlaceLabel(LatLng loc, {String? language}) async {
  try {
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${loc.longitude},${loc.latitude}.json'
      '?types=place&language=${language ?? _geoLanguage()}&limit=1'
      '&access_token=${AppConfig.mapboxPublicToken}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return const PlaceLabel();
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) return const PlaceLabel();
    final feature = features.first as Map<String, dynamic>;
    final place = feature['text'] as String?;
    String? country;
    String? code;
    final context = feature['context'] as List<dynamic>?;
    if (context != null) {
      for (final c in context) {
        final m = c as Map<String, dynamic>;
        if (((m['id'] as String?) ?? '').startsWith('country')) {
          country = m['text'] as String?;
          code = (m['short_code'] as String?)?.toLowerCase();
        }
      }
    }
    return PlaceLabel(place: place, country: country, countryCode: code);
  } catch (_) {
    return const PlaceLabel();
  }
}

/// One forward-geocoding search hit: a human-readable label and its coordinate.
class PlaceResult {
  const PlaceResult({required this.name, required this.location});
  final String name;
  final LatLng location;
}

/// Forward-geocode a free-text query to a handful of place candidates (for the
/// "Search a place" box on the post map). Best-effort; empty on failure.
/// [language] overrides the resolved UI language (defaults to it).
Future<List<PlaceResult>> searchPlaces(String query, {String? language}) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  try {
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${Uri.encodeComponent(q)}.json'
      '?limit=6&language=${language ?? _geoLanguage()}'
      '&access_token=${AppConfig.mapboxPublicToken}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    return [
      for (final f in features)
        if (f is Map<String, dynamic> && f['center'] is List)
          PlaceResult(
            name: (f['place_name'] as String?) ?? (f['text'] as String? ?? ''),
            location: LatLng(
              ((f['center'] as List)[1] as num).toDouble(),
              ((f['center'] as List)[0] as num).toDouble(),
            ),
          ),
    ];
  } catch (_) {
    return const [];
  }
}

/// Country center cache (cc -> center), so each country is geocoded once.
final Map<String, LatLng> _countryCenterCache = {};

/// The geographic center of a country (Mapbox forward geocode of the country
/// code), used to place the zoomed-out flag marker — like the original waylo,
/// so the flag sits on the country, not on the user's photos. Cached; null on
/// failure (caller falls back to the posts' centroid).
Future<LatLng?> countryCenter(String countryCode) async {
  final cached = _countryCenterCache[countryCode];
  if (cached != null) return cached;
  try {
    // The query text is a 2-letter code, which Mapbox matches against country
    // NAMES too -- "no" hits "North Korea", "is" hits "Israel". The country=
    // filter restricts results to the intended country, and we double-check the
    // returned short_code so a mismatch falls back rather than misplacing a flag.
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '$countryCode.json?types=country&country=$countryCode&limit=1'
      '&access_token=${AppConfig.mapboxPublicToken}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) return null;
    final feature = features.first as Map<String, dynamic>;
    final shortCode = (feature['properties'] as Map?)?['short_code'] as String?;
    if (shortCode != null &&
        shortCode.toLowerCase() != countryCode.toLowerCase()) {
      return null;
    }
    final center = feature['center'] as List;
    final ll = LatLng(
      (center[1] as num).toDouble(),
      (center[0] as num).toDouble(),
    );
    _countryCenterCache[countryCode] = ll;
    return ll;
  } catch (_) {
    return null;
  }
}

/// Reverse-geocodes a location to an ISO 3166-1 alpha-2 country code (lowercase,
/// matching the bundled flag asset filenames) via Mapbox. Best-effort: returns
/// null on any failure so posting still works (the post just has no flag).
Future<String?> reverseCountryCode(LatLng loc) async {
  try {
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${loc.longitude},${loc.latitude}.json'
      '?types=country&limit=1&access_token=${AppConfig.mapboxPublicToken}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) return null;
    final props =
        (features.first as Map<String, dynamic>)['properties'] as Map?;
    final code = props?['short_code'] as String?;
    return code?.toLowerCase();
  } catch (_) {
    return null;
  }
}
