import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch(String value) {
    final q = Uri.encodeComponent(value.trim());
    context.go(q.isEmpty ? AppRoutes.search : '${AppRoutes.search}?q=$q');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final stats = ref.watch(postStatsProvider);
    final urgent = ref.watch(urgentPostsProvider);
    final recent = ref.watch(recentPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(postStatsProvider);
        ref.invalidate(urgentPostsProvider);
        ref.invalidate(recentPostsProvider);
      },
      child: AppScaffold(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfficialHeader(
              title: profile.maybeWhen(
                data: (value) => value == null
                    ? 'بەخێربێیت'
                    : 'بەخێربێیت، ${value.displayName}',
                orElse: () => 'بەخێربێیت',
              ),
              subtitle:
                  'خزمەتگوزارییەکی گشتی بۆ دۆزینەوە و گەڕاندنەوەی شتەکان.',
              trailing: IconButton.filledTonal(
                tooltip: Ku.notifications,
                onPressed: () => context.push(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_rounded),
              ),
            ),
            const SizedBox(height: 18),
            KurdishSearchBar(
              controller: _search,
              onSubmitted: _runSearch,
              onFilter: () => context.go(AppRoutes.search),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppLists.postTypes
                  .map(
                    (type) => InkWell(
                      onTap: () => context.go('${AppRoutes.search}?type=$type'),
                      borderRadius: BorderRadius.circular(999),
                      child: CategoryChip(
                        label: DbValues.postTypeLabels[type] ?? type,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            stats.when(
              data: _StatsGrid.new,
              loading: () => const LoadingSkeleton(count: 1),
              error: (error, stackTrace) => const ErrorView(),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'بابەتە گرنگەکان',
              onSeeAll: () => context.go('${AppRoutes.search}?urgent=true'),
            ),
            const SizedBox(height: 12),
            urgent.when(
              data: (items) => _PostList(items: items),
              loading: () => const LoadingSkeleton(count: 2),
              error: (error, stackTrace) => const ErrorView(),
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'نوێترین بابەتەکان',
              onSeeAll: () => context.go(AppRoutes.search),
            ),
            const SizedBox(height: 12),
            recent.when(
              data: (items) => _PostList(items: items),
              loading: () => const LoadingSkeleton(count: 4),
              error: (error, stackTrace) => const ErrorView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(this.stats);

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        AdminStatCard(
          title: 'ژمارەی بابەتەکان',
          value: '${stats['all'] ?? 0}',
          icon: Icons.inventory_2_rounded,
        ),
        AdminStatCard(
          title: 'شتە دۆزراوەکان',
          value: '${stats['found'] ?? 0}',
          icon: Icons.task_alt_rounded,
          color: AppColors.success,
        ),
        AdminStatCard(
          title: 'شتە ونبووەکان',
          value: '${stats['lost'] ?? 0}',
          icon: Icons.search_rounded,
          color: AppColors.warning,
        ),
        AdminStatCard(
          title: 'شتە گەڕێنراوەکان',
          value: '${stats['returned'] ?? 0}',
          icon: Icons.verified_rounded,
          color: AppColors.accent,
        ),
      ],
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

class _PostList extends StatelessWidget {
  const _PostList({required this.items});

  final List<PostModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyState();
    return Column(
      children: items
          .map(
            (post) => PostCard(
              post: post,
              onDetails: () => context.push('${AppRoutes.post}/${post.id}'),
              onContact: () => context.push('${AppRoutes.post}/${post.id}'),
            ),
          )
          .toList(),
    );
  }
}
