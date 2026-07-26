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

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  void _invalidate(WidgetRef ref) {
    ref
      ..invalidate(myPostsProvider)
      ..invalidate(recentPostsProvider)
      ..invalidate(postStatsProvider);
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
    PostStatus status,
  ) async {
    try {
      await ref.read(postsRepositoryProvider).updateStatus(post.id, status);
      _invalidate(ref);
      if (!context.mounted) return;
      showMessageSnackBar(context, 'دۆخی بابەتەکە گۆڕا');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: Ku.deleteConfirm,
      message: 'ئەم کردارە ناگەڕێتەوە و وێنەکانیش دەسڕدرێنەوە.',
      confirmLabel: Ku.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(postsRepositoryProvider).deletePost(post.id);
      _invalidate(ref);
      if (!context.mounted) return;
      showMessageSnackBar(context, 'بابەتەکە سڕایەوە');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    final result = await showDialog<_EditedPost>(
      context: context,
      builder: (dialogContext) => _EditPostDialog(post: post),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(postsRepositoryProvider)
          .updateOwnPost(
            postId: post.id,
            title: result.title,
            description: result.description,
            city: result.city,
            area: result.area,
            locationText: result.locationText,
          );
      _invalidate(ref);
      if (!context.mounted) return;
      showMessageSnackBar(context, 'بابەتەکە نوێکرایەوە');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signedInProvider)) {
      return const AppScaffold(
        title: Ku.myPosts,
        child: GuestModeView(
          title: Ku.myPosts,
          message: 'بابەتە تایبەتەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    final posts = ref.watch(myPostsProvider);

    return AppScaffold(
      title: Ku.myPosts,
      onRefresh: () async {
        ref.invalidate(myPostsProvider);
        try {
          await ref.read(myPostsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: posts.when(
        loading: () => const LoadingSkeleton(count: 4),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(myPostsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ بابەتێکت نییە',
              message: 'بابەتی نوێ زیاد بکە تا لێرە دەربکەوێت.',
              icon: Icons.inventory_2_outlined,
            );
          }
          return Column(
            children: [
              for (final post in items) ...[
                PostCard(
                  post: post,
                  onDetails: () => context.push('${AppRoutes.post}/${post.id}'),
                  onContact: () => context.push('${AppRoutes.post}/${post.id}'),
                ),
                ActionChipBar(
                  actions: [
                    ActionChipData(
                      label: Ku.edit,
                      icon: Icons.edit_rounded,
                      onPressed: () => _edit(context, ref, post),
                    ),
                    // Only offer transitions that change something: marking an
                    // already-returned post as returned was previously possible
                    // and silently did nothing.
                    if (post.status != PostStatus.returned)
                      ActionChipData(
                        label: 'گەڕێنراوەتەوە',
                        icon: Icons.assignment_turned_in_rounded,
                        onPressed: () =>
                            _setStatus(context, ref, post, PostStatus.returned),
                      ),
                    if (post.status != PostStatus.closed)
                      ActionChipData(
                        label: 'داخستن',
                        icon: Icons.lock_rounded,
                        onPressed: () =>
                            _setStatus(context, ref, post, PostStatus.closed),
                      )
                    else
                      ActionChipData(
                        label: 'کردنەوە',
                        icon: Icons.lock_open_rounded,
                        onPressed: () =>
                            _setStatus(context, ref, post, PostStatus.pending),
                      ),
                    ActionChipData(
                      label: Ku.delete,
                      icon: Icons.delete_rounded,
                      destructive: true,
                      onPressed: () => _delete(context, ref, post),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The values returned by [_EditPostDialog].
class _EditedPost {
  const _EditedPost({
    required this.title,
    required this.description,
    required this.city,
    required this.area,
    required this.locationText,
  });

  final String title;
  final String description;
  final String city;
  final String area;
  final String locationText;
}

/// Edit form for a post the user owns.
///
/// A real widget rather than an inline `showDialog` closure, so its five text
/// controllers are disposed instead of leaking on every open.
class _EditPostDialog extends StatefulWidget {
  const _EditPostDialog({required this.post});

  final PostModel post;

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final _title = TextEditingController(text: widget.post.title);
  late final _description = TextEditingController(
    text: widget.post.description,
  );
  late final _area = TextEditingController(text: widget.post.area);
  late final _location = TextEditingController(text: widget.post.locationText);
  late String _city = widget.post.city;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _area.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('دەستکاری بابەت'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'ناونیشان'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'وەسف'),
            ),
            const SizedBox(height: 10),
            CityDropdown(
              value: _city,
              onChanged: (value) => setState(() => _city = value ?? _city),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'ناوچە'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'شوێن'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Ku.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            _EditedPost(
              title: _title.text.trim(),
              description: _description.text.trim(),
              city: _city,
              area: _area.text.trim(),
              locationText: _location.text.trim(),
            ),
          ),
          child: const Text(Ku.save),
        ),
      ],
    );
  }
}
