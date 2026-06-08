import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/procurement_api.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/daos/procurement_dao.dart';
import '../network/connectivity_service.dart';
import '../storage/secure_session_storage.dart';
import '../sync/sync_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final procurementDaoProvider = Provider<ProcurementDao>((ref) {
  return ProcurementDao(ref.watch(appDatabaseProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.effectiveBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

final procurementApiProvider = Provider<ProcurementApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return ProcurementApi(
    ref.watch(dioProvider),
    baseUrl: config.effectiveBaseUrl,
  );
});

final secureSessionStorageProvider = Provider<SecureSessionStorage>((ref) {
  return SecureSessionStorage();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});
