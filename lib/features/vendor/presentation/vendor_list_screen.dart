import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import 'vendor_providers.dart';

class VendorListScreen extends ConsumerWidget {
  const VendorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Vendor List',
      child: AsyncValueView(
        value: ref.watch(vendorsProvider),
        empty: const AppEmptyState(message: 'No vendors available.'),
        data: (vendors) {
          return AppSeparatedListView(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return AppListTileCard(
                leading: const Icon(AppIcons.store),
                title: Text(vendor.name),
                subtitle: Text(
                  [
                    vendor.email,
                    vendor.phone,
                    vendor.address,
                  ].whereType<String>().join(' • '),
                ),
                trailing: vendor.isActive
                    ? const Icon(AppIcons.circleCheck)
                    : const Icon(AppIcons.circlePause),
              );
            },
          );
        },
      ),
    );
  }
}
