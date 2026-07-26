import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    try {
      await ref.read(profileRepositoryProvider).removeSavedPost(post.id);
      ref.invalidate(savedPostsProvider);
      if (!context.mounted) return;
      showMessageSnackBar(context, 'لە پاشەکەوتکراوەکان لابرا');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signedInProvider)) {
      return const AppScaffold(
        title: Ku.savedPosts,
        child: GuestModeView(
          title: Ku.savedPosts,
          message: 'پاشەکەوتکراوەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.bookmark_border_rounded,
        ),
      );
    }

    final saved = ref.watch(savedPostsProvider);

    return AppScaffold(
      title: Ku.savedPosts,
      onRefresh: () async {
        ref.invalidate(savedPostsProvider);
        try {
          await ref.read(savedPostsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: saved.when(
        loading: () => const LoadingSkeleton(count: 4),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(savedPostsProvider),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              title: 'هیچ بابەتێک پاشەکەوت نەکراوە',
              message: 'لە وردەکاری بابەت دەتوانیت پاشەکەوتی بکەیت.',
              icon: Icons.bookmark_border_rounded,
            );
          }
          return Column(
            children: [
              for (final post in posts) ...[
                PostCard(
                  post: post,
                  onDetails: () => context.push('${AppRoutes.post}/${post.id}'),
                  onContact: () => context.push('${AppRoutes.post}/${post.id}'),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _remove(context, ref, post),
                    icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
                    label: const Text('لابردن'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}
