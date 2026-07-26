import 'package:flutter/material.dart';

class EnvKeys {
  const EnvKeys._();

  static const supabaseUrl = 'SUPABASE_URL';
  static const supabaseAnonKey = 'SUPABASE_ANON_KEY';
}

/// OAuth redirect configuration.
///
/// [deepLinkScheme] and [deepLinkHost] must stay in sync with the
/// `<data android:scheme=... android:host=.../>` intent filter in
/// `android/app/src/main/AndroidManifest.xml` and the `CFBundleURLSchemes`
/// entry in `ios/Runner/Info.plist`. The same URL must also be registered as an
/// allowed redirect in the Supabase dashboard.
class AuthConfig {
  const AuthConfig._();

  static const deepLinkScheme = 'krd.gov.find.find';
  static const deepLinkHost = 'login-callback';
  static const nativeRedirectUrl = '$deepLinkScheme://$deepLinkHost';

  /// Scopes requested from GitHub. `user:email` is required so the profile
  /// upsert can store an email address.
  static const githubScopes = 'read:user user:email';
}

class AppRoutes {
  const AppRoutes._();

  static const intro = '/intro';
  static const splash = '/splash';
  static const login = '/login';
  static const loginCallback = '/login-callback';
  static const home = '/home';
  static const search = '/search';
  static const addPost = '/add-post';
  static const post = '/post';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const myPosts = '/profile/my-posts';
  static const saved = '/profile/saved';
  static const settings = '/settings';
  static const admin = '/admin';
  static const adminPosts = '/admin/posts';
  static const adminReports = '/admin/reports';
  static const adminUsers = '/admin/users';
  static const about = '/about';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const help = '/help';
  static const offline = '/offline';

  /// Routes that require a signed-in account. Visiting one while signed out
  /// redirects to [login] rather than silently bouncing to [home].
  static const accountOnly = <String>{
    myPosts,
    saved,
    notifications,
    admin,
    adminPosts,
    adminReports,
    adminUsers,
  };

  /// Routes that additionally require a moderator or admin role.
  static const moderatorOnly = <String>{
    admin,
    adminPosts,
    adminReports,
    adminUsers,
  };

  /// Query parameter carrying the route to return to after a successful login.
  static const redirectParam = 'from';
}

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF116A7B);
  static const primarySoft = Color(0xFFE7F6F7);
  static const secondary = Color(0xFF2F9C74);
  static const secondarySoft = Color(0xFFE9F7F0);
  static const accent = Color(0xFFE79E4F);
  static const accentSoft = Color(0xFFFFF1DD);
  static const rose = Color(0xFFDF6B7D);
  static const roseSoft = Color(0xFFFFE8EC);
  static const background = Color(0xFFF7F9F7);
  static const darkBackground = Color(0xFF101615);
  static const danger = Color(0xFFC94E54);
  static const success = Color(0xFF239B70);
  static const warning = Color(0xFFE59639);
  static const ink = Color(0xFF162321);
  static const muted = Color(0xFF687A76);

  /// Hairline border used on cards and tiles. Previously this was written as
  /// four slightly different literals scattered across the widget layer.
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0x14FFFFFF);
}

class DbTables {
  const DbTables._();

  static const profiles = 'profiles';
  static const posts = 'posts';
  static const postImages = 'post_images';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const savedPosts = 'saved_posts';
  static const reports = 'reports';
  static const notifications = 'notifications';
  static const categories = 'categories';
}

class DbSelects {
  const DbSelects._();

  static const publicProfile =
      'id,auth_user_id,github_id,github_username,display_name,avatar_url,role,is_banned,created_at,updated_at';
  static const postWithImages = '*, post_images(*)';
  static const postWithImagesAndProfile =
      '*, post_images(*), profiles($publicProfile)';
  static const messageWithSender = '*, profiles($publicProfile)';
  static const savedPostJoin =
      'posts(*, post_images(*), profiles($publicProfile))';
}

/// Limits enforced client-side so the user gets fast feedback. The
/// authoritative limits are database constraints and RLS policies.
class AppLimits {
  const AppLimits._();

  static const maxPostImages = 5;
  static const maxPostsPerDay = 10;
  static const maxMessagesPerHour = 20;
  static const recentPostsPageSize = 20;
  static const urgentPostsPageSize = 8;
  static const searchPageSize = 60;
  static const similarMatchesPageSize = 8;
}

class AppLists {
  const AppLists._();

  static const itemTypes = <String>[
    'مۆبایل',
    'پارەدان',
    'ناسنامە',
    'ئۆتۆمبێل',
    'کلیل',
    'جانتا',
    'کاڵای ئەلیکترۆنی',
    'بەڵگەنامە',
    'پۆشاک',
    'ئاژەڵ',
    'شتی تر',
  ];

  static const cities = <String>[
    'هەولێر',
    'سلێمانی',
    'دهۆک',
    'کەرکووک',
    'هەڵەبجە',
    'زاخۆ',
    'سۆران',
    'ڕانیە',
    'کۆیە',
    'چەمچەماڵ',
    'کەلار',
    'خانەقین',
    'بەغدا',
    'مووسڵ',
    'بەسرە',
    'نەجەف',
    'کەربەلا',
    'شتی تر',
  ];

  static const reportReasons = <String>[
    'زانیاری هەڵەیە',
    'بابەتەکە ساختەیە',
    'هەوڵی فێڵکردنە',
    'وێنە یان وشەی نەگونجاوە',
    'دووبارەیە',
    'هۆکاری تر',
  ];
}

class StorageBuckets {
  const StorageBuckets._();

  static const postImages = 'post-images';
}
