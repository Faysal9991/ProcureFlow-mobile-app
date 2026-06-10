import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class QuotationEntryScreen extends ConsumerStatefulWidget {
  const QuotationEntryScreen({
    super.key,
    required this.rfqId,
    this.showBottomNavigation = true,
  });

  final String rfqId;
  final bool showBottomNavigation;

  @override
  ConsumerState<QuotationEntryScreen> createState() =>
      _QuotationEntryScreenState();
}

class _QuotationEntryScreenState extends ConsumerState<QuotationEntryScreen> {
  final _quotationNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _unitPriceControllers = {};

  String? _vendorId;
  DateTime? _quotationDate;
  DateTime? _validUntil;
  bool _hydrated = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(rfqControllerProvider.notifier).loadDetail(widget.rfqId),
    );
  }

  @override
  void dispose() {
    _quotationNumberController.dispose();
    _notesController.dispose();
    for (final controller in _unitPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final rfq = state.selectedRfq;
    if (rfq != null && !_hydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hydrated) {
          _hydrate(rfq);
        }
      });
    }

    return AppScaffold(
      title: 'Add Quotation',
      showBottomNavigation: widget.showBottomNavigation,
      child: Builder(
        builder: (context) {
          if (state.isLoading && rfq == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && rfq == null) {
            return AppScreenListView(
              children: [AppEmptyCard(message: state.errorMessage!)],
            );
          }
          if (rfq == null) {
            return const AppScreenListView(
              children: [AppEmptyCard(message: 'RFQ not found.')],
            );
          }
          if (rfq.vendors.isEmpty) {
            return const AppScreenListView(
              children: [
                AppEmptyCard(
                  message: 'Assign vendors before entering quotations.',
                ),
              ],
            );
          }
          return _QuotationForm(
            rfq: rfq,
            vendorId: _vendorId,
            quotationNumberController: _quotationNumberController,
            notesController: _notesController,
            unitPriceControllers: _unitPriceControllers,
            quotationDate: _quotationDate,
            validUntil: _validUntil,
            submitted: _submitted,
            isMutating: state.isMutating,
            errorMessage: state.errorMessage,
            onVendorChanged: (value) => setState(() => _vendorId = value),
            onPickQuotationDate: () => _selectDate(isQuotationDate: true),
            onPickValidUntil: () => _selectDate(isQuotationDate: false),
            onChanged: () => setState(() {}),
            onSubmit: _submit,
          );
        },
      ),
    );
  }

  void _hydrate(Rfq rfq) {
    _vendorId ??= rfq.vendors.isEmpty ? null : rfq.vendors.first.vendorId;
    _quotationDate ??= DateTime.now();
    for (final item in rfq.items) {
      _unitPriceControllers.putIfAbsent(item.id, () => TextEditingController());
    }
    _hydrated = true;
    setState(() {});
  }

  Future<void> _selectDate({required bool isQuotationDate}) async {
    final now = DateTime.now();
    final current = isQuotationDate ? _quotationDate : _validUntil;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() {
        if (isQuotationDate) {
          _quotationDate = selected;
        } else {
          _validUntil = selected;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final rfq = ref.read(rfqControllerProvider).selectedRfq;
    if (rfq == null || !_isValid(rfq)) return;
    final quotation = await ref
        .read(rfqControllerProvider.notifier)
        .createQuotation(
          widget.rfqId,
          CreateQuotationPayload(
            vendorId: _vendorId!,
            quotationNumber: _quotationNumberController.text.trim(),
            quotationDate: _quotationDate,
            validUntil: _validUntil,
            notes: _blankToNull(_notesController.text),
            items: [
              for (final item in rfq.items)
                CreateQuotationItemInput(
                  rfqItemId: item.id,
                  itemName: item.itemName,
                  quantity: item.quantity,
                  unitPrice:
                      double.tryParse(
                        _unitPriceControllers[item.id]?.text ?? '',
                      ) ??
                      0,
                ),
            ],
          ),
        );
    if (!mounted || quotation == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quotation saved.')));
    context.replace('/rfqs/${widget.rfqId}');
  }

  bool _isValid(Rfq rfq) {
    if (_vendorId == null || _quotationNumberController.text.trim().isEmpty) {
      return false;
    }
    if (_quotationDate == null || rfq.items.isEmpty) return false;
    for (final item in rfq.items) {
      final price = double.tryParse(_unitPriceControllers[item.id]?.text ?? '');
      if (price == null || price <= 0) return false;
    }
    return true;
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _QuotationForm extends StatelessWidget {
  const _QuotationForm({
    required this.rfq,
    required this.vendorId,
    required this.quotationNumberController,
    required this.notesController,
    required this.unitPriceControllers,
    required this.quotationDate,
    required this.validUntil,
    required this.submitted,
    required this.isMutating,
    required this.errorMessage,
    required this.onVendorChanged,
    required this.onPickQuotationDate,
    required this.onPickValidUntil,
    required this.onChanged,
    required this.onSubmit,
  });

  final Rfq rfq;
  final String? vendorId;
  final TextEditingController quotationNumberController;
  final TextEditingController notesController;
  final Map<String, TextEditingController> unitPriceControllers;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final bool submitted;
  final bool isMutating;
  final String? errorMessage;
  final ValueChanged<String?> onVendorChanged;
  final VoidCallback onPickQuotationDate;
  final VoidCallback onPickValidUntil;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final total = rfq.items.fold<double>(0, (sum, item) {
      final price = double.tryParse(unitPriceControllers[item.id]?.text ?? '');
      return sum + ((price ?? 0) * item.quantity);
    });

    return AppScreenListView(
      children: [
        AppSectionCard(
          padding: AppInsets.cardLarge,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('quotationVendorField-$vendorId'),
                initialValue: vendorId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Vendor',
                  prefixIcon: const Icon(AppIcons.vendors),
                  errorText: submitted && vendorId == null
                      ? 'Vendor is required'
                      : null,
                ),
                items: [
                  for (final vendor in rfq.vendors)
                    DropdownMenuItem(
                      value: vendor.vendorId,
                      child: Text(vendor.vendorName),
                    ),
                ],
                onChanged: onVendorChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('quotationNumberField'),
                controller: quotationNumberController,
                decoration: InputDecoration(
                  labelText: 'Quotation Number',
                  prefixIcon: const Icon(AppIcons.title),
                  errorText:
                      submitted && quotationNumberController.text.trim().isEmpty
                      ? 'Quotation number is required'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Quotation Date',
                      value: quotationDate == null
                          ? 'Select date'
                          : dateFormat.format(quotationDate!),
                      errorText: submitted && quotationDate == null
                          ? 'Quotation date is required'
                          : null,
                      onTap: onPickQuotationDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateField(
                      label: 'Valid Until',
                      value: validUntil == null
                          ? 'Optional'
                          : dateFormat.format(validUntil!),
                      onTap: onPickValidUntil,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
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
        const SizedBox(height: 16),
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in rfq.items)
          AppSectionCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('${_quantity(item.quantity)} ${item.unit}'),
                const SizedBox(height: 10),
                TextField(
                  key: Key('quotationUnitPriceField-${item.id}'),
                  controller: unitPriceControllers[item.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: 'Unit Price',
                    prefixIcon: const Icon(AppIcons.money),
                    errorText:
                        submitted &&
                            ((double.tryParse(
                                      unitPriceControllers[item.id]?.text ?? '',
                                    ) ??
                                    0) <=
                                0)
                        ? 'Enter unit price'
                        : null,
                  ),
                ),
              ],
            ),
          ),
        AppListTileCard(
          title: const Text('Quotation Total'),
          trailing: Text(
            currency.format(total),
            key: const Key('quotationTotalText'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          AppEmptyCard(message: errorMessage!),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('saveQuotationButton'),
          onPressed: isMutating ? null : onSubmit,
          icon: isMutating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.check),
          label: const Text('Save Quotation'),
        ),
      ],
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.controlBorder,
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(AppIcons.calendar),
          errorText: errorText,
        ),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
