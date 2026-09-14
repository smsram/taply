import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/services/native_bridge.dart';
import 'core/services/providers.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service eagerly
  final storageService = SharedPreferencesStorageService();
  await storageService.init();

  // Listen for native intent routes (e.g. from OverlayService or shortcuts)
  NativeBridge.instance.setNavigationHandler((route) {
    try {
      appRouter.go(route);
    } catch (e) {
      debugPrint('[Taply] Failed to navigate to native route: $route ($e)');
    }
  });

  // Android system bar configuration
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const TaplyApp(),
    ),
  );
}

class TaplyApp extends ConsumerWidget {
  const TaplyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Determine theme mode and active ThemeData
    ThemeMode themeMode;
    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;

    switch (settings.themeMode) {
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.amoled:
        themeMode = ThemeMode.dark;
        darkTheme = AppTheme.amoledTheme;
        break;
    }

    final selectedLocale = AppLocalizations.parseLocale(settings.language);

    return MaterialApp.router(
      title: AppConstants.appDisplayName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: selectedLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
