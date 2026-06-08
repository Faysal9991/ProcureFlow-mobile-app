import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../vendor/presentation/vendor_providers.dart';

class QuotationCompareScreen extends ConsumerWidget {
  const QuotationCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorsProvider).valueOrNull ?? [];
    return AppScaffold(
      title: 'Quotation Compare',
      child: AppScreenListView(
        padding: AppInsets.compactScreen,
        children: [
          AppSectionCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Vendor')),
                  DataColumn(label: Text('Lead time')),
                  DataColumn(label: Text('Score')),
                ],
                rows: [
                  for (var index = 0; index < vendors.length; index++)
                    DataRow(
                      cells: [
                        DataCell(Text(vendors[index].name)),
                        DataCell(Text('${3 + index} days')),
                        DataCell(Text('${92 - (index * 7)}')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
