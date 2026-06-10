import 'package:equatable/equatable.dart';

import '../domain/report_entity.dart';

class ReportState extends Equatable {
  const ReportState({
    this.isLoading = false,
    this.isExporting = false,
    this.exportProgress,
    this.errorMessage,
    this.filters = const ReportFilters(),
    this.items = const [],
    this.summary = const {},
    this.total = 0,
  });

  final bool isLoading;
  final bool isExporting;
  final double? exportProgress;
  final String? errorMessage;
  final ReportFilters filters;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> summary;
  final int total;

  ReportState copyWith({
    bool? isLoading,
    bool? isExporting,
    double? exportProgress,
    bool clearExportProgress = false,
    String? errorMessage,
    bool clearError = false,
    ReportFilters? filters,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? summary,
    int? total,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      exportProgress: clearExportProgress
          ? null
          : exportProgress ?? this.exportProgress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isExporting,
    exportProgress,
    errorMessage,
    filters,
    items,
    summary,
    total,
  ];
}
