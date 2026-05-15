import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaticPage(
      title: Ku.about,
      icon: Icons.info_rounded,
      paragraphs: [
        'Find خزمەتگوزارییەکی گشتییە بۆ یارمەتیدانی هاووڵاتیان لە دۆزینەوە و گەڕاندنەوەی شتە ونبوو، دزراو، یان دۆزراوەکان.',
        'ئامانجمان دروستکردنی ژینگەیەکی پاک، ڕێکخراو و باوەڕپێکراوە بۆ ئەوەی خاوەنە ڕاستەقینەکان بە ئاسانی پەیوەندی بکەن.',
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaticPage(
      title: Ku.privacy,
      icon: Icons.privacy_tip_rounded,
      paragraphs: [
        'زانیارییە تایبەتییەکانت بەبێ ڕێگەپێدانت بە ئاشکرا نیشان نادرێن.',
        'زانیاری GitHub تەنها بۆ دروستکردنی هەژمار، دڵنیابوون لە ناسنامە، و پاراستنی خزمەتگوزارییەکە بەکاردێت.',
        'دەتوانیت لە ڕێکخستنەکان داوای ڕاگرتنی هەژمار بکەیت.',
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StaticPage(
      title: Ku.terms,
      icon: Icons.gavel_rounded,
      paragraphs: [
        'بابەتەکان دەبێت ڕاست، ڕوون و بە وێنەی گونجاوەوە بن.',
        'هەوڵی فێڵکردن، زانیاری ساختە، یان بەکارهێنانی شتی دزراو بۆ مەبەستی خراپ قەدەغەیە.',
        'بەڕێوەبەر دەتوانێت بابەتی گومانلێکراو داخات، ڕەتبکاتەوە، یان بسڕێتەوە.',
      ],
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPage(
      title: Ku.help,
      icon: Icons.help_rounded,
      paragraphs: const [
        'بۆ زیادکردنی بابەت، جۆری بابەت، جۆری شت، شار، وێنە و وەسفی ورد پڕبکەرەوە.',
        'کاتێک پەیوەندی بە کەسێک دەکەیت، پێش وەرگرتنەوەی شت زانیارییەکان پشتڕاست بکەرەوە.',
        'ئەگەر بابەتێک ساختە یان گومانلێکراو بوو، ڕاپۆرتی بکە.',
        'بۆ پشتگیری، لە ڕێگەی بەشی نامەکان پەیوەندی بە بەڕێوەبەر بکە.',
      ],
      footer: PrimaryButton(
        label: 'زیادکردنی بابەت',
        icon: Icons.add_rounded,
        onPressed: () => context.go(AppRoutes.addPost),
      ),
    );
  }
}

class _StaticPage extends StatelessWidget {
  const _StaticPage({
    required this.title,
    required this.icon,
    required this.paragraphs,
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfficialHeader(
            title: title,
            subtitle: 'زانیارییە فەرمییەکانی خزمەتگوزاری Find.',
            trailing: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          ...paragraphs.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.9),
              ),
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
