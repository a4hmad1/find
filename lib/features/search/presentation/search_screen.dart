import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/kurdish_date_picker.dart';
import '../../posts/data/local_posts_store.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  Future<List<PostModel>>? _future;
  String? _city;
  String? _postType;
  String? _status;
  String? _itemType;
  DateTime? _date;
  String _sort = 'نوێترین';
  bool _urgentOnly = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    _query.text = params['q'] ?? '';
    _postType = params['type'];
    _urgentOnly = params['urgent'] == 'true';
    _search();
    _hydrated = true;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() {
    final local = searchLocalPosts(
      ref.read(localPostsProvider),
      query: _query.text,
      city: _city,
      postType: _postType,
      status: _status,
      itemType: _itemType,
      date: _date,
      sort: _sort,
    ).where((post) => !_urgentOnly || post.isUrgent).toList();

    if (!ref.read(supabaseConfiguredProvider)) {
      setState(() {
        _future = Future.value(local);
      });
      return;
    }
    setState(() {
      _future = () async {
        try {
          final remote = await ref
              .read(postsRepositoryProvider)
              .search(
                query: _query.text,
                city: _city,
                postType: _postType,
                status: _status,
                itemType: _itemType,
                date: _date,
                sort: _sort,
              );
          return [
            ...local,
            ...remote.where((post) => !_urgentOnly || post.isUrgent),
          ];
        } catch (_) {
          return local;
        }
      }();
    });
  }

  Future<void> _pickDate() async {
    final result = await showKurdishDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (result != null) {
      setState(() => _date = result);
      _search();
    }
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'فلتەرەکان',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _postType ?? '',
                      decoration: const InputDecoration(
                        labelText: 'جۆری بابەت',
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('هەموو')),
                        ...AppLists.postTypes.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(DbValues.postTypeLabels[type] ?? type),
                          ),
                        ),
                      ],
                      onChanged: (value) => setSheetState(
                        () => _postType = value?.isEmpty == true ? null : value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CityDropdown(
                      value: _city,
                      onChanged: (value) => setSheetState(() => _city = value),
                    ),
                    const SizedBox(height: 12),
                    ItemTypeDropdown(
                      value: _itemType,
                      onChanged: (value) =>
                          setSheetState(() => _itemType = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status ?? '',
                      decoration: const InputDecoration(labelText: 'دۆخ'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('هەموو')),
                        ...AppLists.statuses.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              DbValues.statusLabels[status] ?? status,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setSheetState(
                        () => _status = value?.isEmpty == true ? null : value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sort,
                      decoration: const InputDecoration(labelText: 'ڕیزکردن'),
                      items: AppLists.sortOptions
                          .map(
                            (sort) => DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => _sort = value ?? _sort),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: const Text('ڕێکەوت'),
                      subtitle: Text(DateFormatters.date(_date)),
                      trailing: TextButton(
                        onPressed: _pickDate,
                        child: const Text('دیاریکردن'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: Ku.filter,
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _search();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'گەڕان لە بابەتەکان',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KurdishSearchBar(
            controller: _query,
            onSubmitted: (_) => _search(),
            onFilter: _showFilters,
            hint: 'گەڕان بە ناونیشان، وەسف، یان شار',
          ),
          const SizedBox(height: 16),
          Text(
            'ئەنجامەکان',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PostModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingSkeleton(count: 4);
              }
              if (snapshot.hasError) return const ErrorView();
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const EmptyState();
              return Column(
                children: items
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
        ],
      ),
    );
  }
}
