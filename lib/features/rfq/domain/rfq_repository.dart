import 'rfq_entity.dart';

abstract interface class RfqRepository {
  Future<RfqPage> getRfqs(RfqFilters filters);

  Future<Rfq> createRfq(CreateRfqPayload payload);

  Future<Rfq?> getById(String id);

  Future<Rfq> assignVendors(String id, AssignRfqVendorsPayload payload);

  Future<Rfq> openRfq(String id);

  Future<Quotation> createQuotation(String id, CreateQuotationPayload payload);

  Future<RfqComparison> getComparison(String id);

  Future<Rfq> selectQuotation(String id, SelectedQuotationPayload payload);

  Future<List<EligiblePurchaseRequest>> getEligiblePurchaseRequests({
    int page = 1,
    int limit = 20,
  });
}
