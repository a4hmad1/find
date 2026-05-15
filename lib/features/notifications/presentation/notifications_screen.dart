import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<AppNotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _canUseAccount()
        ? ref.read(notificationsRepositoryProvider).list()
        : Future.value(const <AppNotificationModel>[]);
  }

  bool _canUseAccount() {
    if (!ref.read(supabaseConfiguredProvider)) return false;
    return ref.read(supabaseClientProvider).auth.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
      return AppScaffold(
        title: 'ئاگادارییەکان',
        child: GuestModeView(
          title: 'هیچ ئاگادارییەک نییە',
          message: 'ئاگادارییە تایبەتەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.notifications_none_rounded,
          actionLabel: 'سەرەکی',
          onAction: () => context.go(AppRoutes.home),
        ),
      );
    }

    return AppScaffold(
      title: 'ئاگادارییەکان',
      child: FutureBuilder<List<AppNotificationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 5);
          }
          if (snapshot.hasError) return const ErrorView();
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ ئاگادارییەک نییە',
              message: 'ئاگادارییە گرنگەکان لێرە دەردەکەون.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return Column(
            children: items
                .map(
                  (item) => NotificationTile(
                    notification: item,
                    onTap: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markRead(item.id);
                      if (!context.mounted) return;
                      if (item.relatedPostId != null) {
                        context.push('${AppRoutes.post}/${item.relatedPostId}');
                      }
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
