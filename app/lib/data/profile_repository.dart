import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A user's profile (the fields collected at sign-up).
class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarPath,
    this.gender,
    this.birthDate,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarPath;
  final String? gender;
  final DateTime? birthDate;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final birth = map['birth_date'] as String?;
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String?,
      avatarPath: map['avatar_path'] as String?,
      gender: map['gender'] as String?,
      birthDate: birth == null ? null : DateTime.tryParse(birth),
    );
  }

  /// Public URL for the avatar (the `avatars` bucket is public), or null.
  String? get avatarUrl {
    final path = avatarPath;
    if (path == null) return null;
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
  }
}

/// Reads/writes the current user's row in `profiles`. RLS enforces that a user
/// can only insert/update their own row, so we never pass a foreign user id.
class ProfileRepository {
  ProfileRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// The signed-in user's profile, or null if they haven't created one yet.
  Future<Profile?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  /// Creates the signed-in user's profile row.
  /// Throws [UsernameTakenException] if the username is already in use.
  Future<Profile> createMyProfile({
    required String username,
    String? displayName,
    String? gender,
    DateTime? birthDate,
  }) async {
    final uid = _client.auth.currentUser!.id;

    final payload = <String, dynamic>{'id': uid, 'username': username};
    if (displayName != null && displayName.isNotEmpty) {
      payload['display_name'] = displayName;
    }
    if (gender != null) payload['gender'] = gender;
    if (birthDate != null) payload['birth_date'] = _dateOnly(birthDate);

    try {
      final data =
          await _client.from('profiles').insert(payload).select().single();
      return Profile.fromMap(data);
    } on PostgrestException catch (e) {
      // 23505 = unique_violation (username already taken).
      if (e.code == '23505') {
        throw const UsernameTakenException();
      }
      // 23503 = foreign_key_violation: the session's user no longer exists in
      // auth.users (e.g. a stale/deleted test session). Recoverable by re-auth.
      if (e.code == '23503') {
        throw const SessionInvalidException();
      }
      rethrow;
    }
  }

  /// Updates the signed-in user's username. Throws [UsernameTakenException] if
  /// another user already has it.
  Future<Profile> updateUsername(String username) =>
      _update({'username': username});

  /// Updates the display name. An empty/blank value clears it (stored null).
  Future<Profile> updateDisplayName(String? displayName) {
    final v = displayName?.trim();
    return _update({'display_name': (v == null || v.isEmpty) ? null : v});
  }

  /// Uploads [bytes] (a square crop) as the user's avatar, then points
  /// `avatar_path` at it. The new file gets a unique name so the public URL
  /// changes (no stale CDN cache). Returns the updated profile.
  Future<Profile> uploadAvatar(Uint8List bytes) async {
    final uid = _client.auth.currentUser!.id;
    final jpeg = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 512,
      minHeight: 512,
      quality: 85,
    );
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          jpeg,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _update({'avatar_path': path});
  }

  /// Clears the user's avatar (back to the initial fallback).
  Future<Profile> removeAvatar() => _update({'avatar_path': null});

  /// Permanently deletes the caller's account. The `delete_account` RPC
  /// (SECURITY DEFINER, derives the user from auth.uid()) removes the auth user
  /// — which cascades to the profile and everything under it — plus the user's
  /// Storage files. The caller should sign out afterwards.
  Future<void> deleteAccount() => _client.rpc('delete_account');

  /// Updates the caller's own profile row (RLS limits writes to that row).
  Future<Profile> _update(Map<String, dynamic> payload) async {
    final uid = _client.auth.currentUser!.id;
    try {
      final data = await _client
          .from('profiles')
          .update(payload)
          .eq('id', uid)
          .select()
          .single();
      return Profile.fromMap(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const UsernameTakenException();
      }
      rethrow;
    }
  }

  static String _dateOnly(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'That username is already taken.';
}

/// The current auth session refers to a user that no longer exists.
class SessionInvalidException implements Exception {
  const SessionInvalidException();
  @override
  String toString() => 'Your session is no longer valid.';
}
