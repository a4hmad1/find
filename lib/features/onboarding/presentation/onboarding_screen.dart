import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _IntroPage(
      title: 'شتە ونبووەکان زوو بدۆزەرەوە',
      body: 'بابەتە نوێ و گرنگەکان لە یەک شوێندا دەبینیت.',
      imageUrl:
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=1200&q=80',
      icon: Icons.search_rounded,
      color: AppColors.primary,
    ),
    _IntroPage(
      title: 'دۆزراوەکەت بە ئاسانی بنێرە',
      body: 'وێنە، شار، ڕێکەوت و ژمارەی پەیوەندی زیاد بکە.',
      imageUrl:
          'https://images.unsplash.com/photo-1523206489230-c012c64b2b48?auto=format&fit=crop&w=1200&q=80',
      icon: Icons.add_photo_alternate_rounded,
      color: AppColors.rose,
    ),
    _IntroPage(
      title: 'بەبێ چوونەژوورەوە دەستپێبکە',
      body: 'ئەپەکە وەک میوانیش کاردەکات و نموونەی ئامادەی هەیە.',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80',
      icon: Icons.favorite_rounded,
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_index == _pages.length - 1) {
      context.go(AppRoutes.home);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final page = _pages[_index];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              child: CachedNetworkImage(
                key: ValueKey(page.imageUrl),
                imageUrl: page.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.primarySoft,
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.primarySoft,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: isDark ? 0.72 : 0.55),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Ku.appName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text(
                          'تێپەڕاندن',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 330,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        return _IntroContent(page: _pages[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProgressBar(value: (_index + 1) / _pages.length),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _continue,
                    icon: Icon(
                      _index == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    label: Text(
                      _index == _pages.length - 1 ? 'دەستپێکردن' : 'دواتر',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.page});

  final _IntroPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: page.color,
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            page.title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.body,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value,
        backgroundColor: Colors.white.withValues(alpha: 0.22),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final String imageUrl;
  final IconData icon;
  final Color color;
}
