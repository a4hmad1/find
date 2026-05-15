import '../../core/constants/app_constants.dart';
import 'profile_model.dart';

class PostImageModel {
  const PostImageModel({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.storagePath,
    required this.sortOrder,
  });

  final String id;
  final String postId;
  final String imageUrl;
  final String storagePath;
  final int sortOrder;

  factory PostImageModel.fromJson(Map<String, dynamic> json) {
    return PostImageModel(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      storagePath: json['storage_path']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
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

  final String id;
  final String userId;
  final String title;
  final String description;
  final String postType;
  final String itemType;
  final String status;
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

  String get postTypeLabel => DbValues.postTypeLabels[postType] ?? postType;
  String get statusLabel => DbValues.statusLabels[status] ?? status;
  String? get coverUrl => images.isEmpty ? null : images.first.imageUrl;
  bool get isClosed => status == DbValues.closed || status == DbValues.returned;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['post_images'];
    final parsedImages = rawImages is List
        ? rawImages
              .whereType<Map>()
              .map(
                (item) =>
                    PostImageModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <PostImageModel>[];

    final profileJson = json['profiles'] ?? json['profile'];
    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      postType: json['post_type']?.toString() ?? DbValues.found,
      itemType: json['item_type']?.toString() ?? '',
      status: json['status']?.toString() ?? DbValues.pending,
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      eventDate: DateTime.tryParse(json['event_date']?.toString() ?? ''),
      contactPhone: json['contact_phone']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      allowContactPublic: json['allow_contact_public'] == true,
      needsVerification: json['needs_verification'] != false,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      isUrgent: json['is_urgent'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      images: parsedImages,
      profile: profileJson is Map
          ? ProfileModel.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }
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
  final String postType;
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
      'post_type': postType,
      'item_type': itemType,
      'status': DbValues.pending,
      'city': city,
      'area': area,
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate.toIso8601String().split('T').first,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'allow_contact_public': allowContactPublic,
      'needs_verification': needsVerification,
    };
  }
}
