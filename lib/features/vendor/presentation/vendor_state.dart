import 'package:equatable/equatable.dart';

import '../domain/vendor_entity.dart';

class VendorState extends Equatable {
  const VendorState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const VendorFilters(),
    this.vendors = const [],
    this.selectedVendor,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final VendorFilters filters;
  final List<VendorEntity> vendors;
  final VendorEntity? selectedVendor;
  final int total;

  VendorState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    VendorFilters? filters,
    List<VendorEntity>? vendors,
    VendorEntity? selectedVendor,
    bool clearSelectedVendor = false,
    int? total,
  }) {
    return VendorState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      vendors: vendors ?? this.vendors,
      selectedVendor: clearSelectedVendor
          ? null
          : selectedVendor ?? this.selectedVendor,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    vendors,
    selectedVendor,
    total,
  ];
}
