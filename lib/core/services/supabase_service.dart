import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';

/// Access to the Supabase client, plus the check for whether the app was given
/// credentials at all.
///
/// The app deliberately runs without Supabase configured — guest mode shows
/// seeded posts — so every entry point has to be able to ask whether a backend
/// exists before touching one.
class SupabaseService {
  const SupabaseService._();

  /// Whether `.env` supplied both a URL and an anon key.
  ///
  /// Read from `dotenv` rather than a cached boolean so that tests which load a
  /// different environment see the change.
  static bool get isConfigured {
    final url = dotenv.env[EnvKeys.supabaseUrl]?.trim() ?? '';
    final anonKey = dotenv.env[EnvKeys.supabaseAnonKey]?.trim() ?? '';
    return url.isNotEmpty && anonKey.isNotEmpty;
  }

  /// The initialised client.
  ///
  /// Throws [ConfigurationFailure] rather than the raw assertion
  /// `Supabase.instance` would throw, so a missing `.env` surfaces as a
  /// translated message instead of a crash.
  static SupabaseClient get client {
    if (!isConfigured) throw const ConfigurationFailure();
    return Supabase.instance.client;
  }

  /// Initialises Supabase when credentials are present.
  ///
  /// Returns whether initialisation happened, letting `main` keep going in
  /// guest mode when it did not.
  static Future<bool> initialize() async {
    if (!isConfigured) return false;
    await Supabase.initialize(
      url: dotenv.env[EnvKeys.supabaseUrl]!.trim(),
      anonKey: dotenv.env[EnvKeys.supabaseAnonKey]!.trim(),
      // PKCE is required for the mobile OAuth deep-link callback: the code
      // verifier stays on the device, so the redirect cannot be replayed.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    return true;
  }
}
