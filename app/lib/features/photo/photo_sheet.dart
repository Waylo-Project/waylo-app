import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../../core/date_format.dart';
import '../../core/error_dialog.dart';
import '../../core/lat_lng.dart';
import '../../data/feed_repository.dart';
import '../../data/geocoding.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../post/post_details_screen.dart';

/// A draggable, non-modal sheet for a tapped photo / photo cluster. Photo-first:
/// the photo dominates; below it the place (with the country flag as a
/// "passport stamp"), the date, the caption, then social — likes (a reactor
/// cluster + a quiet outline pill, NOT an Instagram action bar) and guestbook
/// comments, with a composer pinned to the foot of the sheet. Your own posts get
/// a ••• menu (edit caption / delete). Drag the handle up to expand toward full,
/// down to dismiss. Clusters are a horizontal swipe with page dots.
class PhotoSheet extends StatefulWidget {
  const PhotoSheet({
    super.key,
    required this.photos,
    required this.onClose,
    this.onPostDeleted,
    this.onPostEdited,
  });

  /// The photos at the tapped marker (one, or all in a screen cluster).
  final List<FeedPoint> photos;
  final VoidCallback onClose;

  /// Called after a post is deleted, so the host can refresh its markers.
  final VoidCallback? onPostDeleted;

  /// Called after a post is edited (its location may have moved), so the host
  /// can refresh its markers.
  final VoidCallback? onPostEdited;

  @override
  State<PhotoSheet> createState() => _PhotoSheetState();
}

class _PhotoSheetState extends State<PhotoSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  final _pageController = PageController();
  int _index = 0;

  // One key per post so the foot composer can post into the visible card.
  late final List<GlobalKey<_PhotoCardState>> _cardKeys = [
    for (final _ in widget.photos) GlobalKey<_PhotoCardState>(),
  ];

  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();
  bool _sending = false;

  // The comment being replied to (null = a new top-level comment). Belongs to
  // the currently visible card; cleared when the page changes or after sending.
  Comment? _replyTarget;

  // Sheet height as a fraction of the screen; dragged between collapsed and
  // (near) full. The old sheet was fixed-height and couldn't be pulled up.
  static const double _collapsed = 0.6;
  static const double _expanded = 0.92;
  static const double _dismissBelow = 0.45;
  double _frac = _collapsed;

  @override
  void initState() {
    super.initState();
    // Focusing the composer needs the room: expand the sheet so the comment
    // list and the field both stay visible above the keyboard.
    _commentFocus.addListener(() {
      if (_commentFocus.hasFocus && _frac < _expanded) {
        setState(() => _frac = _expanded);
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _pageController.dispose();
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _anim.reverse();
    widget.onClose();
  }

  void _onHandleDrag(DragUpdateDetails d, double screenH) {
    setState(() {
      _frac = (_frac - d.primaryDelta! / screenH).clamp(0.3, 0.94);
    });
  }

  void _onHandleDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v > 700 || _frac < _dismissBelow) {
      _dismiss();
      return;
    }
    setState(() => _frac = _frac < 0.72 ? _collapsed : _expanded);
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final replyTo = _replyTarget;
    setState(() => _sending = true);
    try {
      await _cardKeys[_index].currentState?.submitComment(text, replyTo: replyTo);
      _commentCtrl.clear();
      if (mounted) setState(() => _replyTarget = null);
    } catch (e) {
      if (mounted) {
        showErrorDialog(
            context, AppLocalizations.of(context).photoCouldNotPostComment('$e'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Aim the composer at [c] (a reply). Focuses the field and shows a banner.
  void _startReply(Comment c) {
    setState(() => _replyTarget = c);
    _commentFocus.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTarget = null);

  void _onDeleted() {
    widget.onPostDeleted?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final multiple = widget.photos.length > 1;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: Material(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          elevation: 12,
          child: SizedBox(
            height: screenH * _frac,
            child: Column(
              children: [
                // Drag handle: pull up to expand, down (or fling) to dismiss.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) => _onHandleDrag(d, screenH),
                  onVerticalDragEnd: _onHandleDragEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.c.chevron,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (multiple) ...[
                          const SizedBox(height: 10),
                          widget.photos.length <= 6 ? _dots() : _counter(),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: (i) => setState(() {
                      _index = i;
                      _replyTarget = null;
                    }),
                    itemBuilder: (_, i) => _PhotoCard(
                      key: _cardKeys[i],
                      photo: widget.photos[i],
                      onDeleted: _onDeleted,
                      onEdited: widget.onPostEdited,
                      onReply: _startReply,
                    ),
                  ),
                ),
                _Composer(
                  controller: _commentCtrl,
                  focusNode: _commentFocus,
                  sending: _sending,
                  bottomInset: keyboard,
                  onSubmit: _submitComment,
                  replyTo: _replyTarget,
                  onCancelReply: _cancelReply,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.photos.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _index ? context.c.primary : Colors.black26,
            ),
          ),
      ],
    );
  }

  Widget _counter() {
    return Text(
      '${_index + 1} / ${widget.photos.length}',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.c.inkMuted,
      ),
    );
  }
}

/// One post page: its photo(s), place + flag stamp, author·date, caption, then
/// likes and comments.
class _PhotoCard extends StatefulWidget {
  const _PhotoCard({
    super.key,
    required this.photo,
    required this.onDeleted,
    required this.onEdited,
    required this.onReply,
  });

  final FeedPoint photo;
  final VoidCallback onDeleted;

  /// Called after this post is edited, so the host map can refresh its markers.
  final VoidCallback? onEdited;

  /// Ask the sheet to aim its composer at [comment] as a reply.
  final void Function(Comment comment) onReply;

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard>
    with AutomaticKeepAliveClientMixin {
  final _feed = FeedRepository();

  List<String>? _photoUrls; // signed URLs for all photos of this post
  // The real aspect ratio of the (first) photo, so the detail view shows the
  // crop the user actually made instead of forcing a fixed 4:5 box. Null until
  // the image resolves; clamped to a sane range so an extreme crop can't break
  // the sheet layout.
  double? _aspect;
  String? _place;
  String? _countryCode;
  PostDetail? _detail;
  // The post's location, mutable so an edit can move the pin and re-geocode the
  // place/flag in place without reopening the sheet.
  late LatLng _location = widget.photo.location;
  LikeSummary _likes = LikeSummary.empty;
  List<Comment>? _comments;
  final _innerPage = PageController();
  int _photoIndex = 0;

  String get _postId => widget.photo.postId;
  bool get _isOwn =>
      Supabase.instance.client.auth.currentUser?.id == widget.photo.ownerId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _innerPage.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loc = _location;
    reversePlaceName(loc).then((p) {
      if (mounted) setState(() => _place = p);
    });
    reverseCountryCode(loc).then((c) {
      if (mounted) setState(() => _countryCode = c);
    });
    _feed.postDetail(_postId).then((d) {
      if (mounted) setState(() => _detail = d);
    });
    _feed.likeSummary(_postId).then((s) {
      if (mounted) setState(() => _likes = s);
    });
    _feed.comments(_postId).then((c) {
      if (mounted) setState(() => _comments = c);
    });

    // Resolve every photo of the post to a signed URL (a post may hold several).
    try {
      final paths = await _feed.postPhotos(_postId);
      final list = paths.isEmpty ? [widget.photo.imagePath] : paths;
      final urls = await Future.wait(list.map(_feed.signedUrl));
      if (mounted) setState(() => _photoUrls = urls);
      if (urls.isNotEmpty) _resolveAspect(urls.first);
    } catch (_) {
      // Fall back to the marker's single image path.
      try {
        final u = await _feed.signedUrl(widget.photo.imagePath);
        if (mounted) setState(() => _photoUrls = [u]);
        _resolveAspect(u);
      } catch (_) {
        if (mounted) setState(() => _photoUrls = const []);
      }
    }
  }

  /// Resolve the photo's intrinsic dimensions and size the stage to its real
  /// aspect ratio (so a square/landscape crop isn't squeezed into a 4:5 box).
  void _resolveAspect(String url) {
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (mounted && h > 0) {
        setState(() => _aspect = (w / h).clamp(0.6, 1.91));
      }
      stream.removeListener(listener);
    }, onError: (_, _) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  /// Called by the sheet composer to add a comment to this post, or a reply
  /// when [replyTo] is set. One-level threading: a reply always attaches to the
  /// top-level parent (replying to a reply threads under the same parent).
  Future<void> submitComment(String body, {Comment? replyTo}) async {
    final parentId = replyTo == null ? null : (replyTo.parentId ?? replyTo.id);
    final c = await _feed.addComment(_postId, body, parentId: parentId);
    if (mounted) setState(() => _comments = [...?_comments, c]);
  }

  Future<void> _toggleLike() async {
    final next = !_likes.likedByMe;
    setState(() => _likes = LikeSummary(
          count: _likes.count + (next ? 1 : -1),
          likedByMe: next,
          topLikers: _likes.topLikers,
        ));
    try {
      await _feed.setLike(_postId, next);
      final fresh = await _feed.likeSummary(_postId);
      if (mounted) setState(() => _likes = fresh);
    } catch (_) {
      // Revert on failure.
      if (mounted) {
        setState(() => _likes = LikeSummary(
              count: _likes.count + (next ? -1 : 1),
              likedByMe: !next,
              topLikers: _likes.topLikers,
            ));
      }
    }
  }

  Future<void> _deleteComment(Comment c) async {
    setState(() =>
        _comments = [for (final x in _comments ?? <Comment>[]) if (x.id != c.id) x]);
    try {
      await _feed.deleteComment(c.id);
    } catch (e) {
      if (mounted) {
        setState(() => _comments = [...?_comments, c]);
        showErrorDialog(
            context, AppLocalizations.of(context).photoCouldNotDelete('$e'));
      }
    }
  }

  /// Edit the whole post (location, date, caption) on the reusable post-details
  /// screen. On save it returns the new values, which we apply to the card in
  /// place (re-geocoding the moved pin) and report up so the map refreshes.
  Future<void> _editPost() async {
    final l = AppLocalizations.of(context);
    // Show the existing photo on the edit screen.
    final urls = _photoUrls;
    final ImageProvider image;
    if (urls != null && urls.isNotEmpty) {
      image = NetworkImage(urls.first);
    } else {
      try {
        image = NetworkImage(await _feed.signedUrl(widget.photo.imagePath));
      } catch (e) {
        if (mounted) showErrorDialog(context, l.photoCouldNotSave('$e'));
        return;
      }
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<EditPostResult>(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen.edit(
          editPostId: _postId,
          photoImage: image,
          initialLocation: _location,
          takenAt: _detail?.takenAt,
          initialCaption: _detail?.caption,
          initialPlaceLabel: _detail?.placeLabel,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _location = result.location;
      _detail = PostDetail(
        username: _detail?.username,
        caption: result.caption,
        takenAt: result.takenAt,
        avatarUrl: _detail?.avatarUrl,
        placeLabel: result.placeLabel,
      );
      // Clear the derived place/flag; re-geocode the new location below.
      _place = null;
      _countryCode = null;
    });
    reversePlaceName(_location).then((p) {
      if (mounted) setState(() => _place = p);
    });
    reverseCountryCode(_location).then((c) {
      if (mounted) setState(() => _countryCode = c);
    });
    widget.onEdited?.call();
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.photoDeleteTitle),
        content: Text(l.photoDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.c.danger),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _feed.deletePost(_postId);
      widget.onDeleted();
    } catch (e) {
      if (mounted) {
        showErrorDialog(
            context, AppLocalizations.of(context).photoCouldNotDelete('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final when = _detail?.takenAt;
    final meta = [
      if (!_isOwn && _detail?.username != null) '@${_detail!.username}',
      if (when != null) formatPhotoDate(context, when),
    ].join('  ·  ');
    final caption = _detail?.caption;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoStage(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_countryCode != null) ...[
                _FlagStamp(countryCode: _countryCode!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  // The poster's own name wins over the geocoded one.
                  _detail?.placeLabel ??
                      _place ??
                      AppLocalizations.of(context).photoSomewhere,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: context.c.ink,
                  ),
                ),
              ),
              if (_isOwn) _ownMenu(),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: TextStyle(fontSize: 13, color: context.c.inkFaint),
            ),
          ],
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.c.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _likesRow(),
          const SizedBox(height: 18),
          _commentsSection(),
        ],
      ),
    );
  }

  // ---- Photo stage --------------------------------------------------------

  /// Instagram-style pinch-to-zoom: two fingers lift the photo into an overlay
  /// and scale it in place; releasing animates it back. `twoTouchOnly` keeps a
  /// single-finger swipe/scroll flowing to the surrounding PageViews and sheet.
  Widget _zoomable(Widget child) {
    return ZoomOverlay(
      twoTouchOnly: true,
      minScale: 1.0,
      maxScale: 4.0,
      animationDuration: const Duration(milliseconds: 220),
      animationCurve: Curves.easeOut,
      modalBarrierColor: Colors.black.withValues(alpha: 0.5),
      child: child,
    );
  }

  Widget _photoStage() {
    final urls = _photoUrls;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: _aspect ?? 4 / 5,
        child: urls == null
            ? const _PhotoLoading()
            : urls.isEmpty
                ? const _PhotoError()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      urls.length == 1
                          ? _zoomable(_PhotoImage(url: urls.first))
                          : PageView.builder(
                              controller: _innerPage,
                              itemCount: urls.length,
                              onPageChanged: (i) =>
                                  setState(() => _photoIndex = i),
                              itemBuilder: (_, i) =>
                                  _zoomable(_PhotoImage(url: urls[i])),
                            ),
                      if (urls.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < urls.length; i++)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _photoIndex
                                        ? Colors.white
                                        : Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _ownMenu() {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l.settingsEdit,
      icon: Icon(Icons.more_horiz, color: context.c.inkFaint),
      position: PopupMenuPosition.under,
      color: context.c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'edit') _editPost();
        if (v == 'delete') _confirmDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 19, color: context.c.ink),
            const SizedBox(width: 10),
            Text(l.photoEditPost),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 19, color: context.c.danger),
            const SizedBox(width: 10),
            Text(l.photoDeletePost, style: TextStyle(color: context.c.danger)),
          ]),
        ),
      ],
    );
  }

  // ---- Likes --------------------------------------------------------------

  Widget _likesRow() {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        if (_likes.count > 0) ...[
          _ReactorCluster(likers: _likes.topLikers),
          const SizedBox(width: 8),
          Text(
            l.photoLikesCount(_likes.count),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.c.inkMuted,
            ),
          ),
        ] else
          Text(
            l.photoNoLikes,
            style: TextStyle(fontSize: 13, color: context.c.inkFaint),
          ),
        const Spacer(),
        _LikePill(liked: _likes.likedByMe, onTap: _toggleLike),
      ],
    );
  }

  // ---- Comments -----------------------------------------------------------

  Widget _commentsSection() {
    final l = AppLocalizations.of(context);
    final comments = _comments;
    final myId = Supabase.instance.client.auth.currentUser?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comments == null
              ? l.photoComments
              : l.photoCommentsCount(comments.length),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.c.inkFaint,
          ),
        ),
        const SizedBox(height: 12),
        if (comments == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (comments.isEmpty)
          Text(
            l.photoNoComments,
            style: TextStyle(fontSize: 13.5, color: context.c.inkFaint),
          )
        else
          for (final t in FeedRepository.threadComments(comments)) ...[
            _CommentBubble(
              comment: t.comment,
              // Author can delete their own; the post owner can delete any.
              canDelete: t.comment.userId == myId || _isOwn,
              onDelete: () => _deleteComment(t.comment),
              onReply: () => widget.onReply(t.comment),
            ),
            // One level of replies, indented to sit under the parent's text.
            for (final r in t.replies)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _CommentBubble(
                  comment: r,
                  canDelete: r.userId == myId || _isOwn,
                  onDelete: () => _deleteComment(r),
                  onReply: () => widget.onReply(r),
                  isReply: true,
                ),
              ),
          ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const _PhotoLoading(),
      errorBuilder: (_, _, _) => const _PhotoError(),
    );
  }
}

class _PhotoLoading extends StatelessWidget {
  const _PhotoLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.c.fill,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.c.fill,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined,
              color: context.c.inkFaint, size: 26),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).photoCouldNotLoad,
            style: TextStyle(fontSize: 12, color: context.c.inkFaint),
          ),
        ],
      ),
    );
  }
}

/// The country flag shown like a passport stamp next to the place name — a real
/// flag asset (clean graphic), not a fake rubber stamp.
class _FlagStamp extends StatelessWidget {
  const _FlagStamp({required this.countryCode});
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Image.asset(
        'assets/flags/$countryCode.png',
        height: 22,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Overlapping liker avatars (the "reactor cluster").
class _ReactorCluster extends StatelessWidget {
  const _ReactorCluster({required this.likers});
  final List<Liker> likers;

  @override
  Widget build(BuildContext context) {
    if (likers.isEmpty) return const SizedBox.shrink();
    const d = 24.0;
    final width = d + (likers.length - 1) * (d - 8);
    return SizedBox(
      width: width,
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < likers.length; i++)
            Positioned(
              left: i * (d - 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.c.surface,
                ),
                padding: const EdgeInsets.all(1.5),
                child: _MiniAvatar(
                  url: likers[i].avatarUrl,
                  name: likers[i].username,
                  radius: d / 2 - 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quiet outline pill that toggles your like — deliberately not a heart-shaped
/// Instagram action.
class _LikePill extends StatelessWidget {
  const _LikePill({required this.liked, required this.onTap});
  final bool liked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: liked ? context.c.primary.withValues(alpha: 0.25) : context.c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: liked ? context.c.primary : context.c.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: liked ? const Color(0xFF2C7E9B) : context.c.inkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              liked
                  ? AppLocalizations.of(context).photoLiked
                  : AppLocalizations.of(context).photoLike,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: liked ? const Color(0xFF2C7E9B) : context.c.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A guestbook comment: avatar + name · time + soft bubble, with an optional
/// delete on long-press for comments you may remove.
class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
    this.onReply,
    this.isReply = false,
  });
  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback? onReply;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniAvatar(
            url: comment.avatarUrl,
            name: comment.username,
            radius: isReply ? 12 : 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${comment.username}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.c.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _ago(AppLocalizations.of(context), comment.createdAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.c.inkFaint,
                      ),
                    ),
                    if (canDelete) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(Icons.close,
                            size: 15, color: context.c.inkFaint),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: context.c.fill,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    comment.body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: context.c.inkMuted,
                    ),
                  ),
                ),
                if (onReply != null) ...[
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: onReply,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        AppLocalizations.of(context).photoReply,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.c.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The comment composer pinned to the foot of the sheet. Lifts above the
/// keyboard via [bottomInset].
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.bottomInset,
    required this.onSubmit,
    this.replyTo,
    this.onCancelReply,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final double bottomInset;
  final VoidCallback onSubmit;
  final Comment? replyTo;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final replyTo = this.replyTo;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTo != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .photoReplyingTo(replyTo.username),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.c.inkFaint,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 16, color: context.c.inkFaint),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                minLines: 1,
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: context.c.ink),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).photoAddComment,
                  hintStyle: TextStyle(color: context.c.inkFaint),
                  filled: true,
                  fillColor: context.c.fill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSubmit,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.c.primary,
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.c.onPrimary,
                        ),
                      )
                    : Icon(Icons.arrow_forward,
                        size: 20, color: context.c.onPrimary),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small round avatar: the network image if present, else a tinted initial.
class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.url, required this.name, this.radius = 15});
  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.c.primary.withValues(alpha: 0.25),
      foregroundImage: url != null ? NetworkImage(url!) : null,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: context.c.ink,
        ),
      ),
    );
  }
}

String _ago(AppLocalizations l, DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.timeNow;
  if (d.inMinutes < 60) return l.timeMinutesShort(d.inMinutes);
  if (d.inHours < 24) return l.timeHoursShort(d.inHours);
  if (d.inDays < 7) return l.timeDaysShort(d.inDays);
  return l.timeWeeksShort((d.inDays / 7).floor());
}
