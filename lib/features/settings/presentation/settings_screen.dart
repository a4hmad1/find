import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deleting = false;

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'سڕینەوەی هەژمار',
      // Says what actually happens: this is a deactivation, not a hard delete,
      // because posts and threads other people rely on stay in place.
      message:
          'هەژمارەکەت ڕادەگیرێت و دەردەچیت. ناتوانیت بابەت یان نامە بنێریت، بەڵام بابەتە پێشووەکانت لە سیستەم دەمێننەوە.',
      confirmLabel: Ku.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final signedIn = ref.watch(signedInProvider);

    return AppScaffold(
      title: Ku.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OfficialHeader(
            title: 'ڕێکخستنەکان',
            subtitle: 'زمانی ئەپەکە بۆ ئێستا تەنها کوردیی سۆرانییە.',
          ),
          const SizedBox(height: 18),
          Text(
            'ڕووکار',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('ڕووناک')),
                ButtonSegment(value: ThemeMode.dark, label: Text('تاریک')),
                ButtonSegment(value: ThemeMode.system, label: Text('سیستەم')),
              ],
              selected: {themeMode},
              onSelectionChanged: (values) =>
                  ref.read(themeModeProvider.notifier).setMode(values.first),
            ),
          ),
          const Divider(height: 28),
          // The notification and contact-privacy switches that used to sit here
          // were pure local state: toggling them changed nothing on the server
          // and reset on restart. They are gone rather than left as decoration;
          // contact visibility is already a real, persisted per-post setting on
          // the add-post screen.
          _SettingsTile(title: Ku.privacy, route: AppRoutes.privacy),
          _SettingsTile(title: Ku.terms, route: AppRoutes.terms),
          _SettingsTile(title: Ku.help, route: AppRoutes.help),
          _SettingsTile(title: Ku.about, route: AppRoutes.about),
          if (signedIn) ...[
            const Divider(height: 28),
            SecondaryButton(
              label: 'سڕینەوەی هەژمار',
              icon: Icons.delete_forever_rounded,
              loading: _deleting,
              onPressed: _deleteAccount,
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.title, required this.route});

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return MenuTile(title: title, onTap: () => context.push(route));
  }
}
