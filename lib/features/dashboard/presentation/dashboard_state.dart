import 'package:equatable/equatable.dart';

import '../domain/app_menu_item.dart';
import '../domain/dashboard_repository.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.cards = const [],
    this.activities = const [],
    this.modules = const [],
    this.quickActions = const [],
    this.menuItems = const [],
    this.accessProfile = const DashboardAccessProfile(
      primaryLabel: 'Employee',
      roleLabels: ['Employee'],
    ),
    this.unreadCount = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<DashboardSummaryCard> cards;
  final List<DashboardActivity> activities;
  final List<DashboardModule> modules;
  final List<DashboardQuickAction> quickActions;
  final List<AppMenuItem> menuItems;
  final DashboardAccessProfile accessProfile;
  final int unreadCount;

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<DashboardSummaryCard>? cards,
    List<DashboardActivity>? activities,
    List<DashboardModule>? modules,
    List<DashboardQuickAction>? quickActions,
    List<AppMenuItem>? menuItems,
    DashboardAccessProfile? accessProfile,
    int? unreadCount,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      cards: cards ?? this.cards,
      activities: activities ?? this.activities,
      modules: modules ?? this.modules,
      quickActions: quickActions ?? this.quickActions,
      menuItems: menuItems ?? this.menuItems,
      accessProfile: accessProfile ?? this.accessProfile,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    cards,
    activities,
    modules,
    quickActions,
    menuItems,
    accessProfile,
    unreadCount,
  ];
}
