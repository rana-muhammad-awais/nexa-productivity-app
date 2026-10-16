import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/app_store.dart';
import 'features/search/search_page.dart';
import 'features/settings/settings_page.dart';
import 'features/splash/splash_screen.dart';

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(appStoreProvider);
    final user = asyncData.valueOrNull?.user;
    
    final themeMode = switch (user?.theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final fontScale = kFontScaleFactors[user?.fontSize ?? 'default'] ?? 1.0;

    return MaterialApp(
      title: 'Nexora',
      debugShowCheckedModeBanner: false,
      theme: _applyFont(buildLightTheme(user?.accentColor), fontScale),
      darkTheme: _applyFont(buildDarkTheme(user?.accentColor), fontScale),
      themeMode: themeMode,
      home: const SplashScreen(),
      routes: {
        '/search': (_) => const SearchPage(),
        '/settings': (_) => const SettingsPage(),
        '/splash': (_) => const SplashScreen(),
      },
    );
  }

  ThemeData _applyFont(ThemeData base, double scale) {
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final scaledTextTheme = inter.apply(fontSizeFactor: scale);
    return base.copyWith(
      textTheme: scaledTextTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 20 * scale,
          color: base.appBarTheme.foregroundColor,
        ),
      ),
    );
  }
}

/// Pin entry route used when biometric lock is enabled.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexora locked'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry unlock',
            onPressed: () => SystemNavigator.pop(),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'App locked. Biometric unlock failed — reopen Nexora to try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
