import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/profile_guard.dart';
import '../core/domain/post_status.dart';
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
import '../shared/models/message_model.dart';
import '../shared/models/notification_model.dart';
import '../shared/models/post_model.dart';
import '../shared/models/profile_model.dart';
import '../shared/models/report_model.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

/// Whether a Supabase backend is available. Overridden in tests to exercise
/// guest mode deterministically.
final supabaseConfiguredProvider = Provider<bool>(
  (ref) => SupabaseService.isConfigured,
);

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);

final profileGuardProvider = Provider<ProfileGuard>(
  (ref) => ProfileGuard(ref.watch(supabaseClientProvider)),
);

final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => ImageUploadService(ref.watch(supabaseClientProvider)),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(Connectivity()),
);

final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).isOnlineStream,
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(profileGuardProvider),
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(profileGuardProvider),
  ),
);

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(imageUploadServiceProvider),
    ref.watch(profileGuardProvider),
  ),
);

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(imageUploadServiceProvider),
    ref.watch(profileGuardProvider),
  ),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(profileGuardProvider),
  ),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(imageUploadServiceProvider),
    ref.watch(profileGuardProvider),
  ),
);

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

final localPostsProvider =
    NotifierProvider<LocalPostsController, List<PostModel>>(
      LocalPostsController.new,
    );

/// The signed-in user, or null. Emits null immediately in guest mode so the
/// router never waits on a backend that is not there.
final authUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) {
    return Stream<User?>.value(null);
  }
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Whether there is an active session.
///
/// Treats loading as signed-out so account-only UI never flashes before the
/// session is restored.
final signedInProvider = Provider<bool>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return false;
  return ref
      .watch(authUserProvider)
      .maybeWhen(data: (user) => user != null, orElse: () => false);
});

/// The signed-in user's profile row, or null in guest mode.
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).currentProfile();
});

/// Whether the current account may open the moderation area.
final canModerateProvider = Provider<bool>((ref) {
  return ref
      .watch(currentProfileProvider)
      .maybeWhen(
        data: (profile) => profile?.isAdmin ?? false,
        orElse: () => false,
      );
});

// ---------------------------------------------------------------------------
// Posts
// ---------------------------------------------------------------------------

/// Merges guest-mode posts with remote ones.
///
/// Remote failures are surfaced rather than swallowed: the previous version
/// caught every error and silently returned only the seeded examples, so a
/// broken backend looked to the user like an app with four posts in it. When
/// the device is offline the local posts are still shown, because that is a
/// known, explainable state rather than an unexplained empty screen.
final recentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  final local = ref.watch(localPostsProvider);
  if (!ref.watch(supabaseConfiguredProvider)) return local;

  final remote = await ref.watch(postsRepositoryProvider).recent();
  return [...local, ...remote]
    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
});

final urgentPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  final local = ref
      .watch(localPostsProvider)
      .where((post) => post.isUrgent)
      .toList();
  if (!ref.watch(supabaseConfiguredProvider)) return local;

  final remote = await ref.watch(postsRepositoryProvider).urgent();
  return [...local, ...remote]
    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
});

final postStatsProvider = FutureProvider<Map<PostStatKey, int>>((ref) async {
  final local = localPostStats(ref.watch(localPostsProvider));
  if (!ref.watch(supabaseConfiguredProvider)) return local;

  final remote = await ref.watch(postsRepositoryProvider).stats();
  return {
    for (final key in PostStatKey.values)
      key: (remote[key] ?? 0) + (local[key] ?? 0),
  };
});

/// A single post by id. Guest posts live only in memory, so they are checked
/// before the network.
final postDetailsProvider = FutureProvider.family<PostModel?, String>((
  ref,
  id,
) async {
  final local = ref.watch(localPostsProvider).where((post) => post.id == id);
  if (local.isNotEmpty) return local.first;
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return ref.watch(postsRepositoryProvider).byId(id);
});

/// Results for one set of search criteria.
///
/// Keyed by the query itself, so Riverpod caches and de-duplicates repeat
/// searches instead of the screen juggling a `Future` field by hand.
final searchResultsProvider = FutureProvider.family<List<PostModel>, PostQuery>(
  (ref, query) async {
    final local = searchLocalPosts(ref.watch(localPostsProvider), query);
    if (!ref.watch(supabaseConfiguredProvider)) return local;

    final remote = await ref.watch(postsRepositoryProvider).search(query);
    return [...local, ...remote];
  },
);

// ---------------------------------------------------------------------------
// Account-scoped reads
// ---------------------------------------------------------------------------

/// Rebuilt whenever the session changes, so signing in or out refreshes these
/// lists without each screen wiring up its own listener.
final myPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  if (!ref.watch(signedInProvider)) return const <PostModel>[];
  return ref.watch(profileRepositoryProvider).myPosts();
});

final savedPostsProvider = FutureProvider<List<PostModel>>((ref) async {
  if (!ref.watch(signedInProvider)) return const <PostModel>[];
  return ref.watch(profileRepositoryProvider).savedPosts();
});

final notificationsProvider = FutureProvider<List<AppNotificationModel>>((
  ref,
) async {
  if (!ref.watch(signedInProvider)) return const <AppNotificationModel>[];
  return ref.watch(notificationsRepositoryProvider).list();
});

final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  if (!ref.watch(signedInProvider)) return 0;
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final conversationsProvider = FutureProvider<List<ConversationModel>>((
  ref,
) async {
  if (!ref.watch(signedInProvider)) return const <ConversationModel>[];
  return ref.watch(messagesRepositoryProvider).conversations();
});

final conversationProvider = FutureProvider.family<ConversationModel, String>((
  ref,
  id,
) async {
  return ref.watch(messagesRepositoryProvider).conversationById(id);
});

final conversationMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, id) {
      return ref.watch(messagesRepositoryProvider).streamMessages(id);
    });

// ---------------------------------------------------------------------------
// Moderation
// ---------------------------------------------------------------------------

final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).stats(),
);

final adminReportsProvider = FutureProvider<List<ReportModel>>(
  (ref) => ref.watch(adminRepositoryProvider).reports(),
);

final adminUsersProvider = FutureProvider<List<ProfileModel>>(
  (ref) => ref.watch(adminRepositoryProvider).users(),
);

final adminPostsProvider = FutureProvider.family<List<PostModel>, PostStatus?>(
  (ref, status) => ref.watch(adminRepositoryProvider).posts(status: status),
);

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
