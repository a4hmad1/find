import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';

class LocalPostsController extends Notifier<List<PostModel>> {
  @override
  List<PostModel> build() => _examplePosts();

  Future<PostModel> addGuestPost(
    CreatePostInput input,
    List<XFile> files,
  ) async {
    final id = 'guest-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final images = <PostImageModel>[];

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      images.add(
        PostImageModel(
          id: '$id-image-$index',
          postId: id,
          imageUrl: 'data:$mime;base64,${base64Encode(bytes)}',
          storagePath: '',
          sortOrder: index,
        ),
      );
    }
    if (images.isEmpty) {
      images.add(
        PostImageModel(
          id: '$id-image-example',
          postId: id,
          imageUrl: _fallbackImage(input.itemType),
          storagePath: '',
          sortOrder: 0,
        ),
      );
    }

    final post = PostModel(
      id: id,
      userId: _guestProfile.id,
      title: input.title,
      description: input.description,
      postType: input.postType,
      itemType: input.itemType,
      status: DbValues.approved,
      city: input.city,
      area: input.area,
      locationText: input.locationText,
      eventDate: input.eventDate,
      contactPhone: input.contactPhone,
      contactEmail: input.contactEmail,
      allowContactPublic: input.allowContactPublic,
      needsVerification: input.needsVerification,
      viewsCount: 0,
      isUrgent: input.postType == DbValues.lost,
      createdAt: now,
      updatedAt: now,
      images: images,
      profile: _guestProfile,
    );

    state = [post, ...state];
    return post;
  }
}

List<PostModel> searchLocalPosts(
  List<PostModel> posts, {
  String? query,
  String? city,
  String? postType,
  String? status,
  String? itemType,
  DateTime? date,
  String sort = 'نوێترین',
}) {
  final needle = query?.trim().toLowerCase() ?? '';
  var results = posts.where((post) {
    final matchesQuery =
        needle.isEmpty ||
        post.title.toLowerCase().contains(needle) ||
        post.description.toLowerCase().contains(needle) ||
        post.city.toLowerCase().contains(needle) ||
        post.itemType.toLowerCase().contains(needle);
    final matchesCity = city == null || city.isEmpty || post.city == city;
    final matchesType =
        postType == null || postType.isEmpty || post.postType == postType;
    final matchesStatus =
        status == null || status.isEmpty || post.status == status;
    final matchesItem =
        itemType == null || itemType.isEmpty || post.itemType == itemType;
    final matchesDate =
        date == null ||
        _sameDay(post.eventDate ?? post.createdAt ?? DateTime(2000), date);

    return matchesQuery &&
        matchesCity &&
        matchesType &&
        matchesStatus &&
        matchesItem &&
        matchesDate;
  }).toList();

  if (sort == 'کۆنترین') {
    results.sort((a, b) => _dateFor(a).compareTo(_dateFor(b)));
  } else if (sort == 'گرنگترین') {
    results.sort((a, b) {
      final urgent = (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0);
      return urgent == 0 ? _dateFor(b).compareTo(_dateFor(a)) : urgent;
    });
  } else {
    results.sort((a, b) => _dateFor(b).compareTo(_dateFor(a)));
  }
  return results;
}

Map<String, int> localPostStats(List<PostModel> posts) {
  final visible = posts
      .where(
        (post) => const {
          DbValues.approved,
          DbValues.returned,
          DbValues.closed,
        }.contains(post.status),
      )
      .toList();
  return {
    'all': visible.length,
    'found': visible.where((post) => post.postType == DbValues.found).length,
    'lost': visible.where((post) => post.postType == DbValues.lost).length,
    'returned': visible
        .where((post) => post.status == DbValues.returned)
        .length,
  };
}

DateTime _dateFor(PostModel post) {
  return post.createdAt ?? post.eventDate ?? DateTime(2000);
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _fallbackImage(String itemType) {
  if (itemType == 'مۆبایل') {
    return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=80';
  }
  if (itemType == 'کلیل') {
    return 'https://images.unsplash.com/photo-1523206489230-c012c64b2b48?auto=format&fit=crop&w=900&q=80';
  }
  if (itemType == 'جانتا') {
    return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=80';
  }
  if (itemType == 'پۆشاک') {
    return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80';
  }
  return 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=900&q=80';
}

final _guestProfile = ProfileModel(
  id: 'guest-profile',
  authUserId: 'guest-auth',
  githubId: 'guest',
  githubUsername: 'guest',
  displayName: 'میوان',
  avatarUrl: '',
  role: 'user',
  isBanned: false,
  createdAt: DateTime(2026, 5, 14),
  updatedAt: DateTime(2026, 5, 14),
);

List<PostModel> _examplePosts() {
  final now = DateTime.now();
  return [
    _post(
      id: 'example-phone',
      title: 'مۆبایلی ڕەش لە بازاڕ دۆزرایەوە',
      description:
          'مۆبایلێکی ڕەش لە نزیک بازاڕی ناوەندی دۆزرایەوە. خاوەنەکە دەتوانێت بە نیشانی تایبەت پشتڕاستی بکاتەوە.',
      postType: DbValues.found,
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
    _post(
      id: 'example-wallet',
      title: 'جانتا بچووک لە تاکسی لەدەستچووە',
      description:
          'جانتا بچووکێکی قاوەیی لە تاکسییەک لە نێوان سلێمانی و هەڵەبجە لەدەستچووە. ناوی خاوەنەکە لە ناو بەڵگەکاندا هەیە.',
      postType: DbValues.lost,
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
    _post(
      id: 'example-keys',
      title: 'کلیلەکان گەڕێنراونەتەوە',
      description:
          'کۆمەڵە کلیلێک لە نزیک پارک دۆزرابوو و خاوەنەکە پاش پشتڕاستکردنەوە وەریگرتەوە.',
      postType: DbValues.found,
      itemType: 'کلیل',
      status: DbValues.returned,
      city: 'دهۆک',
      area: 'پارکی گشتی',
      locationText: 'لای دەروازەی ڕۆژئاوا',
      imageUrl:
          'https://images.unsplash.com/photo-1523206489230-c012c64b2b48?auto=format&fit=crop&w=900&q=80',
      eventDate: now.subtract(const Duration(days: 4)),
      createdAt: now.subtract(const Duration(days: 1)),
      views: 19,
    ),
    _post(
      id: 'example-camera',
      title: 'کامێرای سپی لە کافێیەک ماوەتەوە',
      description:
          'کامێرایەکی بچووک لە کافێیەک لە کەرکووک ماوەتەوە. تکایە جۆر و وێنەی ناوی ناوەوە دیاری بکە.',
      postType: DbValues.found,
      itemType: 'کاڵای ئەلیکترۆنی',
      city: 'کەرکووک',
      area: 'ڕەحیم ئاوا',
      locationText: 'کافێی نزیک قوتابخانە',
      imageUrl:
          'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=900&q=80',
      eventDate: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(hours: 18)),
      views: 27,
    ),
  ];
}

PostModel _post({
  required String id,
  required String title,
  required String description,
  required String postType,
  required String itemType,
  required String city,
  required String area,
  required String locationText,
  required String imageUrl,
  required DateTime eventDate,
  required DateTime createdAt,
  required int views,
  String status = DbValues.approved,
  bool urgent = false,
}) {
  return PostModel(
    id: id,
    userId: _guestProfile.id,
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
    contactEmail: null,
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
    profile: _guestProfile,
  );
}
