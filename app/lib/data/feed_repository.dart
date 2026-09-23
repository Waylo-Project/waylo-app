import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/lat_lng.dart';

/// One photo pin on the map: a post's location plus its first photo's path.
class FeedPoint {
  const FeedPoint({
    required this.postId,
    required this.ownerId,
    required this.location,
    required this.imagePath,
  });

  final String postId;
  final String ownerId;
  final LatLng location;
  final String imagePath;

  factory FeedPoint.fromMap(Map<String, dynamic> m) {
    return FeedPoint(
      postId: m['post_id'] as String,
      ownerId: m['owner_id'] as String,
      location: LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      ),
      imagePath: m['image_path'] as String,
    );
  }
}

/// One country's flag marker on the zoomed-out map: how many visible posts are
/// in that country and where to place the flag (centroid of those posts).
class FlagPoint {
  const FlagPoint({
    required this.countryCode,
    required this.count,
    required this.location,
  });

  final String countryCode; // ISO alpha-2, lowercase (matches flag assets)
  final int count;
  final LatLng location;

  factory FlagPoint.fromMap(Map<String, dynamic> m) {
    return FlagPoint(
      countryCode: m['country_code'] as String,
      count: (m['post_count'] as num).toInt(),
      location: LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      ),
    );
  }
}

/// Details for the photo sheet: who posted, caption, when, and their avatar.
class PostDetail {
  const PostDetail({this.username, this.caption, this.takenAt, this.avatarUrl});

  final String? username;
  final String? caption;
  final DateTime? takenAt;
  final String? avatarUrl;
}

/// A recent (last-24h) friend post for the merged "Recent" map + "Just in"
/// strip: a map pin plus enough of the author to badge a marker and label a
/// card. Extends [FeedPoint] so it drops straight into the marker/sheet code.
class RecentPoint extends FeedPoint {
  const RecentPoint({
    required super.postId,
    required super.ownerId,
    required super.location,
    required super.imagePath,
    required this.username,
    required this.createdAt,
    this.avatarUrl,
  });

  final String username;
  final DateTime createdAt;
  final String? avatarUrl;

  factory RecentPoint.fromMap(Map<String, dynamic> m, String? avatarUrl) {
    return RecentPoint(
      postId: m['post_id'] as String,
      ownerId: m['owner_id'] as String,
      location: LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      ),
      imagePath: m['image_path'] as String,
      username: m['username'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      avatarUrl: avatarUrl,
    );
  }
}

/// One person who liked a post (for the reactor cluster on the sheet).
class Liker {
  const Liker({required this.userId, required this.username, this.avatarUrl});
  final String userId;
  final String username;
  final String? avatarUrl;
}

/// Aggregate like state for a post: total, whether I liked it, and a few faces
/// for the reactor cluster.
class LikeSummary {
  const LikeSummary({
    required this.count,
    required this.likedByMe,
    required this.topLikers,
  });
  final int count;
  final bool likedByMe;
  final List<Liker> topLikers;

  static const empty = LikeSummary(count: 0, likedByMe: false, topLikers: []);
}

/// One comment on a post (guestbook bubble). A top-level comment has a null
/// [parentId]; a one-level reply carries the id of the comment it answers.
class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.body,
    required this.createdAt,
    this.parentId,
    this.avatarUrl,
  });
  final String id;
  final String userId;
  final String username;
  final String body;
  final DateTime createdAt;
  final String? parentId;
  final String? avatarUrl;

  bool get isReply => parentId != null;
}

/// A top-level comment together with its replies, oldest first — the shape the
/// photo sheet renders (parents in order, each followed by its reply thread).
class CommentThread {
  const CommentThread({required this.comment, required this.replies});
  final Comment comment;
  final List<Comment> replies;
}

/// Reads the posts visible to the current user (own + accepted friends, via
/// RLS) within a map bounding box. Backed by the `posts_in_view` RPC.
class FeedRepository {
  FeedRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// [userId]'s posts whose location falls inside the box [sw]..[ne]. RLS still
  /// applies, so this only returns posts the caller may see (own, or a friend's).
  Future<List<FeedPoint>> pointsInView(
      LatLng sw, LatLng ne, String userId) async {
    final rows = await _client.rpc('posts_in_view', params: {
      'min_lng': sw.longitude,
      'min_lat': sw.latitude,
      'max_lng': ne.longitude,
      'max_lat': ne.latitude,
      'p_user_id': userId,
    }) as List<dynamic>;

    return rows
        .map((r) => FeedPoint.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// The coordinates of [userId]'s posts in one country (RLS-scoped). Used when
  /// a country flag is tapped, to frame the camera over the real posts instead
  /// of the geographic country center. Backed by `posts_for_country`.
  Future<List<LatLng>> postsForCountry(
      String userId, String countryCode) async {
    final rows = await _client.rpc('posts_for_country', params: {
      'p_user_id': userId,
      'p_country_code': countryCode,
    }) as List<dynamic>;
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      return LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
    }).toList();
  }

  /// Whether [userId] has any post the caller may see (RLS-scoped) — a cheap
  /// existence check for the empty-map hint. Queries the `posts` table directly
  /// (limit 1, no PostGIS), so it avoids the full-globe envelope that trips
  /// `posts_in_view`.
  Future<bool> hasVisiblePosts(String userId) async {
    final rows = await _client
        .from('posts')
        .select('id')
        .eq('user_id', userId)
        .limit(1) as List<dynamic>;
    return rows.isNotEmpty;
  }

  /// Per-country aggregates for [userId]'s zoomed-out flag tier (no bounding box;
  /// a full-globe envelope trips PostGIS). Backed by `flags_for_user`.
  Future<List<FlagPoint>> flagsForUser(String userId) async {
    final rows = await _client
        .rpc('flags_for_user', params: {'p_user_id': userId}) as List<dynamic>;
    return rows
        .map((r) => FlagPoint.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// A time-limited URL for viewing a full photo (the `photos` bucket is
  /// private, so a signed URL is required).
  Future<String> signedUrl(String imagePath, {int expiresIn = 3600}) {
    return _client.storage.from('photos').createSignedUrl(imagePath, expiresIn);
  }

  /// Author + caption + date for a post (RLS limits this to visible posts).
  Future<PostDetail> postDetail(String postId) async {
    final row = await _client
        .from('posts')
        // Disambiguate the embed: post_likes/post_comments also link posts to
        // profiles (many-to-many), so name the author FK explicitly.
        .select('caption, taken_at, profiles!posts_user_id_fkey(username, avatar_path)')
        .eq('id', postId)
        .maybeSingle();
    if (row == null) return const PostDetail();
    final profile = row['profiles'] as Map<String, dynamic>?;
    final taken = row['taken_at'] as String?;
    final avatarPath = profile?['avatar_path'] as String?;
    return PostDetail(
      username: profile?['username'] as String?,
      caption: row['caption'] as String?,
      takenAt: taken == null ? null : DateTime.tryParse(taken),
      avatarUrl: avatarPath == null
          ? null
          : _client.storage.from('avatars').getPublicUrl(avatarPath),
    );
  }

  /// Public URL for an avatar (the `avatars` bucket is public). null-safe.
  String? _avatarUrl(String? path) => path == null
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);

  /// Every accepted friend's posts from the last 24h, newest first, for the
  /// merged "Recent" map + "Just in" strip. Backed by the `recent_feed` RPC
  /// (RLS-scoped to friends; excludes your own posts).
  Future<List<RecentPoint>> recentFeed() async {
    final rows = await _client.rpc('recent_feed') as List<dynamic>;
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      return RecentPoint.fromMap(m, _avatarUrl(m['avatar_path'] as String?));
    }).toList();
  }

  /// All photo paths of a post, in carousel order (a post may hold several).
  Future<List<String>> postPhotos(String postId) async {
    final rows = await _client
        .from('post_photos')
        .select('image_path')
        .eq('post_id', postId)
        .order('position') as List<dynamic>;
    return rows.map((r) => (r as Map)['image_path'] as String).toList();
  }

  /// Like count + whether I liked + a few faces for the reactor cluster. The
  /// friend-scale row count makes a full fetch fine (no separate count call).
  Future<LikeSummary> likeSummary(String postId) async {
    final uid = _client.auth.currentUser?.id;
    final rows = await _client
        .from('post_likes')
        .select('user_id, profiles(username, avatar_path)')
        .eq('post_id', postId)
        .order('created_at', ascending: false) as List<dynamic>;
    final likers = [
      for (final r in rows)
        if ((r as Map)['profiles'] != null)
          Liker(
            userId: r['user_id'] as String,
            username: (r['profiles'] as Map)['username'] as String,
            avatarUrl:
                _avatarUrl((r['profiles'] as Map)['avatar_path'] as String?),
          ),
    ];
    return LikeSummary(
      count: rows.length,
      likedByMe: rows.any((r) => (r as Map)['user_id'] == uid),
      topLikers: likers.take(3).toList(),
    );
  }

  /// Add or remove my like on a post (idempotent).
  Future<void> setLike(String postId, bool liked) async {
    final uid = _client.auth.currentUser!.id;
    if (liked) {
      await _client
          .from('post_likes')
          .upsert({'post_id': postId, 'user_id': uid});
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    }
  }

  /// Comments on a post, oldest first (guestbook order). Both top-level comments
  /// and one-level replies come back in this flat list; [parentId] distinguishes
  /// them. The UI groups them into threads for display.
  Future<List<Comment>> comments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select(
            'id, user_id, body, created_at, parent_id, profiles(username, avatar_path)')
        .eq('post_id', postId)
        .order('created_at') as List<dynamic>;
    return rows.map((r) => _comment(r as Map<String, dynamic>)).toList();
  }

  /// Post a comment (or a reply, when [parentId] is set) and return the saved
  /// row (so the UI can append it without a refetch). The DB trigger enforces
  /// one-level threading and same-post integrity.
  Future<Comment> addComment(String postId, String body, {String? parentId}) async {
    final uid = _client.auth.currentUser!.id;
    final row = await _client
        .from('post_comments')
        .insert({
          'post_id': postId,
          'user_id': uid,
          'body': body,
          'parent_id': ?parentId,
        })
        .select(
            'id, user_id, body, created_at, parent_id, profiles(username, avatar_path)')
        .single();
    return _comment(row);
  }

  /// Delete a comment (RLS allows the author or the post owner).
  Future<void> deleteComment(String commentId) async {
    await _client.from('post_comments').delete().eq('id', commentId);
  }

  Comment _comment(Map<String, dynamic> r) {
    final profile = r['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      username: profile?['username'] as String? ?? 'someone',
      body: r['body'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      parentId: r['parent_id'] as String?,
      avatarUrl: _avatarUrl(profile?['avatar_path'] as String?),
    );
  }

  /// Group a flat, chronologically-ordered comment list into threads: each
  /// top-level comment followed by its replies (also oldest first). A reply
  /// whose parent isn't present (e.g. a deleted parent) is dropped.
  static List<CommentThread> threadComments(List<Comment> flat) {
    final replies = <String, List<Comment>>{};
    for (final c in flat) {
      if (c.parentId != null) {
        (replies[c.parentId!] ??= <Comment>[]).add(c);
      }
    }
    return [
      for (final c in flat)
        if (c.parentId == null)
          CommentThread(comment: c, replies: replies[c.id] ?? const []),
    ];
  }

  /// Edit a post the caller owns: location, caption, date, and country code, in
  /// one atomic `update_post` RPC (owner check + server-built geography). An
  /// empty caption is stored as null.
  Future<void> updatePost({
    required String postId,
    required LatLng location,
    required String? caption,
    required DateTime? takenAt,
    required String? countryCode,
  }) async {
    await _client.rpc('update_post', params: {
      'p_post_id': postId,
      'p_lng': location.longitude,
      'p_lat': location.latitude,
      'p_caption': (caption == null || caption.isEmpty) ? null : caption,
      'p_taken_at': takenAt?.toIso8601String(),
      'p_country_code': countryCode,
    });
  }

  /// Delete a post the caller owns: drop the row (FK cascades photos, likes,
  /// comments), then best-effort remove its Storage objects (originals +
  /// thumbs). RLS restricts the row delete to the owner.
  Future<void> deletePost(String postId) async {
    final photoRows = await _client
        .from('post_photos')
        .select('image_path')
        .eq('post_id', postId) as List<dynamic>;
    final paths = <String>[];
    for (final r in photoRows) {
      final p = (r as Map)['image_path'] as String;
      paths.add(p);
      paths.add(p.replaceFirst(RegExp(r'\.jpg$'), '_thumb.jpg'));
    }
    await _client.from('posts').delete().eq('id', postId);
    if (paths.isNotEmpty) {
      try {
        await _client.storage.from('photos').remove(paths);
      } catch (_) {
        // Orphaned files are harmless; the authoritative row is already gone.
      }
    }
  }

  /// A small thumbnail for a map marker. Prefers the pre-generated static thumb
  /// (`*_thumb.jpg`, ~40ms); falls back to an on-the-fly transform of the
  /// original (~600ms) for older posts that have no pre-made thumb.
  Future<Uint8List> thumbnail(String imagePath, {int size = 120}) async {
    final store = _client.storage.from('photos');
    final thumbPath = imagePath.replaceFirst(RegExp(r'\.jpg$'), '_thumb.jpg');
    try {
      return await store.download(thumbPath);
    } catch (_) {
      return store.download(
        imagePath,
        transform: TransformOptions(
          width: size,
          height: size,
          resize: ResizeMode.cover,
        ),
      );
    }
  }
}
