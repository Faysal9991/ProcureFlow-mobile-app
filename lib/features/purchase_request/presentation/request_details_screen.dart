import 'purchase_request_details_screen.dart';

class RequestDetailsScreen extends PurchaseRequestDetailsScreen {
  const RequestDetailsScreen({
    super.key,
    required String localId,
    super.showBottomNavigation,
  }) : super(requestId: localId);
}
