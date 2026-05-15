import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

class ImageUploadService {
  ImageUploadService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> uploadPostImage({
    required XFile file,
    required String postId,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = p.extension(file.name).isEmpty
        ? '.jpg'
        : p.extension(file.name);
    final storagePath = 'posts/$postId/${_uuid.v4()}$ext';
    final contentType =
        lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
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
}
