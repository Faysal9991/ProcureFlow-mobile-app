import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/report_entity.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      child: AppScreenListView(
        children: [
          for (final type in ReportType.values)
            AppActionTile(
              icon: _icon(type),
              title: type.label,
              subtitle: 'View, filter, and export ${type.label.toLowerCase()}',
              onTap: () => context.push(type.route),
            ),
        ],
      ),
    );
  }

  IconData _icon(ReportType type) {
    return switch (type) {
      ReportType.purchaseRequests => AppIcons.list,
      ReportType.approvals => AppIcons.approval,
      ReportType.purchaseOrders => AppIcons.order,
      ReportType.invoices || ReportType.payments => AppIcons.money,
    };
  }
}
