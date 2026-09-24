import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;

import '../../core/lat_lng.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// A chosen photo (full image) plus whatever location / capture time we could
/// read for it. Produced by the grid screen, then cropped by the crop screen.
class PickedPostPhoto {
  const PickedPostPhoto({required this.bytes, this.location, this.takenAt});
  final Uint8List bytes;
  final LatLng? location;
  final DateTime? takenAt;
}

/// Step 1 of posting: pick a photo from a library grid (no system gallery hop),
/// or take one with the camera. Tapping a thumbnail returns the chosen photo;
/// the caller then opens the crop screen.
class PostGridScreen extends StatefulWidget {
  const PostGridScreen({super.key, this.startCamera = false});

  /// Launch straight into the camera (the "(+) → Take a photo" path).
  final bool startCamera;

  @override
  State<PostGridScreen> createState() => _PostGridScreenState();
}

class _PostGridScreenState extends State<PostGridScreen> {
  final Map<String, Uint8List> _thumbCache = {};
  List<AssetEntity> _assets = const [];
  bool _permissionDenied = false;
  bool _busy = false;

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
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: true,
        ),
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
    if (mounted) setState(() => _assets = assets);
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Permission.accessMediaLocation.request();
      final bytes = await asset.thumbnailDataWithSize(
        ThumbnailSize(2048, 2048),
      );
      if (bytes == null || !mounted) {
        setState(() => _busy = false);
        return;
      }
      LatLng? loc;
      final ll = await asset.latlngAsync();
      final lat = ll?.latitude, lng = ll?.longitude;
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        loc = LatLng(lat, lng);
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        PickedPostPhoto(
          bytes: bytes,
          location: loc,
          takenAt: asset.createDateTime,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCamera() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 3000,
    );
    if (shot == null || !mounted) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    Navigator.pop(
      context,
      PickedPostPhoto(bytes: bytes, location: null, takenAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        foregroundColor: context.c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: context.c.inkMuted),
          child: Text(l.commonCancel, style: const TextStyle(fontSize: 16)),
        ),
        leadingWidth: 84,
        title: Text(
          l.postNewPost,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _openCamera,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: context.c.hairline),
        ),
      ),
      body: Stack(
        children: [
          _buildGrid(),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_permissionDenied) {
      final l = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.postPhotoAccessOff,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.c.inkMuted, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: Text(l.avatarOpenSettings),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _assets.length,
      itemBuilder: (_, i) => _GridCell(
        asset: _assets[i],
        cache: _thumbCache,
        onTap: () => _selectAsset(_assets[i]),
      ),
    );
  }
}

class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.asset,
    required this.cache,
    required this.onTap,
  });
  final AssetEntity asset;
  final Map<String, Uint8List> cache;
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
    final b = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(220),
    );
    if (b == null) return;
    widget.cache[widget.asset.id] = b;
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: const Color(0xFFEDEFF1),
        child: _bytes == null
            ? null
            : Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}
