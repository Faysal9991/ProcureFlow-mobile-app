import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  SecureSessionStorage._();

  factory SecureSessionStorage() => instance;

  static final SecureSessionStorage instance = SecureSessionStorage._();

  static const _sessionKey = 'auth_session';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
    } on Exception {
      // Tests and unsupported platforms can still clear in-memory auth state.
    }
  }
}
