import 'package:flutter/material.dart';

class EnvKeys {
  static const supabaseUrl = 'SUPABASE_URL';
  static const supabaseAnonKey = 'SUPABASE_ANON_KEY';
}

class AppRoutes {
  static const intro = '/intro';
  static const splash = '/splash';
  static const login = '/login';
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
}

class AppColors {
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
}

class DbTables {
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
  static const publicProfile =
      'id,auth_user_id,github_id,github_username,display_name,avatar_url,role,is_banned,created_at,updated_at';
  static const postWithImages = '*, post_images(*)';
  static const postWithImagesAndProfile =
      '*, post_images(*), profiles($publicProfile)';
}

class DbValues {
  static const found = 'found';
  static const lost = 'lost';
  static const stolen = 'stolen';
  static const pending = 'pending';
  static const approved = 'approved';
  static const returned = 'returned';
  static const closed = 'closed';
  static const rejected = 'rejected';

  static const postTypeLabels = <String, String>{
    found: 'دۆزراوە',
    lost: 'ونبووە',
    stolen: 'دزراوە',
  };

  static const statusLabels = <String, String>{
    pending: 'چاوەڕوانە',
    approved: 'پشتڕاستکراوە',
    returned: 'گەڕێنراوەتەوە',
    closed: 'داخراوە',
    rejected: 'پەسەند نەکرا',
  };

  static const notificationLabels = <String, String>{
    'new_message': 'نامەیەکی نوێت هەیە',
    'post_approved': 'بابەتەکەت پشتڕاستکرایەوە',
    'post_rejected': 'بابەتەکەت پەسەند نەکرا',
    'post_returned': 'شتەکە گەڕێنراوەتەوە',
    'similar_item': 'شتێکی هاوشێوە دۆزرایەوە',
    'admin_notice': 'ئاگادارکردنەوەی بەڕێوەبەر',
  };
}

class AppLists {
  static const postTypes = <String>[
    DbValues.found,
    DbValues.lost,
    DbValues.stolen,
  ];

  static const statuses = <String>[
    DbValues.pending,
    DbValues.approved,
    DbValues.returned,
    DbValues.closed,
  ];

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

  static const sortOptions = <String>[
    'نوێترین',
    'کۆنترین',
    'نزیکترین',
    'گرنگترین',
  ];
}

class StorageBuckets {
  static const postImages = 'post-images';
}
