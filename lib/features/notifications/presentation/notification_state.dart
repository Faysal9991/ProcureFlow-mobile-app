import 'package:equatable/equatable.dart';

import '../domain/notification_repository.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.items = const [],
    this.unreadCount = 0,
    this.page = 1,
    this.limit = 10,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final List<AppNotification> items;
  final int unreadCount;
  final int page;
  final int limit;
  final int total;

  NotificationState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    List<AppNotification>? items,
    int? unreadCount,
    int? page,
    int? limit,
    int? total,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    items,
    unreadCount,
    page,
    limit,
    total,
  ];
}
