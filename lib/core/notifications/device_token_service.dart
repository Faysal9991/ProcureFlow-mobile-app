import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/domain/auth_session.dart';
import '../api/api_dtos.dart';
import '../api/procurement_api.dart';
import '../config/app_config.dart';

class DeviceTokenService {
  DeviceTokenService({required ProcurementApi api, required AppConfig config})
    : _api = api,
      _config = config;

  final ProcurementApi _api;
  final AppConfig _config;

  String? _registeredDeviceId;

  Future<void> register(AuthSession session) async {
    if (_config.useMockApi) return;
    try {
      await _ensureFirebase();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      final deviceId = _deviceId(session);
      await _api.registerDeviceToken(
        DeviceTokenPayloadDto(
          deviceId: deviceId,
          platform: Platform.operatingSystem,
          fcmToken: token,
        ),
      );
      _registeredDeviceId = deviceId;
    } catch (_) {
      // Firebase config may be absent in local/dev builds. REST remains source
      // of truth, so token registration is best-effort.
    }
  }

  Future<void> unregister() async {
    final deviceId = _registeredDeviceId;
    if (_config.useMockApi || deviceId == null) return;
    try {
      await _api.deleteDeviceToken(deviceId);
    } catch (_) {
      // Best-effort cleanup; backend token expiry handles missed deletes.
    } finally {
      _registeredDeviceId = null;
    }
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  String _deviceId(AuthSession session) {
    return '${Platform.operatingSystem}-${session.companyId}-${session.userId}';
  }
}
