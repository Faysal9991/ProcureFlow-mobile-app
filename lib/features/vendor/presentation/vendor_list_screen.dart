import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/vendor_entity.dart';
import 'vendor_controller.dart';
import 'vendor_state.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  final _searchController = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorControllerProvider);

    return AppScaffold(
      title: 'Vendors',
      showBottomNavigation: widget.showBottomNavigation,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createVendorButton'),
        onPressed: () => context.push('/vendors/new'),
        icon: const Icon(AppIcons.add),
        label: const Text('Create'),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _VendorFiltersCard(
              searchController: _searchController,
              status: _status,
              onStatusChanged: (value) => setState(() => _status = value),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _VendorList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(vendorControllerProvider.notifier).loadList();
  }

  Future<void> _applyFilters() {
    return ref
        .read(vendorControllerProvider.notifier)
        .loadList(
          VendorFilters(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            status: _status,
          ),
        );
  }

  Future<void> _clearFilters() {
    setState(() {
      _searchController.clear();
      _status = null;
    });
    return ref
        .read(vendorControllerProvider.notifier)
        .loadList(const VendorFilters());
  }
}

class _VendorFiltersCard extends StatelessWidget {
  const _VendorFiltersCard({
    required this.searchController,
    required this.status,
    required this.onStatusChanged,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('vendorSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.list),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey('vendorStatusFilter-$status'),
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(AppIcons.circleCheck),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(
                value: VendorStatus.active,
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: VendorStatus.inactive,
                child: Text('Inactive'),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              const Spacer(),
              FilledButton.icon(
                key: const Key('vendorFilterApplyButton'),
                onPressed: onApply,
                icon: const Icon(AppIcons.check),
                label: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorList extends StatelessWidget {
  const _VendorList({required this.state});

  final VendorState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.vendors.isEmpty) {
      return const AppSectionCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return AppEmptyCard(message: state.errorMessage!);
    }

    if (state.vendors.isEmpty) {
      return const AppEmptyCard(message: 'No vendors found.');
    }

    return Column(
      children: [
        for (final vendor in state.vendors) _VendorCard(vendor: vendor),
      ],
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor});

  final VendorEntity vendor;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (vendor.contactPerson?.trim().isNotEmpty == true)
        vendor.contactPerson!.trim(),
      if (vendor.phone?.trim().isNotEmpty == true) vendor.phone!.trim(),
      if (vendor.email?.trim().isNotEmpty == true) vendor.email!.trim(),
    ];

    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.vendors),
      title: Text(vendor.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
      trailing: StatusChip(status: vendor.normalizedStatus),
      onTap: () => context.push('/vendors/${vendor.localId}'),
    );
  }
}
