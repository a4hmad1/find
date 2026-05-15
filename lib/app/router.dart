import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../shared/widgets/app_widgets.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_posts_screen.dart';
import '../features/admin/presentation/admin_reports_screen.dart';
import '../features/admin/presentation/admin_users_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/messages/presentation/conversation_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/posts/presentation/add_post_screen.dart';
import '../features/posts/presentation/post_details_screen.dart';
import '../features/profile/presentation/my_posts_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/saved_posts_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/static_pages/presentation/static_pages.dart';
import 'main_shell.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final configured = ref.watch(supabaseConfiguredProvider);
  final client = configured ? ref.watch(supabaseClientProvider) : null;
  final refresh = configured
      ? GoRouterRefreshStream(client!.auth.onAuthStateChange)
      : null;
  ref.onDispose(() => refresh?.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.intro,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.uri.path;
      final loggedIn = client?.auth.currentUser != null;
      if (location == AppRoutes.login || location == AppRoutes.splash) {
        return AppRoutes.home;
      }
      final accountOnlyRoutes = {
        AppRoutes.myPosts,
        AppRoutes.saved,
        AppRoutes.admin,
        AppRoutes.adminPosts,
        AppRoutes.adminReports,
        AppRoutes.adminUsers,
      };
      if (!loggedIn &&
          (accountOnlyRoutes.contains(location) ||
              location.startsWith('${AppRoutes.messages}/'))) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.intro),
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        redirect: (context, state) => AppRoutes.home,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.addPost,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AddPostScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MessagesScreen()),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ConversationScreen(
                      conversationId: state.pathParameters['conversationId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.post}/:id',
        builder: (context, state) =>
            PostDetailsScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myPosts,
        builder: (context, state) => const MyPostsScreen(),
      ),
      GoRoute(
        path: AppRoutes.saved,
        builder: (context, state) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPosts,
        builder: (context, state) => const AdminPostsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.offline,
        builder: (context, state) => const NoInternetScreen(),
      ),
    ],
    errorBuilder: (context, state) => const AppScaffold(
      title: 'هەڵە',
      child: ErrorView(message: 'ئەم پەڕەیە نەدۆزرایەوە'),
    ),
  );
});
