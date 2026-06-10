import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/invoice_entity.dart';
import '../domain/invoice_repository.dart';
import 'invoice_providers.dart';
import 'invoice_state.dart';

final invoiceControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceController, InvoiceState>((ref) {
      return InvoiceController(ref.watch(invoiceRepositoryProvider));
    });

class InvoiceController extends StateNotifier<InvoiceState> {
  InvoiceController(this._repository) : super(const InvoiceState());

  final InvoiceRepository _repository;

  Future<void> loadList([InvoiceFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getInvoices(nextFilters);
      state = state.copyWith(
        isLoading: false,
        invoices: page.items,
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
      clearSelectedInvoice: true,
    );
    try {
      final invoice = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedInvoice: invoice);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<Invoice?> create(CreateInvoicePayload payload) {
    return _mutate(() => _repository.create(payload));
  }

  Future<Invoice?> update(String id, UpdateInvoicePayload payload) {
    return _mutate(() => _repository.update(id, payload));
  }

  Future<Invoice?> cancel(String id) {
    return _mutate(() => _repository.cancel(id));
  }

  Future<Invoice?> _mutate(Future<Invoice> Function() action) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final invoice = await action();
      final updatedInvoices = [
        for (final item in state.invoices)
          if (item.localId == invoice.localId ||
              item.serverId == invoice.serverId)
            invoice
          else
            item,
      ];
      if (!updatedInvoices.any(
        (item) =>
            item.localId == invoice.localId ||
            item.serverId == invoice.serverId,
      )) {
        updatedInvoices.insert(0, invoice);
      }
      state = state.copyWith(
        isMutating: false,
        selectedInvoice: invoice,
        invoices: updatedInvoices,
      );
      return invoice;
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
