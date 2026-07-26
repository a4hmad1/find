import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failure.dart';
import 'app_scaffold.dart';
import 'buttons.dart';

/// Placeholder for a list or section that has no content yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = Ku.noItems,
    this.message = 'کاتێک بابەتێک هەبێت لێرە دەردەکەوێت.',
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a failed load.
///
/// Prefer the [ErrorView.failure] constructor: it shows the specific reason the
/// operation failed and only offers a retry when retrying could actually help,
/// instead of the previous blanket "something went wrong" on every error.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message = Ku.genericError,
    this.detail = 'تکایە دواتر هەوڵبدەرەوە.',
    this.icon = Icons.error_rounded,
    this.onRetry,
  });

  /// Builds the view from a typed failure.
  ErrorView.failure(AppFailure failure, {super.key, VoidCallback? onRetry})
    : message = failure.message,
      detail = switch (failure) {
        NetworkFailure() => 'پەیوەندی ئینتەرنێت پشتڕاست بکەرەوە.',
        PermissionFailure() => 'ئەم بەشە بۆ تۆ نییە.',
        NotFoundFailure() => 'لەوانەیە سڕابێتەوە.',
        ConfigurationFailure() => 'پەڕگەی .env ڕێک بخە.',
        _ => 'تکایە دواتر هەوڵبدەرەوە.',
      },
      icon = switch (failure) {
        NetworkFailure() => Icons.wifi_off_rounded,
        PermissionFailure() => Icons.lock_rounded,
        NotFoundFailure() => Icons.search_off_rounded,
        ConfigurationFailure() => Icons.settings_rounded,
        _ => Icons.error_rounded,
      },
      // A retry button that cannot succeed is worse than no button.
      onRetry = failure.isRetryable ? onRetry : null;

  final String message;
  final String detail;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(title: message, message: detail, icon: icon),
        if (onRetry case final retry?)
          PrimaryButton(
            label: Ku.retry,
            icon: Icons.refresh_rounded,
            onPressed: retry,
          ),
      ],
    );
  }
}

/// Placeholder shown where a signed-in-only feature would be.
///
/// Always offers a way forward: previously several of these were dead ends with
/// no path to the (unreachable) login screen.
class GuestModeView extends StatelessWidget {
  const GuestModeView({
    super.key,
    this.title = 'دۆخی میوان',
    this.message = 'ئەم بەشە پێویستی بە چوونەژوورەوە هەیە.',
    this.icon = Icons.lock_outline_rounded,
    this.showLoginAction = true,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool showLoginAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(title: title, message: message, icon: icon),
        if (showLoginAction) ...[
          PrimaryButton(
            label: Ku.githubLogin,
            icon: Icons.login_rounded,
            onPressed: () => context.push(
              Uri(
                path: AppRoutes.login,
                queryParameters: {
                  AppRoutes.redirectParam: GoRouterState.of(
                    context,
                  ).uri.toString(),
                },
              ).toString(),
            ),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: Ku.home,
            icon: Icons.home_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ],
    );
  }
}

/// Shimmering placeholder cards shown while a list loads.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF162235) : const Color(0xFFE8EEF5),
      highlightColor: isDark
          ? const Color(0xFF22304A)
          : const Color(0xFFF7FAFC),
      child: Column(
        children: List.generate(
          count,
          (index) => Container(
            height: 126,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain spinner, for waits too short to justify a skeleton.
class Loader extends StatelessWidget {
  const Loader({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

/// Inline notice for non-blocking information, such as missing configuration.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_rounded,
    this.color = AppColors.accent,
    this.background = AppColors.accentSoft,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen shown when the device has no connectivity.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.noInternet,
      child: Column(
        children: [
          const EmptyState(
            title: Ku.noInternet,
            message: 'تکایە پەیوەندی ئینتەرنێت پشتڕاست بکەرەوە.',
            icon: Icons.wifi_off_rounded,
          ),
          PrimaryButton(
            label: Ku.retry,
            icon: Icons.refresh_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

/// Shows [failure]'s message, with a retry action when one is useful.
///
/// Centralised so that every catch site reports the real reason instead of the
/// generic string that used to be hard-coded at a dozen call sites.
void showFailureSnackBar(
  BuildContext context,
  AppFailure failure, {
  VoidCallback? onRetry,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(failure.message),
        behavior: SnackBarBehavior.floating,
        action: (failure.isRetryable && onRetry != null)
            ? SnackBarAction(label: Ku.retry, onPressed: onRetry)
            : null,
      ),
    );
}

/// Shows a plain confirmation message.
void showMessageSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

/// Asks the user to confirm a destructive action.
///
/// Returns false when dismissed, so callers can treat the result as a plain
/// bool without a null check.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = Ku.confirm,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(Ku.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
