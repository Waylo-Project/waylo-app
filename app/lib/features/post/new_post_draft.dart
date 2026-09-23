import 'dart:io';

import '../../core/lat_lng.dart';

/// A post being composed but not yet uploaded. Phase 2.1 produces this; Phase
/// 2.2 turns it into a Storage upload + a `create_post` RPC call.
///
/// v1 is one photo per post (the backend already supports a carousel via
/// `post_photos`, so this can grow to a list later).
class NewPostDraft {
  NewPostDraft({
    required this.photo,
    required this.location,
    this.takenAt,
    this.caption = '',
    this.placeLabel,
  });

  /// The picked/captured image file.
  final File photo;

  /// The confirmed map location for the pin.
  final LatLng location;

  /// When the photo was taken (date edited by the user; time kept from EXIF).
  final DateTime? takenAt;

  /// Optional caption for the post.
  final String caption;

  /// A place name the user wrote (e.g. "Grandma's café"). Null when they kept
  /// the auto-filled name, which viewers then see geocoded in their language.
  final String? placeLabel;

  NewPostDraft copyWith({LatLng? location, String? caption, String? placeLabel}) {
    return NewPostDraft(
      photo: photo,
      location: location ?? this.location,
      takenAt: takenAt,
      caption: caption ?? this.caption,
      placeLabel: placeLabel ?? this.placeLabel,
    );
  }
}
