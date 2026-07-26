import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// The standard page frame: optional app bar, safe area, and padding.
///
/// [scrollable] wraps the body in a scroll view. Leave it false when the child
/// manages its own scrolling — nesting a `ListView` inside this one forces
/// `shrinkWrap`, which lays out every row on every frame.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding = const EdgeInsets.all(20),
    this.scrollable = true,
    this.onRefresh,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets padding;
  final bool scrollable;

  /// Enables pull-to-refresh. Requires a scrollable body, so it implies
  /// [scrollable] when the child does not scroll itself.
  final Future<void> Function()? onRefresh;

  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(padding: padding, child: child);

    if (scrollable) {
      body = SingleChildScrollView(
        // Always scrollable so pull-to-refresh works even when the content is
        // shorter than the viewport.
        physics: onRefresh != null
            ? const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              )
            : const BouncingScrollPhysics(),
        child: body,
      );
    }

    if (onRefresh case final refresh?) {
      body = RefreshIndicator(onRefresh: refresh, child: body);
    }

    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Branded header card used at the top of the main sections.
class OfficialHeader extends StatelessWidget {
  const OfficialHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final widget?) ...[
            const SizedBox(width: 12),
            widget,
          ],
        ],
      ),
    );
  }
}

/// A card/tile border that follows the active brightness.
///
/// The widget layer previously hard-coded a light-mode border colour, which
/// drew a pale hairline across every card in dark mode.
extension HairlineColor on BuildContext {
  Color get hairline => Theme.of(this).brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.border;
}
