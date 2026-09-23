import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;

import '../../core/error_dialog.dart';
import '../../core/lat_lng.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// The result of the post photo picker: the cropped image plus whatever
/// location / capture time we could read from the chosen photo.
class PickedPostPhoto {
  const PickedPostPhoto({required this.bytes, this.location, this.takenAt});
  final Uint8List bytes;
  final LatLng? location;
  final DateTime? takenAt;
}

/// One screen, like the profile-photo picker: a crop stage on top (rectangular
/// crop with preset ratios + Free) over a scrolling library grid below. No
/// system gallery hop. The default ratio is **Original** framed to the WHOLE
/// photo. "Next" returns the cropped bytes (+ the photo's location/date).
class PostPhotoPickerScreen extends StatefulWidget {
  const PostPhotoPickerScreen({super.key, this.startCamera = false});

  /// Launch straight into the camera (the "(+) → Take a photo" path).
  final bool startCamera;

  @override
  State<PostPhotoPickerScreen> createState() => _PostPhotoPickerScreenState();
}

class _PostPhotoPickerScreenState extends State<PostPhotoPickerScreen> {
  static const _presets = <String, double?>{
    'Original': null, // resolves to the photo's own aspect (whole image)
    '1:1': 1.0,
    '4:5': 0.8,
    '3:4': 0.75,
    'Free': null,
  };
  static const double _minSize = 64;
  static const Color _stageBg = Color(0xFF0F1216);
  static const Color _cellBg = Color(0xFF181A1C);

  final Map<String, Uint8List> _thumbCache = {};
  List<AssetEntity> _assets = const [];
  bool _permissionDenied = false;

  // Current photo in the crop stage.
  ui.Image? _src;
  Uint8List? _bytes;
  LatLng? _location;
  DateTime? _takenAt;

  String _ratio = 'Original';
  bool _free = false;
  bool _working = false;

  Size? _stage;
  Rect? _imgRect; // photo draw rect (contain) in stage coords
  Rect? _crop;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
    if (widget.startCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
    }
  }

  Future<void> _loadLibrary() async {
    final ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission:
            AndroidPermission(type: RequestType.image, mediaLocation: true),
      ),
    );
    if (!ps.hasAccess) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return;
    final assets = await paths.first.getAssetListPaged(page: 0, size: 120);
    if (!mounted) return;
    setState(() => _assets = assets);
    if (_src == null && _bytes == null && assets.isNotEmpty) {
      _selectAsset(assets.first);
    }
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    // Real GPS needs ACCESS_MEDIA_LOCATION (redacted otherwise).
    await Permission.accessMediaLocation.request();
    final bytes =
        await asset.thumbnailDataWithSize(ThumbnailSize(2048, 2048));
    if (bytes == null || !mounted) return;
    LatLng? loc;
    final ll = await asset.latlngAsync();
    final lat = ll?.latitude, lng = ll?.longitude;
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      loc = LatLng(lat, lng);
    }
    await _setPhoto(bytes, location: loc, takenAt: asset.createDateTime);
  }

  Future<void> _openCamera() async {
    final shot = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 3000);
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    // A fresh shot has no embedded GPS; the details screen falls back to the
    // device location. Capture time is now.
    await _setPhoto(bytes, location: null, takenAt: DateTime.now());
  }

  Future<void> _setPhoto(Uint8List bytes,
      {LatLng? location, DateTime? takenAt}) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    _src?.dispose();
    setState(() {
      _bytes = bytes;
      _src = frame.image;
      _location = location;
      _takenAt = takenAt;
      _imgRect = null; // recompute layout + crop on next build
    });
  }

  @override
  void dispose() {
    _src?.dispose();
    super.dispose();
  }

  double? _ratioOf(String name) {
    if (name == 'Original' && _src != null) return _src!.width / _src!.height;
    return _presets[name];
  }

  Rect _containRect(Size img, Size box) {
    final s = math.min(box.width / img.width, box.height / img.height);
    final w = img.width * s, h = img.height * s;
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  /// The largest rect of aspect [ar] centered in [area]. Original (ar = image
  /// aspect) lands exactly on the whole photo. Free uses the full area too.
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

  void _moveBy(Offset d) {
    final crop = _crop, area = _imgRect;
    if (crop == null || area == null) return;
    var r = crop.shift(d);
    final dx = r.left < area.left
        ? area.left - r.left
        : (r.right > area.right ? area.right - r.right : 0.0);
    final dy = r.top < area.top
        ? area.top - r.top
        : (r.bottom > area.bottom ? area.bottom - r.bottom : 0.0);
    setState(() => _crop = r.shift(Offset(dx, dy)));
  }

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
    final maxW = c.contains('e') ? area.right - anchor.dx : anchor.dx - area.left;
    final maxH = c.contains('s') ? area.bottom - anchor.dy : anchor.dy - area.top;
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

  Future<void> _next() async {
    final src = _src, imgRect = _imgRect, crop = _crop;
    if (src == null || imgRect == null || crop == null) return;
    setState(() => _working = true);
    try {
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
      Canvas(recorder).drawImageRect(src, srcRect,
          Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()), Paint());
      final img = await recorder.endRecording().toImage(outW, outH);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (!mounted) return;
      final bytes = data?.buffer.asUint8List();
      if (bytes == null) return;
      Navigator.pop(
        context,
        PickedPostPhoto(bytes: bytes, location: _location, takenAt: _takenAt),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        showErrorDialog(
            context, AppLocalizations.of(context).avatarCouldNotCrop('$e'));
      }
    }
  }

  String _ratioLabel(AppLocalizations l, String name) => switch (name) {
        'Original' => l.postRatioOriginal,
        'Free' => l.postRatioFree,
        _ => name,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _stageBg,
      body: Column(
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
                    onPressed: _working ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: context.c.inkMuted),
                    child: Text(l.commonCancel, style: const TextStyle(fontSize: 16)),
                  ),
                  Text(l.postNewPost,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.c.ink)),
                  _NextButton(
                      onTap: (_working || _src == null) ? null : _next),
                ],
              ),
            ),
          ),
          Expanded(flex: 5, child: _buildCropStage()),
          _buildChips(),
          _buildGalleryHeader(),
          Expanded(flex: 4, child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildCropStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = constraints.biggest;
        final src = _src;
        if (src != null && (_stage != stage || _imgRect == null)) {
          final imgRect = _containRect(
              Size(src.width.toDouble(), src.height.toDouble()), stage);
          _stage = stage;
          _imgRect = imgRect;
          _crop = _fitRect(_ratioOf(_ratio), imgRect);
        }
        final bytes = _bytes, imgRect = _imgRect, crop = _crop;
        if (bytes == null || imgRect == null || crop == null) {
          return ColoredBox(
            color: _stageBg,
            child: Center(
              child: Text(AppLocalizations.of(context).postPickPhoto,
                  style: TextStyle(color: Colors.white38)),
            ),
          );
        }
        const handle = 28.0;
        return ColoredBox(
          color: _stageBg,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: imgRect,
                child: Image.memory(bytes,
                    fit: BoxFit.fill, gaplessPlayback: true),
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
                  onPanUpdate: (d) => _moveBy(d.delta),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildChips() {
    final l = AppLocalizations.of(context);
    return Container(
      color: context.c.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryHeader() {
    return Container(
      color: context.c.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
      child: Row(
        children: [
          Text(AppLocalizations.of(context).postRecents,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.c.ink)),
          Spacer(),
          IconButton(
            onPressed: _working ? null : _openCamera,
            icon: Icon(Icons.photo_camera_outlined,
                color: context.c.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_permissionDenied) {
      final l = AppLocalizations.of(context);
      return Container(
        color: context.c.surface,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.postPhotoAccessOff,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkMuted, fontSize: 14),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: PhotoManager.openSetting,
              child: Text(l.avatarOpenSettings),
            ),
          ],
        ),
      );
    }
    return Container(
      color: context.c.surface,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _assets.length,
        itemBuilder: (_, i) => _GridCell(
          asset: _assets[i],
          cache: _thumbCache,
          background: _cellBg,
          onTap: () => _selectAsset(_assets[i]),
        ),
      ),
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
          child: Text(AppLocalizations.of(context).commonNext,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onTap == null
                      ? context.c.onPrimary.withValues(alpha: 0.4)
                      : context.c.onPrimary)),
        ),
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip(
      {required this.label, required this.selected, required this.onTap});
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
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? context.c.onPrimary : context.c.inkMuted)),
      ),
    );
  }
}

class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.asset,
    required this.cache,
    required this.background,
    required this.onTap,
  });
  final AssetEntity asset;
  final Map<String, Uint8List> cache;
  final Color background;
  final VoidCallback onTap;
  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
  Uint8List? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = widget.cache[widget.asset.id];
    if (cached != null) {
      _bytes = cached;
      return;
    }
    final b = await widget.asset
        .thumbnailDataWithSize(const ThumbnailSize.square(220));
    if (b == null) return;
    widget.cache[widget.asset.id] = b;
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: widget.background,
        child: _bytes == null
            ? null
            : Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true),
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
          left: left ? 7 : null,
          right: left ? null : 7,
          top: top ? 7 : null,
          bottom: top ? null : 7,
          child: Container(width: 18, height: 4, color: Colors.white),
        ),
        Positioned(
          left: left ? 7 : null,
          right: left ? null : 7,
          top: top ? 7 : null,
          bottom: top ? null : 7,
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
            color: Colors.white, borderRadius: BorderRadius.circular(2)),
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
