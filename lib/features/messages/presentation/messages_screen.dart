import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/widgets/app_widgets.dart';

/// List of the user's message threads.
///
/// Reads from `conversationsProvider` rather than kicking off a future in
/// `initState`. That removes the stale-list bug where signing in or out left
/// the previous account's threads on screen until the tab was rebuilt.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signedInProvider)) {
      return const AppScaffold(
        title: Ku.messages,
        child: GuestModeView(
          title: 'نامەکان لە دۆخی میواندا داخراون',
          message:
              'دەتوانیت بابەتە گشتییەکان ببینیت، بەڵام گفتوگۆ پێویستی بە ناسنامەی پشتڕاستکراو هەیە.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }

    final conversations = ref.watch(conversationsProvider);

    return AppScaffold(
      title: Ku.messages,
      onRefresh: () async {
        ref.invalidate(conversationsProvider);
        try {
          await ref.read(conversationsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: conversations.when(
        loading: () => const LoadingSkeleton(count: 5),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ نامەیەک نییە',
              message: 'کاتێک کەسێک پەیوەندی بکات، لێرە دەردەکەوێت.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }
          return Column(
            children: [
              for (final item in items) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.chat_rounded, color: AppColors.primary),
                  ),
                  title: const Text(
                    'گفتوگۆی بابەت',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    item.lastMessage ?? 'هیچ نامەیەک نییە',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormatters.date(item.lastMessageAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  onTap: () => context.push('${AppRoutes.messages}/${item.id}'),
                ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}
