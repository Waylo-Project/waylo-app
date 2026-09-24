import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/data/feed_repository.dart';

Comment _c(String id, {String? parent, int minute = 0}) => Comment(
  id: id,
  userId: 'u',
  username: 'u',
  body: id,
  createdAt: DateTime(2026, 1, 1, 0, minute),
  parentId: parent,
);

void main() {
  test('threadComments groups replies under their parent, in order', () {
    final threads = FeedRepository.threadComments([
      _c('a', minute: 0),
      _c('b', minute: 1),
      _c('a1', parent: 'a', minute: 2),
      _c('b1', parent: 'b', minute: 3),
      _c('a2', parent: 'a', minute: 4),
    ]);
    expect([for (final t in threads) t.comment.id], ['a', 'b']);
    expect([for (final r in threads[0].replies) r.id], ['a1', 'a2']);
    expect([for (final r in threads[1].replies) r.id], ['b1']);
  });

  test('threadComments drops replies whose parent is gone', () {
    final threads = FeedRepository.threadComments([
      _c('a'),
      _c('x1', parent: 'deleted'),
    ]);
    expect(threads, hasLength(1));
    expect(threads.single.replies, isEmpty);
  });

  test('thumbPathFor derives the marker thumbnail next to the original', () {
    expect(thumbPathFor('uid/group/0.jpg'), 'uid/group/0_thumb.jpg');
    // Only the trailing extension changes.
    expect(thumbPathFor('uid/a.jpg.dir/0.jpg'), 'uid/a.jpg.dir/0_thumb.jpg');
  });
}
