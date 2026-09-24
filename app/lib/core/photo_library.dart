import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// The newest [limit] images in the device library, or null if photo access
/// was denied. The permission request is scoped to images only — the default
/// also checks video + audio, which fails when only READ_MEDIA_IMAGES is
/// granted. [mediaLocation] also asks (Android) for photo GPS access, which the
/// post flow needs to read where a photo was taken.
Future<List<AssetEntity>?> loadRecentPhotos({
  required bool mediaLocation,
  int limit = 120,
}) async {
  final ps = await PhotoManager.requestPermissionExtend(
    requestOption: PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.image,
        mediaLocation: mediaLocation,
      ),
    ),
  );
  if (!ps.hasAccess) return null;
  final paths = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );
  if (paths.isEmpty) return const [];
  return paths.first.getAssetListPaged(page: 0, size: limit);
}

/// The 4-column library thumbnail grid shared by the post and avatar pickers.
/// Thumbnails go into [cache] (owned by the screen) so scrolling back doesn't
/// re-decode them.
class PhotoLibraryGrid extends StatelessWidget {
  const PhotoLibraryGrid({
    super.key,
    required this.assets,
    required this.cache,
    required this.onTap,
  });

  final List<AssetEntity> assets;
  final Map<String, Uint8List> cache;
  final ValueChanged<AssetEntity> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: assets.length,
      itemBuilder: (_, i) => _GridCell(
        asset: assets[i],
        cache: cache,
        onTap: () => onTap(assets[i]),
      ),
    );
  }
}

/// One grid thumbnail. Loads (and caches) its bytes once.
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
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(220),
    );
    if (bytes == null) return;
    widget.cache[widget.asset.id] = bytes;
    if (mounted) setState(() => _bytes = bytes);
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
