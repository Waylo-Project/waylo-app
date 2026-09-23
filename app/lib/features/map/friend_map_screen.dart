import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'photo_map_view.dart';

/// A friend's own map: their photos only, opened from the Friends list. RLS
/// allows it because they're an accepted friend; no compose FAB (not your map).
class FriendMapScreen extends StatelessWidget {
  const FriendMapScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  final String userId;
  final String username;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.friendMapTitle(username))),
      body: PhotoMapView(
        feed: UserMapFeed(userId),
        emptyText: l.mapEmptyFriend(username),
      ),
    );
  }
}
