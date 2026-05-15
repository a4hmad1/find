import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _privateContact = true;

  Future<void> _deleteAccount() async {
    if (!ref.read(supabaseConfiguredProvider) ||
        ref.read(supabaseClientProvider).auth.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لە دۆخی میواندا نییە')));
      return;
    }
    final ok = await showConfirmationDialog(
      context: context,
      title: 'سڕینەوەی هەژمار',
      message: 'هەژمارەکەت ڕادەگیرێت و ناتوانیت بابەت یان نامە بنێریت.',
    );
    if (!ok) return;
    await ref.read(profileRepositoryProvider).deleteAccount();
    if (mounted) context.go(AppRoutes.home);
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
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('ڕووناک')),
                ButtonSegment(value: ThemeMode.dark, label: Text('تاریک')),
                ButtonSegment(value: ThemeMode.system, label: Text('سیستەم')),
              ],
              selected: {themeMode},
              onSelectionChanged: (values) {
                ref.read(themeModeProvider.notifier).setMode(values.first);
              },
            ),
          ),
          const Divider(height: 28),
          SwitchListTile(
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
            title: const Text('ئاگادارییەکان'),
            subtitle: const Text('نامە و گۆڕانی دۆخی بابەت وەربگرە.'),
          ),
          SwitchListTile(
            value: _privateContact,
            onChanged: (value) => setState(() => _privateContact = value),
            title: const Text('پاراستنی زانیاری پەیوەندی'),
            subtitle: const Text(
              'زانیاری پەیوەندی تەنها بە ڕێگەپێدانت پیشان بدرێت.',
            ),
          ),
          const Divider(height: 28),
          _SettingsTile(title: Ku.privacy, route: AppRoutes.privacy),
          _SettingsTile(title: Ku.terms, route: AppRoutes.terms),
          _SettingsTile(title: Ku.help, route: AppRoutes.help),
          if (signedIn) ...[
            const SizedBox(height: 18),
            SecondaryButton(
              label: 'سڕینەوەی هەژمار',
              icon: Icons.delete_forever_rounded,
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () => context.push(route),
    );
  }
}
