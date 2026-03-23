import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:myapp/core/theme/theme_provider.dart';
import 'package:myapp/features/authentication/providers/auth_provider.dart';
import 'package:myapp/features/crm/providers/contact_provider.dart';
import 'package:myapp/features/crm/providers/crm_provider.dart';
import 'package:myapp/features/dashboard/providers/dashboard_provider.dart';
import 'package:myapp/features/dashboard/providers/smart_scan_provider.dart';
import 'package:myapp/features/pipeline/providers/pipeline_provider.dart';
import 'package:myapp/features/profile/providers/profile_provider.dart';

void main() {
  testWidgets(
    'Main provider graph initializes without crashes',
    (WidgetTester tester) async {
      bool hasThemeProvider = false;
      bool hasAuthProvider = false;
      bool hasPipelineProvider = false;
      bool hasCrmProvider = false;
      bool hasDashboardProvider = false;
      bool hasProfileProvider = false;
      bool hasContactProvider = false;
      bool hasSmartScanProvider = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
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
        ],
        child: Builder(
          builder: (context) {
            context.read<ThemeProvider>();
            context.read<AuthProvider>();
            context.read<PipelineProvider>();
            context.read<CrmProvider>();
            context.read<DashboardProvider>();
            context.read<ProfileProvider>();
            context.read<ContactProvider>();
            context.read<SmartScanProvider>();

            hasThemeProvider = true;
            hasAuthProvider = true;
            hasPipelineProvider = true;
            hasCrmProvider = true;
            hasDashboardProvider = true;
            hasProfileProvider = true;
            hasContactProvider = true;
            hasSmartScanProvider = true;

            return const SizedBox.shrink();
          },
        ),
      ),
    );

      await tester.pump();

      expect(hasThemeProvider, isTrue);
      expect(hasAuthProvider, isTrue);
      expect(hasPipelineProvider, isTrue);
      expect(hasCrmProvider, isTrue);
      expect(hasDashboardProvider, isTrue);
      expect(hasProfileProvider, isTrue);
      expect(hasContactProvider, isTrue);
      expect(hasSmartScanProvider, isTrue);
    },
  );
}
