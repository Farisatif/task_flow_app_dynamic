import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/database/database_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/settings_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await NotificationService.initialize(
    onTap: _handleNotificationTap,
  );

  runApp(
    DatabaseBootstrap(
      builder: (context) => const TaskFlowApp(),
    ),
  );
}

void _handleNotificationTap(String? payload) {
  if (payload == null || payload.trim().isEmpty) return;

  final data = payload.trim();

  if (data.startsWith('/')) {
    appRouter.go(data);
    return;
  }

  final taskId = int.tryParse(data);
  if (taskId != null) {
    appRouter.go('/task-details/$taskId');
    return;
  }

  appRouter.go('/today');
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, _) {
          return MaterialApp.router(
            title: 'Task Flow - إدارة المهام',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(primary: settings.primaryColor),
            darkTheme: AppTheme.dark(primary: settings.primaryColor),
            themeMode: themeProvider.mode,
            routerConfig: appRouter,
            locale: const Locale('ar'),
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
