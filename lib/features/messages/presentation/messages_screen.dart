import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late Future<List<ConversationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _canUseAccount()
        ? ref.read(messagesRepositoryProvider).conversations()
        : Future.value(const <ConversationModel>[]);
  }

  bool _canUseAccount() {
    if (!ref.read(supabaseConfiguredProvider)) return false;
    return ref.read(supabaseClientProvider).auth.currentUser != null;
  }

  Future<void> _refresh() async {
    if (!_canUseAccount()) return;
    setState(() {
      _future = ref.read(messagesRepositoryProvider).conversations();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
      return AppScaffold(
        title: 'نامەکان',
        child: GuestModeView(
          title: 'نامەکان لە دۆخی میواندا داخراون',
          message:
              'دەتوانیت بابەتە گشتییەکان ببینیت، بەڵام نامە و گفتوگۆ پێویستی بە ناسنامەی پشتڕاستکراو هەیە.',
          icon: Icons.chat_bubble_outline_rounded,
          actionLabel: 'سەرەکی',
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return AppScaffold(
      title: 'نامەکان',
      child: FutureBuilder<List<ConversationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 5);
          }
          if (snapshot.hasError) return const ErrorView();
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ نامەیەک نییە',
              message: 'کاتێک کەسێک پەیوەندی بکات، لێرە دەردەکەوێت.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.chat_rounded, color: AppColors.primary),
                  ),
                  title: const Text(
                    'گفتوگۆی بابەت',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(item.lastMessage ?? 'هیچ نامەیەک نییە'),
                  trailing: Text(DateFormatters.date(item.lastMessageAt)),
                  onTap: () => context.push('${AppRoutes.messages}/${item.id}'),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemCount: items.length,
            ),
          );
        },
      ),
    );
  }
}
