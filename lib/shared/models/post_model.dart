import '../../core/domain/post_status.dart';
import '../../core/domain/post_type.dart';
import '../../core/utils/json.dart';
import 'profile_model.dart';

class PostImageModel {
  const PostImageModel({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.storagePath,
    required this.sortOrder,
  });

  factory PostImageModel.fromJson(Map<String, dynamic> json) {
    return PostImageModel(
      id: json.asString('id'),
      postId: json.asString('post_id'),
      imageUrl: json.asString('image_url'),
      storagePath: json.asString('storage_path'),
      sortOrder: json.asInt('sort_order'),
    );
  }

  final String id;
  final String postId;
  final String imageUrl;
  final String storagePath;
  final int sortOrder;
}

class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.postType,
    required this.itemType,
    required this.status,
    required this.city,
    required this.area,
    required this.locationText,
    required this.allowContactPublic,
    required this.needsVerification,
    required this.viewsCount,
    required this.isUrgent,
    required this.images,
    this.latitude,
    this.longitude,
    this.eventDate,
    this.contactPhone,
    this.contactEmail,
    this.createdAt,
    this.updatedAt,
    this.profile,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] ?? json['profile'];
    return PostModel(
      id: json.asString('id'),
      userId: json.asString('user_id'),
      title: json.asString('title'),
      description: json.asString('description'),
      postType: PostType.tryParse(json['post_type']) ?? PostType.found,
      itemType: json.asString('item_type'),
      status: PostStatus.tryParse(json['status']) ?? PostStatus.pending,
      city: json.asString('city'),
      area: json.asString('area'),
      locationText: json.asString('location_text'),
      latitude: json.asDoubleOrNull('latitude'),
      longitude: json.asDoubleOrNull('longitude'),
      eventDate: json.asDateOrNull('event_date'),
      contactPhone: json.asStringOrNull('contact_phone'),
      contactEmail: json.asStringOrNull('contact_email'),
      allowContactPublic: json.asBool('allow_contact_public'),
      needsVerification: json.asBool('needs_verification', ifAbsent: true),
      viewsCount: json.asInt('views_count'),
      isUrgent: json.asBool('is_urgent'),
      createdAt: json.asDateOrNull('created_at'),
      updatedAt: json.asDateOrNull('updated_at'),
      images: json.asModelList('post_images', PostImageModel.fromJson)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      profile: profileJson is Map
          ? ProfileModel.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }

  final String id;
  final String userId;
  final String title;
  final String description;
  final PostType postType;
  final String itemType;
  final PostStatus status;
  final String city;
  final String area;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final DateTime? eventDate;
  final String? contactPhone;
  final String? contactEmail;
  final bool allowContactPublic;
  final bool needsVerification;
  final int viewsCount;
  final bool isUrgent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PostImageModel> images;
  final ProfileModel? profile;

  String get postTypeLabel => postType.label;
  String get statusLabel => status.label;
  String? get coverUrl => images.isEmpty ? null : images.first.imageUrl;
  bool get isClosed => status.isTerminal;

  /// The timestamp lists are sorted by. Falls back through creation date and
  /// event date so posts with partial data still order deterministically.
  DateTime get sortDate =>
      createdAt ?? eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// The profile id of the owner, preferring the joined profile when the query
  /// included one.
  String get ownerId => profile?.id ?? userId;
}

class CreatePostInput {
  const CreatePostInput({
    required this.title,
    required this.description,
    required this.postType,
    required this.itemType,
    required this.city,
    required this.area,
    required this.locationText,
    required this.eventDate,
    required this.needsVerification,
    this.contactPhone,
    this.contactEmail,
    this.allowContactPublic = false,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String description;
  final PostType postType;
  final String itemType;
  final String city;
  final String area;
  final String locationText;
  final DateTime eventDate;
  final String? contactPhone;
  final String? contactEmail;
  final bool allowContactPublic;
  final bool needsVerification;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'post_type': postType.wire,
      'item_type': itemType,
      'status': PostStatus.pending.wire,
      'city': city,
      'area': area,
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate.toDateOnlyString(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'allow_contact_public': allowContactPublic,
      'needs_verification': needsVerification,
    };
  }
}
