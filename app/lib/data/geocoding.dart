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

/// Runs one Mapbox geocoding request ([search] is "lng,lat" for a reverse
/// lookup, or URL-encoded text) and hands the result features to [parse].
/// Every lookup is best-effort: a non-200 response or any error gives
/// [fallback], never a throw.
Future<T> _geocode<T>(
  String search,
  Map<String, String> params, {
  required T fallback,
  required T Function(List<Map<String, dynamic>> features) parse,
}) async {
  try {
    final uri =
        Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$search.json',
        ).replace(
          queryParameters: {
            ...params,
            'access_token': AppConfig.mapboxPublicToken,
          },
        );
    final res = await http.get(uri);
    if (res.statusCode != 200) return fallback;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return parse((data['features'] as List).cast<Map<String, dynamic>>());
  } catch (_) {
    return fallback;
  }
}

String _at(LatLng loc) => '${loc.longitude},${loc.latitude}';

LatLng _centerOf(Map<String, dynamic> feature) {
  final c = feature['center'] as List;
  return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
}

/// A short place name (city/locality) for a location, for the photo sheet
/// headline. Null on failure.
Future<String?> reversePlaceName(LatLng loc) => _geocode(
  _at(loc),
  {'types': 'place', 'language': _geoLanguage(), 'limit': '1'},
  fallback: null,
  parse: (f) => f.isEmpty ? null : f.first['text'] as String?,
);

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
/// feature carries the country in its `context`. Blank on failure.
Future<PlaceLabel> reversePlaceLabel(LatLng loc) => _geocode(
  _at(loc),
  {'types': 'place', 'language': _geoLanguage(), 'limit': '1'},
  fallback: const PlaceLabel(),
  parse: (f) {
    if (f.isEmpty) return const PlaceLabel();
    String? country;
    String? code;
    for (final c in (f.first['context'] as List?) ?? const []) {
      final m = c as Map<String, dynamic>;
      if (((m['id'] as String?) ?? '').startsWith('country')) {
        country = m['text'] as String?;
        code = (m['short_code'] as String?)?.toLowerCase();
      }
    }
    return PlaceLabel(
      place: f.first['text'] as String?,
      country: country,
      countryCode: code,
    );
  },
);

/// One forward-geocoding search hit: a human-readable label and its coordinate.
class PlaceResult {
  const PlaceResult({required this.name, required this.location});
  final String name;
  final LatLng location;
}

/// Forward-geocode a free-text query to a handful of place candidates (for the
/// "Search a place" box on the post map). Empty on failure.
Future<List<PlaceResult>> searchPlaces(String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  return _geocode(
    Uri.encodeComponent(q),
    {'limit': '6', 'language': _geoLanguage()},
    fallback: const [],
    parse: (f) => [
      for (final feature in f)
        if (feature['center'] is List)
          PlaceResult(
            name:
                (feature['place_name'] as String?) ??
                (feature['text'] as String? ?? ''),
            location: _centerOf(feature),
          ),
    ],
  );
}

/// Country center cache (cc -> center), so each country is geocoded once.
final Map<String, LatLng> _countryCenterCache = {};

/// The geographic center of a country, used to place the zoomed-out flag
/// marker so it sits on the country rather than on the user's photos. Cached;
/// null on failure (the caller falls back to the posts' centroid).
Future<LatLng?> countryCenter(String countryCode) async {
  final cached = _countryCenterCache[countryCode];
  if (cached != null) return cached;
  // The query text is a 2-letter code, which Mapbox matches against country
  // NAMES too -- "no" hits "North Korea", "is" hits "Israel". The country=
  // filter restricts results to the intended country, and we double-check the
  // returned short_code so a mismatch falls back rather than misplacing a flag.
  final center = await _geocode<LatLng?>(
    countryCode,
    {'types': 'country', 'country': countryCode, 'limit': '1'},
    fallback: null,
    parse: (f) {
      if (f.isEmpty) return null;
      final shortCode =
          (f.first['properties'] as Map?)?['short_code'] as String?;
      if (shortCode != null &&
          shortCode.toLowerCase() != countryCode.toLowerCase()) {
        return null;
      }
      return _centerOf(f.first);
    },
  );
  if (center != null) _countryCenterCache[countryCode] = center;
  return center;
}

/// Reverse-geocodes a location to an ISO 3166-1 alpha-2 country code (lowercase,
/// matching the bundled flag asset filenames). Null on failure, so posting
/// still works (the post just has no flag).
Future<String?> reverseCountryCode(LatLng loc) => _geocode(
  _at(loc),
  {'types': 'country', 'limit': '1'},
  fallback: null,
  parse: (f) => f.isEmpty
      ? null
      : ((f.first['properties'] as Map?)?['short_code'] as String?)
            ?.toLowerCase(),
);
