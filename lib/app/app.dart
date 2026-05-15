import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localization.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class FindApp extends ConsumerWidget {
  const FindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: Ku.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: FindTheme.light(),
      darkTheme: FindTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
