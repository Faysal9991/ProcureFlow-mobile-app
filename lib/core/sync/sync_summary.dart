import 'package:equatable/equatable.dart';

class SyncSummary extends Equatable {
  const SyncSummary({
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });

  const SyncSummary.empty() : this(attempted: 0, succeeded: 0, failed: 0);

  final int attempted;
  final int succeeded;
  final int failed;

  bool get hasFailures => failed > 0;

  @override
  List<Object?> get props => [attempted, succeeded, failed];
}
