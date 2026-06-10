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
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/vendor_entity.dart';
import 'vendor_controller.dart';
import 'vendor_providers.dart';

class VendorDetailsScreen extends ConsumerStatefulWidget {
  const VendorDetailsScreen({
    super.key,
    required this.vendorId,
    this.showBottomNavigation = true,
  });

  final String vendorId;
  final bool showBottomNavigation;

  @override
  ConsumerState<VendorDetailsScreen> createState() =>
      _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends ConsumerState<VendorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorControllerProvider);
    final vendor = state.selectedVendor;

    return AppScaffold(
      title: 'Vendor Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && vendor == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && vendor == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (vendor == null)
              const AppEmptyCard(message: 'Vendor not found.')
            else ...[
              _VendorSummary(vendor: vendor),
              const SizedBox(height: 16),
              _VendorActions(
                isMutating: state.isMutating,
                vendor: vendor,
                onDelete: () => _delete(vendor),
              ),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.vendor,
                entityId: vendor.localId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(vendorControllerProvider.notifier)
        .loadDetail(widget.vendorId);
  }

  Future<void> _delete(VendorEntity vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vendor?'),
        content: Text('${vendor.name} will be removed from active vendors.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteVendorButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await ref
        .read(vendorControllerProvider.notifier)
        .delete(vendor.localId);
    if (!mounted || !deleted) return;

    ref.invalidate(vendorsProvider);
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vendor deleted.')));
    context.go('/vendors');
  }
}

class _VendorSummary extends StatelessWidget {
  const _VendorSummary({required this.vendor});

  final VendorEntity vendor;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
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
                  vendor.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: vendor.normalizedStatus),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              if (vendor.contactPerson?.trim().isNotEmpty == true)
                AppInfoItem(
                  label: 'Contact Person',
                  value: vendor.contactPerson!.trim(),
                ),
              AppInfoItem(label: 'Phone', value: _fallback(vendor.phone)),
              AppInfoItem(label: 'Email', value: _fallback(vendor.email)),
              AppInfoItem(
                label: 'Created',
                value: dateFormat.format(vendor.createdAt),
              ),
              AppInfoItem(
                label: 'Updated',
                value: dateFormat.format(vendor.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(_fallback(vendor.address)),
        ],
      ),
    );
  }

  String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}

class _VendorActions extends StatelessWidget {
  const _VendorActions({
    required this.isMutating,
    required this.vendor,
    required this.onDelete,
  });

  final bool isMutating;
  final VendorEntity vendor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          key: const Key('editVendorButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/vendors/${vendor.localId}/edit'),
          icon: const Icon(AppIcons.description),
          label: const Text('Edit'),
        ),
        OutlinedButton.icon(
          key: const Key('deleteVendorButton'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: isMutating ? null : onDelete,
          icon: const Icon(AppIcons.trash),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
