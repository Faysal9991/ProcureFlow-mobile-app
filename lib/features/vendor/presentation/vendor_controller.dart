import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';
import 'vendor_providers.dart';
import 'vendor_state.dart';

final vendorControllerProvider =
    StateNotifierProvider.autoDispose<VendorController, VendorState>((ref) {
      return VendorController(ref.watch(vendorRepositoryProvider));
    });

class VendorController extends StateNotifier<VendorState> {
  VendorController(this._repository) : super(const VendorState());

  final VendorRepository _repository;

  Future<void> loadList([VendorFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getVendors(nextFilters);
      state = state.copyWith(
        isLoading: false,
        vendors: page.items,
        total: page.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadDetail(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelectedVendor: true,
    );
    try {
      final vendor = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedVendor: vendor);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<VendorEntity?> create(VendorPayload payload) {
    return _mutate(() => _repository.create(payload));
  }

  Future<VendorEntity?> update(String id, VendorPayload payload) {
    return _mutate(() => _repository.update(id, payload));
  }

  Future<bool> delete(String id) async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.delete(id);
      state = state.copyWith(
        isMutating: false,
        clearSelectedVendor: true,
        vendors: [
          for (final vendor in state.vendors)
            if (vendor.localId != id) vendor,
        ],
        total: state.total > 0 ? state.total - 1 : 0,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  Future<VendorEntity?> _mutate(Future<VendorEntity> Function() action) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final vendor = await action();
      state = state.copyWith(isMutating: false, selectedVendor: vendor);
      return vendor;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
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
