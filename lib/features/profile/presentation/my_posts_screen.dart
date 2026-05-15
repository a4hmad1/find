import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  late Future<List<PostModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _canUseAccount() {
    if (!ref.read(supabaseConfiguredProvider)) return false;
    return ref.read(supabaseClientProvider).auth.currentUser != null;
  }

  void _load() {
    _future = _canUseAccount()
        ? ref.read(profileRepositoryProvider).myPosts()
        : Future.value(const <PostModel>[]);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _status(PostModel post, String status) async {
    await ref.read(postsRepositoryProvider).updateStatus(post.id, status);
    await _refresh();
  }

  Future<void> _delete(PostModel post) async {
    final ok = await showConfirmationDialog(
      context: context,
      title: Ku.deleteConfirm,
      message: 'ئەم کردارە ناگەڕێتەوە.',
    );
    if (!ok) return;
    await ref.read(postsRepositoryProvider).deletePost(post.id);
    await _refresh();
  }

  Future<void> _edit(PostModel post) async {
    final title = TextEditingController(text: post.title);
    final description = TextEditingController(text: post.description);
    final area = TextEditingController(text: post.area);
    final location = TextEditingController(text: post.locationText);
    String city = post.city;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('دەستکاری بابەت'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'ناونیشان'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'وەسف'),
                ),
                const SizedBox(height: 10),
                CityDropdown(
                  value: city,
                  onChanged: (value) =>
                      setDialogState(() => city = value ?? city),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: area,
                  decoration: const InputDecoration(labelText: 'ناوچە'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'شوێن'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(Ku.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(Ku.save),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await ref
          .read(postsRepositoryProvider)
          .updateOwnPost(
            postId: post.id,
            title: title.text.trim(),
            description: description.text.trim(),
            city: city,
            area: area.text.trim(),
            locationText: location.text.trim(),
          );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
      return AppScaffold(
        title: Ku.myPosts,
        child: GuestModeView(
          title: Ku.myPosts,
          message: 'بابەتە تایبەتەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.inventory_2_outlined,
          actionLabel: Ku.home,
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return AppScaffold(
      title: Ku.myPosts,
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
              title: 'هیچ بابەتێکت نییە',
              message: 'بابەتی نوێ زیاد بکە تا لێرە دەربکەوێت.',
              icon: Icons.inventory_2_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Column(
                  children: [
                    PostCard(
                      post: post,
                      onDetails: () =>
                          context.push('${AppRoutes.post}/${post.id}'),
                      onContact: () =>
                          context.push('${AppRoutes.post}/${post.id}'),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _edit(post),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text(Ku.edit),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _status(post, DbValues.returned),
                          icon: const Icon(Icons.assignment_turned_in_rounded),
                          label: const Text('گەڕێنراوەتەوە'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _status(post, DbValues.closed),
                          icon: const Icon(Icons.lock_rounded),
                          label: const Text('داخستن'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _status(post, DbValues.pending),
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('کردنەوە'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _delete(post),
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text(Ku.delete),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
