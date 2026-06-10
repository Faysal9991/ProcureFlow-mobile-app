import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  SecureSessionStorage._();

  factory SecureSessionStorage() => instance;

  static final SecureSessionStorage instance = SecureSessionStorage._();

  static const _sessionKey = 'auth_session';
  static const _accessTokenKey = 'auth_access_token';
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

  Future<void> clear() async {
    try {
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _accessTokenKey);
    } on Exception {
      // Tests and unsupported platforms can still clear in-memory auth state.
    }
  }
}
