import 'package:flutter/material.dart';

import '../../core/lat_lng.dart';
import 'new_post_draft.dart';
import 'post_crop_screen.dart';
import 'post_grid_screen.dart';
import 'post_location_service.dart';

/// Entry point for composing a post. Three steps: pick from the library grid
/// (no system gallery hop) → crop → details (location + place + date + caption).
/// The crop screen pushes details on top of itself (preparing the file +
/// location under a loading overlay) so the home map never shows through mid
/// transition. Returns the composed [NewPostDraft], or null if the user backed
/// out.
Future<NewPostDraft?> startNewPost(
  BuildContext context, {
  required LatLng fallbackCenter,
  required PhotoSource source,
  PostLocationService locationService = const PostLocationService(),
}) async {
  // 1. Pick a photo from the grid (or camera).
  final raw = await Navigator.of(context).push<PickedPostPhoto>(
    MaterialPageRoute(
      builder: (_) => PostGridScreen(startCamera: source == PhotoSource.camera),
    ),
  );
  if (raw == null || !context.mounted) return null;

  // 2. Crop → (internally) details. Returns the finished draft.
  return Navigator.of(context).push<NewPostDraft>(
    MaterialPageRoute(
      builder: (_) => PostCropScreen(
        raw: raw,
        fallbackCenter: fallbackCenter,
        locationService: locationService,
      ),
    ),
  );
}

/// Where a photo comes from. The home chrome's (+) popup menu picks this and
/// passes it to [startNewPost].
enum PhotoSource { camera, gallery }
