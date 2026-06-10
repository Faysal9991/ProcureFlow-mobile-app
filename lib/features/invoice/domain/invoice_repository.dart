import 'invoice_entity.dart';

abstract interface class InvoiceRepository {
  Future<InvoicePage> getInvoices(InvoiceFilters filters);

  Future<Invoice> create(CreateInvoicePayload payload);

  Future<Invoice?> getById(String id);

  Future<Invoice> update(String id, UpdateInvoicePayload payload);

  Future<Invoice> cancel(String id);

  Future<Invoice?> getByPurchaseOrderId(String purchaseOrderId);
}
