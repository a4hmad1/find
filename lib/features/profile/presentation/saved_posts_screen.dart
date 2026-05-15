import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  late Future<List<PostModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _canUseAccount()
        ? ref.read(profileRepositoryProvider).savedPosts()
        : Future.value(const <PostModel>[]);
  }

  bool _canUseAccount() {
    if (!ref.read(supabaseConfiguredProvider)) return false;
    return ref.read(supabaseClientProvider).auth.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
      return AppScaffold(
        title: Ku.savedPosts,
        child: GuestModeView(
          title: Ku.savedPosts,
          message: 'پاشەکەوتکراوەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.bookmark_border_rounded,
          actionLabel: Ku.home,
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return AppScaffold(
      title: Ku.savedPosts,
      child: FutureBuilder<List<PostModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 4);
          }
          if (snapshot.hasError) return const ErrorView();
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const EmptyState(
              title: 'هیچ بابەتێک پاشەکەوت نەکراوە',
              message: 'لە وردەکاری بابەت دەتوانیت پاشەکەوتی بکەیت.',
              icon: Icons.bookmark_border_rounded,
            );
          }
          return Column(
            children: posts
                .map(
                  (post) => PostCard(
                    post: post,
                    onDetails: () =>
                        context.push('${AppRoutes.post}/${post.id}'),
                    onContact: () =>
                        context.push('${AppRoutes.post}/${post.id}'),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
