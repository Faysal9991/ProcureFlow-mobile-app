import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'budget_controller.dart';

class BudgetTransactionsScreen extends ConsumerStatefulWidget {
  const BudgetTransactionsScreen({super.key, required this.budgetId});

  final String budgetId;

  @override
  ConsumerState<BudgetTransactionsScreen> createState() =>
      _BudgetTransactionsScreenState();
}

class _BudgetTransactionsScreenState
    extends ConsumerState<BudgetTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetControllerProvider);
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final date = DateFormat.yMMMd().add_jm();
    return AppScaffold(
      title: 'Budget Transactions',
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && state.transactions.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null)
              AppEmptyCard(message: state.errorMessage!)
            else if (state.transactions.isEmpty)
              const AppEmptyCard(message: 'No budget transactions yet.')
            else
              for (final item in state.transactions)
                AppListTileCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  leading: const Icon(AppIcons.money),
                  title: Text(item.transactionType),
                  subtitle: Text(
                    '${item.description ?? 'No description'}\n'
                    '${date.format(item.createdAt)}',
                  ),
                  trailing: Text(currency.format(item.amount)),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(budgetControllerProvider.notifier)
        .loadTransactions(widget.budgetId);
  }
}
