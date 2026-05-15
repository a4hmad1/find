import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/image_upload_service.dart';
import '../core/services/supabase_service.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/messages/data/messages_repository.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/posts/data/local_posts_store.dart';
import '../features/posts/data/posts_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../shared/models/post_model.dart';
import '../shared/models/profile_model.dart';

final supabaseConfiguredProvider = Provider<bool>((ref) {
  return SupabaseService.isConfigured;
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(imageUploadServiceProvider),
  );
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(imageUploadServiceProvider),
  );
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final localPostsProvider =
    NotifierProvider<LocalPostsController, List<PostModel>>(
      LocalPostsController.new,
    );

final authUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) {
    return Stream<User?>.value(null);
  }
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final signedInProvider = Provider<bool>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return false;
  return ref
      .watch(authUserProvider)
      .maybeWhen(data: (user) => user != null, orElse: () => false);
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).currentProfile();
});

final recentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  final local = ref.watch(localPostsProvider);
  if (!ref.watch(supabaseConfiguredProvider)) return local;
  try {
    final remote = await ref.watch(postsRepositoryProvider).recent();
    final posts = [...local, ...remote]
      ..sort((a, b) {
        final bDate = b.createdAt ?? b.eventDate ?? DateTime(2000);
        final aDate = a.createdAt ?? a.eventDate ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    return posts;
  } catch (_) {
    return local;
  }
});

final urgentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  final local = ref.watch(localPostsProvider).where((post) => post.isUrgent);
  if (!ref.watch(supabaseConfiguredProvider)) return local.toList();
  try {
    final remote = await ref.watch(postsRepositoryProvider).urgent();
    return [...local, ...remote];
  } catch (_) {
    return local.toList();
  }
});

final postStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final local = localPostStats(ref.watch(localPostsProvider));
  if (!ref.watch(supabaseConfiguredProvider)) {
    return local;
  }
  try {
    final remote = await ref.watch(postsRepositoryProvider).stats();
    return {
      'all': (remote['all'] ?? 0) + (local['all'] ?? 0),
      'found': (remote['found'] ?? 0) + (local['found'] ?? 0),
      'lost': (remote['lost'] ?? 0) + (local['lost'] ?? 0),
      'returned': (remote['returned'] ?? 0) + (local['returned'] ?? 0),
    };
  } catch (_) {
    return local;
  }
});

final postDetailsProvider = FutureProvider.family<PostModel?, String>((
  ref,
  id,
) async {
  final local = ref.watch(localPostsProvider).where((post) => post.id == id);
  if (local.isNotEmpty) return local.first;
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return ref.watch(postsRepositoryProvider).byId(id);
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isOnlineStream;
});

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
