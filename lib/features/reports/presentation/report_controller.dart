import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/report_entity.dart';
import '../domain/report_repository.dart';
import 'report_providers.dart';
import 'report_state.dart';

final reportControllerProvider =
    StateNotifierProvider.autoDispose<ReportController, ReportState>((ref) {
      return ReportController(ref.watch(reportRepositoryProvider));
    });

class ReportController extends StateNotifier<ReportState> {
  ReportController(this._repository) : super(const ReportState());

  final ReportRepository _repository;

  Future<void> load(ReportType type, [ReportFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getReport(type, nextFilters);
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        summary: page.summary,
        total: page.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<String?> export(ReportType type, String format) async {
    if (state.isExporting) return null;
    state = state.copyWith(
      isExporting: true,
      clearError: true,
      clearExportProgress: true,
    );
    try {
      final path = await _repository.exportReport(
        type: type,
        filters: state.filters,
        format: format,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          state = state.copyWith(exportProgress: received / total);
        },
      );
      state = state.copyWith(isExporting: false, exportProgress: 1);
      return path;
    } catch (error) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('Invalid argument(s): ')) {
      return message.substring('Invalid argument(s): '.length);
    }
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    return message;
  }
}
