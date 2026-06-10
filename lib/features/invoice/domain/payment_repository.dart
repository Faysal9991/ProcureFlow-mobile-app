import 'payment_entity.dart';

abstract interface class PaymentRepository {
  Future<PaymentPage> getPayments(PaymentFilters filters);

  Future<Payment?> getById(String id);

  Future<Payment> recordInvoicePayment(
    String invoiceId,
    CreatePaymentPayload payload,
  );
}
