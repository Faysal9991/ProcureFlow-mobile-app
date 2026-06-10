import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_entity.dart';
import '../domain/payment_repository.dart';
import 'invoice_providers.dart';
import 'payment_state.dart';

final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>((ref) {
      return PaymentController(ref.watch(paymentRepositoryProvider));
    });

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController(this._repository) : super(const PaymentState());

  final PaymentRepository _repository;

  Future<void> loadList([PaymentFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getPayments(nextFilters);
      state = state.copyWith(
        isLoading: false,
        payments: page.items,
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
      clearSelectedPayment: true,
    );
    try {
      final payment = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedPayment: payment);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<Payment?> recordInvoicePayment(
    String invoiceId,
    CreatePaymentPayload payload,
  ) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final payment = await _repository.recordInvoicePayment(
        invoiceId,
        payload,
      );
      final updatedPayments = [
        for (final item in state.payments)
          if (item.localId == payment.localId ||
              item.serverId == payment.serverId)
            payment
          else
            item,
      ];
      if (!updatedPayments.any(
        (item) =>
            item.localId == payment.localId ||
            item.serverId == payment.serverId,
      )) {
        updatedPayments.insert(0, payment);
      }
      state = state.copyWith(
        isMutating: false,
        selectedPayment: payment,
        payments: updatedPayments,
      );
      return payment;
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
