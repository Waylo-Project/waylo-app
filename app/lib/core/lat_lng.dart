/// A plain latitude/longitude pair, independent of any map SDK.
///
/// The post flow (pick photo, read EXIF, resolve location) speaks this type so
/// it stays provider-agnostic; only the map widgets convert to/from Mapbox's
/// `Point`/`Position` at the boundary.
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
