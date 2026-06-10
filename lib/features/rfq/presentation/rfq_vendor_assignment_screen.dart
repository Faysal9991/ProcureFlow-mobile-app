import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../vendor/domain/vendor_entity.dart';
import '../../vendor/presentation/vendor_providers.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class RfqVendorAssignmentScreen extends ConsumerStatefulWidget {
  const RfqVendorAssignmentScreen({
    super.key,
    required this.rfqId,
    this.showBottomNavigation = true,
  });

  final String rfqId;
  final bool showBottomNavigation;

  @override
  ConsumerState<RfqVendorAssignmentScreen> createState() {
    return _RfqVendorAssignmentScreenState();
  }
}

class _RfqVendorAssignmentScreenState
    extends ConsumerState<RfqVendorAssignmentScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedVendorIds = {};
  List<VendorEntity> _vendors = const [];
  String? _errorMessage;
  bool _loadingVendors = false;
  bool _selectionHydrated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(rfqControllerProvider.notifier).loadDetail(widget.rfqId);
      await _loadVendors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final rfq = state.selectedRfq;
    if (rfq != null && !_selectionHydrated) {
      _selectedVendorIds
        ..clear()
        ..addAll(rfq.vendors.map((vendor) => vendor.vendorId));
      _selectionHydrated = true;
    }

    return AppScaffold(
      title: 'Assign Vendors',
      showBottomNavigation: widget.showBottomNavigation,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('rfqVendorSearchField'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _loadVendors(),
                    decoration: const InputDecoration(
                      labelText: 'Search Vendors',
                      prefixIcon: Icon(AppIcons.list),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  key: const Key('rfqVendorSearchButton'),
                  tooltip: 'Search',
                  onPressed: _loadVendors,
                  icon: const Icon(AppIcons.check),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (state.isLoading && rfq == null)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_loadingVendors)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_vendors.isEmpty)
            const AppEmptyCard(message: 'No active vendors found.')
          else
            for (final vendor in _vendors)
              CheckboxListTile(
                key: Key('rfqVendorCheckbox-${vendor.localId}'),
                value: _selectedVendorIds.contains(vendor.localId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedVendorIds.add(vendor.localId);
                    } else {
                      _selectedVendorIds.remove(vendor.localId);
                    }
                    _errorMessage = null;
                  });
                },
                title: Text(vendor.name),
                subtitle: vendor.contactPerson?.trim().isNotEmpty == true
                    ? Text(vendor.contactPerson!)
                    : vendor.phone?.trim().isNotEmpty == true
                    ? Text(vendor.phone!)
                    : null,
              ),
          if (_errorMessage != null || state.errorMessage != null) ...[
            const SizedBox(height: 12),
            AppEmptyCard(message: _errorMessage ?? state.errorMessage!),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('saveRfqVendorsButton'),
            onPressed: state.isMutating ? null : _save,
            icon: state.isMutating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.check),
            label: const Text('Save Vendors'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loadingVendors = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(vendorRepositoryProvider)
          .getVendors(
            VendorFilters(
              search: _blankToNull(_searchController.text),
              status: VendorStatus.active,
              limit: 100,
            ),
          );
      if (mounted) {
        setState(() {
          _vendors = page.items;
          _loadingVendors = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _messageFromError(error);
          _loadingVendors = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_selectedVendorIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one vendor.');
      return;
    }
    final rfq = await ref
        .read(rfqControllerProvider.notifier)
        .assignVendors(
          widget.rfqId,
          AssignRfqVendorsPayload(vendorIds: _selectedVendorIds.toList()),
        );
    if (!mounted || rfq == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vendors assigned.')));
    context.replace('/rfqs/${rfq.localId}');
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
