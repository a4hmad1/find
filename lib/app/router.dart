import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/domain/post_status.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_posts_screen.dart';
import '../features/admin/presentation/admin_reports_screen.dart';
import '../features/admin/presentation/admin_users_screen.dart';
import '../features/auth/presentation/login_screen.dart';
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
import '../shared/widgets/app_widgets.dart';
import 'localization.dart';
import 'main_shell.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final configured = ref.watch(supabaseConfiguredProvider);

  // The router re-evaluates its redirect whenever auth changes. Without a
  // backend there is nothing to listen to and every route is public.
  final refresh = configured
      ? GoRouterRefreshStream(ref.watch(authRepositoryProvider).authEvents)
      : null;
  ref.onDispose(() => refresh?.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.intro,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state, configured: configured),
    routes: _routes,
    errorBuilder: (context, state) => const AppScaffold(
      title: 'هەڵە',
      child: ErrorView(message: 'ئەم پەڕەیە نەدۆزرایەوە'),
    ),
  );
});

/// Decides where a navigation should actually land.
///
/// The previous version redirected `/login` to `/home` unconditionally, which
/// made [LoginScreen] unreachable — there was no way to sign in anywhere in the
/// app. The rules now are:
///
///  * signed-out users hitting an account-only route go to the login screen,
///    carrying where they came from so they can be returned there;
///  * signed-in users hitting the login screen go on to their destination;
///  * everything else is public, because browsing is deliberately open to
///    guests.
String? _redirect(Ref ref, GoRouterState state, {required bool configured}) {
  final location = state.uri.path;

  // Guest mode: there is no session to check, so nothing is gated. The login
  // screen still renders and explains that Supabase is not configured.
  if (!configured) return null;

  final signedIn = ref.read(authRepositoryProvider).isSignedIn;

  if (location == AppRoutes.login) {
    if (!signedIn) return null;
    // Already authenticated — continue to wherever the user was headed.
    final target = state.uri.queryParameters[AppRoutes.redirectParam];
    return _isSafeRedirect(target) ? target : AppRoutes.home;
  }

  // The splash screen exists only to cover the session restore at launch.
  if (location == AppRoutes.splash) return null;

  final needsAccount =
      AppRoutes.accountOnly.contains(location) ||
      location.startsWith('${AppRoutes.messages}/');

  if (needsAccount && !signedIn) {
    return Uri(
      path: AppRoutes.login,
      queryParameters: {AppRoutes.redirectParam: state.uri.toString()},
    ).toString();
  }

  return null;
}

/// Guards the post-login redirect against open-redirect style abuse.
///
/// The target arrives as a query parameter, so it is only honoured when it is a
/// relative in-app path. An absolute URL or a scheme-relative `//host` would
/// otherwise send the user off the app after signing in.
bool _isSafeRedirect(String? target) {
  if (target == null || target.isEmpty) return false;
  if (!target.startsWith('/')) return false;
  if (target.startsWith('//')) return false;
  return target != AppRoutes.login;
}

List<RouteBase> get _routes => [
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
    builder: (context, state) => LoginScreen(
      redirectTo: state.uri.queryParameters[AppRoutes.redirectParam],
    ),
  ),
  // The OAuth provider returns to `krd.gov.find.find://login-callback`, which
  // arrives here as the path `/login-callback`. `supabase_flutter` has already
  // consumed the deep link and exchanged the code for a session by this point,
  // so this screen only has to wait for the resulting auth event and move on.
  GoRoute(
    path: AppRoutes.loginCallback,
    builder: (context, state) => LoginCallbackScreen(
      redirectTo: state.uri.queryParameters[AppRoutes.redirectParam],
    ),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        MainShell(navigationShell: navigationShell),
    branches: [
      _branch(AppRoutes.home, const HomeScreen()),
      _branch(AppRoutes.search, const SearchScreen()),
      _branch(AppRoutes.addPost, const AddPostScreen()),
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
      _branch(AppRoutes.profile, const ProfileScreen()),
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
    builder: (context, state) => AdminPostsScreen(
      initialStatus: PostStatus.tryParse(state.uri.queryParameters['status']),
    ),
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
];

StatefulShellBranch _branch(String path, Widget child) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(child: child),
      ),
    ],
  );
}

/// Bridges a [Stream] to the [Listenable] `GoRouter` wants for `refreshListenable`.
///
/// Lives with the router rather than in the provider file because it is a
/// routing concern, and is deliberately not a broadcast wrapper — the auth
/// event stream is already broadcast, and wrapping it again created a second
/// subscription that outlived `dispose`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// Shown while the OAuth deep link is being exchanged for a session.
class LoginCallbackScreen extends ConsumerStatefulWidget {
  const LoginCallbackScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginCallbackScreen> createState() =>
      _LoginCallbackScreenState();
}

class _LoginCallbackScreenState extends ConsumerState<LoginCallbackScreen> {
  @override
  Widget build(BuildContext context) {
    // Navigating during build is not allowed, so the move happens on the next
    // frame once the auth state resolves.
    ref.listen(authUserProvider, (previous, next) {
      final user = next.value;
      if (user == null) return;
      final target = _isSafeRedirect(widget.redirectTo)
          ? widget.redirectTo!
          : AppRoutes.home;
      if (context.mounted) context.go(target);
    });

    return const AppScaffold(
      title: Ku.loading,
      child: Center(
        child: Padding(padding: EdgeInsets.all(40), child: Loader()),
      ),
    );
  }
}
