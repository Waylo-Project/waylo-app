import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../features/post/new_post_draft.dart';
import 'geocoding.dart';

/// Creates posts: compress + upload the photo to Storage, then write the row
/// atomically via the `create_post` RPC.
///
/// Storage path convention is `{uid}/{groupId}/{index}.jpg` — the first segment
/// must be the caller's uid, which both the Storage insert policy and the RPC
/// enforce. v1 is one photo, so the index is always 0.
class PostRepository {
  PostRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<String> createPost(NewPostDraft draft) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Not signed in.');
    }

    // Resize + compress before upload. keepExif: false strips metadata (incl.
    // GPS — we already captured the location) and auto-rotates by orientation.
    final bytes = await FlutterImageCompress.compressWithFile(
      draft.photo.absolute.path,
      minWidth: 2048,
      minHeight: 2048,
      quality: 85,
    );
    if (bytes == null) {
      throw StateError('Could not process the image.');
    }

    final group = _uuid.v4();
    final path = '$uid/$group/0.jpg';
    await _client.storage.from('photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Pre-generate a small thumbnail so map markers load a static file (~40ms)
    // instead of an on-the-fly Storage transform (~600ms). Path convention:
    // the original's name with a `_thumb` suffix (see FeedRepository.thumbnail).
    final thumb = await FlutterImageCompress.compressWithFile(
      draft.photo.absolute.path,
      minWidth: 240,
      minHeight: 240,
      quality: 70,
    );
    if (thumb != null) {
      await _client.storage.from('photos').uploadBinary(
            '$uid/$group/0_thumb.jpg',
            thumb,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }

    // Country for the zoomed-out flag tier (best-effort; null if it fails).
    final countryCode = await reverseCountryCode(draft.location);

    final postId = await _client.rpc('create_post', params: {
      'p_lng': draft.location.longitude,
      'p_lat': draft.location.latitude,
      'p_caption': draft.caption.isEmpty ? null : draft.caption,
      'p_taken_at': draft.takenAt?.toIso8601String(),
      'p_image_paths': [path],
      'p_country_code': countryCode,
      'p_place_label': draft.placeLabel,
    });
    return postId as String;
  }
}
