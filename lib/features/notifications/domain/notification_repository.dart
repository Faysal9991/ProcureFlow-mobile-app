import 'package:equatable/equatable.dart';

import '../../auth/domain/auth_session.dart';

abstract interface class NotificationRepository {
  Future<int> getUnreadCount(AuthSession session);

  Future<NotificationPage> getNotifications(
    AuthSession session, {
    required int page,
    required int limit,
  });

  Future<void> markRead(AuthSession session, String id);

  Future<void> markAllRead(AuthSession session);
}

class NotificationPage extends Equatable {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<AppNotification> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.route,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? route;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      route: route,
    );
  }

  @override
  List<Object?> get props => [id, title, message, createdAt, isRead, route];
}
