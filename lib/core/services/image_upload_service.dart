import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';

class ImageUploadService {
  ImageUploadService(this._client);

  static const _uuid = Uuid();

  /// Extensions we are willing to store. Anything else is rejected before the
  /// bytes are uploaded, so a mislabelled file cannot end up served from the
  /// public bucket with an attacker-chosen content type.
  static const _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
  };

  /// Hard ceiling per image. `image_picker` is already asked to downscale, but
  /// a caller could pass a file that skipped that path.
  static const _maxBytes = 8 * 1024 * 1024;

  final SupabaseClient _client;

  /// Uploads one image for [postId] and returns its storage path.
  ///
  /// The content type is sniffed from the leading bytes rather than trusted
  /// from the file name, since the name is user-controlled.
  Future<String> uploadPostImage({
    required XFile file,
    required String postId,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ValidationFailure('پەڕگەی وێنە بەتاڵە');
    }
    if (bytes.length > _maxBytes) {
      throw const ValidationFailure('قەبارەی وێنەکە زۆر گەورەیە');
    }

    final contentType = lookupMimeType(file.name, headerBytes: bytes);
    if (contentType == null || !_allowedMimeTypes.contains(contentType)) {
      throw const ValidationFailure('تەنها وێنە ڕێگەپێدراوە');
    }

    final extension = p.extension(file.name).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final storagePath = '${storagePrefix(postId)}/${_uuid.v4()}$safeExtension';

    await _client.storage
        .from(StorageBuckets.postImages)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    return storagePath;
  }

  String publicUrl(String storagePath) {
    return _client.storage
        .from(StorageBuckets.postImages)
        .getPublicUrl(storagePath);
  }

  /// All objects belonging to [postId] live under one prefix, which is what
  /// makes bulk cleanup possible.
  String storagePrefix(String postId) => 'posts/$postId';

  /// Removes every stored image for [postId].
  ///
  /// Deleting the `posts` row cascades to `post_images`, but storage objects
  /// are outside the database and would otherwise be retained forever and keep
  /// being billed.
  Future<void> deletePostImages(String postId) async {
    final prefix = storagePrefix(postId);
    final bucket = _client.storage.from(StorageBuckets.postImages);
    final objects = await bucket.list(path: prefix);
    if (objects.isEmpty) return;
    await bucket.remove([
      for (final object in objects) '$prefix/${object.name}',
    ]);
  }
}
