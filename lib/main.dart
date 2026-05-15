import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  final supabaseUrl = dotenv.env[EnvKeys.supabaseUrl] ?? '';
  final supabaseAnonKey = dotenv.env[EnvKeys.supabaseAnonKey] ?? '';
  if (supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: FindApp()));
}
