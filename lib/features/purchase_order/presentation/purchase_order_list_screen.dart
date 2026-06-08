import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import 'purchase_order_providers.dart';

class PurchaseOrderListScreen extends ConsumerWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppScaffold(
      title: 'Purchase Orders',
      child: AsyncValueView(
        value: ref.watch(purchaseOrdersProvider),
        empty: const AppEmptyState(message: 'No purchase orders created yet.'),
        data: (orders) {
          return AppSeparatedListView(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return AppSectionCard(
                child: Row(
                  children: [
                    Icon(
                      AppIcons.order,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.poNumber,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusChip(status: order.status),
                              StatusChip(status: order.syncStatus.label),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(order.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
