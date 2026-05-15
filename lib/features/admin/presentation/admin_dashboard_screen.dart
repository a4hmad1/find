import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Future<Map<String, int>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).stats();
  }

  Future<void> _announcement() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Ku.adminNotice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'ناونیشان'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: body,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'دەق'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Ku.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ناردن'),
          ),
        ],
      ),
    );
    if (ok == true &&
        title.text.trim().isNotEmpty &&
        body.text.trim().isNotEmpty) {
      await ref
          .read(adminRepositoryProvider)
          .sendAnnouncement(title: title.text.trim(), body: body.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.adminDashboard,
      child: FutureBuilder<Map<String, int>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 3);
          }
          if (snapshot.hasError) {
            return const ErrorView(message: Ku.notAllowed);
          }
          final stats = snapshot.data ?? {};
          return Column(
            children: [
              const OfficialHeader(
                title: Ku.adminDashboard,
                subtitle:
                    'چاودێری بابەتەکان، ڕاپۆرتەکان و بەکارهێنەران لە یەک شوێن.',
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
                  AdminStatCard(
                    title: 'هەموو بابەتەکان',
                    value: '${stats['posts'] ?? 0}',
                    icon: Icons.inventory_2_rounded,
                  ),
                  AdminStatCard(
                    title: 'چاوەڕوان',
                    value: '${stats['pending'] ?? 0}',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                  ),
                  AdminStatCard(
                    title: 'ڕاپۆرت',
                    value: '${stats['reports'] ?? 0}',
                    icon: Icons.flag_rounded,
                    color: AppColors.danger,
                  ),
                  AdminStatCard(
                    title: 'بەکارهێنەر',
                    value: '${stats['users'] ?? 0}',
                    icon: Icons.people_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AdminTile(
                title: Ku.adminPosts,
                icon: Icons.fact_check_rounded,
                route: AppRoutes.adminPosts,
              ),
              _AdminTile(
                title: Ku.adminReports,
                icon: Icons.report_rounded,
                route: AppRoutes.adminReports,
              ),
              _AdminTile(
                title: Ku.adminUsers,
                icon: Icons.people_rounded,
                route: AppRoutes.adminUsers,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: Ku.adminNotice,
                icon: Icons.campaign_rounded,
                onPressed: _announcement,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () => context.push(route),
    );
  }
}
