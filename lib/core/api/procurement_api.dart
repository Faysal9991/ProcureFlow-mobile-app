import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'api_dtos.dart';

part 'procurement_api.g.dart';

@RestApi()
abstract class ProcurementApi {
  factory ProcurementApi(Dio dio, {String baseUrl}) = _ProcurementApi;

  @POST('/auth/login')
  Future<LoginResponseDto> login(@Body() LoginRequestDto request);

  @POST('/purchase-requests')
  Future<PurchaseRequestSyncResponseDto> createPurchaseRequest(
    @Body() PurchaseRequestSyncRequestDto request,
  );

  @POST('/purchase-requests/{serverId}/approval-actions')
  Future<void> submitApprovalAction(
    @Path('serverId') String serverId,
    @Body() ApprovalActionRequestDto request,
  );

  @GET('/vendors')
  Future<List<VendorDto>> getVendors(@Query('company_id') String companyId);
}
