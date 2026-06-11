import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../firebase_options.dart';
import '../../features/auth/domain/auth_session.dart';
import '../api/api_dtos.dart';
import '../api/procurement_api.dart';
import '../config/app_config.dart';
import '../storage/secure_session_storage.dart';

class DeviceTokenService {
  DeviceTokenService({
    required ProcurementApi api,
    required AppConfig config,
    required SecureSessionStorage storage,
  }) : _api = api,
       _config = config,
       _storage = storage;

  final ProcurementApi _api;
  final AppConfig _config;
  final SecureSessionStorage _storage;
  final _uuid = const Uuid();

  String? _registeredDeviceId;
  String? _lastRegisteredToken;
  AuthSession? _session;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> register(AuthSession session) async {
    if (_config.useMockApi) return;
    _session = session;
    try {
      await _ensureFirebase();
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission();
      final token = await messaging.getToken();
      await _upsertToken(session: session, token: token);
      _listenForTokenRefresh();
    } on Exception catch (error) {
      // Firebase config may be absent in local/dev builds. REST remains source
      // of truth, so token registration is best-effort.
      if (kDebugMode) {
        debugPrint('FCM token registration failed: $error');
      }
    }
  }

  Future<void> unregister() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _session = null;
    final deviceId = _registeredDeviceId ?? await _storage.readDeviceId();
    if (_config.useMockApi || deviceId == null || deviceId.isEmpty) return;
    try {
      await _api.deleteDeviceToken(deviceId);
    } on Exception catch (error) {
      // Best-effort cleanup; backend token expiry handles missed deletes.
      if (kDebugMode) {
        debugPrint('FCM token unregister failed: $error');
      }
    } finally {
      _registeredDeviceId = null;
      _lastRegisteredToken = null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen((token) async {
          final session = _session;
          if (session == null) return;
          await _upsertToken(session: session, token: token);
        });
  }

  Future<void> _upsertToken({
    required AuthSession session,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return;
    final deviceId = await _deviceId();
    if (_registeredDeviceId == deviceId && _lastRegisteredToken == token) {
      return;
    }
    await _api.registerDeviceToken(
      DeviceTokenPayloadDto(
        deviceId: deviceId,
        platform: _platform,
        fcmToken: token,
      ),
    );
    _session = session;
    _registeredDeviceId = deviceId;
    _lastRegisteredToken = token;
  }

  Future<String> _deviceId() async {
    final existing = await _storage.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = '$_platform-${_uuid.v4()}';
    await _storage.writeDeviceId(generated);
    return generated;
  }

  String get _platform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
