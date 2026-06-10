import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class RfqCreateScreen extends ConsumerStatefulWidget {
  const RfqCreateScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<RfqCreateScreen> createState() => _RfqCreateScreenState();
}

class _RfqCreateScreenState extends ConsumerState<RfqCreateScreen> {
  final _notesController = TextEditingController();
  String? _purchaseRequestId;
  DateTime? _dueDate;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(rfqControllerProvider.notifier)
          .loadEligiblePurchaseRequests(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final dateFormat = DateFormat.yMMMd();

    return AppScaffold(
      title: 'New RFQ',
      showBottomNavigation: widget.showBottomNavigation,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            padding: AppInsets.cardLarge,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('rfqPurchaseRequestField-$_purchaseRequestId'),
                  initialValue: _purchaseRequestId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Purchase Request',
                    prefixIcon: const Icon(AppIcons.list),
                    errorText: _submitted && _purchaseRequestId == null
                        ? 'Purchase request is required'
                        : null,
                  ),
                  items: [
                    for (final request in state.eligiblePurchaseRequests)
                      DropdownMenuItem(
                        value: request.id,
                        child: Text(
                          '${request.requestNumber} • ${request.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _purchaseRequestId = value);
                  },
                ),
                if (state.isLoading &&
                    state.eligiblePurchaseRequests.isEmpty) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (!state.isLoading &&
                    state.eligiblePurchaseRequests.isEmpty) ...[
                  const SizedBox(height: 12),
                  const AppEmptyCard(
                    message: 'No approved purchase requests are eligible.',
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: AppRadius.controlBorder,
                  onTap: _selectDueDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(AppIcons.calendar),
                      errorText: _submitted && _dueDate == null
                          ? 'Due date is required'
                          : null,
                    ),
                    child: Text(
                      _dueDate == null
                          ? 'Select date'
                          : dateFormat.format(_dueDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('rfqNotesField'),
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(AppIcons.description),
                  ),
                ),
              ],
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            AppEmptyCard(message: state.errorMessage!),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('saveRfqButton'),
            onPressed: state.isMutating ? null : _create,
            icon: state.isMutating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.check),
            label: const Text('Create RFQ'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _create() async {
    setState(() => _submitted = true);
    if (_purchaseRequestId == null || _dueDate == null) return;
    final rfq = await ref
        .read(rfqControllerProvider.notifier)
        .createRfq(
          CreateRfqPayload(
            purchaseRequestId: _purchaseRequestId!,
            dueDate: _dueDate,
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || rfq == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('RFQ created.')));
    context.replace('/rfqs/${rfq.localId}/vendors');
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
