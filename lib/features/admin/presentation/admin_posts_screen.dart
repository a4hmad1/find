import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/domain/post_status.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminPostsScreen extends ConsumerStatefulWidget {
  const AdminPostsScreen({super.key, this.initialStatus});

  /// Lets the dashboard deep-link straight into the pending queue.
  final PostStatus? initialStatus;

  @override
  ConsumerState<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends ConsumerState<AdminPostsScreen> {
  late PostStatus? _status = widget.initialStatus ?? PostStatus.pending;

  void _refreshAll() {
    ref
      ..invalidate(adminPostsProvider(_status))
      ..invalidate(adminStatsProvider)
      ..invalidate(recentPostsProvider);
  }

  Future<void> _update(PostModel post, PostStatus status) async {
    try {
      await ref.read(adminRepositoryProvider).updatePostStatus(post.id, status);
      _refreshAll();
      if (!mounted) return;
      showMessageSnackBar(context, 'دۆخی بابەتەکە گۆڕا بۆ ${status.label}');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  Future<void> _delete(PostModel post) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: Ku.deleteConfirm,
      message: 'بابەتەکە و وێنەکانی بە تەواوی لە سیستەم دەسڕدرێنەوە.',
      confirmLabel: Ku.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).deletePost(post.id);
      _refreshAll();
      if (!mounted) return;
      showMessageSnackBar(context, 'بابەتەکە سڕایەوە');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(adminPostsProvider(_status));

    return AppScaffold(
      title: Ku.adminPosts,
      onRefresh: () async {
        ref.invalidate(adminPostsProvider(_status));
        try {
          await ref.read(adminPostsProvider(_status).future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: Column(
        children: [
          LabeledDropdown<PostStatus>(
            label: 'دۆخ',
            value: _status,
            items: PostStatus.values,
            labelOf: (status) => status.label,
            allowAll: true,
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 16),
          posts.when(
            loading: () => const LoadingSkeleton(count: 5),
            error: (error, _) => ErrorView.failure(
              AppFailure.from(error),
              onRetry: () => ref.invalidate(adminPostsProvider(_status)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'هیچ بابەتێک نییە',
                  message: 'لەم دۆخەدا هیچ بابەتێک نەماوە.',
                  icon: Icons.fact_check_outlined,
                );
              }
              return Column(
                children: [
                  for (final post in items) ...[
                    PostCard(
                      post: post,
                      compact: true,
                      onDetails: () =>
                          context.push('${AppRoutes.post}/${post.id}'),
                    ),
                    ActionChipBar(
                      actions: [
                        // Only offer transitions that would change something.
                        if (post.status != PostStatus.approved)
                          ActionChipData(
                            label: 'پشتڕاستکردنەوە',
                            icon: Icons.verified_rounded,
                            onPressed: () => _update(post, PostStatus.approved),
                          ),
                        if (post.status != PostStatus.rejected)
                          ActionChipData(
                            label: 'ڕەتکردنەوە',
                            icon: Icons.block_rounded,
                            onPressed: () => _update(post, PostStatus.rejected),
                          ),
                        if (post.status != PostStatus.closed)
                          ActionChipData(
                            label: 'داخستن',
                            icon: Icons.lock_rounded,
                            onPressed: () => _update(post, PostStatus.closed),
                          ),
                        ActionChipData(
                          label: Ku.delete,
                          icon: Icons.delete_rounded,
                          destructive: true,
                          onPressed: () => _delete(post),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
