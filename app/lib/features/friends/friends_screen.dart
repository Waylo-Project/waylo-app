import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/date_format.dart';
import '../../core/error_dialog.dart';
import '../../core/user_avatar.dart';
import '../../data/feed_repository.dart';
import '../../data/friends_repository.dart';
import '../../data/geocoding.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../map/friend_map_screen.dart';
import '../map/photo_map_view.dart';
import '../photo/photo_sheet.dart';

/// Friends hub: your friends, incoming requests, and finding people by username.
/// Embeddable (no Scaffold / app bar) — hosted under the map-home chrome and
/// swapped in by the `Map | Friends` pill: an iOS-style segmented control
/// (Recent / Friends / Requests) over 72px rows, request cards with mutual
/// context, and a passport strip of country flags per friend.
class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  final _repo = FriendsRepository();

  int _seg = 0; // 0 = Recent, 1 = Friends, 2 = Requests

  // Kept as in-memory lists (not bare futures) so the count badge stays live
  // and swipe-to-remove can drop a row optimistically. null = still loading.
  List<UserSummary>? _friends;
  List<IncomingRequest>? _requests;

  // The tapped Recent photo / cluster, hoisted to this level so its sheet
  // renders ABOVE the floating header.
  List<FeedPoint>? _sheet;

  // Lets a tab switch ask the Recent panel to refetch (it manages its own feed).
  final GlobalKey<_RecentPanelState> _recentKey =
      GlobalKey<_RecentPanelState>();

  /// Refresh the tab you switch to, so friends' new posts / requests show up
  /// without a manual pull (silently: the list stays on screen meanwhile).
  void _onTabChanged(int i) {
    setState(() => _seg = i);
    switch (i) {
      case 0:
        _recentKey.currentState?.reload();
      case 1:
        _loadFriends(silent: true);
      case 2:
        _loadRequests(silent: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadRequests();
  }

  // [silent] keeps the current list on screen while refetching (used by the
  // refresh-on-tab-switch), instead of flashing the loading spinner each time.
  Future<void> _loadFriends({bool silent = false}) async {
    if (!silent && mounted) setState(() => _friends = null);
    try {
      final f = await _repo.friends();
      if (mounted) setState(() => _friends = f);
    } catch (e) {
      if (mounted) {
        setState(() => _friends ??= const []);
        _error(AppLocalizations.of(context).friendsFailed('$e'));
      }
    }
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent && mounted) setState(() => _requests = null);
    try {
      final r = await _repo.incoming();
      if (mounted) setState(() => _requests = r);
    } catch (e) {
      if (mounted) {
        setState(() => _requests ??= const []);
        _error(AppLocalizations.of(context).friendsFailed('$e'));
      }
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    showErrorDialog(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // List content starts below the floating header (top inset + control).
    final listTop = topInset + 52 + 46 + 12;

    return Stack(
      children: [
        // Content fills the WHOLE area. Recent is a full-screen map running
        // behind the status bar and the floating header — exactly like the home
        // map. The list segments start below the header via top padding.
        Positioned.fill(
          child: IndexedStack(
            index: _seg,
            children: [
              _RecentPanel(
                key: _recentKey,
                onPhotosSelected: (pts) => setState(() => _sheet = pts),
              ),
              _friendsPanel(topPad: listTop),
              _requestsPanel(topPad: listTop),
            ],
          ),
        ),
        // Floating header: transparent over the Recent map (map shows through
        // above the buttons), solid white over the lists.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: _seg == 0 ? null : context.c.surface,
            padding: EdgeInsets.fromLTRB(16, topInset + 52, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentedControl(
                    selected: _seg,
                    requestCount: _requests?.length ?? 0,
                    onChanged: _onTabChanged,
                  ),
                ),
                const SizedBox(width: 10),
                _SearchButton(onTap: _openFind),
              ],
            ),
          ),
        ),
        // Sheet sits last so it renders OVER the floating header.
        if (_sheet != null)
          PhotoSheet(
            key: ValueKey(_sheet!.first.postId),
            photos: _sheet!,
            onClose: () => setState(() => _sheet = null),
          ),
      ],
    );
  }

  /// The search icon opens Find as a pushed screen.
  void _openFind() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FindScreen(
          repo: _repo,
          friendIds: {for (final f in _friends ?? const <UserSummary>[]) f.id},
        ),
      ),
    );
  }

  // ---- Friends ------------------------------------------------------------

  Widget _friendsPanel({double topPad = 0}) {
    final l = AppLocalizations.of(context);
    final friends = _friends;
    if (friends == null) return const _Loading();
    if (friends.isEmpty) {
      return _Empty(onRefresh: _loadFriends, text: l.friendsEmptyFriends);
    }
    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView(
        padding: EdgeInsets.only(top: topPad, bottom: 100),
        children: [
          _SectionHeader(l.friendsCountHeader(friends.length)),
          for (final f in friends) _friendRow(f),
        ],
      ),
    );
  }

  Widget _friendRow(UserSummary f) {
    return Dismissible(
      key: ValueKey('friend-${f.id}'),
      direction: DismissDirection.endToStart,
      background: const _RemoveBackground(),
      confirmDismiss: (_) => _confirmRemove(f),
      child: _Row(
        user: f,
        subtitle: _PassportStrip(codes: f.countryCodes),
        trailing: Icon(
          Icons.chevron_right,
          color: context.c.inkFaint,
          size: 24,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FriendMapScreen(userId: f.id, username: f.username),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmRemove(UserSummary f) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.friendsRemoveTitle(f.username)),
        content: Text(l.friendsRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.c.danger),
            child: Text(l.friendsRemove),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    // Optimistically drop the row, then call the server.
    setState(
      () => _friends = [
        for (final x in _friends ?? const <UserSummary>[])
          if (x.id != f.id) x,
      ],
    );
    try {
      await _repo.removeFriend(f.id);
      // The row is already gone from the list — no confirmation toast.
    } catch (e) {
      _error(l.friendsFailed('$e'));
      _loadFriends();
    }
    return true;
  }

  // ---- Requests -----------------------------------------------------------

  Widget _requestsPanel({double topPad = 0}) {
    final l = AppLocalizations.of(context);
    final requests = _requests;
    if (requests == null) return const _Loading();
    if (requests.isEmpty) {
      return _Empty(onRefresh: _loadRequests, text: l.friendsEmptyRequests);
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topPad, 16, 100),
        children: [
          _SectionHeader(l.friendsRequestsHeader),
          for (final r in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                request: r,
                onAccept: () => _respond(r, true),
                onDecline: () => _respond(r, false),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _respond(IncomingRequest r, bool accept) async {
    // Drop the card immediately; refresh the friends list on accept.
    setState(
      () => _requests = [
        for (final x in _requests ?? const <IncomingRequest>[])
          if (x.requestId != r.requestId) x,
      ],
    );
    final l = AppLocalizations.of(context);
    try {
      await _repo.respond(r.requestId, accept: accept);
      // The request card is already gone; an accept refreshes the friends list.
      if (accept) _loadFriends();
    } catch (e) {
      _error(l.friendsFailed('$e'));
      _loadRequests();
    }
  }
}

// ---------------------------------------------------------------------------
// Segmented control
// ---------------------------------------------------------------------------

/// iOS-style three-up segmented control. Sky-blue is reserved for the count
/// badge (selection/notification); the active segment is a white card.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.requestCount,
    required this.onChanged,
  });

  final int selected;
  final int requestCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(context, 0, l.friendsSegRecent),
          _segment(context, 1, l.friendsSegFriends),
          _segment(context, 2, l.friendsSegRequests, badge: requestCount),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    int index,
    String label, {
    int badge = 0,
  }) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 38,
          decoration: BoxDecoration(
            color: active ? context.c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: active ? context.c.ink : context.c.inkFaint,
                ),
              ),
              if (badge > 0) ...[
                SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.c.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.c.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request card
// ---------------------------------------------------------------------------

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final IncomingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = request;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ListAvatar(user: r.from),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${r.from.username}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.c.ink,
                      ),
                    ),
                    if (r.mutualCount > 0) ...[
                      SizedBox(height: 3),
                      Text(
                        _mutualLine(l, r),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.c.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.c.primary,
                      foregroundColor: context.c.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l.friendsAccept),
                  ),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                height: 44,
                width: 104,
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.inkMuted,
                    side: BorderSide(color: context.c.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l.friendsDecline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _mutualLine(AppLocalizations l, IncomingRequest r) {
    final names = r.mutualUsernames.map((u) => '@$u').join(', ');
    final label = l.friendsMutual(r.mutualCount);
    return names.isEmpty ? label : '$label · $names';
  }
}

// ---------------------------------------------------------------------------
// Find
// ---------------------------------------------------------------------------

/// Find people by username and send requests.
class _FindTab extends StatefulWidget {
  const _FindTab({required this.repo, required this.friendIds});
  final FriendsRepository repo;

  /// Ids of people I'm already friends with — their row shows a disabled
  /// "Friends" state instead of an "Add" button.
  final Set<String> friendIds;

  @override
  State<_FindTab> createState() => _FindTabState();
}

class _FindTabState extends State<_FindTab> {
  final _controller = TextEditingController();
  List<UserSummary> _results = [];
  final Set<String> _sent = {};
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Seed the "Sent" state from still-pending outgoing requests, so someone I've
  /// already requested shows "Sent" rather than an "Add" button (best-effort).
  Future<void> _loadSent() async {
    try {
      final ids = await widget.repo.outgoingPendingIds();
      if (mounted && ids.isNotEmpty) setState(() => _sent.addAll(ids));
    } catch (_) {
      // Non-fatal: worst case an already-requested user shows "Add" again, and
      // re-sending is idempotent server-side.
    }
  }

  /// Live search: debounce each keystroke and query automatically. Does NOT
  /// unfocus, so the keyboard stays up while typing.
  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final results = await widget.repo.search(_controller.text);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      debugPrint('[friends] search failed: $e');
      if (mounted) {
        showErrorDialog(
          context,
          AppLocalizations.of(context).friendsSearchFailed('$e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
        });
      }
    }
  }

  Future<void> _send(UserSummary u) async {
    try {
      await widget.repo.sendRequest(u.id);
      if (mounted) setState(() => _sent.add(u.id));
    } catch (e) {
      debugPrint('[friends] sendRequest failed: $e');
      if (mounted) {
        showErrorDialog(
          context,
          AppLocalizations.of(context).friendsFailed('$e'),
        );
      }
    }
  }

  /// Trailing control for a search result: a muted, non-pressable label for
  /// existing friends ("Friends") or already-sent requests ("Sent"), otherwise
  /// the "Add" button.
  Widget _trailingFor(UserSummary u) {
    final l = AppLocalizations.of(context);
    if (widget.friendIds.contains(u.id)) {
      return _StatusLabel(l.friendsSegFriends);
    }
    if (_sent.contains(u.id)) return _StatusLabel(l.friendsStatusSent);
    return FilledButton(
      onPressed: () => _send(u),
      style: FilledButton.styleFrom(
        backgroundColor: context.c.primary,
        foregroundColor: context.c.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Text(l.friendsAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) => _search(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.c.ink,
            ),
            decoration: InputDecoration(
              hintText: l.friendsSearchHint,
              hintStyle: TextStyle(color: context.c.inkFaint),
              prefixIcon: Icon(Icons.search, color: context.c.inkFaint),
              filled: true,
              fillColor: context.c.fill,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_loading)
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: context.c.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? _FindHint(searched: _searched && !_loading)
              : ListView(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  children: [
                    for (final u in _results)
                      _Row(user: u, trailing: _trailingFor(u)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FindHint extends StatelessWidget {
  const _FindHint({required this.searched});
  final bool searched;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          searched ? l.friendsNoOneFound : l.friendsSearchPrompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.c.inkFaint,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Muted, non-pressable trailing label for a search result (e.g. an existing
/// friend or an already-sent request).
class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.c.inkFaint,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// A 72px friend/search row: avatar · handle (+ optional subtitle) · trailing,
/// with a hairline divider inset to the text.
class _Row extends StatelessWidget {
  const _Row({required this.user, this.subtitle, this.trailing, this.onTap});

  final UserSummary user;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.surface,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _ListAvatar(user: user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.c.ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          subtitle!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[SizedBox(width: 8), trailing!],
                ],
              ),
            ),
            // Hairline divider, inset to start under the handle (avatar width).
            Divider(
              height: 1,
              thickness: 1,
              indent: 72,
              endIndent: 16,
              color: context.c.hairline,
            ),
          ],
        ),
      ),
    );
  }
}

/// The 44px avatar used by friend rows and request cards.
class _ListAvatar extends StatelessWidget {
  const _ListAvatar({required this.user});
  final UserSummary user;

  @override
  Widget build(BuildContext context) => UserAvatar(
    name: user.username,
    url: user.avatarUrl,
    radius: 22,
    fontSize: 17,
  );
}

/// The passport strip: up to three country flags, then a count summary.
class _PassportStrip extends StatelessWidget {
  const _PassportStrip({required this.codes});
  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (codes.isEmpty) {
      return Text(
        l.friendsNoPlaces,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.c.inkFaint,
        ),
      );
    }
    final shown = codes.take(3).toList();
    final total = codes.length;
    final suffix = total <= 3
        ? l.friendsCountries(total)
        : l.friendsCountriesMore(total - 3);
    return Row(
      children: [
        for (final c in shown)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(
                'assets/flags/$c.png',
                height: 15,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        const SizedBox(width: 2),
        Text(
          suffix,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.c.inkFaint,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase, letter-spaced section header (e.g. "5 FRIENDS").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.c.inkFaint,
        ),
      ),
    );
  }
}

/// Red swipe background revealed behind a friend row (swipe to remove).
class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.c.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_remove_outlined,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).friendsRemove,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, required this.onRefresh});
  final String text;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Stack(
        children: [
          ListView(), // keep the pull-to-refresh gesture alive
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.c.inkFaint,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Find screen
// ---------------------------------------------------------------------------

/// Rounded-square search button beside the segmented control; opens Find.
class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.c.fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.search, color: context.c.inkMuted),
      ),
    );
  }
}

/// Find people by username, on its own pushed screen.
class _FindScreen extends StatelessWidget {
  const _FindScreen({required this.repo, required this.friendIds});
  final FriendsRepository repo;
  final Set<String> friendIds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).friendsFindTitle),
      ),
      body: SafeArea(
        child: _FindTab(repo: repo, friendIds: friendIds),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent (last 24h): every friend's posts on one merged map + a "Just in" strip
// ---------------------------------------------------------------------------

class _RecentPanel extends StatefulWidget {
  const _RecentPanel({super.key, required this.onPhotosSelected});

  /// Reports a tapped photo / cluster up to [FriendsView], which renders the
  /// sheet above its header (rendering it here put it under the header).
  final void Function(List<FeedPoint>) onPhotosSelected;

  @override
  State<_RecentPanel> createState() => _RecentPanelState();
}

class _RecentPanelState extends State<_RecentPanel> {
  // One feed shared by the map and the strip (it caches the fetch).
  final RecentMapFeed _feed = RecentMapFeed();
  final GlobalKey<PhotoMapViewState> _mapKey = GlobalKey<PhotoMapViewState>();
  List<RecentPoint>? _recent;

  // The "Last 24h" summary pill flashes briefly on entry, then fades away.
  bool _showPill = false;
  Timer? _pillTimer;

  // The "Just in" strip can be collapsed/expanded by tapping its header.
  bool _stripOpen = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  void _loadRecent() {
    _feed
        .load()
        .then((r) {
          if (!mounted) return;
          setState(() => _recent = r);
          _flashPill();
        })
        .catchError((_) {
          if (mounted) setState(() => _recent = const <RecentPoint>[]);
        });
  }

  /// Refetch the recent feed (called when the Recent tab is reselected): drop
  /// the feed's cache, re-pull the list, and re-cluster the map's markers.
  void reload() {
    _feed.invalidate();
    _loadRecent();
    _mapKey.currentState?.refresh();
  }

  /// Show the summary pill for a moment when the panel first has data, then
  /// fade it out so it doesn't linger over the map.
  void _flashPill() {
    if ((_recent?.length ?? 0) == 0) return;
    setState(() => _showPill = true);
    _pillTimer?.cancel();
    _pillTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showPill = false);
    });
  }

  @override
  void dispose() {
    _pillTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = _recent;
    final posts = recent?.length ?? 0;
    final friends = recent == null
        ? 0
        : recent.map((p) => p.ownerId).toSet().length;
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(
          child: PhotoMapView(
            key: _mapKey,
            feed: _feed,
            emptyText: AppLocalizations.of(context).mapEmptyRecent,
            onPhotosSelected: widget.onPhotosSelected,
          ),
        ),
        if (recent != null && posts > 0)
          Positioned(
            top: topInset + 108, // below the floating segmented header
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showPill ? 1 : 0,
                  duration: Duration(milliseconds: 350),
                  child: _SummaryPill(posts: posts, friends: friends),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 92, // clear the floating Map | Friends pill
          child: _JustInStrip(
            points: _recent,
            open: _stripOpen,
            onToggle: () => setState(() => _stripOpen = !_stripOpen),
            onTap: (p) => widget.onPhotosSelected([p]),
          ),
        ),
      ],
    );
  }
}

/// Floating summary chip over the recent map: "● Last 24h · N posts · M friends".
class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.posts, required this.friends});
  final int posts;
  final int friends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: context.c.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.c.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return Text(
                '${l.recentLast24h} · ${l.recentPostsCount(posts)} · '
                '${l.recentFriendsCount(friends)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The bottom strip of "just in" cards — the same recent posts as the map, as a
/// horizontal scroller of postcard-style cards (photo + place label).
class _JustInStrip extends StatelessWidget {
  const _JustInStrip({
    required this.points,
    required this.open,
    required this.onToggle,
    required this.onTap,
  });
  final List<RecentPoint>? points;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<RecentPoint> onTap;

  @override
  Widget build(BuildContext context) {
    final pts = points;
    if (pts == null || pts.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tap the header to collapse/expand the cards.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).friendsJustIn,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: context.c.ink,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  size: 18,
                  color: context.c.ink,
                ),
              ],
            ),
          ),
        ),
        // Animate the cards open/closed; collapsing leaves just the header.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: open
              ? SizedBox(
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        _JustInCard(point: pts[i], onTap: () => onTap(pts[i])),
                  ),
                )
              : SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _JustInCard extends StatefulWidget {
  const _JustInCard({required this.point, required this.onTap});
  final RecentPoint point;
  final VoidCallback onTap;

  @override
  State<_JustInCard> createState() => _JustInCardState();
}

class _JustInCardState extends State<_JustInCard> {
  final _feed = FeedRepository();
  Uint8List? _bytes;
  PlaceLabel? _label;

  @override
  void initState() {
    super.initState();
    _feed
        .thumbnail(widget.point.imagePath)
        .then((b) {
          if (mounted) setState(() => _bytes = b);
        })
        .catchError((_) {});
    reversePlaceLabel(widget.point.location).then((l) {
      if (mounted) setState(() => _label = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final place = label?.place;
    final country = label?.country;
    final sub = [?place, ?country].join(' · ');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.c.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with flag + time badge.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 92,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _bytes == null
                        ? Container(color: const Color(0xFFE9ECEE))
                        : Image.memory(_bytes!, fit: BoxFit.cover),
                    if (label?.countryCode != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(
                            'assets/flags/${label!.countryCode}.png',
                            height: 16,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC15303B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          formatAgo(
                            AppLocalizations.of(context),
                            widget.point.createdAt,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer: avatar + handle, then place · country.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        name: widget.point.username,
                        url: widget.point.avatarUrl,
                        radius: 11,
                        fontSize: 12,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '@${widget.point.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    sub.isEmpty ? ' ' : sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: context.c.inkFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
