import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  SecureSessionStorage._();

  factory SecureSessionStorage() => instance;

  static final SecureSessionStorage instance = SecureSessionStorage._();

  static const _sessionKey = 'auth_session';
  static const _accessTokenKey = 'auth_access_token';
  static const _deviceIdKey = 'device_installation_id';
  static const _appSettingsKey = 'app_settings';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readAccessToken() async {
    try {
      return _storage.read(key: _accessTokenKey);
    } on Exception {
      return null;
    }
  }

  Future<void> writeAccessToken(String value) async {
    try {
      await _storage.write(key: _accessTokenKey, value: value);
    } on Exception {
      // Tests and unsupported platforms can still use the in-memory auth state.
    }
  }

  Future<String?> readSessionJson() async {
    try {
      return _storage.read(key: _sessionKey);
    } on Exception {
      return null;
    }
  }

  Future<void> writeSessionJson(String value) async {
    try {
      await _storage.write(key: _sessionKey, value: value);
    } on Exception {
      // Tests and unsupported platforms can still use the in-memory auth state.
    }
  }

  Future<String?> readDeviceId() async {
    try {
      return _storage.read(key: _deviceIdKey);
    } on Exception {
      return null;
    }
  }

  Future<void> writeDeviceId(String value) async {
    try {
      await _storage.write(key: _deviceIdKey, value: value);
    } on Exception {
      // Tests and unsupported platforms can still register a transient token.
    }
  }

  Future<String?> readAppSettingsJson() async {
    try {
      return _storage.read(key: _appSettingsKey);
    } on Exception {
      return null;
    }
  }

  Future<void> writeAppSettingsJson(String value) async {
    try {
      await _storage.write(key: _appSettingsKey, value: value);
    } on Exception {
      // Tests and unsupported platforms can still use the in-memory settings.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _accessTokenKey);
    } on Exception {
      // Tests and unsupported platforms can still clear in-memory auth state.
    }
  }
}
