import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `.env` is optional on purpose: the app is fully usable in guest mode with
  // seeded posts, which is also what the widget test runs against.
  await dotenv.load(fileName: '.env', isOptional: true);

  // Neither of these is required for the app to render, so a failure in either
  // is logged and stepped over rather than left to crash the launch. Screens
  // check `supabaseConfiguredProvider` before touching the backend.
  await _tryInitialize('Supabase', SupabaseService.initialize);
  await _tryInitialize(
    'Notifications',
    NotificationService.instance.initialize,
  );

  runApp(const ProviderScope(child: FindApp()));
}

Future<void> _tryInitialize(String name, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error, stackTrace) {
    debugPrint('$name initialisation failed: $error');
    assert(() {
      debugPrintStack(stackTrace: stackTrace);
      return true;
    }());
  }
}
