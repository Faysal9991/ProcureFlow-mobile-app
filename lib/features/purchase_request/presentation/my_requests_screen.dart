import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import 'purchase_request_providers.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(purchaseRequestsProvider);
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppScaffold(
      title: 'My Requests',
      showBottomNavigation: showBottomNavigation,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/new'),
        icon: const Icon(AppIcons.add),
        label: const Text('Request'),
      ),
      child: AsyncValueView(
        value: requests,
        empty: const AppEmptyState(message: 'No purchase requests found.'),
        data: (items) {
          return AppSeparatedListView(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final request = items[index];
              return AppSectionCard(
                onTap: () => context.push('/requests/${request.localId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Requested by: ${request.requesterId}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(request.requestNumber)),
                        Text(
                          currency.format(request.totalAmount),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    StatusChip(status: request.syncStatus.label),
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
