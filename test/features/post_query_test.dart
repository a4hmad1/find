import 'package:find/core/domain/post_status.dart';
import 'package:find/core/domain/post_type.dart';
import 'package:find/core/domain/sort_option.dart';
import 'package:find/features/posts/data/local_posts_store.dart';
import 'package:find/features/posts/data/posts_repository.dart';
import 'package:find/shared/models/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

PostModel _post({
  required String id,
  String title = 'ناونیشان',
  String description = 'وەسف',
  PostType postType = PostType.found,
  PostStatus status = PostStatus.approved,
  String city = 'هەولێر',
  String itemType = 'مۆبایل',
  bool urgent = false,
  DateTime? createdAt,
}) {
  return PostModel(
    id: id,
    userId: 'user',
    title: title,
    description: description,
    postType: postType,
    itemType: itemType,
    status: status,
    city: city,
    area: '',
    locationText: '',
    allowContactPublic: false,
    needsVerification: true,
    viewsCount: 0,
    isUrgent: urgent,
    images: const [],
    createdAt: createdAt ?? DateTime(2026, 5, 1),
  );
}

void main() {
  group('PostQuery equality', () {
    test('two identical queries are equal and hash alike', () {
      // This is what makes the Riverpod `family` cache work; without it the
      // search screen would re-issue its query on every rebuild.
      const a = PostQuery(text: 'phone', city: 'هەولێر');
      const b = PostQuery(text: 'phone', city: 'هەولێر');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing criteria are not equal', () {
      const base = PostQuery(text: 'phone');
      expect(base, isNot(const PostQuery(text: 'wallet')));
      expect(base, isNot(base.copyWith(urgentOnly: true)));
      expect(base, isNot(base.copyWith(postType: () => PostType.lost)));
    });

    test('copyWith can clear a nullable field', () {
      // The `() => null` wrapper is what distinguishes "clear this" from
      // "leave it alone"; a plain null argument could not express the former.
      const withType = PostQuery(postType: PostType.lost);
      expect(withType.copyWith(postType: () => null).postType, isNull);
      expect(withType.copyWith(text: 'x').postType, PostType.lost);
    });
  });

  group('hasActiveFilters', () {
    test('is false for a bare text search', () {
      expect(const PostQuery(text: 'phone').hasActiveFilters, isFalse);
      expect(const PostQuery().hasActiveFilters, isFalse);
    });

    test('is true once any criterion narrows the results', () {
      expect(const PostQuery(urgentOnly: true).hasActiveFilters, isTrue);
      expect(const PostQuery(city: 'هەولێر').hasActiveFilters, isTrue);
      expect(const PostQuery(postType: PostType.lost).hasActiveFilters, isTrue);
      expect(PostQuery(date: DateTime(2026, 5, 1)).hasActiveFilters, isTrue);
    });

    test('ignores empty-string criteria', () {
      expect(const PostQuery(city: '', itemType: '').hasActiveFilters, isFalse);
    });
  });

  group('searchLocalPosts', () {
    final posts = [
      _post(
        id: 'a',
        title: 'مۆبایلی ڕەش',
        city: 'هەولێر',
        createdAt: DateTime(2026, 5, 3),
      ),
      _post(
        id: 'b',
        title: 'جانتای قاوەیی',
        postType: PostType.lost,
        city: 'سلێمانی',
        itemType: 'جانتا',
        urgent: true,
        createdAt: DateTime(2026, 5, 1),
      ),
      _post(
        id: 'c',
        title: 'کلیل',
        status: PostStatus.returned,
        itemType: 'کلیل',
        createdAt: DateTime(2026, 5, 2),
      ),
    ];

    List<String> idsFor(PostQuery query) =>
        searchLocalPosts(posts, query).map((post) => post.id).toList();

    test('returns everything, newest first, for an empty query', () {
      expect(idsFor(const PostQuery()), ['a', 'c', 'b']);
    });

    test('oldest reverses the order', () {
      expect(idsFor(const PostQuery(sort: SortOption.oldest)), ['b', 'c', 'a']);
    });

    test('mostUrgent floats urgent posts above newer ones', () {
      // `b` is the oldest post but the only urgent one.
      expect(idsFor(const PostQuery(sort: SortOption.mostUrgent)).first, 'b');
    });

    test('nearest falls back to recency rather than an arbitrary order', () {
      // There is no geo index yet, so this must behave like `newest` instead of
      // silently returning whatever order the list happened to be in.
      expect(
        idsFor(const PostQuery(sort: SortOption.nearest)),
        idsFor(const PostQuery(sort: SortOption.newest)),
      );
    });

    test('matches text against title, city, and item type', () {
      expect(idsFor(const PostQuery(text: 'جانتا')), ['b']);
      expect(idsFor(const PostQuery(text: 'سلێمانی')), ['b']);
    });

    test('filters by city, type, status, and urgency', () {
      expect(idsFor(const PostQuery(city: 'سلێمانی')), ['b']);
      expect(idsFor(const PostQuery(postType: PostType.lost)), ['b']);
      expect(idsFor(const PostQuery(status: PostStatus.returned)), ['c']);
      expect(idsFor(const PostQuery(urgentOnly: true)), ['b']);
    });

    test('combines criteria conjunctively', () {
      expect(
        idsFor(const PostQuery(city: 'هەولێر', postType: PostType.lost)),
        isEmpty,
      );
    });
  });

  group('localPostStats', () {
    test('counts only publicly visible posts, by type and status', () {
      final stats = localPostStats([
        _post(id: 'a'),
        _post(id: 'b', postType: PostType.lost),
        _post(id: 'c', status: PostStatus.returned),
        // Pending and rejected posts are not public, so they are not counted.
        _post(id: 'd', status: PostStatus.pending),
        _post(id: 'e', status: PostStatus.rejected),
      ]);

      expect(stats[PostStatKey.all], 3);
      expect(stats[PostStatKey.found], 2);
      expect(stats[PostStatKey.lost], 1);
      expect(stats[PostStatKey.returned], 1);
    });
  });
}
