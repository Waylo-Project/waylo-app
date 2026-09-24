import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/error_dialog.dart';
import '../../core/lat_lng.dart' as core;
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'new_post_draft.dart';
import 'post_details_screen.dart';
import 'post_grid_screen.dart';
import 'post_location_service.dart';

/// Step 2 of posting: crop / reframe the chosen photo. Preset ratios (Original
/// frames the WHOLE photo by default) plus Free (independent edges). The stage
/// is inset on all sides so the crop handles never sit under the system bars or
/// require reaching the very screen edge. "Next" returns the cropped photo.
class PostCropScreen extends StatefulWidget {
  const PostCropScreen({
    super.key,
    required this.raw,
    required this.fallbackCenter,
    this.locationService = const PostLocationService(),
  });

  final PickedPostPhoto raw;
  final core.LatLng fallbackCenter;
  final PostLocationService locationService;

  @override
  State<PostCropScreen> createState() => _PostCropScreenState();
}

class _PostCropScreenState extends State<PostCropScreen> {
  static const _presets = <String, double?>{
    'Original': null, // resolves to the photo's own aspect (whole image)
    '1:1': 1.0,
    '4:5': 0.8,
    '3:4': 0.75,
    'Free': null,
  };
  static const double _minSize = 64;
  // Breathing room around the photo so handles stay reachable and clear of bars.
  static const EdgeInsets _stagePad = EdgeInsets.fromLTRB(24, 20, 24, 20);
  static const Color _stageBg = Color(0xFF0F1216);

  ui.Image? _src;
  String _ratio = 'Original';
  bool _free = false;
  bool _working = false;

  Size? _stage;
  Rect? _imgRect;
  Rect? _crop;

  // Pinch/drag gesture state for the crop interior.
  Rect? _gestureStart;
  Offset _gesturePan = Offset.zero;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.raw.bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _src = frame.image);
  }

  @override
  void dispose() {
    _src?.dispose();
    super.dispose();
  }

  String _ratioLabel(AppLocalizations l, String name) => switch (name) {
    'Original' => l.postRatioOriginal,
    'Free' => l.postRatioFree,
    _ => name,
  };

  double? _ratioOf(String name) {
    if (name == 'Original' && _src != null) return _src!.width / _src!.height;
    return _presets[name];
  }

  Rect _containRect(Size img, Rect area) {
    final s = math.min(area.width / img.width, area.height / img.height);
    final w = img.width * s, h = img.height * s;
    return Rect.fromCenter(center: area.center, width: w, height: h);
  }

  Rect _fitRect(double? ar, Rect area) {
    if (ar == null) return area;
    double w, h;
    if (area.width / area.height > ar) {
      h = area.height;
      w = h * ar;
    } else {
      w = area.width;
      h = w / ar;
    }
    return Rect.fromCenter(center: area.center, width: w, height: h);
  }

  void _applyRatio(String name) {
    final area = _imgRect;
    setState(() {
      _ratio = name;
      _free = name == 'Free';
      if (area != null) _crop = _fitRect(_ratioOf(name), area);
    });
  }

  // Drag (one finger) + pinch zoom (two fingers) the crop, scaled about its
  // center and clamped inside the photo. Presets keep their aspect; Free scales
  // uniformly.
  void _onScaleStart(ScaleStartDetails d) {
    _gestureStart = _crop;
    _gesturePan = Offset.zero;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final start = _gestureStart, area = _imgRect;
    if (start == null || area == null) return;
    _gesturePan += d.focalPointDelta;
    final ar = start.width / start.height;
    var w = (start.width * d.scale).clamp(_minSize, area.width);
    var h = _free
        ? (start.height * d.scale).clamp(_minSize, area.height)
        : w / ar;
    if (!_free) {
      if (h > area.height) {
        h = area.height;
        w = h * ar;
      }
      if (w > area.width) {
        w = area.width;
        h = w / ar;
      }
    }
    var r = Rect.fromCenter(
      center: start.center + _gesturePan,
      width: w,
      height: h,
    );
    double dx = 0, dy = 0;
    if (r.left < area.left) dx = area.left - r.left;
    if (r.right > area.right) dx = area.right - r.right;
    if (r.top < area.top) dy = area.top - r.top;
    if (r.bottom > area.bottom) dy = area.bottom - r.bottom;
    setState(() => _crop = r.shift(Offset(dx, dy)));
  }

  void _onScaleEnd(ScaleEndDetails d) => _gestureStart = null;

  void _resizeBy(String c, Offset d) {
    final crop = _crop, area = _imgRect;
    if (crop == null || area == null) return;
    if (_free) {
      double l = crop.left, t = crop.top, rt = crop.right, b = crop.bottom;
      if (c.contains('w')) l = (l + d.dx).clamp(area.left, rt - _minSize);
      if (c.contains('e')) rt = (rt + d.dx).clamp(l + _minSize, area.right);
      if (c.contains('n')) t = (t + d.dy).clamp(area.top, b - _minSize);
      if (c.contains('s')) b = (b + d.dy).clamp(t + _minSize, area.bottom);
      setState(() => _crop = Rect.fromLTRB(l, t, rt, b));
      return;
    }
    final ar = crop.width / crop.height;
    final anchor = Offset(
      c.contains('e') ? crop.left : crop.right,
      c.contains('s') ? crop.top : crop.bottom,
    );
    var w = math.max(_minSize, crop.width + (c.contains('e') ? d.dx : -d.dx));
    var h = w / ar;
    final maxW = c.contains('e')
        ? area.right - anchor.dx
        : anchor.dx - area.left;
    final maxH = c.contains('s')
        ? area.bottom - anchor.dy
        : anchor.dy - area.top;
    if (w > maxW) {
      w = maxW;
      h = w / ar;
    }
    if (h > maxH) {
      h = maxH;
      w = h * ar;
    }
    final left = c.contains('e') ? anchor.dx : anchor.dx - w;
    final top = c.contains('s') ? anchor.dy : anchor.dy - h;
    setState(() => _crop = Rect.fromLTWH(left, top, w, h));
  }

  /// Crop, then prepare the file + location and go straight to the details
  /// screen — all under a loading overlay so the home map never shows through.
  Future<void> _next() async {
    final src = _src, imgRect = _imgRect, crop = _crop;
    if (src == null || imgRect == null || crop == null) return;
    setState(() => _working = true);
    try {
      // 1. Crop to pixels.
      final sx = src.width / imgRect.width;
      final sy = src.height / imgRect.height;
      final srcRect = Rect.fromLTWH(
        (crop.left - imgRect.left) * sx,
        (crop.top - imgRect.top) * sy,
        crop.width * sx,
        crop.height * sy,
      );
      final outW = srcRect.width.round().clamp(1, 4096);
      final outH = srcRect.height.round().clamp(1, 4096);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        src,
        srcRect,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint(),
      );
      final img = await recorder.endRecording().toImage(outW, outH);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      final png = data?.buffer.asUint8List();
      if (png == null) {
        if (mounted) setState(() => _working = false);
        return;
      }

      // 2. Compress to a small JPEG so the temp write + later upload are fast.
      final jpeg = await FlutterImageCompress.compressWithList(
        png,
        minWidth: 2048,
        minHeight: 2048,
        quality: 90,
        format: CompressFormat.jpeg,
      );
      final tmp = await getTemporaryDirectory();
      final file = await File(
        '${tmp.path}/waylo_post_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ).writeAsBytes(jpeg);

      // 3. Resolve the starting pin: photo location → device → map center.
      core.LatLng start;
      LocationSource source;
      final photoLoc = widget.raw.location;
      if (photoLoc != null) {
        start = photoLoc;
        source = LocationSource.exif;
      } else {
        final device = await widget.locationService.currentDeviceLocation();
        if (device != null) {
          start = device;
          source = LocationSource.device;
        } else {
          start = widget.fallbackCenter;
          source = LocationSource.mapDefault;
        }
      }
      if (!mounted) return;

      // 4. Push details ON TOP of crop (so home never shows). Bubble its draft.
      final draft = await Navigator.of(context).push<NewPostDraft>(
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            photo: file,
            initialLocation: start,
            source: source,
            takenAt: widget.raw.takenAt,
          ),
        ),
      );
      if (!mounted) return;
      if (draft != null) {
        Navigator.pop(context, draft); // done → back to home with the draft
      } else {
        setState(() => _working = false); // backed out of details → stay here
      }
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        showErrorDialog(
          context,
          AppLocalizations.of(context).postCouldNotPrepare('$e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _stageBg,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  height: 52,
                  color: context.c.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _working
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: context.c.inkMuted,
                        ),
                        child: Text(
                          l.commonBack,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        l.postCropTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.c.ink,
                        ),
                      ),
                      _NextButton(onTap: _working ? null : _next),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildStage()),
              Container(
                color: context.c.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final name in _presets.keys) ...[
                            _RatioChip(
                              label: _ratioLabel(l, name),
                              selected: _ratio == name,
                              onTap: () => _applyRatio(name),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_working)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xCC0F1216),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 14),
                      Text(
                        l.postPreparing,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = constraints.biggest;
        final src = _src;
        if (src != null && (_stage != stage || _imgRect == null)) {
          // The image is fit inside the PADDED area, so even Original's handles
          // sit inset from the screen edges.
          final area = _stagePad.deflateRect(Offset.zero & stage);
          _stage = stage;
          _imgRect = _containRect(
            Size(src.width.toDouble(), src.height.toDouble()),
            area,
          );
          _crop = _fitRect(_ratioOf(_ratio), _imgRect!);
        }
        final imgRect = _imgRect, crop = _crop;
        if (src == null || imgRect == null || crop == null) {
          return Center(child: CircularProgressIndicator());
        }
        const handle = 30.0;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: imgRect,
              child: RawImage(image: src, fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CropPainter(crop)),
              ),
            ),
            Positioned.fromRect(
              rect: crop,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
              ),
            ),
            for (final c in const ['nw', 'ne', 'sw', 'se'])
              Positioned(
                left: (c.contains('e') ? crop.right : crop.left) - handle / 2,
                top: (c.contains('s') ? crop.bottom : crop.top) - handle / 2,
                width: handle,
                height: handle,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (d) => _resizeBy(c, d.delta),
                  child: _HandleMark(corner: c),
                ),
              ),
            if (_free)
              for (final e in const ['n', 's', 'w', 'e'])
                Positioned(
                  left: e == 'w'
                      ? crop.left - handle / 2
                      : (e == 'e'
                            ? crop.right - handle / 2
                            : crop.center.dx - handle / 2),
                  top: e == 'n'
                      ? crop.top - handle / 2
                      : (e == 's'
                            ? crop.bottom - handle / 2
                            : crop.center.dy - handle / 2),
                  width: handle,
                  height: handle,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (d) => _resizeBy(e, d.delta),
                    child: const _EdgeMark(),
                  ),
                ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0x8C0F1216),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context).postCropHint,
                    style: TextStyle(color: Color(0xEBFFFFFF), fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.primary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            AppLocalizations.of(context).commonNext,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: onTap == null
                  ? context.c.onPrimary.withValues(alpha: 0.4)
                  : context.c.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? context.c.primary : context.c.fill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? context.c.onPrimary : context.c.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _HandleMark extends StatelessWidget {
  const _HandleMark({required this.corner});
  final String corner;
  @override
  Widget build(BuildContext context) {
    final left = corner.contains('w');
    final top = corner.contains('n');
    return Stack(
      children: [
        Positioned(
          left: left ? 8 : null,
          right: left ? null : 8,
          top: top ? 8 : null,
          bottom: top ? null : 8,
          child: Container(width: 18, height: 4, color: Colors.white),
        ),
        Positioned(
          left: left ? 8 : null,
          right: left ? null : 8,
          top: top ? 8 : null,
          bottom: top ? null : 8,
          child: Container(width: 4, height: 18, color: Colors.white),
        ),
      ],
    );
  }
}

class _EdgeMark extends StatelessWidget {
  const _EdgeMark();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 18,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.crop);
  final Rect crop;
  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(crop),
    );
    canvas.drawPath(outside, Paint()..color = const Color(0x9E080B0E));
    canvas.drawRect(
      crop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xF5FFFFFF),
    );
    final grid = Paint()
      ..color = const Color(0x59FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = crop.left + crop.width * i / 3;
      final y = crop.top + crop.height * i / 3;
      canvas.drawLine(Offset(x, crop.top), Offset(x, crop.bottom), grid);
      canvas.drawLine(Offset(crop.left, y), Offset(crop.right, y), grid);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.crop != crop;
}
