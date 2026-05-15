import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';

class PostsRepository {
  PostsRepository(this._client, this._images);

  final SupabaseClient _client;
  final ImageUploadService _images;

  String get _postSelect => _client.auth.currentUser == null
      ? DbSelects.postWithImages
      : DbSelects.postWithImagesAndProfile;

  Future<ProfileModel> _profile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) throw const AppException('تکایە بچۆ ژوورەوە');
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authId)
        .limit(1);
    if (rows.isEmpty) throw const AppException('هەژمارەکە نەدۆزرایەوە');
    final profile = ProfileModel.fromJson(rows.first);
    if (profile.isBanned) throw const AppException('هەژمارەکەت ڕاگیراوە');
    return profile;
  }

  Future<List<PostModel>> recent({int limit = 20}) async {
    final rows = await _client
        .from(DbTables.posts)
        .select(_postSelect)
        .eq('status', DbValues.approved)
        .order('created_at', ascending: false)
        .limit(limit);
    return _parsePosts(rows);
  }

  Future<List<PostModel>> urgent({int limit = 8}) async {
    final rows = await _client
        .from(DbTables.posts)
        .select(_postSelect)
        .eq('status', DbValues.approved)
        .eq('is_urgent', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return _parsePosts(rows);
  }

  Future<PostModel> byId(String id) async {
    try {
      await _client.rpc('increment_post_views', params: {'post_id_input': id});
    } catch (_) {
      // View counts are best-effort and should not block public reading.
    }
    final row = await _client
        .from(DbTables.posts)
        .select(_postSelect)
        .eq('id', id)
        .single();
    return PostModel.fromJson(row);
  }

  Future<Map<String, int>> stats() async {
    final rows = await _client
        .from(DbTables.posts)
        .select('post_type,status')
        .inFilter('status', const [
          DbValues.approved,
          DbValues.returned,
          DbValues.closed,
        ]);
    final posts = List<Map<String, dynamic>>.from(rows);
    return {
      'all': posts.length,
      'found': posts.where((row) => row['post_type'] == DbValues.found).length,
      'lost': posts.where((row) => row['post_type'] == DbValues.lost).length,
      'returned': posts
          .where((row) => row['status'] == DbValues.returned)
          .length,
    };
  }

  Future<List<PostModel>> search({
    String? query,
    String? city,
    String? postType,
    String? status,
    String? itemType,
    DateTime? date,
    String sort = 'نوێترین',
  }) async {
    dynamic request = _client.from(DbTables.posts).select(_postSelect);

    if (status == null || status.isEmpty) {
      request = request.inFilter('status', const [
        DbValues.approved,
        DbValues.returned,
      ]);
    } else {
      request = request.eq('status', status);
    }
    if (query != null && query.trim().isNotEmpty) {
      final safe = query.trim().replaceAll(',', ' ');
      request = request.or('title.ilike.%$safe%,description.ilike.%$safe%');
    }
    if (city != null && city.isNotEmpty) request = request.eq('city', city);
    if (postType != null && postType.isNotEmpty) {
      request = request.eq('post_type', postType);
    }
    if (itemType != null && itemType.isNotEmpty) {
      request = request.eq('item_type', itemType);
    }
    if (date != null) {
      request = request.eq(
        'event_date',
        date.toIso8601String().split('T').first,
      );
    }
    if (sort == 'کۆنترین') {
      request = request.order('created_at', ascending: true);
    } else if (sort == 'گرنگترین') {
      request = request.order('is_urgent', ascending: false);
    } else {
      request = request.order('created_at', ascending: false);
    }
    final rows = await request.limit(60);
    return _parsePosts(rows);
  }

  Future<List<PostModel>> similarFor(CreatePostInput input) async {
    final oppositeType = input.postType == DbValues.lost
        ? DbValues.found
        : DbValues.lost;
    final rows = await _client
        .from(DbTables.posts)
        .select(_postSelect)
        .eq('status', DbValues.approved)
        .eq('city', input.city)
        .eq('item_type', input.itemType)
        .eq('post_type', oppositeType)
        .order('created_at', ascending: false)
        .limit(8);
    return _parsePosts(rows);
  }

  Future<PostModel> createPost(CreatePostInput input, List<XFile> files) async {
    if (files.isEmpty) {
      throw const AppException('تکایە لانیکەم یەک وێنە زیاد بکە');
    }
    if (files.length > 5) {
      throw const AppException('تەنها ٥ وێنە ڕێگەپێدراوە');
    }
    final profile = await _profile();
    final start = DateTime.now().toLocal();
    final dayStart = DateTime(start.year, start.month, start.day).toUtc();
    final todaysPosts = await _client
        .from(DbTables.posts)
        .select('id')
        .eq('user_id', profile.id)
        .gte('created_at', dayStart.toIso8601String());
    if (todaysPosts.length >= 10) {
      throw const AppException(
        'ناتوانیت لە ڕۆژێکدا زیاتر لە ١٠ بابەت زیاد بکەیت',
      );
    }

    final inserted = await _client
        .from(DbTables.posts)
        .insert(input.toInsertJson(profile.id))
        .select()
        .single();
    final post = PostModel.fromJson(inserted);

    for (var index = 0; index < files.length; index++) {
      final path = await _images.uploadPostImage(
        file: files[index],
        postId: post.id,
      );
      await _client.from(DbTables.postImages).insert({
        'post_id': post.id,
        'image_url': _images.publicUrl(path),
        'storage_path': path,
        'sort_order': index,
      });
    }

    final fullPost = await byId(post.id);
    final matches = await similarFor(input);
    if (matches.isNotEmpty) {
      await _client.from(DbTables.notifications).insert({
        'user_id': profile.id,
        'title': 'شتێکی هاوشێوە دۆزرایەوە',
        'body': 'ئەم بابەتانە لەوانەیە پەیوەندییان بە بابەتەکەتەوە هەبێت',
        'type': 'similar_item',
        'related_post_id': matches.first.id,
      });
    }
    return fullPost;
  }

  Future<void> updateStatus(String postId, String status) async {
    await _client
        .from(DbTables.posts)
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
  }

  Future<void> updateOwnPost({
    required String postId,
    required String title,
    required String description,
    required String city,
    required String area,
    required String locationText,
  }) async {
    await _profile();
    await _client
        .from(DbTables.posts)
        .update({
          'title': title,
          'description': description,
          'city': city,
          'area': area,
          'location_text': locationText,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    await _client.from(DbTables.posts).delete().eq('id', postId);
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? description,
    String? reportedUserId,
  }) async {
    final profile = await _profile();
    await _client.from(DbTables.reports).insert({
      'reporter_id': profile.id,
      'post_id': postId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'description': description,
    });
  }

  List<PostModel> _parsePosts(List<dynamic> rows) {
    return rows
        .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
