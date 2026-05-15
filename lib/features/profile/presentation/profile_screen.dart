import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return AppScaffold(
      title: 'هەژمارەکەم',
      child: profile.when(
        data: (value) {
          if (value == null) {
            return const _GuestProfileContent();
          }
          return _ProfileContent(
            profile: value,
            onLogout: () => _logout(context, ref),
          );
        },
        loading: () => const LoadingSkeleton(count: 4),
        error: (error, stackTrace) => const ErrorView(),
      ),
    );
  }
}

class _GuestProfileContent extends StatelessWidget {
  const _GuestProfileContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GuestModeView(
          title: 'دۆخی میوان',
          message:
              'ئەپەکە بەبێ چوونەژوورەوە دەکرێت بەکاربهێنرێت. بەشە تایبەتەکان وەک بابەتەکانم و پاشەکەوتکراوەکان لە دۆخی میواندا بەردەست نین.',
          icon: Icons.person_outline_rounded,
        ),
        _MenuTile(
          icon: Icons.settings_rounded,
          title: Ku.settings,
          onTap: () => context.push(AppRoutes.settings),
        ),
        _MenuTile(
          icon: Icons.info_rounded,
          title: Ku.about,
          onTap: () => context.push(AppRoutes.about),
        ),
        _MenuTile(
          icon: Icons.privacy_tip_rounded,
          title: Ku.privacy,
          onTap: () => context.push(AppRoutes.privacy),
        ),
        _MenuTile(
          icon: Icons.help_outline_rounded,
          title: Ku.help,
          onTap: () => context.push(AppRoutes.help),
        ),
      ],
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onLogout});

  final ProfileModel profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ProfileAvatar(profile: profile, radius: 42),
              const SizedBox(height: 12),
              Text(
                profile.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.githubUsername}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              StatusBadge(
                status: profile.isBanned ? DbValues.closed : DbValues.approved,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MenuTile(
          icon: Icons.inventory_2_rounded,
          title: Ku.myPosts,
          onTap: () => context.push(AppRoutes.myPosts),
        ),
        _MenuTile(
          icon: Icons.bookmarks_rounded,
          title: Ku.savedPosts,
          onTap: () => context.push(AppRoutes.saved),
        ),
        _MenuTile(
          icon: Icons.chat_rounded,
          title: Ku.messages,
          onTap: () => context.go(AppRoutes.messages),
        ),
        _MenuTile(
          icon: Icons.settings_rounded,
          title: Ku.settings,
          onTap: () => context.push(AppRoutes.settings),
        ),
        if (profile.isAdmin)
          _MenuTile(
            icon: Icons.admin_panel_settings_rounded,
            title: Ku.admin,
            onTap: () => context.push(AppRoutes.admin),
          ),
        _MenuTile(
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    );
  }
}
