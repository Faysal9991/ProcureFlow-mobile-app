import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/app_menu_item.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_state.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    config: ref.watch(appConfigProvider),
    api: ref.watch(procurementApiProvider),
    dao: ref.watch(procurementDaoProvider),
  );
});

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>(
      (ref) => DashboardController(ref.watch(dashboardRepositoryProvider)),
    );

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;

  Future<void> load(AuthSession? session) async {
    if (session == null) {
      state = const DashboardState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _repository.getSummary(session);
      final unreadCount = await _repository.getUnreadNotificationCount(session);
      state = DashboardState(
        cards: [
          for (final card in summary.cards)
            if (card.isVisibleFor(session)) card,
        ],
        activities: summary.activities,
        modules: visibleDashboardModules(session),
        quickActions: visibleDashboardQuickActions(session),
        menuItems: visiblePhase2MenuItems(session),
        accessProfile: DashboardAccessProfile.fromSession(session),
        unreadCount: unreadCount,
      );
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  String _messageFromError(Exception error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
