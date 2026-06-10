import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/invoice_repository_impl.dart';
import '../data/payment_repository_impl.dart';
import '../domain/invoice_entity.dart';
import '../domain/invoice_repository.dart';
import '../domain/payment_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});

final invoiceForPurchaseOrderProvider = FutureProvider.autoDispose
    .family<Invoice?, String>((ref, purchaseOrderId) {
      return ref
          .watch(invoiceRepositoryProvider)
          .getByPurchaseOrderId(purchaseOrderId);
    });

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});
