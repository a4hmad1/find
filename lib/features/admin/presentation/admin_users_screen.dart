import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  Future<void> _setBanned(
    BuildContext context,
    WidgetRef ref,
    ProfileModel user, {
    required bool banned,
  }) async {
    // Banning is disruptive and easy to mis-tap in a long list, so confirm it.
    if (banned) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'ڕاگرتنی بەکارهێنەر',
        message:
            '${user.resolvedDisplayName} ناتوانێت بابەت یان نامە بنێرێت. دەتوانیت دواتر لایببەیت.',
        confirmLabel: 'ڕاگرتن',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }

    try {
      await ref.read(adminRepositoryProvider).banUser(user.id, banned: banned);
      ref
        ..invalidate(adminUsersProvider)
        ..invalidate(adminStatsProvider);
      if (!context.mounted) return;
      showMessageSnackBar(
        context,
        banned ? 'بەکارهێنەر ڕاگیرا' : 'ڕاگرتنەکە لابرا',
      );
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);

    return AppScaffold(
      title: Ku.adminUsers,
      onRefresh: () async {
        ref.invalidate(adminUsersProvider);
        try {
          await ref.read(adminUsersProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: users.when(
        loading: () => const LoadingSkeleton(count: 5),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const EmptyState();
          return Column(
            children: [
              for (final user in items)
                Card(
                  child: ListTile(
                    leading: ProfileAvatar(profile: user),
                    title: Text(
                      user.resolvedDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@${user.githubUsername}',
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.role.label,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _setBanned(
                        context,
                        ref,
                        user,
                        banned: !user.isBanned,
                      ),
                      style: user.isBanned
                          ? null
                          : OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                      child: Text(user.isBanned ? 'لابردنی ڕاگرتن' : 'ڕاگرتن'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
