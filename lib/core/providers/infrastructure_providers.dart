import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../api/procurement_api.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/daos/procurement_dao.dart';
import '../network/connectivity_service.dart';
import '../notifications/device_token_service.dart';
import '../notifications/notification_socket_service.dart';
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
  final storage = ref.watch(secureSessionStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.effectiveBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null &&
            token.isNotEmpty &&
            !options.path.endsWith('/auth/login')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await storage.clear();
          ref.read(sessionInvalidationProvider.notifier).state++;
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          enabled: kDebugMode,
          printRequestHeaders: false,
          printRequestData: false,
          printResponseHeaders: false,
          printResponseData: false,
          printErrorHeaders: false,
          printErrorData: false,
          printResponseMessage: true,
          printErrorMessage: true,
          printResponseTime: true,
        ),
      ),
    );
  }

  return dio;
});

final sessionInvalidationProvider = StateProvider<int>((ref) => 0);

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

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});

final notificationSocketServiceProvider = Provider<NotificationSocketService>((
  ref,
) {
  final service = NotificationSocketService(
    config: ref.watch(appConfigProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final notificationSocketEventsProvider =
    StreamProvider<NotificationSocketEvent>((ref) {
      return ref.watch(notificationSocketServiceProvider).events;
    });
