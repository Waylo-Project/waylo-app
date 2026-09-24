import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/error_dialog.dart';
import '../../core/lat_lng.dart';
import '../../data/feed_repository.dart';
import '../../data/geocoding.dart';
import '../../data/post_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../photo/photo_sheet.dart';
import '../post/post_location_service.dart';
import '../post/start_new_post.dart';
import 'marker_cache.dart';
import 'photo_marker.dart';

/// A waylo map driven by a [MapFeed]. With a [UserMapFeed] it shows one user's
/// posts (photo tier zoomed in, country flags zoomed out) — each user's own map,
/// never merged. With a [RecentMapFeed] it shows every friend's last-24h posts
/// on one map (photo tier at all zooms). Compose lives in the host page chrome
/// (the home wires its (+) to [PhotoMapViewState.openComposer]); a friend's map
/// hosts it read-only.
class PhotoMapView extends StatefulWidget {
  const PhotoMapView({
    super.key,
    required this.feed,
    this.onPhotosSelected,
    this.emptyText,
    this.startAtMyLocation = false,
  });

  /// What this map shows (a single user's posts, or the merged recent feed).
  final MapFeed feed;

  /// Center the opening globe on the device's location instead of the default
  /// (only the home map sets this — it's "my" map). Falls back to the default
  /// if location is off/denied. The zoom stays fully out either way.
  final bool startAtMyLocation;

  /// Message shown over the map when the feed has no content at all (a brand-new
  /// user's own map, a friend with no posts, an empty recent feed). Null hides
  /// the empty hint. The host supplies it because only it knows the context.
  final String? emptyText;

  /// When set, a marker tap reports its photos to the host instead of showing
  /// the sheet here — so the host (the home) can render the sheet ABOVE its own
  /// chrome (logo / buttons / pill). When null (e.g. a friend's map), this view
  /// shows the sheet itself.
  final ValueChanged<List<FeedPoint>>? onPhotosSelected;

  @override
  State<PhotoMapView> createState() => PhotoMapViewState();
}

class PhotoMapViewState extends State<PhotoMapView> {
  // Default camera target until we have the user's location (Seoul).
  static const LatLng _initialTarget = LatLng(37.5665, 126.9780);
  // Start zoomed all the way out so the globe is visible on open (every map).
  static const double _initialZoom = 1.5;

  // Tracks the map center, used as the last-resort post location when a photo
  // has neither EXIF GPS nor an available device location.
  LatLng _cameraCenter = _initialTarget;

  // At/below this zoom the map shows country flags (Tier A); above it, photos
  // (Tier B). Matches the original waylo threshold (4.0). See DESIGN.md §3.
  static const double _flagZoomMax = 4.0;

  // Fallback zoom base for a flag tap that can't resolve its country's posts:
  // a small margin above _flagZoomMax so it lands in the photo tier (never back
  // on a flag) even after a tiny pan. (Posts that DO resolve are framed to fit;
  // see _frameForPosts.)
  static const double _flagZoomFloor = 4.3;

  final FeedRepository _feed = FeedRepository();
  MapboxMap? _map;
  PointAnnotationManager? _photoManager; // Tier B
  PointAnnotationManager? _flagManager; // Tier A

  // Composed marker PNGs, built once and reused.
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _flagImageCache = {};
  // Avatar bytes for marker badges, cached per public URL (null = none/failed).
  final Map<String, Uint8List?> _avatarBytesCache = {};
  final MarkerCache _markerCache = MarkerCache();
  Uint8List? _placeholder;

  // The photos currently shown in the bottom sheet (a marker's members), or null.
  List<FeedPoint>? _selected;

  // Annotations currently on the map, so each refresh diffs (add/remove changed
  // only) instead of clearing + recreating — which flickered.
  final Map<String, PointAnnotation> _shown = {}; // photos, by iconId
  final Map<String, PointAnnotation> _shownFlags = {}; // flags, by `cc_count`
  final Map<String, _MapMarker> _markerByAnnotation = {};
  // Annotation id -> country code, so a flag tap knows which country to frame.
  final Map<String, String> _flagCodeByAnnotation = {};

  String? _lastViewKey;
  bool _refreshing = false;

  // Initial-load state for the empty / loading / error overlays. The map (globe)
  // is always visible underneath; these only gate the hint shown on top.
  bool _firstLoadDone = false; // initial load (style + first refresh) settled
  bool _loadError = false; // initial content fetch threw (e.g. no network)
  bool _empty = false; // the feed has no content at all
  // The empty hint flashes briefly then fades out, rather than sitting on the
  // map forever (a persistent "no photos" label felt like an error).
  bool _emptyHintGone = false;
  Timer? _emptyHintTimer;

  // Debounce timer for tier-switch detection during camera movement.
  Timer? _tierSwitchTimer;
  // Settle debounce for the recent map: re-cluster shortly after the gesture
  // stops, instead of waiting for the late map-idle event.
  Timer? _settleTimer;
  // Last known tier (true = flag, false = photo) to detect threshold crossings.
  bool? _lastFlagTier;

  // Flag-tap focus: when a tapped country's posts are too spread out to fit
  // above the normal flag threshold, we frame ALL of them anyway (zoom can drop
  // below _flagZoomMax) and force the photo tier so they still render as photos
  // instead of collapsing back to a flag.
  //
  // [_flagFocusPeak] is non-null while a focus is active and holds the highest
  // zoom reached since it armed. [_flagFocusArmed] turns on only after the
  // inbound fly-to settles, so the animation's own zoom changes don't count as a
  // user gesture. Once armed, the first real zoom-out (below the peak) drops the
  // focus and lets flags return — even while still under _flagZoomMax.
  double? _flagFocusPeak;
  bool _flagFocusArmed = false;
  Timer? _flagFocusArmTimer;
  static const double _flagFocusReleaseMargin = 0.15;

  // True when the map should show flags (Tier A) at this zoom. While a flag-tap
  // focus is active we stay in the photo tier regardless of zoom.
  bool _isFlagTier(double zoom) {
    if (!widget.feed.usesFlags) return false;
    if (_flagFocusPeak != null) return false;
    return zoom <= _flagZoomMax;
  }

  // Last time the live re-cluster throttle fired (per-user map photo tier).
  DateTime _lastThrottledRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  // Built once. If a fresh CameraViewportState were passed on every rebuild
  // (e.g. when the photo sheet opens), MapWidget would re-apply it and snap the
  // camera back to the start position. Reusing one instance keeps the camera put.
  late final CameraViewportState _initialViewport = CameraViewportState(
    center: Point(
      coordinates: Position(_initialTarget.longitude, _initialTarget.latitude),
    ),
    zoom: _initialZoom,
  );

  void _onMapCreated(MapboxMap map) {
    _map = map;
    map.style.setProjection(StyleProjection(name: StyleProjectionName.globe));
    // Push the scale bar down so it clears the system status bar (clock); the
    // home chrome (logo + buttons) sits just below it. Margins are in logical
    // pixels.
    map.scaleBar.updateSettings(
      ScaleBarSettings(
        position: OrnamentPosition.TOP_LEFT,
        marginTop: 44,
        marginLeft: 12,
      ),
    );
    // Compass pinned to the very BOTTOM-RIGHT corner — the opposite side from
    // the Mapbox mark (bottom-left), so it clears every chrome element: up top
    // it collided with the Recent header's search button, and a raised margin
    // overlapped the "Just in" strip. Sit it level with the Mapbox logo.
    map.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 8,
        marginRight: 12,
        // Keep it visible (even at north) so the chrome can be spaced to never
        // overlap; flip back to true to hide it when facing north.
        fadeWhenFacingNorth: false,
      ),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || _photoManager != null) return;
    _flagManager = await map.annotations.createPointAnnotationManager();
    _photoManager = await map.annotations.createPointAnnotationManager();
    _photoManager!.tapEvents(onTap: _onPhotoTap);
    _flagManager!.tapEvents(onTap: _onFlagTap);
    if (widget.feed.fitOnLoad) await _fitToContent();
    if (widget.startAtMyLocation) _centerOnMyLocation();
    await _refreshPoints();
    await _evaluateContent();
    if (mounted) setState(() => _firstLoadDone = true);
  }

  /// Best-effort: rotate the opening globe to the device's location (zoom stays
  /// fully out). Silently keeps the default if location is off/denied.
  Future<void> _centerOnMyLocation() async {
    final loc = await const PostLocationService().currentDeviceLocation();
    if (loc == null || _map == null) return;
    await _map!.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(loc.longitude, loc.latitude)),
        zoom: _initialZoom,
      ),
    );
  }

  /// Decide whether the empty hint should show, by asking the feed if it has any
  /// content at all. A throw here (e.g. no network on open) surfaces the error
  /// overlay with a Retry, rather than failing silently to a blank globe.
  Future<void> _evaluateContent() async {
    try {
      final has = await widget.feed.hasContent();
      if (!mounted) return;
      setState(() {
        _empty = !has;
        _loadError = false;
      });
      // Flash the empty hint, then fade it after a few seconds.
      _emptyHintTimer?.cancel();
      if (_empty) {
        _emptyHintGone = false;
        _emptyHintTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _emptyHintGone = true);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = true);
    }
  }

  /// Retry the initial load after a load error (the Retry button on the overlay).
  Future<void> _retryInitialLoad() async {
    setState(() {
      _loadError = false;
      _firstLoadDone = false;
    });
    await _refreshPoints(force: true);
    await _evaluateContent();
    if (mounted) setState(() => _firstLoadDone = true);
  }

  /// Frame the camera over all of the feed's points (used by the recent map,
  /// which has no fixed home location). Centroid + a span-based zoom — a robust
  /// approximation that avoids the finicky cameraForCoordinateBounds API.
  Future<void> _fitToContent() async {
    final map = _map;
    if (map == null) return;
    final pts = await widget.feed.pointsInView(
      const LatLng(-90, -180),
      const LatLng(90, 180),
    );
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      final l = pts.first.location;
      await map.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(l.longitude, l.latitude)),
          zoom: 6,
        ),
      );
      return;
    }
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in pts) {
      final l = p.location;
      minLat = math.min(minLat, l.latitude);
      maxLat = math.max(maxLat, l.latitude);
      minLng = math.min(minLng, l.longitude);
      maxLng = math.max(maxLng, l.longitude);
    }
    final span = math.max(maxLat - minLat, maxLng - minLng);
    final zoom = span > 60
        ? 1.5
        : span > 20
        ? 2.5
        : span > 5
        ? 3.5
        : span > 1
        ? 5.0
        : 8.0;
    await map.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position((minLng + maxLng) / 2, (minLat + maxLat) / 2),
        ),
        zoom: zoom,
      ),
    );
  }

  void _onPhotoTap(PointAnnotation a) {
    final marker = _markerByAnnotation[a.id];
    if (marker == null) return;
    final report = widget.onPhotosSelected;
    if (report != null) {
      report(marker.members);
    } else {
      setState(() => _selected = marker.members);
    }
  }

  /// Tapping a flag frames that country's REAL posts, not the country center
  /// (posts can sit far from it, leaving an empty screen). We fetch the
  /// country's post coordinates and fit them; if they're too spread out to fit
  /// above the flag threshold, we still frame them all as photos and arm a
  /// flag-tap focus (see [_frameForPosts] / [_flagFocusPeak]).
  Future<void> _onFlagTap(PointAnnotation a) async {
    final map = _map;
    if (map == null) return;

    // Fallback to the country center (still inside the photo tier) if we can't
    // resolve the country or fetch its posts.
    Future<void> flyToFlag() => map.flyTo(
      CameraOptions(center: a.geometry, zoom: _flagZoomFloor + 1.5),
      MapAnimationOptions(duration: 800),
    );

    final code = _flagCodeByAnnotation[a.id];
    if (code == null) return flyToFlag();

    List<LatLng> pts;
    try {
      pts = await widget.feed.postLocationsInCountry(code);
    } catch (e) {
      debugPrint('[map] postsForCountry failed for $code: $e');
      return flyToFlag();
    }
    if (pts.isEmpty) return flyToFlag();

    final cam = _frameForPosts(pts);
    _armFlagFocusAfterFly();
    await map.flyTo(cam, MapAnimationOptions(duration: 800));
  }

  /// Arm the flag-tap focus once the inbound fly-to has settled. Until then the
  /// animation's own zoom changes must not count as a user zoom-out, so we wait
  /// a hair past the 800ms animation and re-baseline the peak to where the
  /// camera actually landed.
  void _armFlagFocusAfterFly() {
    if (_flagFocusPeak == null) return;
    _flagFocusArmTimer?.cancel();
    _flagFocusArmTimer = Timer(const Duration(milliseconds: 900), () async {
      final map = _map;
      if (_flagFocusPeak == null || map == null) return;
      _flagFocusPeak = (await map.getCameraState()).zoom;
      _flagFocusArmed = true;
    });
  }

  /// Camera that frames [pts] — always fitting every post on screen. A single
  /// post zooms in close; multiple posts fit their bounding box. If they're so
  /// spread out that the fit drops below the flag threshold, we arm a flag-tap
  /// focus (see [_flagFocusPeak]) so they still render as photos instead of
  /// collapsing back to a flag.
  CameraOptions _frameForPosts(List<LatLng> pts) {
    if (pts.length == 1) {
      _clearFlagFocus();
      final l = pts.first;
      return CameraOptions(
        center: Point(coordinates: Position(l.longitude, l.latitude)),
        zoom: 9,
      );
    }
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final l in pts) {
      minLat = math.min(minLat, l.latitude);
      maxLat = math.max(maxLat, l.latitude);
      minLng = math.min(minLng, l.longitude);
      maxLng = math.max(maxLng, l.longitude);
    }
    final span = math.max(maxLat - minLat, maxLng - minLng);
    final fitZoom = _zoomForSpan(span);
    final center = Point(
      coordinates: Position((minLng + maxLng) / 2, (minLat + maxLat) / 2),
    );
    if (fitZoom > _flagZoomMax) {
      // The fit sits inside the photo tier on its own — ordinary framing.
      _clearFlagFocus();
    } else {
      // So spread out the fit lands in flag territory (zoom <= the flag line).
      // Hold the photo tier here so the whole country shows as photos; the focus
      // arms once the fly settles, then a zoom-out drops it (see _onCameraChanged).
      _flagFocusPeak = fitZoom;
      _flagFocusArmed = false;
    }
    return CameraOptions(center: center, zoom: fitZoom);
  }

  void _clearFlagFocus() {
    _flagFocusArmTimer?.cancel();
    _flagFocusPeak = null;
    _flagFocusArmed = false;
  }

  /// A zoom that fits a [span]-degree extent in the viewport with generous
  /// padding. 360°/2^zoom is the world width; the 3.6 leaves a wide margin so
  /// the posts sit comfortably inside the frame (not pinned to the edges, where
  /// a marker right on the boundary can fail to render).
  double _zoomForSpan(double span) {
    if (span <= 0) return 9;
    final z = math.log(360 / (span * 3.6)) / math.ln2;
    return z.clamp(1.0, 12.0);
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final c = data.cameraState.center.coordinates;
    _cameraCenter = LatLng(c.lat.toDouble(), c.lng.toDouble());

    // The recent map (no flags) only ever shows photos, and its set is small and
    // cached — so re-cluster on a short settle debounce after the gesture stops
    // (the real map-idle event lags), with no busy mid-gesture churn.
    if (!widget.feed.usesFlags) {
      _settleTimer?.cancel();
      _settleTimer = Timer(const Duration(milliseconds: 90), _refreshPoints);
      return;
    }

    // Flag-tap focus bookkeeping: arm once the fly-to has reached the fitted
    // zoom, then leave focus the moment the user zooms back out past it — at
    // which point the normal flag threshold takes over again.
    final zoom = data.cameraState.zoom;
    if (_flagFocusPeak != null && _flagFocusArmed) {
      if (zoom > _flagFocusPeak!) {
        _flagFocusPeak = zoom; // track the highest zoom reached
      } else if (zoom < _flagFocusPeak! - _flagFocusReleaseMargin) {
        // First real zoom-out from the peak → leave focus; flags return at the
        // normal threshold (even though we're still under _flagZoomMax).
        _clearFlagFocus();
      }
    }

    // Per-user maps fetch + compose photo markers on every refresh, so settling
    // only on stop felt slow (one big load at the end). Re-cluster live
    // (throttled) instead, so markers stream in during the gesture.
    final nowFlag = _isFlagTier(zoom);
    if (_lastFlagTier != null && nowFlag != _lastFlagTier) {
      _tierSwitchTimer?.cancel();
      _tierSwitchTimer = Timer(const Duration(milliseconds: 150), () {
        _lastViewKey = null; // force refresh even if bounds haven't changed
        _refreshPoints();
      });
    } else if (!nowFlag) {
      // Within the photo tier: re-cluster live (throttled) so photos merge and
      // split as you zoom, instead of waiting for the map to stop.
      _throttledRefresh();
    }
    _lastFlagTier = nowFlag;
  }

  // Leading-edge throttle for live re-clustering during a gesture. The viewKey
  // guard in _refreshPoints skips redundant renders; _refreshing skips overlaps;
  // the idle listener still delivers the final authoritative refresh.
  void _throttledRefresh() {
    final now = DateTime.now();
    if (now.difference(_lastThrottledRefresh).inMilliseconds < 150) return;
    _lastThrottledRefresh = now;
    _refreshPoints();
  }

  /// Refresh the viewport, switching tier by zoom: flags out, photos in.
  Future<void> _refreshPoints({bool force = false}) async {
    final map = _map;
    if (map == null || _refreshing) return;
    _refreshing = true;
    try {
      final state = await map.getCameraState();
      final bounds = await map.coordinateBoundsForCamera(
        CameraOptions(
          center: state.center,
          zoom: state.zoom,
          bearing: state.bearing,
          pitch: state.pitch,
        ),
      );
      final sw = bounds.southwest.coordinates;
      final ne = bounds.northeast.coordinates;
      final swLL = LatLng(sw.lat.toDouble(), sw.lng.toDouble());
      final neLL = LatLng(ne.lat.toDouble(), ne.lng.toDouble());
      final flagTier = _isFlagTier(state.zoom);

      final viewKey = flagTier
          ? 'F'
          : 'P;${sw.lat.toStringAsFixed(3)},${sw.lng.toStringAsFixed(3)}'
                ';${ne.lat.toStringAsFixed(3)},${ne.lng.toStringAsFixed(3)}'
                ';${state.zoom.toStringAsFixed(1)}';
      if (!force && viewKey == _lastViewKey) return;
      _lastViewKey = viewKey;

      if (flagTier) {
        await _clearPhotos();
        await _renderFlags();
      } else {
        await _clearFlags();
        await _renderPhotos(map, swLL, neLL);
      }
    } catch (e) {
      debugPrint('[map] refresh failed: $e');
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _renderPhotos(MapboxMap map, LatLng sw, LatLng ne) async {
    final mgr = _photoManager;
    if (mgr == null) return;
    final points = await widget.feed.pointsInView(sw, ne);
    final markers = await _clusterByScreen(map, points);
    final desired = {for (final m in markers) m.iconId: m};

    final gone = [
      for (final e in _shown.entries)
        if (!desired.containsKey(e.key)) e,
    ];
    if (gone.isNotEmpty) {
      await mgr.deleteMulti([for (final e in gone) e.value]);
      for (final e in gone) {
        _shown.remove(e.key);
        _markerByAnnotation.remove(e.value.id);
      }
    }

    final toAdd = [
      for (final m in markers)
        if (!_shown.containsKey(m.iconId)) m,
    ];
    if (toAdd.isEmpty) return;

    // 2-pass: instant placeholder (or cached image), then swap in the photo.
    final placeholder = await _placeholderImage();
    final created = await mgr.createMulti([
      for (final m in toAdd)
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(m.location.longitude, m.location.latitude),
          ),
          image: _imageCache[m.iconId] ?? placeholder,
          iconSize: 1.0,
        ),
    ]);
    final needFill = <_MapMarker>[];
    for (var i = 0; i < toAdd.length; i++) {
      final a = created[i];
      if (a == null) continue;
      _shown[toAdd[i].iconId] = a;
      _markerByAnnotation[a.id] = toAdd[i];
      if (!_imageCache.containsKey(toAdd[i].iconId)) needFill.add(toAdd[i]);
    }
    await Future.wait(needFill.map(_ensureImage));
    for (final m in needFill) {
      final bytes = _imageCache[m.iconId];
      final old = _shown[m.iconId];
      if (bytes == null || old == null) continue;
      await mgr.delete(old);
      _markerByAnnotation.remove(old.id);
      final fresh = await mgr.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(m.location.longitude, m.location.latitude),
          ),
          image: bytes,
          iconSize: 1.0,
        ),
      );
      _shown[m.iconId] = fresh;
      _markerByAnnotation[fresh.id] = m;
    }
  }

  Future<Uint8List> _placeholderImage() async {
    return _placeholder ??= await composePlaceholderMarker();
  }

  Future<void> _renderFlags() async {
    final mgr = _flagManager;
    if (mgr == null) return;
    final flags = await widget.feed.flags();
    String keyOf(FlagPoint f) => '${f.countryCode}_${f.count}';
    final desired = {for (final f in flags) keyOf(f): f};

    final gone = [
      for (final e in _shownFlags.entries)
        if (!desired.containsKey(e.key)) e,
    ];
    if (gone.isNotEmpty) {
      await mgr.deleteMulti([for (final e in gone) e.value]);
      for (final e in gone) {
        _flagCodeByAnnotation.remove(e.value.id);
        _shownFlags.remove(e.key);
      }
    }

    final toAdd = [
      for (final f in flags)
        if (!_shownFlags.containsKey(keyOf(f))) f,
    ];
    if (toAdd.isEmpty) return;
    await Future.wait(toAdd.map(_ensureFlagImage));
    final addable = [
      for (final f in toAdd)
        if (_flagImageCache[keyOf(f)] != null) f,
    ];
    // Place each flag at its country's center (geocoded), like the original
    // waylo. Falls back to the centroid of the user's posts in that country if
    // the lookup fails.
    final places = await Future.wait(
      addable.map(
        (f) async => (await countryCenter(f.countryCode)) ?? f.location,
      ),
    );
    final created = await mgr.createMulti([
      for (var i = 0; i < addable.length; i++)
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(places[i].longitude, places[i].latitude),
          ),
          image: _flagImageCache[keyOf(addable[i])],
          iconSize: 1.0,
        ),
    ]);
    for (var i = 0; i < addable.length; i++) {
      final a = created[i];
      if (a != null) {
        _shownFlags[keyOf(addable[i])] = a;
        _flagCodeByAnnotation[a.id] = addable[i].countryCode;
      }
    }
  }

  Future<void> _clearPhotos() async {
    final mgr = _photoManager;
    if (mgr == null || _shown.isEmpty) return;
    await mgr.deleteMulti(_shown.values.toList());
    _shown.clear();
    _markerByAnnotation.clear();
  }

  Future<void> _clearFlags() async {
    final mgr = _flagManager;
    if (mgr == null || _shownFlags.isEmpty) return;
    await mgr.deleteMulti(_shownFlags.values.toList());
    _shownFlags.clear();
    _flagCodeByAnnotation.clear();
  }

  Future<void> _ensureFlagImage(FlagPoint f) async {
    final key = '${f.countryCode}_${f.count}';
    if (_flagImageCache.containsKey(key)) return;
    try {
      final data = await rootBundle.load('assets/flags/${f.countryCode}.png');
      _flagImageCache[key] = await composeFlagMarker(
        data.buffer.asUint8List(),
        count: f.count,
      );
    } catch (e) {
      debugPrint('[map] flag image failed for ${f.countryCode}: $e');
    }
  }

  Future<List<_MapMarker>> _clusterByScreen(
    MapboxMap map,
    List<FeedPoint> points,
  ) async {
    if (points.isEmpty) return const [];
    const cell = 70.0;
    final pixels = await map.pixelsForCoordinates([
      for (final p in points)
        Point(coordinates: Position(p.location.longitude, p.location.latitude)),
    ]);
    final groups = <String, List<FeedPoint>>{};
    for (var i = 0; i < points.length; i++) {
      final sc = pixels[i];
      if (sc == null) continue;
      final key = '${(sc.x / cell).floor()}_${(sc.y / cell).floor()}';
      (groups[key] ??= []).add(points[i]);
    }
    return [
      for (final group in groups.values)
        _MapMarker(location: group.first.location, members: group),
    ];
  }

  Future<void> _ensureImage(_MapMarker m) async {
    if (_imageCache.containsKey(m.iconId)) return;
    final cached = await _markerCache.read(m.iconId);
    if (cached != null) {
      _imageCache[m.iconId] = cached;
      return;
    }
    try {
      final bytes = await _feed.thumbnail(m.repImagePath);
      final avatarUrl = m.avatarUrl;
      final avatarBytes = avatarUrl == null
          ? null
          : await _avatarBytesFor(avatarUrl);
      final composed = await composePhotoMarker(
        bytes,
        count: m.count,
        initial: m.initial,
        avatarBytes: avatarBytes,
      );
      _imageCache[m.iconId] = composed;
      await _markerCache.write(m.iconId, composed);
    } catch (e) {
      debugPrint('[map] marker image failed for ${m.repPostId}: $e');
    }
  }

  /// Avatar bytes for a marker badge (the `avatars` bucket is public). Cached
  /// per URL; a null result is cached too, so a missing/failed avatar quietly
  /// falls back to the author's initial badge.
  Future<Uint8List?> _avatarBytesFor(String url) async {
    if (_avatarBytesCache.containsKey(url)) return _avatarBytesCache[url];
    Uint8List? bytes;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) bytes = res.bodyBytes;
    } catch (_) {}
    _avatarBytesCache[url] = bytes;
    return bytes;
  }

  /// Public entry so the home chrome's (+) popup can start the post flow with
  /// the chosen photo source.
  Future<void> openComposer(PhotoSource source) => _startNewPost(source);

  /// Public refresh (e.g. after a post is deleted from the sheet). Re-checks the
  /// empty state, since deleting the last post flips the map back to empty.
  Future<void> refresh() async {
    await _refreshPoints(force: true);
    await _evaluateContent();
  }

  Future<void> _startNewPost(PhotoSource source) async {
    final draft = await startNewPost(
      context,
      fallbackCenter: _cameraCenter,
      source: source,
    );
    if (draft == null || !mounted) return;

    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await PostRepository().createPost(draft);
      navigator.pop();
      // No success toast: the new pin appears on the map right away.
      if (mounted) setState(() => _empty = false); // a post now exists
      await _refreshPoints(force: true);
    } catch (e) {
      navigator.pop();
      if (mounted) showErrorDialog(context, l.mapCouldNotPost('$e'));
    }
  }

  @override
  void dispose() {
    _tierSwitchTimer?.cancel();
    _settleTimer?.cancel();
    _emptyHintTimer?.cancel();
    _flagFocusArmTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          viewport: _initialViewport,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onCameraChangeListener: _onCameraChanged,
          onMapIdleListener: (_) => _refreshPoints(),
        ),
        // Initial-load overlays (the globe shows underneath either way):
        //   loading -> subtle spinner; error -> retry; empty -> a gentle hint.
        if (!_firstLoadDone && !_loadError)
          const _MapLoadingHint()
        else if (_loadError)
          _MapErrorHint(onRetry: _retryInitialLoad)
        else if (_empty && widget.emptyText != null)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _emptyHintGone ? 0 : 1,
              duration: const Duration(milliseconds: 600),
              child: _MapEmptyHint(text: widget.emptyText!),
            ),
          ),
        if (_selected != null)
          PhotoSheet(
            key: ValueKey(_selected!.first.postId),
            photos: _selected!,
            onClose: () => setState(() => _selected = null),
            onPostDeleted: () => _refreshPoints(force: true),
            onPostEdited: () => _refreshPoints(force: true),
          ),
      ],
    );
  }
}

/// What a [PhotoMapView] draws. Lets the same marker/clustering machinery serve
/// both a single user's map and the merged recent feed.
abstract class MapFeed {
  /// Posts to show in the bounding box. The recent feed ignores the box (its
  /// set is small and time-limited) and returns everything.
  Future<List<FeedPoint>> pointsInView(LatLng sw, LatLng ne);

  /// Per-country flag aggregates for the zoomed-out tier; empty disables it.
  Future<List<FlagPoint>> flags();

  /// The coordinates of this feed's posts in [countryCode], used to frame the
  /// camera when its flag is tapped. Empty for feeds without flags.
  Future<List<LatLng>> postLocationsInCountry(String countryCode);

  /// Whether to drop to the country-flag tier when zoomed out.
  bool get usesFlags;

  /// Whether the view should frame the camera over its content on first load
  /// (the recent map has no fixed home location).
  bool get fitOnLoad;

  /// Whether this feed has any content at all (globally), to decide the
  /// empty-state hint. Called once on map open and after mutations.
  Future<bool> hasContent();
}

/// One user's own map (photo tier + country flags). Each user's map, never merged.
class UserMapFeed implements MapFeed {
  UserMapFeed(this.userId, [FeedRepository? repo])
    : _repo = repo ?? FeedRepository();

  final String userId;
  final FeedRepository _repo;

  @override
  Future<List<FeedPoint>> pointsInView(LatLng sw, LatLng ne) =>
      _repo.pointsInView(sw, ne, userId);

  @override
  Future<List<FlagPoint>> flags() => _repo.flagsForUser(userId);

  @override
  Future<List<LatLng>> postLocationsInCountry(String countryCode) =>
      _repo.postsForCountry(userId, countryCode);

  @override
  bool get usesFlags => true;

  @override
  bool get fitOnLoad => false;

  @override
  Future<bool> hasContent() => _repo.hasVisiblePosts(userId);
}

/// The merged "Recent" map: every accepted friend's posts from the last 24h on
/// one map. Photo tier at all zooms (no flags); frames its content on load. The
/// fetched list is cached so the host can also feed the "Just in" strip from it.
class RecentMapFeed implements MapFeed {
  RecentMapFeed([FeedRepository? repo]) : _repo = repo ?? FeedRepository();

  final FeedRepository _repo;
  List<RecentPoint>? _cache;

  Future<List<RecentPoint>> load() async => _cache ??= await _repo.recentFeed();

  /// Drop the cache so the next [load] refetches (used by pull-to-refresh /
  /// reselecting the Recent tab).
  void invalidate() => _cache = null;

  @override
  Future<List<FeedPoint>> pointsInView(LatLng sw, LatLng ne) => load();

  @override
  Future<List<FlagPoint>> flags() async => const [];

  @override
  Future<List<LatLng>> postLocationsInCountry(String countryCode) async =>
      const [];

  @override
  bool get usesFlags => false;

  // Start zoomed out on the globe like every other map (no auto-fit to content).
  @override
  bool get fitOnLoad => false;

  @override
  Future<bool> hasContent() async => (await load()).isNotEmpty;
}

/// One thing drawn on the map: a single photo, or a screen-space cluster of
/// several. Carries its members so a tap can open them all in a carousel.
class _MapMarker {
  _MapMarker({required this.location, required this.members});

  final LatLng location;
  final List<FeedPoint> members;

  String get repPostId => members.first.postId;
  String get repImagePath => members.first.imagePath;
  int get count => members.length;

  /// Friend initial for the recent merged map (null on a single-user map, where
  /// every marker is the same person and an initial would be noise).
  String? get initial {
    final f = members.first;
    return f is RecentPoint && f.username.isNotEmpty
        ? f.username[0].toUpperCase()
        : null;
  }

  /// The author's avatar URL for the recent merged map's badge (null on a
  /// single-user map, or when the author has no avatar → falls back to initial).
  String? get avatarUrl {
    final f = members.first;
    return f is RecentPoint ? f.avatarUrl : null;
  }

  String get iconId {
    final base = count > 1 ? 'cluster_${repPostId}_$count' : 'photo_$repPostId';
    // The badge (avatar or initial) is baked into the marker PNG, so it must be
    // part of the cache key — else a friend's own map (no badge) and the recent
    // map would collide on the same post. Avatar markers use a distinct suffix
    // so a previously-cached initial-only PNG isn't reused.
    if (avatarUrl != null) return '${base}_av';
    return initial != null ? '${base}_$initial' : base;
  }
}

// ---------------------------------------------------------------------------
// Initial-load overlays (loading / error / empty). Each sits over the globe.
// ---------------------------------------------------------------------------

/// A subtle spinner shown over the globe during the first load. Non-blocking —
/// the user can still pan/zoom the globe underneath.
class _MapLoadingHint extends StatelessWidget {
  const _MapLoadingHint();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: _Chip(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

/// A gentle, non-blocking hint shown when a map has no content at all.
class _MapEmptyHint extends StatelessWidget {
  const _MapEmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: _Chip(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 20,
                color: context.c.inkMuted,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.c.inkMuted,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the initial load fails (e.g. no network). Offers a Retry — this
/// one is tappable, so it is NOT wrapped in IgnorePointer.
class _MapErrorHint extends StatelessWidget {
  const _MapErrorHint({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: _Chip(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 26, color: context.c.inkFaint),
            const SizedBox(height: 10),
            Text(
              l.mapLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.c.inkMuted,
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => onRetry(),
              style: TextButton.styleFrom(
                foregroundColor: context.c.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
              child: Text(
                l.commonRetry,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A floating white chip the overlays share (rounded, soft shadow).
class _Chip extends StatelessWidget {
  const _Chip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
