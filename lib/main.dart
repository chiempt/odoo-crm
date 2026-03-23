import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/pipeline/providers/pipeline_provider.dart';
import 'features/crm/providers/crm_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/crm/providers/contact_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/dashboard/providers/smart_scan_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PipelineProvider>(
          create: (_) => PipelineProvider(),
          update: (_, auth, previous) {
            previous?.updateAuth(auth.token ?? '', auth.serverUrl ?? '');
            return previous ?? PipelineProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CrmProvider>(
          create: (_) => CrmProvider(),
          update: (_, auth, previous) {
            previous?.updateAuth(
              auth.token ?? '',
              auth.serverUrl ?? '',
              auth.uid,
            );
            return previous ?? CrmProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, previous) {
            previous?.updateAuth(
              auth.token ?? '',
              auth.serverUrl ?? '',
              auth.uid,
            );
            return previous ?? DashboardProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, previous) {
            previous?.updateAuth(auth.uid);
            return previous ?? ProfileProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => SmartScanProvider()),
        // Provide AppRouter and react to AuthProvider via refreshListenable
        Provider<AppRouter>(
          create: (context) => AppRouter(context.read<AuthProvider>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final appRouter = context.read<AppRouter>();

    return MaterialApp.router(
      title: 'Odoo CRM',
      theme: AppTheme.createThemeData(
        brightness: Brightness.light,
        font: themeProvider.font,
        fontSizeScale: themeProvider.fontSizeScale,
      ),
      darkTheme: AppTheme.createThemeData(
        brightness: Brightness.dark,
        font: themeProvider.font,
        fontSizeScale: themeProvider.fontSizeScale,
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
