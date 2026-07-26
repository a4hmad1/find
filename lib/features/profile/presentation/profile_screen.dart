import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/domain/post_status.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: Ku.logout,
      message: 'دڵنیایت لە چوونەدەرەوە؟',
      confirmLabel: Ku.logout,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!context.mounted) return;
      context.go(AppRoutes.home);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final unread = ref.watch(unreadNotificationsProvider).value ?? 0;

    return AppScaffold(
      title: 'هەژمارەکەم',
      child: profile.when(
        loading: () => const LoadingSkeleton(count: 4),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (value) => value == null
            ? const _GuestMenu()
            : _AccountMenu(
                profile: value,
                unreadCount: unread,
                onLogout: () => _logout(context, ref),
              ),
      ),
    );
  }
}

/// Menu shown to visitors without an account.
class _GuestMenu extends StatelessWidget {
  const _GuestMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GuestModeView(
          title: 'دۆخی میوان',
          message:
              'ئەپەکە بەبێ چوونەژوورەوە دەکرێت بەکاربهێنرێت. بەشە تایبەتەکان وەک بابەتەکانم و پاشەکەوتکراوەکان پێویستیان بە هەژمارە.',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 8),
        MenuTile(
          icon: Icons.settings_rounded,
          title: Ku.settings,
          onTap: () => context.push(AppRoutes.settings),
        ),
        MenuTile(
          icon: Icons.info_rounded,
          title: Ku.about,
          onTap: () => context.push(AppRoutes.about),
        ),
        MenuTile(
          icon: Icons.privacy_tip_rounded,
          title: Ku.privacy,
          onTap: () => context.push(AppRoutes.privacy),
        ),
        MenuTile(
          icon: Icons.help_outline_rounded,
          title: Ku.help,
          onTap: () => context.push(AppRoutes.help),
        ),
      ],
    );
  }
}

/// Menu shown to a signed-in user.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.profile,
    required this.unreadCount,
    required this.onLogout,
  });

  final ProfileModel profile;
  final int unreadCount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.hairline),
          ),
          child: Column(
            children: [
              ProfileAvatar(profile: profile, radius: 42),
              const SizedBox(height: 12),
              Text(
                profile.resolvedDisplayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.githubUsername}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              StatusBadge(
                status: profile.isBanned
                    ? PostStatus.closed
                    : PostStatus.approved,
              ),
              if (profile.role.canModerate) ...[
                const SizedBox(height: 8),
                CategoryChip(label: profile.role.label, selected: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        MenuTile(
          icon: Icons.inventory_2_rounded,
          title: Ku.myPosts,
          onTap: () => context.push(AppRoutes.myPosts),
        ),
        MenuTile(
          icon: Icons.bookmarks_rounded,
          title: Ku.savedPosts,
          onTap: () => context.push(AppRoutes.saved),
        ),
        MenuTile(
          icon: Icons.notifications_rounded,
          title: Ku.notifications,
          badgeCount: unreadCount,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        MenuTile(
          icon: Icons.chat_rounded,
          title: Ku.messages,
          onTap: () => context.go(AppRoutes.messages),
        ),
        MenuTile(
          icon: Icons.settings_rounded,
          title: Ku.settings,
          onTap: () => context.push(AppRoutes.settings),
        ),
        if (profile.isAdmin)
          MenuTile(
            icon: Icons.admin_panel_settings_rounded,
            title: Ku.admin,
            onTap: () => context.push(AppRoutes.admin),
          ),
        MenuTile(
          icon: Icons.info_rounded,
          title: Ku.about,
          onTap: () => context.push(AppRoutes.about),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: Ku.logout,
          icon: Icons.logout_rounded,
          onPressed: onLogout,
        ),
      ],
    );
  }
}
