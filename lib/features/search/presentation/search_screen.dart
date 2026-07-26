import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/domain/post_status.dart';
import '../../../core/domain/post_type.dart';
import '../../../core/domain/sort_option.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/kurdish_date_picker.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../posts/data/posts_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();

  /// The criteria currently being displayed.
  ///
  /// Results come from `searchResultsProvider`, which is keyed by this value —
  /// so updating it is the whole of "run a search". The screen no longer owns a
  /// `Future` field, which is what previously made it possible for a slow
  /// response to overwrite a newer one.
  PostQuery _query = const PostQuery();
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;

    // Deep links and the home screen arrive with criteria in the URL.
    final params = GoRouterState.of(context).uri.queryParameters;
    _queryController.text = params['q'] ?? '';
    _query = PostQuery(
      text: params['q'] ?? '',
      postType: PostType.tryParse(params['type']),
      urgentOnly: params['urgent'] == 'true',
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _apply(PostQuery query) => setState(() => _query = query);

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<PostQuery>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FilterSheet(initial: _query),
    );
    if (result != null) _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_query));

    return AppScaffold(
      title: 'گەڕان لە بابەتەکان',
      onRefresh: () async {
        ref.invalidate(searchResultsProvider(_query));
        try {
          await ref.read(searchResultsProvider(_query).future);
        } on Object {
          // The results block renders the error itself.
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KurdishSearchBar(
            controller: _queryController,
            hint: 'گەڕان بە ناونیشان، وەسف، یان شار',
            hasActiveFilters: _query.hasActiveFilters,
            onSubmitted: (value) => _apply(_query.copyWith(text: value)),
            onFilter: _showFilters,
          ),
          const SizedBox(height: 12),
          if (_query.hasActiveFilters)
            _ActiveFilters(
              query: _query,
              onClear: () => _apply(PostQuery(text: _queryController.text)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ئەنجامەکان',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (results.value case final items?)
                Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          results.when(
            loading: () => const LoadingSkeleton(count: 4),
            error: (error, _) => ErrorView.failure(
              AppFailure.from(error),
              onRetry: () => ref.invalidate(searchResultsProvider(_query)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  message: 'هیچ ئەنجامێک نەدۆزرایەوە. فلتەرەکان بگۆڕە.',
                );
              }
              return Column(
                children: [
                  for (final post in items)
                    PostCard(
                      post: post,
                      onDetails: () =>
                          context.push('${AppRoutes.post}/${post.id}'),
                      onContact: () =>
                          context.push('${AppRoutes.post}/${post.id}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Summary chips for the filters in effect, with a way to clear them.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.query, required this.onClear});

  final PostQuery query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (query.postType case final type?) CategoryChip(label: type.label),
        if (query.status case final status?) CategoryChip(label: status.label),
        if (query.city case final city? when city.isNotEmpty)
          CategoryChip(label: city),
        if (query.itemType case final item? when item.isNotEmpty)
          CategoryChip(label: item),
        if (query.date case final date?)
          CategoryChip(label: DateFormatters.date(date)),
        if (query.urgentOnly) const CategoryChip(label: 'گرنگ'),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear_rounded, size: 18),
          label: const Text('لابردنی فلتەرەکان'),
        ),
      ],
    );
  }
}

/// Bottom sheet for editing search criteria.
///
/// Edits a local copy and returns it on apply, so dismissing the sheet leaves
/// the active search untouched. The previous version mutated the screen's
/// fields directly from inside a `StatefulBuilder`, which meant swiping the
/// sheet away still changed the filters.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final PostQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PostQuery _draft = widget.initial;

  Future<void> _pickDate() async {
    final result = await showKurdishDatePicker(
      context: context,
      initialDate: _draft.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (result == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(date: () => result));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'فلتەرەکان',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            LabeledDropdown<PostType>(
              label: 'جۆری بابەت',
              value: _draft.postType,
              items: PostType.values,
              labelOf: (type) => type.label,
              allowAll: true,
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(postType: () => value),
              ),
            ),
            const SizedBox(height: 12),
            CityDropdown(
              value: _draft.city,
              allowAll: true,
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(city: () => value)),
            ),
            const SizedBox(height: 12),
            ItemTypeDropdown(
              value: _draft.itemType,
              allowAll: true,
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(itemType: () => value),
              ),
            ),
            const SizedBox(height: 12),
            LabeledDropdown<PostStatus>(
              label: 'دۆخ',
              value: _draft.status,
              items: PostStatus.selectable,
              labelOf: (status) => status.label,
              allowAll: true,
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(status: () => value)),
            ),
            const SizedBox(height: 12),
            LabeledDropdown<SortOption>(
              label: 'ڕیزکردن',
              value: _draft.sort,
              items: SortOption.values,
              labelOf: (option) => option.label,
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(sort: value ?? _draft.sort),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _draft.urgentOnly,
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(urgentOnly: value)),
              title: const Text('تەنها بابەتە گرنگەکان'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('ڕێکەوت'),
              subtitle: Text(DateFormatters.date(_draft.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_draft.date != null)
                    IconButton(
                      tooltip: 'لابردن',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(
                        () => _draft = _draft.copyWith(date: () => null),
                      ),
                    ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('دیاریکردن'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: Ku.filter,
              icon: Icons.tune_rounded,
              onPressed: () => Navigator.of(context).pop(_draft),
            ),
          ],
        ),
      ),
    );
  }
}
