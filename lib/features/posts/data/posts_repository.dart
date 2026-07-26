import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/domain/notification_type.dart';
import '../../../core/domain/post_status.dart';
import '../../../core/domain/post_type.dart';
import '../../../core/domain/sort_option.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/json.dart';
import '../../../core/utils/postgrest_filter.dart' as filters;
import '../../../shared/models/post_model.dart';

/// Criteria for a post search.
///
/// Bundling these into a value type keeps [PostsRepository.search] from taking
/// eight loosely-related optional parameters, and lets the search screen hold
/// one immutable object instead of eight fields that can drift out of sync.
class PostQuery {
  const PostQuery({
    this.text = '',
    this.city,
    this.postType,
    this.status,
    this.itemType,
    this.date,
    this.sort = SortOption.newest,
    this.urgentOnly = false,
  });

  final String text;
  final String? city;
  final PostType? postType;
  final PostStatus? status;
  final String? itemType;
  final DateTime? date;
  final SortOption sort;
  final bool urgentOnly;

  String get trimmedText => text.trim();
  bool get hasText => trimmedText.isNotEmpty;

  /// Whether anything beyond the free-text term is narrowing the results.
  ///
  /// Drives the "filters applied" affordance, so an empty result set reads as
  /// "your filters are too narrow" rather than "search is broken".
  bool get hasActiveFilters =>
      postType != null ||
      status != null ||
      date != null ||
      urgentOnly ||
      (city?.isNotEmpty ?? false) ||
      (itemType?.isNotEmpty ?? false);

  PostQuery copyWith({
    String? text,
    String? Function()? city,
    PostType? Function()? postType,
    PostStatus? Function()? status,
    String? Function()? itemType,
    DateTime? Function()? date,
    SortOption? sort,
    bool? urgentOnly,
  }) {
    return PostQuery(
      text: text ?? this.text,
      city: city == null ? this.city : city(),
      postType: postType == null ? this.postType : postType(),
      status: status == null ? this.status : status(),
      itemType: itemType == null ? this.itemType : itemType(),
      date: date == null ? this.date : date(),
      sort: sort ?? this.sort,
      urgentOnly: urgentOnly ?? this.urgentOnly,
    );
  }

  // Value equality matters here: this type is the key of a Riverpod `family`,
  // and without it every rebuild would allocate a distinct key, defeating the
  // cache and re-issuing the query on each frame.
  @override
  bool operator ==(Object other) {
    return other is PostQuery &&
        other.text == text &&
        other.city == city &&
        other.postType == postType &&
        other.status == status &&
        other.itemType == itemType &&
        other.date == date &&
        other.sort == sort &&
        other.urgentOnly == urgentOnly;
  }

  @override
  int get hashCode => Object.hash(
    text,
    city,
    postType,
    status,
    itemType,
    date,
    sort,
    urgentOnly,
  );
}

class PostsRepository {
  PostsRepository(this._client, this._images, this._profiles);

  final SupabaseClient _client;
  final ImageUploadService _images;
  final ProfileGuard _profiles;

  /// Signed-out visitors cannot read the `profiles` relation under RLS, so the
  /// join is only requested when there is a session to authorise it.
  String get _postSelect => _client.auth.currentUser == null
      ? DbSelects.postWithImages
      : DbSelects.postWithImagesAndProfile;

  Future<List<PostModel>> recent({int limit = AppLimits.recentPostsPageSize}) {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.posts)
          .select(_postSelect)
          .eq('status', PostStatus.approved.wire)
          .order('created_at', ascending: false)
          .limit(limit);
      return _parsePosts(rows);
    });
  }

  Future<List<PostModel>> urgent({int limit = AppLimits.urgentPostsPageSize}) {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.posts)
          .select(_postSelect)
          .eq('status', PostStatus.approved.wire)
          .eq('is_urgent', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return _parsePosts(rows);
    });
  }

  Future<PostModel> byId(String id) {
    return guardFailures(() async {
      // View counting is best-effort: a failure here (rate limit, RLS, missing
      // function) must not stop the post from being read.
      try {
        await _client.rpc<void>(
          'increment_post_views',
          params: {'post_id_input': id},
        );
      } on Object {
        // Intentionally ignored — see above.
      }
      final row = await _client
          .from(DbTables.posts)
          .select(_postSelect)
          .eq('id', id)
          .single();
      return PostModel.fromJson(row);
    });
  }

  Future<Map<PostStatKey, int>> stats() {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.posts)
          .select('post_type,status')
          .inFilter(
            'status',
            PostStatus.publiclyVisible.map((status) => status.wire).toList(),
          );
      final posts = rows.cast<Map<String, dynamic>>();
      return {
        PostStatKey.all: posts.length,
        PostStatKey.found: posts
            .where((row) => row['post_type'] == PostType.found.wire)
            .length,
        PostStatKey.lost: posts
            .where((row) => row['post_type'] == PostType.lost.wire)
            .length,
        PostStatKey.returned: posts
            .where((row) => row['status'] == PostStatus.returned.wire)
            .length,
      };
    });
  }

  Future<List<PostModel>> search(PostQuery query) {
    return guardFailures(() async {
      // The builder is re-assigned as filters are applied, so it is typed as
      // the shared `PostgrestFilterBuilder` rather than the narrower type each
      // individual call returns.
      var request = _client.from(DbTables.posts).select(_postSelect);

      if (query.status case final status?) {
        request = request.eq('status', status.wire);
      } else {
        // Default view: everything a visitor is allowed to browse, excluding
        // posts still awaiting moderation.
        request = request.inFilter('status', const ['approved', 'returned']);
      }

      if (query.hasText) {
        // User text is quoted and its LIKE wildcards escaped before it reaches
        // the `or` filter — interpolating it raw would let a query like
        // `x,status.eq.pending` append its own condition and escape the status
        // restriction applied above.
        final pattern = filters.containsPattern(query.trimmedText);
        request = request.or(
          filters.or(['title.ilike.$pattern', 'description.ilike.$pattern']),
        );
      }
      if (query.city case final city? when city.isNotEmpty) {
        request = request.eq('city', city);
      }
      if (query.postType case final postType?) {
        request = request.eq('post_type', postType.wire);
      }
      if (query.itemType case final itemType? when itemType.isNotEmpty) {
        request = request.eq('item_type', itemType);
      }
      if (query.date case final date?) {
        request = request.eq('event_date', date.toDateOnlyString());
      }
      if (query.urgentOnly) {
        request = request.eq('is_urgent', true);
      }

      final ordered = switch (query.sort) {
        SortOption.oldest => request.order('created_at', ascending: true),
        SortOption.mostUrgent =>
          request
              .order('is_urgent', ascending: false)
              .order('created_at', ascending: false),
        // `nearest` has no geo index yet, so it falls back to recency rather
        // than silently returning an arbitrary order.
        SortOption.nearest ||
        SortOption.newest => request.order('created_at', ascending: false),
      };

      final rows = await ordered.limit(AppLimits.searchPageSize);
      return _parsePosts(rows);
    });
  }

  /// Posts of the opposite type in the same city and category — the candidates
  /// shown to someone who just reported a lost or found item.
  Future<List<PostModel>> similarFor(CreatePostInput input) {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.posts)
          .select(_postSelect)
          .eq('status', PostStatus.approved.wire)
          .eq('city', input.city)
          .eq('item_type', input.itemType)
          .eq('post_type', input.postType.opposite.wire)
          .order('created_at', ascending: false)
          .limit(AppLimits.similarMatchesPageSize);
      return _parsePosts(rows);
    });
  }

  Future<PostModel> createPost(CreatePostInput input, List<XFile> files) {
    return guardFailures(() async {
      if (files.isEmpty) {
        throw const ValidationFailure('تکایە لانیکەم یەک وێنە زیاد بکە');
      }
      if (files.length > AppLimits.maxPostImages) {
        throw const ValidationFailure('تەنها ٥ وێنە ڕێگەپێدراوە');
      }

      final profile = await _profiles.require();
      await _assertDailyQuota(profile.id);

      final inserted = await _client
          .from(DbTables.posts)
          .insert(input.toInsertJson(profile.id))
          .select()
          .single();
      final postId = PostModel.fromJson(inserted).id;

      // Postgres has no transaction spanning these calls, so a failure part-way
      // through would previously leave a post with a partial image set and
      // orphaned objects in storage. Roll the whole thing back by hand instead.
      try {
        await _attachImages(postId: postId, files: files);
      } on Object {
        await _rollbackPost(postId);
        rethrow;
      }

      final post = await byId(postId);
      await _notifyOfSimilarPosts(input: input, profileId: profile.id);
      return post;
    });
  }

  /// Uploads each image and records it against the post.
  ///
  /// Uploads run concurrently — sequential awaits made creating a five-image
  /// post take five round-trips end to end — while the row inserts preserve
  /// the user's chosen order via `sort_order`.
  Future<void> _attachImages({
    required String postId,
    required List<XFile> files,
  }) async {
    final paths = await Future.wait([
      for (final file in files)
        _images.uploadPostImage(file: file, postId: postId),
    ]);

    await _client.from(DbTables.postImages).insert([
      for (final (index, path) in paths.indexed)
        {
          'post_id': postId,
          'image_url': _images.publicUrl(path),
          'storage_path': path,
          'sort_order': index,
        },
    ]);
  }

  /// Best-effort cleanup after a failed create. Any error here is swallowed so
  /// the caller still sees the original failure rather than a confusing one
  /// raised while unwinding.
  Future<void> _rollbackPost(String postId) async {
    try {
      await _images.deletePostImages(postId);
      await _client.from(DbTables.posts).delete().eq('id', postId);
    } on Object {
      // Nothing useful to do; the orphan is cleaned up server-side.
    }
  }

  Future<void> _assertDailyQuota(String profileId) async {
    final todaysPosts = await _client
        .from(DbTables.posts)
        .select('id')
        .eq('user_id', profileId)
        .gte('created_at', DateTime.now().startOfLocalDay.toIso8601String());
    if (todaysPosts.length >= AppLimits.maxPostsPerDay) {
      throw const ValidationFailure(
        'ناتوانیت لە ڕۆژێکدا زیاتر لە ١٠ بابەت زیاد بکەیت',
      );
    }
  }

  /// Notifies the author when their new post has plausible counterparts.
  ///
  /// Best-effort: the post is already created, so a failure to notify must not
  /// surface as a failure to publish.
  Future<void> _notifyOfSimilarPosts({
    required CreatePostInput input,
    required String profileId,
  }) async {
    try {
      final matches = await similarFor(input);
      if (matches.isEmpty) return;
      await _client.from(DbTables.notifications).insert({
        'user_id': profileId,
        'title': NotificationType.similarItem.label,
        'body': 'ئەم بابەتانە لەوانەیە پەیوەندییان بە بابەتەکەتەوە هەبێت',
        'type': NotificationType.similarItem.wire,
        'related_post_id': matches.first.id,
      });
    } on Object {
      // Intentionally ignored — see above.
    }
  }

  Future<void> updateStatus(String postId, PostStatus status) {
    return guardFailures(() async {
      await _profiles.require();
      await _client
          .from(DbTables.posts)
          .update({
            'status': status.wire,
            'updated_at': DateTime.now().toUtcIso(),
          })
          .eq('id', postId);
    });
  }

  Future<void> updateOwnPost({
    required String postId,
    required String title,
    required String description,
    required String city,
    required String area,
    required String locationText,
  }) {
    return guardFailures(() async {
      await _profiles.require();
      await _client
          .from(DbTables.posts)
          .update({
            'title': title,
            'description': description,
            'city': city,
            'area': area,
            'location_text': locationText,
            'updated_at': DateTime.now().toUtcIso(),
          })
          .eq('id', postId);
    });
  }

  Future<void> deletePost(String postId) {
    return guardFailures(() async {
      await _profiles.require();
      await _images.deletePostImages(postId);
      await _client.from(DbTables.posts).delete().eq('id', postId);
    });
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? description,
    String? reportedUserId,
  }) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client.from(DbTables.reports).insert({
        'reporter_id': profile.id,
        'post_id': postId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
      });
    });
  }

  List<PostModel> _parsePosts(List<dynamic> rows) {
    return rows
        .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}

/// Keys for the home-screen counters.
///
/// These were previously bare map keys (`'all'`, `'found'`, …) duplicated in
/// the repository, the local store, and the widget that renders them, so a typo
/// in any one of the three silently rendered a zero.
enum PostStatKey { all, found, lost, returned }
