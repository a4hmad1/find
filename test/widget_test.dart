import 'package:find/app/app.dart';
import 'package:find/app/providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ئەپەکە پێشەکی پیشان دەدات و بەبێ چوونەژوورەوە دەکرێتەوە', (
    tester,
  ) async {
    await dotenv.load(fileName: '.env', isOptional: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const FindApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('شتە ونبووەکان زوو بدۆزەرەوە'), findsOneWidget);

    await tester.tap(find.text('تێپەڕاندن'));
    await tester.pumpAndSettle();
    expect(find.text('بەخێربێیت'), findsOneWidget);
  });
}
