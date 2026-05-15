import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class SupabaseService {
  static bool get isConfigured {
    final url = dotenv.env[EnvKeys.supabaseUrl] ?? '';
    final anonKey = dotenv.env[EnvKeys.supabaseAnonKey] ?? '';
    return url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw const AppException('زانیاری Supabase لە پەڕگەی .env دانەنراوە');
    }
    return Supabase.instance.client;
  }
}
