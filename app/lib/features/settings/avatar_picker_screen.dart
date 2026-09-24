import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/error_dialog.dart';
import '../../core/photo_library.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Instagram "new post" style avatar picker: a square preview on top (a circular
/// crop guide fills the square edge-to-edge, only the corners dimmed) over a
/// scrolling 4-column grid of the user's photo library. Tap a thumbnail to load
/// it into the preview; pan/zoom to frame; "Next" captures the square and
/// returns it as PNG bytes (the caller compresses + uploads). The square is the
/// crop — avatar widgets clip it to a circle when displaying.
class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key, this.initialImage});

  /// A just-taken camera shot to seed the preview (the grid still loads below).
  final Uint8List? initialImage;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  // Match the post crop screen: dark crop stage, white chrome + grid.
  static const Color _bg = Color(0xFF0F1216);

  final GlobalKey _previewKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  final Map<String, Uint8List> _thumbCache = {};

  List<AssetEntity> _assets = const [];
  Uint8List? _previewBytes;
  Size? _imgSize; // intrinsic size of _previewBytes, for cover-fit framing
  bool _working = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _previewBytes = widget.initialImage;
      _imgSize = const Size(1, 1); // until decoded
      _decodeSize(widget.initialImage!).then((s) {
        if (!mounted) return;
        setState(() => _imgSize = s);
        _centerPreview();
      });
    }
    _loadLibrary();
  }

  /// Center the (cover-sized) photo in the square so equal amounts overflow on
  /// each side, instead of starting pinned to the top-left.
  void _centerPreview() {
    final size = _imgSize;
    if (size == null || !mounted) return;
    final side = MediaQuery.of(context).size.width;
    final aspect = size.width / size.height;
    final childW = aspect >= 1 ? side * aspect : side;
    final childH = aspect >= 1 ? side : side / aspect;
    _controller.value = Matrix4.identity()
      ..setTranslationRaw(-(childW - side) / 2, -(childH - side) / 2, 0);
  }

  Future<Size> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    return size;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final assets = await loadRecentPhotos(mediaLocation: false);
    if (!mounted) return;
    if (assets == null) {
      setState(() => _permissionDenied = true);
      return;
    }
    setState(() => _assets = assets);
    // Seed the preview with the most recent photo (unless a camera shot seeded it).
    if (_previewBytes == null && assets.isNotEmpty) {
      _selectAsset(assets.first);
    }
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    // Instant feedback: show the already-loaded square grid thumbnail, then
    // swap in the high-res with the photo's real aspect ratio.
    final quick = _thumbCache[asset.id];
    if (quick != null && mounted) {
      setState(() {
        _previewBytes = quick;
        _imgSize = Size(1, 1); // grid thumbs are square-cropped
      });
      _centerPreview();
    }
    final bytes = await asset.thumbnailDataWithSize(ThumbnailSize(1280, 1280));
    if (bytes == null || !mounted) return;
    final size = (asset.width > 0 && asset.height > 0)
        ? Size(asset.width.toDouble(), asset.height.toDouble())
        : await _decodeSize(bytes);
    if (!mounted) return;
    setState(() {
      _previewBytes = bytes;
      _imgSize = size;
    });
    _centerPreview();
  }

  Future<void> _openCamera() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
    );
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    final size = await _decodeSize(bytes);
    if (!mounted) return;
    setState(() {
      _previewBytes = bytes;
      _imgSize = size;
    });
    _centerPreview();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.c.surface,
      body: Column(
        children: [
          // Top bar (white chrome, like the post crop screen).
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _working ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.c.ink),
                  ),
                  Text(
                    l.avatarNewProfilePhoto,
                    style: TextStyle(
                      color: context.c.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _working ? null : _openCamera,
                        icon: Icon(
                          Icons.photo_camera_outlined,
                          color: context.c.inkMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: (_working || _previewBytes == null)
                            ? null
                            : _crop,
                        child: Text(
                          l.commonNext,
                          style: TextStyle(
                            color: _previewBytes == null
                                ? context.c.primary.withValues(alpha: 0.4)
                                : context.c.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Square preview with the edge-to-edge circular crop guide.
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  key: _previewKey,
                  child: ClipRect(
                    child: ColoredBox(color: _bg, child: _buildPreview()),
                  ),
                ),
                const IgnorePointer(
                  child: CustomPaint(painter: _CircleGuidePainter()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          // Photo grid.
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  /// The pannable/zoomable photo, sized to always cover the square crop window
  /// (the bounded InteractiveViewer can never reveal empty space).
  Widget _buildPreview() {
    final bytes = _previewBytes;
    final size = _imgSize;
    if (bytes == null || size == null) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final aspect = size.width / size.height;
        final childW = aspect >= 1 ? side * aspect : side;
        final childH = aspect >= 1 ? side : side / aspect;
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 1.0,
          maxScale: 6.0,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: childW,
            height: childH,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    if (_permissionDenied) {
      final l = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.avatarPhotoAccessOff,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.c.inkMuted, fontSize: 14),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: Text(
                  l.avatarOpenSettings,
                  style: TextStyle(color: context.c.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return PhotoLibraryGrid(
      assets: _assets,
      cache: _thumbCache,
      onTap: _selectAsset,
    );
  }

  /// Capture the square preview to PNG bytes (the whole square is the crop).
  Future<void> _crop() async {
    setState(() => _working = true);
    try {
      final boundary =
          _previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted) return;
      Navigator.pop(context, data?.buffer.asUint8List());
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        showErrorDialog(
          context,
          AppLocalizations.of(context).avatarCouldNotCrop('$e'),
        );
      }
    }
  }
}

/// Darkens only the four corners (square minus the inscribed circle); draws the
/// ring + rule-of-thirds guides. The circle fills the square edge-to-edge.
class _CircleGuidePainter extends CustomPainter {
  const _CircleGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Rect.fromCircle(
      center: rect.center,
      radius: size.shortestSide / 2,
    );

    // Corner dim (square minus circle).
    final corners = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addOval(circle),
    );
    canvas.drawPath(corners, Paint()..color = const Color(0x9E0B0C0D));

    // Ring.
    canvas.drawCircle(
      circle.center,
      circle.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xE6FFFFFF),
    );

    // Rule-of-thirds guides, clipped to the circle.
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final guide = Paint()
      ..color = const Color(0x29FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final dx = circle.left + circle.width * i / 3;
      final dy = circle.top + circle.height * i / 3;
      canvas.drawLine(Offset(dx, circle.top), Offset(dx, circle.bottom), guide);
      canvas.drawLine(Offset(circle.left, dy), Offset(circle.right, dy), guide);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircleGuidePainter oldDelegate) => false;
}
