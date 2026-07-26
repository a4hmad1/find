import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/domain/post_type.dart';
import '../../../core/errors/app_failure.dart';
import '../../../features/posts/data/posts_repository.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch({String? text, PostType? type, bool urgentOnly = false}) {
    // Query values are encoded by `Uri`, so a search term containing `&` or `=`
    // cannot corrupt the rest of the URL.
    context.go(
      Uri(
        path: AppRoutes.search,
        queryParameters: {
          if (text != null && text.trim().isNotEmpty) 'q': text.trim(),
          if (type != null) 'type': type.wire,
          if (urgentOnly) 'urgent': 'true',
        },
      ).toString(),
    );
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(postStatsProvider)
      ..invalidate(urgentPostsProvider)
      ..invalidate(recentPostsProvider);
    // Wait for the reloads so the refresh indicator reflects real work rather
    // than disappearing immediately. Failures are swallowed here because each
    // section renders its own error state from the provider.
    try {
      await Future.wait([
        ref.read(postStatsProvider.future),
        ref.read(urgentPostsProvider.future),
        ref.read(recentPostsProvider.future),
      ]);
    } on Object {
      // Reported per-section; see above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    return AppScaffold(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfficialHeader(
            title: profile.maybeWhen(
              data: (value) => value == null
                  ? 'بەخێربێیت'
                  : 'بەخێربێیت، ${value.resolvedDisplayName}',
              orElse: () => 'بەخێربێیت',
            ),
            subtitle: 'خزمەتگوزارییەکی گشتی بۆ دۆزینەوە و گەڕاندنەوەی شتەکان.',
            trailing: Badge(
              isLabelVisible: (unread.value ?? 0) > 0,
              label: Text('${unread.value ?? 0}'),
              child: IconButton.filledTonal(
                tooltip: Ku.notifications,
                onPressed: () => context.push(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_rounded),
              ),
            ),
          ),
          const SizedBox(height: 18),
          KurdishSearchBar(
            controller: _searchController,
            onSubmitted: (value) => _openSearch(text: value),
            // Every parameter is optional, so the tearoff opens search with no
            // criteria applied.
            onFilter: _openSearch,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in PostType.values)
                CategoryChip(
                  label: type.label,
                  onTap: () => _openSearch(type: type),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _StatsSection(
            stats: ref.watch(postStatsProvider),
            onRetry: () => ref.invalidate(postStatsProvider),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'بابەتە گرنگەکان',
            onSeeAll: () => _openSearch(urgentOnly: true),
          ),
          const SizedBox(height: 12),
          _PostSection(
            posts: ref.watch(urgentPostsProvider),
            skeletonCount: 2,
            emptyMessage: 'ئێستا هیچ بابەتێکی گرنگ نییە.',
            onRetry: () => ref.invalidate(urgentPostsProvider),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'نوێترین بابەتەکان', onSeeAll: _openSearch),
          const SizedBox(height: 12),
          _PostSection(
            posts: ref.watch(recentPostsProvider),
            skeletonCount: 4,
            onRetry: () => ref.invalidate(recentPostsProvider),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.onRetry});

  final AsyncValue<Map<PostStatKey, int>> stats;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return stats.when(
      loading: () => const LoadingSkeleton(count: 1),
      error: (error, _) =>
          ErrorView.failure(AppFailure.from(error), onRetry: onRetry),
      data: (values) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: [
          StatCard(
            title: 'ژمارەی بابەتەکان',
            value: '${values[PostStatKey.all] ?? 0}',
            icon: Icons.inventory_2_rounded,
          ),
          StatCard(
            title: 'شتە دۆزراوەکان',
            value: '${values[PostStatKey.found] ?? 0}',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
          StatCard(
            title: 'شتە ونبووەکان',
            value: '${values[PostStatKey.lost] ?? 0}',
            icon: Icons.search_rounded,
            color: AppColors.warning,
          ),
          StatCard(
            title: 'شتە گەڕێنراوەکان',
            value: '${values[PostStatKey.returned] ?? 0}',
            icon: Icons.verified_rounded,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('بینینی هەموو')),
      ],
    );
  }
}

/// A list of post cards with its own loading, empty, and error states.
class _PostSection extends StatelessWidget {
  const _PostSection({
    required this.posts,
    required this.skeletonCount,
    required this.onRetry,
    this.emptyMessage,
  });

  final AsyncValue<List<PostModel>> posts;
  final int skeletonCount;
  final VoidCallback onRetry;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return posts.when(
      loading: () => LoadingSkeleton(count: skeletonCount),
      error: (error, _) =>
          ErrorView.failure(AppFailure.from(error), onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            message: emptyMessage ?? 'کاتێک بابەتێک هەبێت لێرە دەردەکەوێت.',
          );
        }
        return Column(
          children: [
            for (final post in items)
              PostCard(
                post: post,
                onDetails: () => context.push('${AppRoutes.post}/${post.id}'),
                onContact: () => context.push('${AppRoutes.post}/${post.id}'),
              ),
          ],
        );
      },
    );
  }
}
