import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminPostsScreen extends ConsumerStatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  ConsumerState<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends ConsumerState<AdminPostsScreen> {
  late Future<List<PostModel>> _future;
  String? _status = DbValues.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(adminRepositoryProvider).posts(status: _status);
  }

  Future<void> _update(PostModel post, String status) async {
    await ref.read(adminRepositoryProvider).updatePostStatus(post.id, status);
    setState(_load);
  }

  Future<void> _delete(PostModel post) async {
    final ok = await showConfirmationDialog(
      context: context,
      title: Ku.deleteConfirm,
      message: 'بابەتەکە لە سیستەم دەسڕدرێتەوە.',
    );
    if (!ok) {
      return;
    }
    await ref.read(adminRepositoryProvider).deletePost(post.id);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.adminPosts,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _status ?? '',
            decoration: const InputDecoration(labelText: 'دۆخ'),
            items: [
              const DropdownMenuItem(value: '', child: Text('هەموو')),
              const DropdownMenuItem(
                value: DbValues.pending,
                child: Text('چاوەڕوانە'),
              ),
              const DropdownMenuItem(
                value: DbValues.approved,
                child: Text('پشتڕاستکراوە'),
              ),
              const DropdownMenuItem(
                value: DbValues.rejected,
                child: Text('پەسەند نەکرا'),
              ),
              const DropdownMenuItem(
                value: DbValues.closed,
                child: Text('داخراوە'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _status = value?.isEmpty == true ? null : value;
                _load();
              });
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<PostModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingSkeleton(count: 5);
              }
              if (snapshot.hasError) {
                return const ErrorView(message: Ku.notAllowed);
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const EmptyState();
              }
              return Column(
                children: posts.map((post) {
                  return Column(
                    children: [
                      PostCard(
                        post: post,
                        compact: true,
                        onDetails: () =>
                            context.push('${AppRoutes.post}/${post.id}'),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _update(post, DbValues.approved),
                            icon: const Icon(Icons.verified_rounded),
                            label: const Text('پشتڕاستکردنەوە'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _update(post, DbValues.rejected),
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('ڕەتکردنەوە'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _update(post, DbValues.closed),
                            icon: const Icon(Icons.lock_rounded),
                            label: const Text('داخستن'),
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
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
