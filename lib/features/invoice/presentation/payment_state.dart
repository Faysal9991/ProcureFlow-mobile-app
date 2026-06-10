import 'package:equatable/equatable.dart';

import '../domain/payment_entity.dart';

class PaymentState extends Equatable {
  const PaymentState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const PaymentFilters(),
    this.payments = const [],
    this.selectedPayment,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final PaymentFilters filters;
  final List<Payment> payments;
  final Payment? selectedPayment;
  final int total;

  PaymentState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    PaymentFilters? filters,
    List<Payment>? payments,
    Payment? selectedPayment,
    bool clearSelectedPayment = false,
    int? total,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      payments: payments ?? this.payments,
      selectedPayment: clearSelectedPayment
          ? null
          : selectedPayment ?? this.selectedPayment,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    payments,
    selectedPayment,
    total,
  ];
}
