import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/auth/domain/auth_session.dart';
import '../config/app_config.dart';

class NotificationSocketEvent {
  const NotificationSocketEvent({
    required this.title,
    required this.message,
    this.route,
  });

  factory NotificationSocketEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return NotificationSocketEvent(
      title: (data['title'] ?? 'Notification').toString(),
      message: (data['message'] ?? data['body'] ?? '').toString(),
      route: data['route']?.toString(),
    );
  }

  final String title;
  final String message;
  final String? route;
}

class NotificationSocketService {
  NotificationSocketService({required AppConfig config}) : _config = config;

  final AppConfig _config;
  final _controller = StreamController<NotificationSocketEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  AuthSession? _session;
  bool _isConnecting = false;

  Stream<NotificationSocketEvent> get events => _controller.stream;

  Future<void> connect(AuthSession session) async {
    if (_config.useMockApi || _isConnecting) return;
    if (_session?.accessToken == session.accessToken && _channel != null) {
      return;
    }
    await disconnect();
    _session = session;
    _isConnecting = true;
    try {
      final channel = WebSocketChannel.connect(_socketUri(session.accessToken));
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: () => _channel = null,
        onError: (_) => _channel = null,
        cancelOnError: false,
      );
    } catch (_) {
      _channel = null;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> reconnect() async {
    final session = _session;
    if (session == null) return;
    await disconnect(clearSession: false);
    await connect(session);
  }

  Future<void> disconnect({bool clearSession = true}) async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    if (clearSession) _session = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  void _handleMessage(Object? message) {
    try {
      final decoded = message is String ? jsonDecode(message) : message;
      if (decoded is Map) {
        _controller.add(
          NotificationSocketEvent.fromJson(Map<String, dynamic>.from(decoded)),
        );
      }
    } catch (_) {
      // Ignore malformed socket payloads.
    }
  }

  Uri _socketUri(String token) {
    final base = Uri.parse(_config.effectiveBaseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws',
      queryParameters: {'token': token},
    );
  }
}
