import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _sendAnnouncement(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_Announcement>(
      context: context,
      builder: (dialogContext) => const _AnnouncementDialog(),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(adminRepositoryProvider)
          .sendAnnouncement(title: result.title, body: result.body);
      if (!context.mounted) return;
      // The previous version awaited this and then said nothing at all, so a
      // moderator could not tell whether the broadcast had gone out.
      showMessageSnackBar(context, 'ئاگادارکردنەوەکە نێردرا');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return AppScaffold(
      title: Ku.adminDashboard,
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        try {
          await ref.read(adminStatsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: stats.when(
        loading: () => const LoadingSkeleton(count: 3),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(adminStatsProvider),
        ),
        data: (value) => _Dashboard(
          stats: value,
          onAnnounce: () => _sendAnnouncement(context, ref),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.stats, required this.onAnnounce});

  final AdminStats stats;
  final VoidCallback onAnnounce;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfficialHeader(
          title: Ku.adminDashboard,
          subtitle: 'چاودێری بابەتەکان، ڕاپۆرتەکان و بەکارهێنەران لە یەک شوێن.',
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            StatCard(
              title: 'هەموو بابەتەکان',
              value: '${stats.posts}',
              icon: Icons.inventory_2_rounded,
            ),
            StatCard(
              title: 'چاوەڕوان',
              value: '${stats.pendingPosts}',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
            ),
            StatCard(
              title: 'ڕاپۆرت',
              value: '${stats.openReports}',
              icon: Icons.flag_rounded,
              color: AppColors.danger,
            ),
            StatCard(
              title: 'بەکارهێنەر',
              value: '${stats.users}',
              icon: Icons.people_rounded,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 18),
        MenuTile(
          icon: Icons.fact_check_rounded,
          title: Ku.adminPosts,
          badgeCount: stats.pendingPosts,
          onTap: () => context.push(AppRoutes.adminPosts),
        ),
        MenuTile(
          icon: Icons.report_rounded,
          title: Ku.adminReports,
          badgeCount: stats.openReports,
          onTap: () => context.push(AppRoutes.adminReports),
        ),
        MenuTile(
          icon: Icons.people_rounded,
          title: Ku.adminUsers,
          onTap: () => context.push(AppRoutes.adminUsers),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: Ku.adminNotice,
          icon: Icons.campaign_rounded,
          onPressed: onAnnounce,
        ),
      ],
    );
  }
}

class _Announcement {
  const _Announcement({required this.title, required this.body});

  final String title;
  final String body;
}

/// Compose form for a broadcast notification.
///
/// Validates before returning, so the caller cannot send the empty announcement
/// the previous inline dialog silently allowed.
class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog();

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Ku.adminNotice),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'ناونیشان'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'تکایە ناونیشان بنووسە'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _body,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'دەق'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'تکایە دەق بنووسە' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Ku.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _Announcement(title: _title.text.trim(), body: _body.text.trim()),
            );
          },
          child: const Text('ناردن'),
        ),
      ],
    );
  }
}
