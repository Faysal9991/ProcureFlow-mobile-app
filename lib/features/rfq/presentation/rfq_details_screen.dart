import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../attachments/domain/attachment_entity.dart';
import '../../attachments/presentation/attachment_section.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class RfqDetailsScreen extends ConsumerStatefulWidget {
  const RfqDetailsScreen({
    super.key,
    required this.rfqId,
    this.showBottomNavigation = true,
  });

  final String rfqId;
  final bool showBottomNavigation;

  @override
  ConsumerState<RfqDetailsScreen> createState() => _RfqDetailsScreenState();
}

class _RfqDetailsScreenState extends ConsumerState<RfqDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final rfq = state.selectedRfq;
    final session = ref.watch(authControllerProvider).session;

    return AppScaffold(
      title: 'RFQ Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && rfq == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && rfq == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (rfq == null)
              const AppEmptyCard(message: 'RFQ not found.')
            else ...[
              _RfqSummary(rfq: rfq),
              const SizedBox(height: 16),
              _AssignedVendors(rfq: rfq),
              const SizedBox(height: 16),
              _RfqItems(rfq: rfq),
              const SizedBox(height: 16),
              _Quotations(rfq: rfq),
              const SizedBox(height: 16),
              _RfqActions(
                rfq: rfq,
                isMutating: state.isMutating,
                canManage: PermissionPolicy.canManageRfq(session),
                onOpen: () => _open(rfq),
              ),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.rfq,
                entityId: rfq.localId,
                canView: PermissionPolicy.canViewAttachments(session: session),
                canUpload:
                    rfq.normalizedStatus != RfqStatus.completed &&
                    rfq.normalizedStatus != RfqStatus.cancelled &&
                    PermissionPolicy.canUploadAttachments(session: session),
                canDelete:
                    rfq.normalizedStatus != RfqStatus.completed &&
                    rfq.normalizedStatus != RfqStatus.cancelled &&
                    PermissionPolicy.canDeleteAttachments(session: session),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(rfqControllerProvider.notifier).loadDetail(widget.rfqId);
  }

  Future<void> _open(Rfq rfq) async {
    if (!PermissionPolicy.canManageRfq(
      ref.read(authControllerProvider).session,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission for this action.'),
        ),
      );
      return;
    }
    if (rfq.vendorCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please assign at least one vendor before opening this RFQ.',
          ),
        ),
      );
      return;
    }
    final opened = await ref
        .read(rfqControllerProvider.notifier)
        .openRfq(rfq.localId);
    if (!mounted || opened == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('RFQ opened.')));
  }
}

class _RfqSummary extends StatelessWidget {
  const _RfqSummary({required this.rfq});

  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  rfq.rfqNumber.isEmpty ? 'RFQ' : rfq.rfqNumber,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: rfq.normalizedStatus),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${rfq.purchaseRequestNumber} • ${rfq.purchaseRequestTitle}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (rfq.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(rfq.notes!),
          ],
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Due Date',
                value: rfq.dueDate == null
                    ? 'Not set'
                    : dateFormat.format(rfq.dueDate!),
              ),
              AppInfoItem(
                label: 'Assigned Vendors',
                value: '${rfq.vendorCount}',
              ),
              AppInfoItem(label: 'Quotations', value: '${rfq.quotationCount}'),
              AppInfoItem(
                label: 'Created',
                value: dateFormat.format(rfq.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedVendors extends StatelessWidget {
  const _AssignedVendors({required this.rfq});

  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Vendors',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (rfq.vendors.isEmpty)
          const AppEmptyCard(message: 'No vendors assigned.')
        else
          for (final vendor in rfq.vendors)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 10),
              leading: const Icon(AppIcons.vendors),
              title: Text(vendor.vendorName),
              subtitle: Text(
                [vendor.contactPerson, vendor.phone, vendor.email]
                    .whereType<String>()
                    .where((item) => item.isNotEmpty)
                    .join(' • '),
              ),
            ),
      ],
    );
  }
}

class _RfqItems extends StatelessWidget {
  const _RfqItems({required this.rfq});

  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RFQ Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (rfq.items.isEmpty)
          const AppEmptyCard(message: 'No RFQ items found.')
        else
          for (final item in rfq.items)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 10),
              leading: const Icon(AppIcons.item),
              title: Text(item.itemName),
              subtitle: Text('${_quantity(item.quantity)} ${item.unit}'),
              trailing: Text(currency.format(item.estimatedUnitPrice)),
            ),
      ],
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _Quotations extends StatelessWidget {
  const _Quotations({required this.rfq});

  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quotations', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (rfq.quotations.isEmpty)
          const AppEmptyCard(message: 'No quotations received.')
        else
          for (final quotation in rfq.quotations)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 10),
              leading: const Icon(AppIcons.money),
              title: Text(quotation.quotationNumber),
              subtitle: Text(quotation.vendorName),
              trailing: Text(currency.format(quotation.totalAmount)),
              onTap: () => context.push(
                '/rfqs/${rfq.localId}/quotations/${quotation.localId}',
              ),
            ),
      ],
    );
  }
}

class _RfqActions extends StatelessWidget {
  const _RfqActions({
    required this.rfq,
    required this.isMutating,
    required this.canManage,
    required this.onOpen,
  });

  final Rfq rfq;
  final bool isMutating;
  final bool canManage;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (rfq.canAddVendors && canManage) {
      actions.add(
        OutlinedButton.icon(
          key: const Key('addRfqVendorsButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/rfqs/${rfq.localId}/vendors'),
          icon: const Icon(AppIcons.vendors),
          label: const Text('Add Vendors'),
        ),
      );
    }
    if (rfq.canOpen && canManage) {
      actions.add(
        FilledButton.icon(
          key: const Key('openRfqButton'),
          onPressed: isMutating ? null : onOpen,
          icon: const Icon(AppIcons.send),
          label: const Text('Open RFQ'),
        ),
      );
    }
    if (rfq.canAddQuotations && canManage) {
      actions.add(
        FilledButton.icon(
          key: const Key('addRfqQuotationButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/rfqs/${rfq.localId}/quotations'),
          icon: const Icon(AppIcons.money),
          label: const Text('Add Quotations'),
        ),
      );
    }
    if (rfq.canCompareQuotations) {
      actions.add(
        OutlinedButton.icon(
          key: const Key('compareRfqQuotationsButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/rfqs/${rfq.localId}/comparison'),
          icon: const Icon(AppIcons.compare),
          label: const Text('Compare Quotations'),
        ),
      );
    }
    if (actions.isEmpty) {
      return const AppEmptyCard(message: 'No actions available.');
    }
    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }
}
