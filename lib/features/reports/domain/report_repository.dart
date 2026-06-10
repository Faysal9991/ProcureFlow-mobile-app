import 'report_entity.dart';

abstract class ReportRepository {
  Future<ReportPage> getReport(ReportType type, ReportFilters filters);

  Future<String> exportReport({
    required ReportType type,
    required ReportFilters filters,
    required String format,
    void Function(int received, int total)? onReceiveProgress,
  });
}
