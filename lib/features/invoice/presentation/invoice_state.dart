import 'package:equatable/equatable.dart';

import '../domain/invoice_entity.dart';

class InvoiceState extends Equatable {
  const InvoiceState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const InvoiceFilters(),
    this.invoices = const [],
    this.selectedInvoice,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final InvoiceFilters filters;
  final List<Invoice> invoices;
  final Invoice? selectedInvoice;
  final int total;

  InvoiceState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    InvoiceFilters? filters,
    List<Invoice>? invoices,
    Invoice? selectedInvoice,
    bool clearSelectedInvoice = false,
    int? total,
  }) {
    return InvoiceState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      invoices: invoices ?? this.invoices,
      selectedInvoice: clearSelectedInvoice
          ? null
          : selectedInvoice ?? this.selectedInvoice,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    invoices,
    selectedInvoice,
    total,
  ];
}
