import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/date_format.dart';
import '../../core/error_dialog.dart';
import '../../core/lat_lng.dart' as core;
import '../../data/feed_repository.dart';
import '../../data/geocoding.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'new_post_draft.dart';

/// Where the post pin starts: read from the photo, the device, or the map.
enum LocationSource { exif, device, mapDefault }

/// What editing an existing post returns to the caller (the photo sheet), so it
/// can update its card in place without a refetch.
class EditPostResult {
  const EditPostResult({
    required this.location,
    required this.takenAt,
    required this.caption,
    required this.placeLabel,
  });

  final core.LatLng location;
  final DateTime? takenAt;
  final String? caption;
  final String? placeLabel;
}

/// Step 2 of posting (per `docs/POST.md` + the design handoff, screen 2):
/// confirm where the photo is pinned and its details. A real map up top (drag
/// to place, search to jump, recenter), then editable place name, date (date
/// only), caption, and a coordinates expander. "Post" returns a [NewPostDraft].
class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    super.key,
    required File this.photo,
    required this.initialLocation,
    required LocationSource this.source,
    this.takenAt,
  })  : editPostId = null,
        photoImage = null,
        initialCaption = null,
        initialPlaceLabel = null;

  /// Edit an existing post: the same map / date / caption UI, but seeded from
  /// the post and saving via [FeedRepository.updatePost] (returning an
  /// [EditPostResult]) instead of returning a [NewPostDraft] for a fresh post.
  const PostDetailsScreen.edit({
    super.key,
    required String this.editPostId,
    required ImageProvider this.photoImage,
    required this.initialLocation,
    this.takenAt,
    this.initialCaption,
    this.initialPlaceLabel,
  })  : photo = null,
        source = null;

  /// The picked file for a new post; null when editing (see [photoImage]).
  final File? photo;

  /// The existing photo to display when editing; null for a new post.
  final ImageProvider? photoImage;

  final core.LatLng initialLocation;

  /// Where a new post's pin came from (drives the source chip); null in edit
  /// mode, where the chip is hidden.
  final LocationSource? source;

  final DateTime? takenAt;

  /// Non-null only in edit mode: the id of the post being edited.
  final String? editPostId;

  /// Prefill for the caption field in edit mode.
  final String? initialCaption;

  /// The post's saved (user-written) place name in edit mode; null if it uses
  /// the auto-filled one.
  final String? initialPlaceLabel;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  MapboxMap? _map;
  final _feed = FeedRepository();
  bool _saving = false;
  bool get _isEdit => widget.editPostId != null;
  late core.LatLng _center = widget.initialLocation;

  // Built ONCE. Passing a fresh CameraViewportState on every rebuild makes
  // MapWidget re-apply it and snap the camera back to the start — which is why
  // a search/drag appeared not to move the map (see photo_map_view.dart).
  late final CameraViewportState _viewport = CameraViewportState(
    center: Point(
      coordinates: Position(
        widget.initialLocation.longitude,
        widget.initialLocation.latitude,
      ),
    ),
    zoom: 15,
  );

  final _placeCtl = TextEditingController();
  final _captionCtl = TextEditingController();
  final _latCtl = TextEditingController();
  final _lngCtl = TextEditingController();
  final _searchCtl = TextEditingController();

  // True once the place field holds a name the user wrote. Only that is saved;
  // the auto-filled name is left null so viewers geocode it in their language.
  bool _placeEdited = false;
  bool _coordsOpen = false;
  bool _searching = false;
  List<PlaceResult> _results = const [];
  Timer? _searchDebounce;
  late DateTime _date = widget.takenAt ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialCaption != null) _captionCtl.text = widget.initialCaption!;
    if (widget.initialPlaceLabel != null) {
      _placeCtl.text = widget.initialPlaceLabel!;
      _placeEdited = true;
    }
    _syncCoordFields();
    _reverseGeocode();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _placeCtl.dispose();
    _captionCtl.dispose();
    _latCtl.dispose();
    _lngCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _syncCoordFields() {
    _latCtl.text = _center.latitude.toStringAsFixed(5);
    _lngCtl.text = _center.longitude.toStringAsFixed(5);
  }

  Future<void> _reverseGeocode() async {
    final label = await reversePlaceLabel(_center);
    if (!mounted || _placeEdited) return;
    final parts = [if (label.place != null) label.place!, if (label.country != null) label.country!];
    if (parts.isNotEmpty) _placeCtl.text = parts.join(', ');
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    map.compass.updateSettings(CompassSettings(enabled: false));
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final c = data.cameraState.center.coordinates;
    _center = core.LatLng(c.lat.toDouble(), c.lng.toDouble());
  }

  void _onMapIdle(MapIdleEventData _) {
    if (mounted) {
      _syncCoordFields();
      _reverseGeocode();
    }
  }

  Future<void> _flyTo(core.LatLng to, {double zoom = 15}) async {
    _center = to;
    await _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(to.longitude, to.latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 700),
    );
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    _searchDebounce = Timer(Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      final r = await searchPlaces(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searching = false;
      });
    });
  }

  void _pickResult(PlaceResult r) {
    FocusScope.of(context).unfocus();
    _searchCtl.text = r.name;
    setState(() => _results = const []);
    _placeEdited = false;
    _flyTo(r.location);
  }

  /// Keyboard search button → jump to the best match.
  Future<void> _onSearchSubmitted(String q) async {
    _searchDebounce?.cancel();
    if (q.trim().isEmpty) return;
    setState(() => _searching = true);
    final results = await searchPlaces(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (results.isNotEmpty) _pickResult(results.first);
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Keep the original time-of-day; the user edits the date only.
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _date.hour,
            _date.minute,
            _date.second,
          ));
    }
  }

  void _applyTypedCoords() {
    final lat = double.tryParse(_latCtl.text.trim());
    final lng = double.tryParse(_lngCtl.text.trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      showErrorDialog(context, AppLocalizations.of(context).postInvalidCoords);
      return;
    }
    FocusScope.of(context).unfocus();
    _placeEdited = false;
    _flyTo(core.LatLng(lat, lng));
  }

  void _post() {
    Navigator.of(context).pop(
      NewPostDraft(
        photo: widget.photo!,
        location: _center,
        takenAt: _date,
        caption: _captionCtl.text.trim(),
        placeLabel: _customPlaceLabel,
      ),
    );
  }

  /// The place name to save: the user's own text, or null for the auto name.
  String? get _customPlaceLabel {
    final text = _placeCtl.text.trim();
    return _placeEdited && text.isNotEmpty ? text : null;
  }

  /// Edit mode: recompute the country code, persist via the RPC, and return the
  /// new values so the photo sheet can update its card in place.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final caption = _captionCtl.text.trim();
    final placeLabel = _customPlaceLabel;
    try {
      final country = await reverseCountryCode(_center);
      await _feed.updatePost(
        postId: widget.editPostId!,
        location: _center,
        caption: caption,
        takenAt: _date,
        countryCode: country,
        placeLabel: placeLabel,
      );
      if (!mounted) return;
      Navigator.of(context).pop(EditPostResult(
        location: _center,
        takenAt: _date,
        caption: caption.isEmpty ? null : caption,
        placeLabel: placeLabel,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorDialog(
          context, AppLocalizations.of(context).photoCouldNotSave('$e'));
    }
  }

  String _sourceHint(AppLocalizations l) {
    switch (widget.source) {
      case LocationSource.exif:
        return l.postSourceExif;
      case LocationSource.device:
        return l.postSourceDevice;
      case LocationSource.mapDefault:
        return l.postSourceMapDefault;
      case null:
        return ''; // edit mode hides the source chip; never reached
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // When the keyboard is up, collapse the fixed-height map so the place /
    // caption fields get the room and scroll above the keyboard instead of
    // hiding behind it.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        foregroundColor: context.c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(_isEdit ? l.photoEditPost : l.postDetailsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _buildMap(collapsed: keyboardOpen),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _placeField(),
                _dateField(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.postTimeAutoNote,
                      style: TextStyle(fontSize: 12.5, color: context.c.inkFaint)),
                ),
                _captionField(),
                _coordsExpander(),
              ],
            ),
          ),
          _postBar(),
        ],
      ),
    );
  }

  Widget _buildMap({bool collapsed = false}) {
    // Collapse to zero height (but keep the MapWidget mounted, so the camera /
    // pin state survive) while the keyboard is up. ClipRect hides the fixed
    // overlays during the squeeze.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: collapsed ? 0 : 286,
      child: ClipRect(
        child: OverflowBox(
          minHeight: 0,
          maxHeight: 286,
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 286,
            child: Stack(
        children: [
          Positioned.fill(
            child: MapWidget(
              viewport: _viewport,
              onMapCreated: _onMapCreated,
              onCameraChangeListener: _onCameraChanged,
              onMapIdleListener: _onMapIdle,
            ),
          ),
          // Fixed center pin (tip at the map center).
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -19),
                child: Icon(Icons.location_on, size: 40, color: context.c.ink),
              ),
            ),
          ),
          // Search box + results (inline over the map).
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x24143B30), blurRadius: 18, offset: Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: context.c.inkFaint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtl,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _onSearchSubmitted,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: AppLocalizations.of(context).postSearchPlace,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      if (_searching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                if (_results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 196),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x24143B30), blurRadius: 18, offset: Offset(0, 6)),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final r in _results)
                          InkWell(
                            onTap: () => _pickResult(r),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.place_outlined, size: 18, color: context.c.inkFaint),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(r.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, color: context.c.ink)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Source chip (new posts only; hidden when editing).
          if (widget.source != null)
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: context.c.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F143B30), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: context.c.checkAccent, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(_sourceHint(AppLocalizations.of(context)),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.c.inkMuted)),
                ],
              ),
            ),
          ),
          // Recenter to the starting location.
          Positioned(
            right: 14,
            bottom: 14,
            child: Material(
              color: context.c.surface,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _flyTo(widget.initialLocation),
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.my_location, size: 20, color: context.c.checkAccent),
                ),
              ),
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9, color: context.c.inkFaint),
      );

  Widget _placeField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.c.hairline)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image(
              image: widget.photo != null
                  ? FileImage(widget.photo!)
                  : widget.photoImage!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(AppLocalizations.of(context).postPlaceNameLabel),
                const SizedBox(height: 2),
                TextField(
                  controller: _placeCtl,
                  // Clearing the field hands it back to the auto name.
                  onChanged: (v) => _placeEdited = v.trim().isNotEmpty,
                  // Matches the posts.place_label length check.
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: AppLocalizations.of(context).postPlaceNameHint,
                  ),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.c.ink),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: context.c.inkFaint),
        ],
      ),
    );
  }

  Widget _dateField() {
    final l = AppLocalizations.of(context);
    final dateLabel = formatPhotoDate(context, _date);
    return InkWell(
      onTap: _editDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.c.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(l.postDateLabel),
                  const SizedBox(height: 3),
                  Text(dateLabel,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.c.ink)),
                ],
              ),
            ),
            Text(l.settingsEdit, style: TextStyle(fontSize: 12.5, color: context.c.caption)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: context.c.chevron),
          ],
        ),
      ),
    );
  }

  Widget _captionField() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.c.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldLabel(AppLocalizations.of(context).postCaptionLabel),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).postCaptionOptional,
                  style: TextStyle(fontSize: 11, color: context.c.chevron)),
            ],
          ),
          SizedBox(height: 6),
          TextField(
            controller: _captionCtl,
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: AppLocalizations.of(context).postCaptionHint,
            ),
            style: TextStyle(fontSize: 16, color: context.c.ink),
          ),
        ],
      ),
    );
  }

  Widget _coordsExpander() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _coordsOpen = !_coordsOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.postEnterCoordsManually,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.c.inkMuted)),
                Icon(_coordsOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20, color: context.c.chevron),
              ],
            ),
          ),
        ),
        if (_coordsOpen)
          Row(
            children: [
              Expanded(child: _coordBox(l.postLatLabel, _latCtl)),
              SizedBox(width: 12),
              Expanded(child: _coordBox(l.postLngLabel, _lngCtl)),
            ],
          ),
        if (_coordsOpen)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: _applyTypedCoords,
              child: Text(l.postGoToCoords),
            ),
          ),
      ],
    );
  }

  Widget _coordBox(String label, TextEditingController ctl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.c.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, letterSpacing: 0.6, color: context.c.inkFaint)),
          TextField(
            controller: ctl,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onSubmitted: (_) => _applyTypedCoords(),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(fontSize: 15, color: context.c.ink),
          ),
        ],
      ),
    );
  }

  Widget _postBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 54,
            child: Material(
              color: context.c.primary,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving ? null : (_isEdit ? _save : _post),
                child: Center(
                  child: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: context.c.onPrimary),
                        )
                      : Text(
                          _isEdit
                              ? AppLocalizations.of(context).commonSave
                              : AppLocalizations.of(context).postPost,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.c.onPrimary)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
