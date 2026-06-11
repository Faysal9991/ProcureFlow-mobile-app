import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/dashboard/presentation/dashboard_controller.dart';
import '../features/notifications/presentation/notification_controller.dart';
import '../features/profile/presentation/app_settings_controller.dart';
import '../features/sync/presentation/sync_providers.dart';
import '../core/providers/infrastructure_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ProcurementApp extends ConsumerStatefulWidget {
  const ProcurementApp({super.key});

  @override
  ConsumerState<ProcurementApp> createState() => _ProcurementAppState();
}

class _ProcurementAppState extends ConsumerState<ProcurementApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).restoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.session != next.session) {
        ref.read(syncControllerProvider.notifier).syncNow();
        final session = next.session;
        if (session != null) {
          ref.read(deviceTokenServiceProvider).register(session);
          ref.read(notificationSocketServiceProvider).connect(session);
        }
      }
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        ref.read(deviceTokenServiceProvider).unregister();
        ref.read(notificationSocketServiceProvider).disconnect();
      }
    });
    ref.listen<AsyncValue<bool>>(onlineStatusProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? false;
      final session = ref.read(authControllerProvider).session;
      if (isOnline && session != null) {
        ref.read(syncControllerProvider.notifier).syncNow();
        ref.read(notificationSocketServiceProvider).reconnect();
      }
    });
    ref.listen(notificationSocketEventsProvider, (previous, next) {
      final event = next.valueOrNull;
      final session = ref.read(authControllerProvider).session;
      if (event == null || session == null) return;
      ref
          .read(procurementDaoProvider)
          .addNotification(
            companyId: session.companyId,
            title: event.title,
            body: event.message,
            route: event.route,
          );
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(notificationControllerProvider);
    });

    final settings = ref.watch(appSettingsControllerProvider);

    return MaterialApp.router(
      title: 'Procurement Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
