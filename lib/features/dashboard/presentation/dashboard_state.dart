import 'package:equatable/equatable.dart';

import '../domain/app_menu_item.dart';
import '../domain/dashboard_repository.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.cards = const [],
    this.activities = const [],
    this.menuItems = const [],
    this.unreadCount = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<DashboardSummaryCard> cards;
  final List<DashboardActivity> activities;
  final List<AppMenuItem> menuItems;
  final int unreadCount;

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<DashboardSummaryCard>? cards,
    List<DashboardActivity>? activities,
    List<AppMenuItem>? menuItems,
    int? unreadCount,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      cards: cards ?? this.cards,
      activities: activities ?? this.activities,
      menuItems: menuItems ?? this.menuItems,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    cards,
    activities,
    menuItems,
    unreadCount,
  ];
}
