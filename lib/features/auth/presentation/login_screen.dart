import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Sign-in screen.
///
/// Reachable from the profile tab, from every guest-mode placeholder, and by
/// the router when a signed-out user opens an account-only route. In the latter
/// case [redirectTo] carries where they were going so they land there rather
/// than on the home screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGitHub();
      // The browser is now open. The session arrives later through the deep
      // link, so the button stays disabled until this screen is popped by the
      // auth listener below — resetting `_loading` here would invite a second
      // tap that opens a second browser tab.
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Show the specific reason rather than a blanket "login failed": a
      // misconfigured redirect URL and a dead network need different fixes.
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(supabaseConfiguredProvider);
    final theme = Theme.of(context);

    // Signing in can complete while this screen is on top (deep link) or before
    // it is opened at all; either way, leave as soon as there is a session.
    ref.listen(signedInProvider, (previous, signedIn) {
      if (!signedIn || !context.mounted) return;
      final target = widget.redirectTo;
      context.go(
        target != null && target.startsWith('/') && !target.startsWith('//')
            ? target
            : AppRoutes.home,
      );
    });

    return Scaffold(
      appBar: AppBar(
        // Guests reach this screen by choice, so leaving must always be possible.
        leading: IconButton(
          tooltip: Ku.cancel,
          icon: const Icon(Icons.close_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const _LoginMark(),
              const SizedBox(height: 28),
              Text(
                Ku.welcomeTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'دۆزینەوەی شتە ونبووەکان بە شێوەیەکی ئاسان و باوەڕپێکراو.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Ku.welcomeBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              if (!configured) ...[
                const InfoBanner(message: Ku.setupMissing),
                const SizedBox(height: 12),
              ],
              GitHubLoginButton(
                loading: _loading,
                onPressed: configured ? _login : null,
              ),
              const SizedBox(height: 14),
              Text(
                'بە چوونەژوورەوە، یاسا و پاراستنی نهێنی پەسەند دەکەیت.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('بەردەوامبوون وەک میوان'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginMark extends StatelessWidget {
  const _LoginMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        color: Colors.white,
        size: 52,
      ),
    );
  }
}
