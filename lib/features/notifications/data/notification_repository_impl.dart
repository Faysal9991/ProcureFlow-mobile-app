import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required AppConfig config,
    required ProcurementApi api,
    required ProcurementDao dao,
  }) : _config = config,
       _api = api,
       _dao = dao;

  final AppConfig _config;
  final ProcurementApi _api;
  final ProcurementDao _dao;

  @override
  Future<int> getUnreadCount(AuthSession session) {
    if (_config.useMockApi) {
      return _dao.countUnreadNotifications(session.companyId);
    }
    return _api.getNotificationUnreadCount().then((response) => response.count);
  }

  @override
  Future<NotificationPage> getNotifications(
    AuthSession session, {
    required int page,
    required int limit,
  }) async {
    if (_config.useMockApi) {
      final offset = (page - 1) * limit;
      final rows = await _dao.getNotifications(
        session.companyId,
        limit: limit,
        offset: offset,
      );
      return NotificationPage(
        items: rows.map(_notificationFromRow).toList(),
        page: page,
        limit: limit,
        total: rows.length,
      );
    }

    final response = await _api.getNotifications(page, limit);
    return _pageFromDto(response);
  }

  @override
  Future<void> markRead(AuthSession session, String id) {
    if (_config.useMockApi) {
      return _dao.markNotificationRead(id);
    }
    return _api.markNotificationRead(id);
  }

  @override
  Future<void> markAllRead(AuthSession session) {
    if (_config.useMockApi) {
      return _dao.markAllNotificationsRead(session.companyId);
    }
    return _api.markAllNotificationsRead();
  }

  NotificationPage _pageFromDto(NotificationPageDto dto) {
    return NotificationPage(
      items: dto.items.map(_notificationFromDto).toList(),
      page: dto.page,
      limit: dto.limit,
      total: dto.total,
    );
  }

  AppNotification _notificationFromDto(NotificationDto dto) {
    return AppNotification(
      id: dto.id,
      title: dto.title,
      message: dto.message,
      createdAt: dto.createdAt,
      isRead: dto.isRead,
      route: dto.route,
    );
  }

  AppNotification _notificationFromRow(LocalNotification row) {
    return AppNotification(
      id: row.localId,
      title: row.title,
      message: row.body,
      createdAt: row.createdAt,
      isRead: row.isRead,
      route: row.route,
    );
  }
}
