import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/sync/presentation/sync_providers.dart';
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
      }
    });
    ref.listen<AsyncValue<bool>>(onlineStatusProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? false;
      final session = ref.read(authControllerProvider).session;
      if (isOnline && session != null) {
        ref.read(syncControllerProvider.notifier).syncNow();
      }
    });

    return MaterialApp.router(
      title: 'Procurement Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
