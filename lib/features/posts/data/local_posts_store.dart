import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/domain/post_status.dart';
import '../../../core/domain/post_type.dart';
import '../../../core/domain/sort_option.dart';
import '../../../core/domain/user_role.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';
import 'posts_repository.dart';

/// In-memory posts backing guest mode.
///
/// The app is usable without an account and without Supabase configured; this
/// holds the seeded example posts plus anything a guest adds during the session.
/// Nothing here is persisted — a guest post exists only until the app restarts,
/// which the add-post screen tells the user.
class LocalPostsController extends Notifier<List<PostModel>> {
  @override
  List<PostModel> build() => _seedPosts();

  Future<PostModel> addGuestPost(
    CreatePostInput input,
    List<XFile> files,
  ) async {
    final id = 'guest-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();

    final images = await _encodeImages(id, files);
    final post = PostModel(
      id: id,
      userId: guestProfile.id,
      title: input.title,
      description: input.description,
      postType: input.postType,
      itemType: input.itemType,
      // Guest posts skip moderation because they never leave the device.
      status: PostStatus.approved,
      city: input.city,
      area: input.area,
      locationText: input.locationText,
      eventDate: input.eventDate,
      contactPhone: input.contactPhone,
      contactEmail: input.contactEmail,
      allowContactPublic: input.allowContactPublic,
      needsVerification: input.needsVerification,
      viewsCount: 0,
      isUrgent: input.postType == PostType.lost,
      createdAt: now,
      updatedAt: now,
      images: images,
      profile: guestProfile,
    );

    state = [post, ...state];
    return post;
  }

  /// Encodes picked files as data URIs so they render without a network round
  /// trip. Falls back to a stock image when the guest added none.
  Future<List<PostImageModel>> _encodeImages(
    String postId,
    List<XFile> files,
  ) async {
    if (files.isEmpty) {
      return [
        PostImageModel(
          id: '$postId-image-placeholder',
          postId: postId,
          imageUrl: _placeholderImage,
          storagePath: '',
          sortOrder: 0,
        ),
      ];
    }

    final encoded = await Future.wait([
      for (final file in files)
        file.readAsBytes().then(
          (bytes) => (mime: file.mimeType ?? 'image/jpeg', bytes: bytes),
        ),
    ]);

    return [
      for (final (index, image) in encoded.indexed)
        PostImageModel(
          id: '$postId-image-$index',
          postId: postId,
          imageUrl: 'data:${image.mime};base64,${base64Encode(image.bytes)}',
          storagePath: '',
          sortOrder: index,
        ),
    ];
  }
}

/// Applies [query] to in-memory posts, mirroring the server-side filtering in
/// [PostsRepository.search] so guest and signed-in results behave the same.
List<PostModel> searchLocalPosts(List<PostModel> posts, PostQuery query) {
  final needle = query.trimmedText.toLowerCase();

  final results = posts.where((post) {
    if (needle.isNotEmpty) {
      final haystack = [
        post.title,
        post.description,
        post.city,
        post.itemType,
      ].join(' ').toLowerCase();
      if (!haystack.contains(needle)) return false;
    }
    if (query.city case final city? when city.isNotEmpty) {
      if (post.city != city) return false;
    }
    if (query.postType case final postType?) {
      if (post.postType != postType) return false;
    }
    if (query.status case final status?) {
      if (post.status != status) return false;
    }
    if (query.itemType case final itemType? when itemType.isNotEmpty) {
      if (post.itemType != itemType) return false;
    }
    if (query.date case final date?) {
      final eventDay = post.eventDate ?? post.createdAt;
      if (eventDay == null || !eventDay.isSameLocalDay(date)) return false;
    }
    if (query.urgentOnly && !post.isUrgent) return false;
    return true;
  }).toList()..sort(_comparatorFor(query.sort));

  return results;
}

int Function(PostModel, PostModel) _comparatorFor(SortOption sort) {
  return switch (sort) {
    SortOption.oldest => (a, b) => a.sortDate.compareTo(b.sortDate),
    SortOption.mostUrgent => (a, b) {
      final urgency = (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0);
      return urgency != 0 ? urgency : b.sortDate.compareTo(a.sortDate);
    },
    SortOption.nearest ||
    SortOption.newest => (a, b) => b.sortDate.compareTo(a.sortDate),
  };
}

Map<PostStatKey, int> localPostStats(List<PostModel> posts) {
  final visible = posts
      .where((post) => PostStatus.publiclyVisible.contains(post.status))
      .toList();
  return {
    PostStatKey.all: visible.length,
    PostStatKey.found: visible
        .where((post) => post.postType == PostType.found)
        .length,
    PostStatKey.lost: visible
        .where((post) => post.postType == PostType.lost)
        .length,
    PostStatKey.returned: visible
        .where((post) => post.status == PostStatus.returned)
        .length,
  };
}

extension on DateTime {
  bool isSameLocalDay(DateTime other) {
    final a = toLocal();
    final b = other.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

const _placeholderImage =
    'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=900&q=80';

final guestProfile = ProfileModel(
  id: 'guest-profile',
  authUserId: 'guest-auth',
  githubId: 'guest',
  githubUsername: 'guest',
  displayName: 'میوان',
  avatarUrl: '',
  role: UserRole.user,
  isBanned: false,
  createdAt: DateTime(2026, 5, 14),
  updatedAt: DateTime(2026, 5, 14),
);

List<PostModel> _seedPosts() {
  final now = DateTime.now();
  return [
    _seedPost(
      id: 'example-phone',
      title: 'مۆبایلی ڕەش لە بازاڕ دۆزرایەوە',
      description:
          'مۆبایلێکی ڕەش لە نزیک بازاڕی ناوەندی دۆزرایەوە. خاوەنەکە دەتوانێت بە نیشانی تایبەت پشتڕاستی بکاتەوە.',
      postType: PostType.found,
      itemType: 'مۆبایل',
      city: 'هەولێر',
      area: 'بازاڕ',
      locationText: 'نزیک دەروازەی سەرەکی',
      imageUrl:
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=80',
      eventDate: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(hours: 3)),
      views: 38,
      urgent: true,
    ),
    _seedPost(
      id: 'example-wallet',
      title: 'جانتا بچووک لە تاکسی لەدەستچووە',
      description:
          'جانتا بچووکێکی قاوەیی لە تاکسییەک لە نێوان سلێمانی و هەڵەبجە لەدەستچووە. ناوی خاوەنەکە لە ناو بەڵگەکاندا هەیە.',
      postType: PostType.lost,
      itemType: 'جانتا',
      city: 'سلێمانی',
      area: 'سەرچنار',
      locationText: 'ڕێگای سەرچنار',
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=80',
      eventDate: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(hours: 7)),
      views: 52,
      urgent: true,
    ),
    _seedPost(
      id: 'example-keys',
      title: 'کلیلەکان گەڕێنراونەتەوە',
      description:
          'کۆمەڵە کلیلێک لە نزیک پارک دۆزرابوو و خاوەنەکە پاش پشتڕاستکردنەوە وەریگرتەوە.',
      postType: PostType.found,
      itemType: 'کلیل',
      status: PostStatus.returned,
      city: 'دهۆک',
      area: 'پارکی گشتی',
      locationText: 'لای دەروازەی ڕۆژئاوا',
      imageUrl:
          'https://images.unsplash.com/photo-1523206489230-c012c64b2b48?auto=format&fit=crop&w=900&q=80',
      eventDate: now.subtract(const Duration(days: 4)),
      createdAt: now.subtract(const Duration(days: 1)),
      views: 19,
    ),
    _seedPost(
      id: 'example-camera',
      title: 'کامێرای سپی لە کافێیەک ماوەتەوە',
      description:
          'کامێرایەکی بچووک لە کافێیەک لە کەرکووک ماوەتەوە. تکایە جۆر و وێنەی ناوی ناوەوە دیاری بکە.',
      postType: PostType.found,
      itemType: 'کاڵای ئەلیکترۆنی',
      city: 'کەرکووک',
      area: 'ڕەحیم ئاوا',
      locationText: 'کافێی نزیک قوتابخانە',
      imageUrl: _placeholderImage,
      eventDate: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(hours: 18)),
      views: 27,
    ),
  ];
}

PostModel _seedPost({
  required String id,
  required String title,
  required String description,
  required PostType postType,
  required String itemType,
  required String city,
  required String area,
  required String locationText,
  required String imageUrl,
  required DateTime eventDate,
  required DateTime createdAt,
  required int views,
  PostStatus status = PostStatus.approved,
  bool urgent = false,
}) {
  return PostModel(
    id: id,
    userId: guestProfile.id,
    title: title,
    description: description,
    postType: postType,
    itemType: itemType,
    status: status,
    city: city,
    area: area,
    locationText: locationText,
    eventDate: eventDate,
    contactPhone: '07501234567',
    allowContactPublic: true,
    needsVerification: true,
    viewsCount: views,
    isUrgent: urgent,
    createdAt: createdAt,
    updatedAt: createdAt,
    images: [
      PostImageModel(
        id: '$id-image',
        postId: id,
        imageUrl: imageUrl,
        storagePath: '',
        sortOrder: 0,
      ),
    ],
    profile: guestProfile,
  );
}
