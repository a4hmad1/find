import 'package:find/app/app.dart';
import 'package:find/app/localization.dart';
import 'package:find/app/providers.dart';
import 'package:find/core/constants/app_constants.dart';
import 'package:find/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression tests for the bug that made signing in impossible.
///
/// The router used to redirect `/login` to `/home` unconditionally, so
/// [LoginScreen] could not be reached from anywhere in the app. These tests
/// pin the behaviour that replaced it.
void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Guest mode: no backend, so no session to restore and no network.
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const FindApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('the login route renders the login screen', (tester) async {
    await pumpApp(tester);

    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(Ku.githubLogin), findsOneWidget);
  });

  testWidgets('login explains itself when Supabase is unconfigured', (
    tester,
  ) async {
    await pumpApp(tester);

    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    // The sign-in button is disabled rather than silently failing, and the
    // reason is on screen.
    expect(find.text(Ku.setupMissing), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(Ku.githubLogin),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('guests can leave the login screen', (tester) async {
    await pumpApp(tester);

    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();

    // Browsing is deliberately open, so login must never be a dead end.
    await tester.tap(find.text('بەردەوامبوون وەک میوان'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('account-only routes stay open in guest mode', (tester) async {
    await pumpApp(tester);

    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    // Without a backend there is no session to gate on, so these screens render
    // their guest placeholders instead of bouncing to login.
    router.go(AppRoutes.saved);
    await tester.pumpAndSettle();

    expect(find.text(Ku.savedPosts), findsWidgets);
  });
}
