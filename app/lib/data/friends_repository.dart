import 'package:supabase_flutter/supabase_flutter.dart';

/// A user shown in friend lists / search results.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.countryCodes = const [],
  });

  final String id;
  final String username;
  final String? avatarUrl;

  /// ISO 3166-1 alpha-2 (lowercase) codes for the countries this friend has
  /// posted in, most-posted-first — the "passport strip". Empty for search
  /// results (only populated by [FriendsRepository.friends]).
  final List<String> countryCodes;

  UserSummary withCountries(List<String> codes) => UserSummary(
    id: id,
    username: username,
    avatarUrl: avatarUrl,
    countryCodes: codes,
  );
}

/// A pending friend request addressed to the current user, with mutual-friend
/// context for the request card.
class IncomingRequest {
  const IncomingRequest({
    required this.requestId,
    required this.from,
    this.mutualCount = 0,
    this.mutualUsernames = const [],
  });

  final String requestId;
  final UserSummary from;

  /// How many friends the sender and I share.
  final int mutualCount;

  /// A small sample (up to 3) of those mutual friends' usernames, for the
  /// "2 mutual · @yuki, @minseo" line.
  final List<String> mutualUsernames;
}

/// Friends: search, requests, accept/decline, list, remove. Wraps the existing
/// tables + security-definer RPCs (`send_friend_request`,
/// `respond_to_friend_request`, `remove_friend`). RLS limits what's visible.
class FriendsRepository {
  FriendsRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  UserSummary _summary(Map<String, dynamic> row) {
    final avatarPath = row['avatar_path'] as String?;
    return UserSummary(
      id: row['id'] as String,
      username: row['username'] as String,
      avatarUrl: avatarPath == null
          ? null
          : _client.storage.from('avatars').getPublicUrl(avatarPath),
    );
  }

  /// Search profiles by username (case-insensitive), excluding myself.
  Future<List<UserSummary>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final rows = await _client
        .from('profiles')
        .select('id, username, avatar_path')
        .ilike('username', '%$q%')
        .neq('id', _uid)
        .limit(20);
    return rows.map((r) => _summary(r)).toList();
  }

  Future<void> sendRequest(String toUserId) async {
    await _client.rpc('send_friend_request', params: {'p_to_user': toUserId});
  }

  /// Ids of users I have a still-pending outgoing request to, so the Find screen
  /// can show "Sent" instead of an "Add" button for them (RLS lets a sender read
  /// their own requests).
  Future<Set<String>> outgoingPendingIds() async {
    final rows = await _client
        .from('friend_requests')
        .select('to_user')
        .eq('from_user', _uid)
        .eq('status', 'pending');
    return {for (final r in rows) r['to_user'] as String};
  }

  /// Pending requests addressed to me, each with mutual-friend context.
  /// Backed by `incoming_requests_with_mutuals` (see migration
  /// `20260625090000_friends_meta.sql`).
  Future<List<IncomingRequest>> incoming() async {
    final rows = await _client.rpc('incoming_requests_with_mutuals') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        IncomingRequest(
          requestId: r['request_id'] as String,
          // The RPC returns the sender id as `from_user` (not `id`); map it to
          // the key `_summary` expects, else `r['id']` is null and the cast
          // throws once an actual request arrives.
          from: _summary({
            'id': r['from_user'],
            'username': r['username'],
            'avatar_path': r['avatar_path'],
          }),
          mutualCount: (r['mutual_count'] as num?)?.toInt() ?? 0,
          mutualUsernames: ((r['mutual_usernames'] as List?) ?? const [])
              .map((e) => e as String)
              .toList(),
        ),
    ];
  }

  Future<void> respond(String requestId, {required bool accept}) async {
    await _client.rpc(
      'respond_to_friend_request',
      params: {'p_request_id': requestId, 'p_accept': accept},
    );
  }

  /// My accepted friends, each with their "passport strip" of country codes
  /// (ordered most-posted-first) attached.
  Future<List<UserSummary>> friends() async {
    final rows = await _client
        .from('friendships')
        .select('friend_id')
        .eq('user_id', _uid);
    if (rows.isEmpty) return [];
    final ids = [for (final r in rows) r['friend_id'] as String];
    final profiles = await _client
        .from('profiles')
        .select('id, username, avatar_path')
        .inFilter('id', ids);
    final countries = await _countriesByFriend();
    return profiles
        .map((r) => _summary(r).withCountries(countries[r['id']] ?? const []))
        .toList();
  }

  /// friend id -> distinct country codes, most-posted-first. One RPC call
  /// (`friend_countries`) instead of a query per friend.
  Future<Map<String, List<String>>> _countriesByFriend() async {
    final rows = await _client.rpc('friend_countries') as List;
    // Collect (code, count) per friend, then sort by count desc.
    final byFriend = <String, List<MapEntry<String, int>>>{};
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final fid = r['friend_id'] as String;
      final code = r['country_code'] as String;
      final count = (r['post_count'] as num?)?.toInt() ?? 0;
      (byFriend[fid] ??= []).add(MapEntry(code, count));
    }
    return byFriend.map((fid, entries) {
      entries.sort((a, b) => b.value.compareTo(a.value));
      return MapEntry(fid, [for (final e in entries) e.key]);
    });
  }

  Future<void> removeFriend(String friendId) async {
    await _client.rpc('remove_friend', params: {'p_friend_id': friendId});
  }
}
