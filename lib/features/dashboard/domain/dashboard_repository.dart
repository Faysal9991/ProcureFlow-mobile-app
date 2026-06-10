import 'package:equatable/equatable.dart';

import '../../auth/domain/auth_session.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary(AuthSession session);

  Future<int> getUnreadNotificationCount(AuthSession session);
}

class DashboardSummary extends Equatable {
  const DashboardSummary({required this.cards, required this.activities});

  final List<DashboardSummaryCard> cards;
  final List<DashboardActivity> activities;

  @override
  List<Object?> get props => [cards, activities];
}

class DashboardSummaryCard extends Equatable {
  const DashboardSummaryCard({
    required this.key,
    required this.label,
    required this.value,
    this.requiredPermissions = const [],
  });

  final String key;
  final String label;
  final String value;
  final List<String> requiredPermissions;

  bool isVisibleFor(AuthSession session) {
    return requiredPermissions.isEmpty ||
        session.hasAnyPermission(requiredPermissions);
  }

  @override
  List<Object?> get props => [key, label, value, requiredPermissions];
}

class DashboardActivity extends Equatable {
  const DashboardActivity({
    required this.title,
    required this.message,
    required this.createdAt,
    this.route,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  final String? route;

  @override
  List<Object?> get props => [title, message, createdAt, route];
}
