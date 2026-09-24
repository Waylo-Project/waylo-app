import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/feed_repository.dart';
import '../../data/profile_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../friends/friends_screen.dart';
import '../photo/photo_sheet.dart';
import '../post/start_new_post.dart';
import '../settings/settings_screen.dart';
import 'photo_map_view.dart';

/// The home screen: the signed-in user's own map. Chrome is floating only — no
/// app bar, no full tab bar (see DESIGN.md §1/§2): the waylo mark sits top-left,
/// the post (+) and the You button top-right, and a compact `Map | Friends` pill
/// at the bottom swaps the body in place between the map and the friends view.
class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key, required this.profile});

  /// The signed-in user's profile.
  final Profile profile;

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  // Lets the top-right (+) button drive the map view's compose flow.
  final GlobalKey<PhotoMapViewState> _mapKey = GlobalKey<PhotoMapViewState>();

  // 0 = map, 1 = friends. Swapped by the bottom pill (body stays alive).
  int _tab = 0;

  // The tapped photo / cluster, rendered as a sheet ABOVE the chrome so the
  // logo / buttons / pill don't cover it.
  List<FeedPoint>? _sheetPhotos;

  // One-time "tap + to post" coach mark for new sign-ups (armed at sign-up).
  static const _pendingPostGuideKey = 'pending_post_guide';
  bool _showPostGuide = false;

  @override
  void initState() {
    super.initState();
    _maybeShowPostGuide();
  }

  Future<void> _maybeShowPostGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool(_pendingPostGuideKey) ?? false) && mounted) {
      setState(() => _showPostGuide = true);
    }
  }

  Future<void> _dismissPostGuide() async {
    setState(() => _showPostGuide = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPostGuideKey);
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.profile.id;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              PhotoMapView(
                key: _mapKey,
                feed: UserMapFeed(uid),
                // Open the globe facing the user's own location (zoom stays out).
                startAtMyLocation: true,
                // No persistent "no photos" hint on your own map — new users get
                // a one-time post guide instead (see ROADMAP Phase 6).
                onPhotosSelected: (photos) =>
                    setState(() => _sheetPhotos = photos),
              ),
              // Friends view is full-bleed: it handles its own top inset (the
              // header sits below the status bar) and the Recent map runs
              // edge-to-edge behind the floating pill, like the home map.
              const FriendsView(),
            ],
          ),
          // Top chrome (mark · + · You) is map-only; the Friends screen leads
          // with its own segmented control.
          if (_tab == 0) _topChrome(context),
          _bottomPill(),
          // Sheet sits last so it renders over the chrome + pill.
          if (_sheetPhotos != null)
            PhotoSheet(
              key: ValueKey(_sheetPhotos!.first.postId),
              photos: _sheetPhotos!,
              onClose: () => setState(() => _sheetPhotos = null),
              onPostDeleted: () => _mapKey.currentState?.refresh(),
              onPostEdited: () => _mapKey.currentState?.refresh(),
            ),
          // One-time post guide for new sign-ups (map tab only), over everything.
          if (_showPostGuide && _tab == 0)
            _PostGuideCoach(onDismiss: _dismissPostGuide),
        ],
      ),
    );
  }

  /// Mark top-left; post (+) (map tab only) and You top-right. Sits below the
  /// (lowered) scale bar + compass.
  Widget _topChrome(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 72),
        child: Row(
          children: [
            Image.asset('assets/logos/logo2.png', height: 44),
            const Spacer(),
            if (_tab == 0) ...[_addButton(), const SizedBox(width: 8)],
            _youButton(context),
          ],
        ),
      ),
    );
  }

  /// Compact two-segment pill (Map | Friends) — not a full-width tab bar.
  Widget _bottomPill() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 36),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pillSegment(
                label: AppLocalizations.of(context).mapTabMap,
                index: 0,
              ),
              _pillSegment(
                label: AppLocalizations.of(context).friendsSegFriends,
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillSegment({required String label, required int index}) {
    final selected = _tab == index;
    final fg = selected ? context.c.onPrimary : context.c.inkFaint;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? context.c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }

  /// (+) opens an anchored, rounded popup (camera / gallery) under the button —
  /// replaces the old bottom sheet.
  Widget _addButton() {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<PhotoSource>(
      tooltip: l.mapAddPhotoTooltip,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: context.c.surface,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (source) => _mapKey.currentState?.openComposer(source),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: PhotoSource.camera,
          child: _MenuRow(icon: Icons.photo_camera, label: l.settingsTakePhoto),
        ),
        PopupMenuItem(
          value: PhotoSource.gallery,
          child: _MenuRow(
            icon: Icons.photo_library,
            label: l.settingsChooseFromGallery,
          ),
        ),
      ],
      child: _circleVisual(Icons.add),
    );
  }

  /// You opens an anchored, rounded popup (profile, map style, sign out).
  Widget _youButton(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l.mapYou,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: context.c.surface,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v) async {
        if (v == 'settings') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(profile: widget.profile),
            ),
          );
        } else if (v == 'signout') {
          await Supabase.instance.client.auth.signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.profile.username,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Supabase.instance.client.auth.currentUser?.email ?? '',
                style: TextStyle(fontSize: 12, color: context.c.inkFaint),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: _MenuRow(
            icon: Icons.settings_outlined,
            label: l.settingsTitle,
          ),
        ),
        PopupMenuItem<String>(
          value: 'signout',
          child: _MenuRow(icon: Icons.logout, label: l.mapSignOut),
        ),
      ],
      child: _circleVisual(Icons.person),
    );
  }

  Widget _circleVisual(IconData icon) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      color: context.c.surface,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 20, color: context.c.ink),
      ),
    );
  }
}

/// One row inside an anchored popup menu: leading icon + label.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: context.c.inkMuted),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: context.c.ink)),
      ],
    );
  }
}

/// One-time coach mark shown to new sign-ups: a scrim plus a callout pointing at
/// the (+) button. Tapping anywhere dismisses it.
class _PostGuideCoach extends StatelessWidget {
  const _PostGuideCoach({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: ColoredBox(
          color: const Color(0x8A000000),
          child: Stack(
            children: [
              Positioned(
                // Just under the top chrome row (SafeArea + top:72 + button).
                top: topInset + 72 + 52,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Pointer aimed up at the (+) button (2nd icon from right).
                    const Padding(
                      padding: EdgeInsets.only(right: 46),
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.mapGuidePost,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.c.ink,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l.commonGotIt,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.c.checkAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
