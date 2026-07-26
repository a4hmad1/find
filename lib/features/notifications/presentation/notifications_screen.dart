import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel notification,
  ) async {
    // Navigate first: the read receipt is bookkeeping and should not delay the
    // tap, nor block it if the write fails. `push` returns the popped result,
    // which nothing here needs.
    if (notification.opensPost) {
      unawaited(
        context.push('${AppRoutes.post}/${notification.relatedPostId}'),
      );
    }
    if (notification.isRead) return;

    try {
      await ref.read(notificationsRepositoryProvider).markRead(notification.id);
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(unreadNotificationsProvider);
    } on AppFailure {
      // Not worth surfacing; the badge corrects itself on the next load.
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(unreadNotificationsProvider);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signedInProvider)) {
      return const AppScaffold(
        title: Ku.notifications,
        child: GuestModeView(
          title: 'هیچ ئاگادارییەک نییە',
          message: 'ئاگادارییە تایبەتەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.notifications_none_rounded,
        ),
      );
    }

    final notifications = ref.watch(notificationsProvider);
    final hasUnread = (ref.watch(unreadNotificationsProvider).value ?? 0) > 0;

    return AppScaffold(
      title: Ku.notifications,
      actions: [
        if (hasUnread)
          IconButton(
            tooltip: 'هەموو خوێندراوە',
            onPressed: () => _markAllRead(context, ref),
            icon: const Icon(Icons.done_all_rounded),
          ),
      ],
      onRefresh: () async {
        ref
          ..invalidate(notificationsProvider)
          ..invalidate(unreadNotificationsProvider);
        try {
          await ref.read(notificationsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: notifications.when(
        loading: () => const LoadingSkeleton(count: 5),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ ئاگادارییەک نییە',
              message: 'ئاگادارییە گرنگەکان لێرە دەردەکەون.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return Column(
            children: [
              for (final item in items)
                NotificationTile(
                  notification: item,
                  onTap: () => _open(context, ref, item),
                ),
            ],
          );
        },
      ),
    );
  }
}
